import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/widgets/app_refresh_indicator.dart';

/// 다른 프로젝트에서 iCloud 동기화 구조를 붙일 때 참고하는 예제 파일.
///
/// 이 파일은 실제 앱 로직에 연결되지 않는 샘플이다.
/// 복붙해서 "내 Repository / 내 Model"에 맞게 바꿔 쓰면 된다.

class ExampleItem {
  const ExampleItem({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime updatedAt;

  ExampleItem copyWith({
    String? id,
    String? title,
    DateTime? updatedAt,
  }) {
    return ExampleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

abstract class ExampleItemRepository {
  Future<List<ExampleItem>> fetchItems();
  Future<void> saveItem(ExampleItem item);
  Future<void> deleteItem(String id);
}

class ExampleICloudController extends GetxController {
  ExampleICloudController(this._repository);

  final ExampleItemRepository _repository;
  final ICloudSyncService _iCloudSync = ICloudSyncService();
  final ICloudSyncSettingsService _settings = ICloudSyncSettingsService();

  final items = <ExampleItem>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// 화면 진입 시:
  /// 1. CloudKit -> local pull
  /// 2. local DB 조회
  Future<void> load() async {
    isLoading.value = true;
    try {
      await _iCloudSync.pullIfEnabled();
      items.assignAll(await _repository.fetchItems());
    } finally {
      isLoading.value = false;
    }
  }

  /// 데이터 저장 시:
  /// 1. local DB 저장
  /// 2. local -> CloudKit 백그라운드 업로드
  /// 3. local DB 재조회
  Future<void> saveItem(ExampleItem item) async {
    isLoading.value = true;
    try {
      await _repository.saveItem(
        item.copyWith(updatedAt: DateTime.now()),
      );
      _iCloudSync.schedulePushIfEnabled();
      items.assignAll(await _repository.fetchItems());
    } finally {
      isLoading.value = false;
    }
  }

  /// 삭제 시에도 local 삭제 후 전체 스냅샷을 다시 올리는 방식으로 맞춘다.
  Future<void> deleteItem(String id) async {
    isLoading.value = true;
    try {
      await _repository.deleteItem(id);
      _iCloudSync.schedulePushIfEnabled();
      items.assignAll(await _repository.fetchItems());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setICloudEnabled(bool enabled) async {
    await _settings.setEnabled(enabled);
  }
}

class ExampleICloudScreen extends GetView<ExampleICloudController> {
  const ExampleICloudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: const Text('Example iCloud Screen')),
        body:
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator.adaptive())
                : AppRefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.updatedAt.toIso8601String()),
                        trailing: IconButton(
                          onPressed: () => controller.deleteItem(item.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap:
                            () => controller.saveItem(
                              item.copyWith(title: '${item.title} (edited)'),
                            ),
                      );
                    },
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              () => controller.saveItem(
                ExampleItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: 'New Item',
                  updatedAt: DateTime.now(),
                ),
              ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

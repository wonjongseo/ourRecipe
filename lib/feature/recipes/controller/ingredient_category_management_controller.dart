import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';

class IngredientCategoryManagementController extends GetxController {
  IngredientCategoryManagementController(this._repository);
  final IngredientCategoryRepository _repository;
  final ICloudSyncService _iCloudSync = ICloudSyncService();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final inputCtrl = TextEditingController();
  final customCategories = <String>[].obs;
  String get languageCode => Get.locale?.languageCode ?? 'ja';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    try {
      _isLoading.value = true;
      await _syncFromICloudIfEnabled();
      final values = await _repository.fetchCustomCategories();
      values.sort();
      customCategories.assignAll(values);
    } catch (e) {
      LogManager.error('$e');
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> add() async {
    final value = inputCtrl.text.trim();
    if (value.isEmpty) return;
    try {
      await _repository.addCustomCategory(value);
      await _syncPushPullIfEnabled();
      inputCtrl.clear();
      await load();
    } catch (e, s) {
      LogManager.error('Add custom ingredient category failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    }
  }

  Future<void> remove(String value) async {
    try {
      await _repository.removeCustomCategory(value);
      await _syncPushPullIfEnabled();
      await load();
    } catch (e, s) {
      LogManager.error(
        'Remove custom ingredient category failed',
        error: e,
        stackTrace: s,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    }
  }

  Future<void> _syncPushPullIfEnabled() async {
    await _iCloudSync.pushPullIfEnabled();
  }

  Future<void> _syncFromICloudIfEnabled() async {
    await _iCloudSync.pullIfEnabled();
  }
}

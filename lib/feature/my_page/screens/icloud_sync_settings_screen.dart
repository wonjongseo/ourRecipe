import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/my_page/controller/my_page_controller.dart';

class ICloudSyncSettingsScreen extends GetView<MyPageController> {
  const ICloudSyncSettingsScreen({super.key});

  static const String name = '/icloud_sync_settings';

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).colorScheme.outline;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final canUseICloud = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.iCloudSync.tr)),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.iCloudStatusMessage.value.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(controller.iCloudStatusMessage.value),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: SwitchListTile(
                  value: controller.iCloudSyncEnabled.value,
                  onChanged:
                      canUseICloud && !controller.isICloudSyncUpdating.value
                          ? controller.changeICloudSync
                          : null,
                  secondary: const Icon(Icons.cloud_sync_outlined),
                  title: Text(AppStrings.iCloudSync.tr),
                  subtitle: Text(
                    controller.isICloudSyncUpdating.value
                        ? AppStrings.loading.tr
                        : AppStrings.iCloudSyncDescription.tr,
                  ),
                ),
              ),
              if (controller.iCloudSyncEnabled.value) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed:
                        controller.isICloudSyncUpdating.value
                            ? null
                            : controller.uploadLocalDataToICloud,
                    child: Text(AppStrings.uploadToICloud.tr),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.iCloudUploadButtonGuide.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: hintColor, height: 1.45),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed:
                        controller.isICloudSyncUpdating.value
                            ? null
                            : controller.downloadICloudDataToLocal,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(AppStrings.downloadFromICloud.tr),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.iCloudDownloadButtonGuide.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: hintColor, height: 1.45),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton.tonal(
                    onPressed:
                        controller.isICloudSyncUpdating.value
                            ? null
                            : _onTapDeleteAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                    child: Text(AppStrings.deleteAllICloudData.tr),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.iCloudDeleteButtonGuide.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: hintColor, height: 1.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapDeleteAll() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteAllICloudData.tr),
        content: Text(AppStrings.deleteAllICloudDataDescription.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppStrings.cancel.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.delete.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteAllICloudData();
  }
}

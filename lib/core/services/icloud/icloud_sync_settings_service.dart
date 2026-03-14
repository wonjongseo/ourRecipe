import 'dart:io';

import 'package:get/get.dart';
import 'package:our_recipe/core/services/premium_service.dart';
import 'package:our_recipe/core/services/shared_preferences_service.dart';

class ICloudSyncSettingsService {
  ICloudSyncSettingsService({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  static const String _iCloudSyncEnabledKey = 'icloud_sync_enabled';
  static const String _deletedRecipeTombstonesKey =
      'icloud_deleted_recipe_tombstones';
  final SharedPreferencesService _storage;

  Future<bool> isEnabled() async {
    final saved = await _storage.getBool(_iCloudSyncEnabledKey);
    if (!Platform.isIOS) return false;
    final isPremium =
        Get.isRegistered<PremiumService>() && Get.find<PremiumService>().canUseICloud;
    return (saved ?? false) && isPremium;
  }

  Future<void> setEnabled(bool enabled) async {
    if (!Platform.isIOS) {
      await _storage.setBool(_iCloudSyncEnabledKey, false);
      return;
    }
    final isPremium =
        Get.isRegistered<PremiumService>() && Get.find<PremiumService>().canUseICloud;
    if (enabled && !isPremium) {
      await _storage.setBool(_iCloudSyncEnabledKey, false);
      return;
    }
    await _storage.setBool(_iCloudSyncEnabledKey, enabled);
  }

  Future<Map<String, String>> getDeletedRecipeTombstones() async {
    return await _storage.getJson<Map<String, String>>(_deletedRecipeTombstonesKey, (
      decoded,
    ) {
      final map = (decoded as Map<Object?, Object?>?) ?? const {};
      return map.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }) ??
        <String, String>{};
  }

  Future<void> saveDeletedRecipeTombstones(Map<String, String> tombstones) async {
    await _storage.setJson(_deletedRecipeTombstonesKey, tombstones);
  }

  Future<void> markRecipeDeleted(String recipeId, DateTime deletedAt) async {
    final tombstones = await getDeletedRecipeTombstones();
    tombstones[recipeId] = deletedAt.toIso8601String();
    await saveDeletedRecipeTombstones(tombstones);
  }

  Future<void> clearDeletedRecipe(String recipeId) async {
    final tombstones = await getDeletedRecipeTombstones();
    if (tombstones.remove(recipeId) != null) {
      await saveDeletedRecipeTombstones(tombstones);
    }
  }
}

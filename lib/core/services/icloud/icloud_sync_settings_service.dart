import 'package:our_recipe/core/services/shared_preferences_service.dart';

class ICloudSyncSettingsService {
  ICloudSyncSettingsService({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  static const String _iCloudSyncEnabledKey = 'icloud_sync_enabled';
  final SharedPreferencesService _storage;

  Future<bool> isEnabled() async {
    final saved = await _storage.getBool(_iCloudSyncEnabledKey);
    // 기본값은 OFF.
    return saved ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.setBool(_iCloudSyncEnabledKey, enabled);
  }
}

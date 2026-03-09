import 'package:flutter/material.dart';
import 'package:our_recipe/core/services/shared_preferences_service.dart';

class ThemeService {
  ThemeService({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  static const String _themeModeKey = 'app_theme_mode';
  final SharedPreferencesService _storage;

  Future<ThemeMode?> getSavedThemeMode() async {
    final value = await _storage.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.setString(_themeModeKey, value);
  }
}

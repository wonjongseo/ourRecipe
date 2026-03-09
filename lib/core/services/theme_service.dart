import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/services/shared_preferences_service.dart';

class ThemeService {
  ThemeService({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _fontKey = 'app_font_key';
  static const String _textScaleKey = 'app_text_scale';
  static final RxDouble textScale = 1.0.obs;
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

  Future<String?> getSavedFontKey() async {
    return _storage.getString(_fontKey);
  }

  Future<void> saveFontKey(String key) async {
    await _storage.setString(_fontKey, key);
  }

  Future<double?> getSavedTextScale() async {
    return _storage.getDouble(_textScaleKey);
  }

  Future<void> saveTextScale(double value) async {
    await _storage.setDouble(_textScaleKey, value);
  }
}

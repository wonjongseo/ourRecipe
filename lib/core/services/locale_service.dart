import 'package:flutter/material.dart';
import 'package:our_recipe/core/services/shared_preferences_service.dart';

class LocaleService {
  LocaleService({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  static const String _localeKey = 'app_locale';
  final SharedPreferencesService _storage;

  Future<Locale?> getSavedLocale() async {
    final value = await _storage.getString(_localeKey);
    if (value == null || value.isEmpty) return null;
    final parts = value.split('_');
    if (parts.length != 2) return null;
    return Locale(parts[0], parts[1]);
  }

  Future<void> saveLocale(Locale locale) async {
    await _storage.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  Future<String?> getString(String key) async {
    return (await _prefs).getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return (await _prefs).setString(key, value);
  }

  Future<bool> remove(String key) async {
    return (await _prefs).remove(key);
  }

  Future<T?> getJson<T>(
    String key,
    T Function(Object? decoded) decoder,
  ) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return decoder(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, Object value) async {
    return setString(key, jsonEncode(value));
  }
}

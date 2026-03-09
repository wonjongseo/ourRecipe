import 'dart:convert';

import 'package:our_recipe/core/services/shared_preferences_service.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_storage_keys.dart';

class CookLogRepository {
  CookLogRepository({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  final SharedPreferencesService _storage;

  Future<List<CookLogModel>> fetchCookLogs() async {
    final raw = await _storage.getString(RecipeStorageKeys.cookLogs);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CookLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCookLog(CookLogModel cookLog) async {
    final logs = await fetchCookLogs();
    final index = logs.indexWhere((item) => item.id == cookLog.id);
    if (index == -1) {
      logs.add(cookLog);
    } else {
      logs[index] = cookLog;
    }
    await saveCookLogs(logs);
  }

  Future<void> saveCookLogs(List<CookLogModel> logs) async {
    final encoded = jsonEncode(logs.map((item) => item.toJson()).toList());
    await _storage.setString(RecipeStorageKeys.cookLogs, encoded);
  }

  Future<void> deleteCookLog(String cookLogId) async {
    final logs = await fetchCookLogs();
    logs.removeWhere((item) => item.id == cookLogId);
    await saveCookLogs(logs);
  }
}

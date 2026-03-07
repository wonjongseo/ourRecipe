import 'dart:convert';

import 'package:our_recipe/core/services/shared_preferences_service.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_storage_keys.dart';

class RecipeRepository {
  RecipeRepository({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  final SharedPreferencesService _storage;

  Future<List<RecipeModel>> fetchRecipes() async {
    final raw = await _storage.getString(RecipeStorageKeys.recipes);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecipe(RecipeModel recipe) async {
    final recipes = await fetchRecipes();
    final index = recipes.indexWhere((item) => item.id == recipe.id);
    if (index == -1) {
      recipes.add(recipe);
    } else {
      recipes[index] = recipe;
    }
    await saveRecipes(recipes);
  }

  Future<void> saveRecipes(List<RecipeModel> recipes) async {
    final encoded = jsonEncode(recipes.map((item) => item.toJson()).toList());
    await _storage.setString(RecipeStorageKeys.recipes, encoded);
  }

  Future<void> deleteRecipe(String recipeId) async {
    final recipes = await fetchRecipes();
    recipes.removeWhere((item) => item.id == recipeId);
    await saveRecipes(recipes);
  }

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

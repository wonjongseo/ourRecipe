import 'dart:convert';

import 'package:our_recipe/core/services/shared_preferences_service.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_storage_keys.dart';

class RecipeCategoryRepository {
  RecipeCategoryRepository({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  final SharedPreferencesService _storage;

  Future<List<String>> fetchCategories() async {
    final raw = await _storage.getString(RecipeStorageKeys.categories);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCategories(List<String> categories) async {
    final normalized =
        categories
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
    final encoded = jsonEncode(normalized);
    await _storage.setString(RecipeStorageKeys.categories, encoded);
  }

  Future<void> addCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final categories = await fetchCategories();
    if (categories.contains(value)) return;
    categories.add(value);
    await saveCategories(categories);
  }

  Future<void> removeCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final categories = await fetchCategories();
    categories.removeWhere((item) => item == value);
    await saveCategories(categories);
  }
}

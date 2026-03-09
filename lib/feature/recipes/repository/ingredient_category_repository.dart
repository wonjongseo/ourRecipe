import 'dart:convert';

import 'package:our_recipe/core/services/shared_preferences_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_storage_keys.dart';

class IngredientCategoryRepository {
  IngredientCategoryRepository({SharedPreferencesService? storage})
    : _storage = storage ?? SharedPreferencesService();

  final SharedPreferencesService _storage;

  Future<List<String>> fetchCustomCategories() async {
    final raw = await _storage.getString(RecipeStorageKeys.ingredientCategories);
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

  Future<List<String>> fetchAllCategories() async {
    final custom = await fetchCustomCategories();
    return [...IngredientCategoryCatalog.defaultIds, ...custom];
  }

  Future<void> saveCustomCategories(List<String> categories) async {
    final normalized =
        categories
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .where((item) => !IngredientCategoryCatalog.isDefaultId(item))
            .toSet()
            .toList();
    final encoded = jsonEncode(normalized);
    await _storage.setString(RecipeStorageKeys.ingredientCategories, encoded);
  }

  Future<void> addCustomCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final normalized = IngredientCategoryCatalog.normalizeDefaultId(value);
    if (IngredientCategoryCatalog.isDefaultId(normalized)) return;
    final categories = await fetchCustomCategories();
    if (categories.contains(value)) return;
    categories.add(value);
    await saveCustomCategories(categories);
  }

  Future<void> removeCustomCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final categories = await fetchCustomCategories();
    categories.removeWhere((item) => item == value);
    await saveCustomCategories(categories);
  }
}

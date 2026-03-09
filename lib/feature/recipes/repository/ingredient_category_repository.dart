import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';
import 'package:sqflite/sqflite.dart';

class IngredientCategoryRepository {
  IngredientCategoryRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;

  Future<List<String>> fetchCustomCategories() async {
    final db = await _database.db;
    final rows = await db.query(RecipeDatabaseService.ingredientCategories);
    return rows
        .map((row) => (row['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
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
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(RecipeDatabaseService.ingredientCategories);
      for (final category in normalized) {
        await txn.insert(
          RecipeDatabaseService.ingredientCategories,
          {'name': category},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> addCustomCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final normalized = IngredientCategoryCatalog.normalizeDefaultId(value);
    if (IngredientCategoryCatalog.isDefaultId(normalized)) return;
    final db = await _database.db;
    await db.insert(
      RecipeDatabaseService.ingredientCategories,
      {'name': value},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeCustomCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final db = await _database.db;
    await db.delete(
      RecipeDatabaseService.ingredientCategories,
      where: 'name = ?',
      whereArgs: [value],
    );
  }
}

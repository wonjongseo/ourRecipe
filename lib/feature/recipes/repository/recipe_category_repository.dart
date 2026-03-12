import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:sqflite/sqflite.dart';

class RecipeCategoryRepository {
  RecipeCategoryRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;

  Future<List<String>> fetchCategories() async {
    final db = await _database.db;
    final rows = await db.query(RecipeDatabaseService.recipeCategories);
    return rows
        .map((row) => (row['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> saveCategories(List<String> categories) async {
    final normalized =
        categories
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(RecipeDatabaseService.recipeCategories);
      for (final category in normalized) {
        await txn.insert(
          RecipeDatabaseService.recipeCategories,
          {'name': category},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> addCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final db = await _database.db;
    await db.insert(
      RecipeDatabaseService.recipeCategories,
      {'name': value},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;
    final db = await _database.db;
    await db.delete(
      RecipeDatabaseService.recipeCategories,
      where: 'name = ?',
      whereArgs: [value],
    );
  }

  Future<void> renameCategory(String oldCategory, String newCategory) async {
    final oldValue = oldCategory.trim();
    final newValue = newCategory.trim();
    if (oldValue.isEmpty || newValue.isEmpty || oldValue == newValue) return;

    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.update(
        RecipeDatabaseService.recipeCategories,
        {'name': newValue},
        where: 'name = ?',
        whereArgs: [oldValue],
      );
      await txn.update(
        RecipeDatabaseService.recipes,
        {'category': newValue},
        where: 'category = ?',
        whereArgs: [oldValue],
      );
    });
  }
}

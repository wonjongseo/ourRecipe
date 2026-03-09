import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:sqflite/sqflite.dart';

class ShoppingTodoRepository {
  ShoppingTodoRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;

  Future<Set<String>> fetchCheckedKeys() async {
    final db = await _database.db;
    final rows = await db.query(
      RecipeDatabaseService.shoppingTodos,
      where: 'checked = 1',
    );
    return rows.map((row) => row['todo_key'] as String).toSet();
  }

  Future<void> saveCheckedKeys(Set<String> keys) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(RecipeDatabaseService.shoppingTodos);
      for (final key in keys) {
        await txn.insert(RecipeDatabaseService.shoppingTodos, {
          'todo_key': key,
          'checked': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}

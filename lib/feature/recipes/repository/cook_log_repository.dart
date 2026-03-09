import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:sqflite/sqflite.dart';

class CookLogRepository {
  CookLogRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;

  Future<List<CookLogModel>> fetchCookLogs() async {
    final db = await _database.db;
    final rows = await db.query(
      RecipeDatabaseService.cookLogs,
      orderBy: 'cooked_at DESC',
    );
    return rows.map(_toCookLogModel).toList();
  }

  Future<void> saveCookLog(CookLogModel cookLog) async {
    final db = await _database.db;
    await db.insert(
      RecipeDatabaseService.cookLogs,
      _toRow(cookLog),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveCookLogs(List<CookLogModel> logs) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(RecipeDatabaseService.cookLogs);
      for (final log in logs) {
        await txn.insert(
          RecipeDatabaseService.cookLogs,
          _toRow(log),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteCookLog(String cookLogId) async {
    final db = await _database.db;
    await db.delete(
      RecipeDatabaseService.cookLogs,
      where: 'id = ?',
      whereArgs: [cookLogId],
    );
  }

  Map<String, Object?> _toRow(CookLogModel cookLog) {
    return {
      'id': cookLog.id,
      'recipe_id': cookLog.recipeId,
      'cooked_at': cookLog.cookedAt.toIso8601String(),
      'rating': cookLog.rating,
      'memo': cookLog.memo,
      'result_image_path': cookLog.resultImagePath,
      'actual_servings': cookLog.actualServings,
    };
  }

  CookLogModel _toCookLogModel(Map<String, Object?> row) {
    return CookLogModel(
      id: row['id'] as String,
      recipeId: row['recipe_id'] as String,
      cookedAt:
          DateTime.tryParse((row['cooked_at'] as String?) ?? '') ??
          DateTime.now(),
      rating: row['rating'] as int?,
      memo: (row['memo'] as String?) ?? '',
      resultImagePath: row['result_image_path'] as String?,
      actualServings: row['actual_servings'] as int?,
    );
  }
}

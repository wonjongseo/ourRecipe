import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:our_recipe/core/services/app_data_path_service.dart';

class RecipeDatabaseService {
  /// 앱 실행 중 중복 open을 피하기 위한 DB 캐시.
  static Database? _cachedDb;

  static const String recipes = 'recipes';
  static const String recipeIngredients = 'recipe_ingredients';
  static const String recipeSteps = 'recipe_steps';
  static const String cookLogs = 'cook_logs';
  static const String recipeCategories = 'recipe_categories';
  static const String ingredientCategories = 'ingredient_categories';
  static const String ingredientProducts = 'ingredient_products';
  static const String ingredientDefaultDeletions =
      'ingredient_default_deletions';
  static const String shoppingTodos = 'shopping_todos';

  Future<Database> get db async {
    final cached = _cachedDb;
    if (cached != null) return cached;

    // iOS에서는 iCloud 경로, 그 외에는 로컬 경로를 사용해 DB 파일 경로를 계산한다.
    final fullPath = await _resolveDatabaseFilePath();
    _cachedDb = await openDatabase(
      fullPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $recipes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            website_link TEXT NOT NULL DEFAULT '',
            servings INTEGER NOT NULL DEFAULT 1,
            cover_image_path TEXT,
            category TEXT NOT NULL DEFAULT '',
            is_liked INTEGER NOT NULL DEFAULT 0,
            total_ingredient_cost REAL NOT NULL DEFAULT 0,
            total_kcal REAL NOT NULL DEFAULT 0,
            total_water REAL NOT NULL DEFAULT 0,
            total_protein REAL NOT NULL DEFAULT 0,
            total_fat REAL NOT NULL DEFAULT 0,
            total_carbohydrate REAL NOT NULL DEFAULT 0,
            total_fiber REAL NOT NULL DEFAULT 0,
            total_ash REAL NOT NULL DEFAULT 0,
            total_sodium REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $recipeIngredients (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            unit TEXT NOT NULL,
            memo TEXT NOT NULL DEFAULT '',
            price REAL,
            product_amount REAL,
            product_unit TEXT,
            kcal REAL,
            water REAL,
            protein REAL,
            fat REAL,
            carbohydrate REAL,
            fiber REAL,
            ash REAL,
            sodium REAL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (recipe_id) REFERENCES $recipes(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE $recipeSteps (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            step_order INTEGER NOT NULL,
            instruction TEXT NOT NULL,
            timer_sec INTEGER,
            image_path TEXT,
            FOREIGN KEY (recipe_id) REFERENCES $recipes(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE $cookLogs (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            cooked_at TEXT NOT NULL,
            rating INTEGER,
            memo TEXT NOT NULL DEFAULT '',
            result_image_path TEXT,
            actual_servings INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE $recipeCategories (
            name TEXT PRIMARY KEY
          )
        ''');

        await db.execute('''
          CREATE TABLE $ingredientCategories (
            name TEXT PRIMARY KEY
          )
        ''');

        await db.execute('''
          CREATE TABLE $ingredientProducts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            manufacturer TEXT NOT NULL DEFAULT '',
            price REAL NOT NULL DEFAULT 0,
            base_gram REAL NOT NULL DEFAULT 0,
            kcal REAL,
            water REAL,
            protein REAL,
            fat REAL,
            carbohydrate REAL,
            fiber REAL,
            ash REAL,
            sodium REAL,
            is_default INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $ingredientDefaultDeletions (
            id TEXT PRIMARY KEY
          )
        ''');

        await db.execute('''
          CREATE TABLE $shoppingTodos (
            todo_key TEXT PRIMARY KEY,
            checked INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _cachedDb!;
  }

  static Future<void> reset() async {
    final cached = _cachedDb;
    if (cached != null) {
      await cached.close();
    }
    _cachedDb = null;
  }

  /// 현재 플랫폼/설정 기준으로 최종 DB 파일 경로를 결정한다.
  Future<String> _resolveDatabaseFilePath() async {
    final localDbDir = await getDatabasesPath();
    final localDbPath = path.join(localDbDir, 'our_recipe_data.db');
    final appDataDir = await AppDataPathService.getAppDataDirectoryPath();
    final targetDbPath = path.join(appDataDir, 'our_recipe_data.db');
    await _migrateLocalDatabaseIfNeeded(
      localDbPath: localDbPath,
      targetDbPath: targetDbPath,
    );
    return targetDbPath;
  }

  /// iOS에서 저장 위치가 변경될 때(로컬<->iCloud) 기존 DB를 1회 복사한다.
  Future<void> _migrateLocalDatabaseIfNeeded({
    required String localDbPath,
    required String targetDbPath,
  }) async {
    if (!Platform.isIOS) return;
    final iCloudDir = await AppDataPathService.getICloudDirectoryPathIfAvailable();
    final iCloudDbPath =
        iCloudDir == null ? null : path.join(iCloudDir, 'our_recipe_data.db');

    String? sourceDbPath;
    if (localDbPath == targetDbPath) {
      sourceDbPath = iCloudDbPath;
    } else {
      sourceDbPath = localDbPath;
    }
    if (sourceDbPath == null || sourceDbPath == targetDbPath) return;

    final localDb = File(sourceDbPath);
    final targetDb = File(targetDbPath);
    if (!await localDb.exists()) return;
    if (await targetDb.exists()) return;

    await targetDb.parent.create(recursive: true);
    await localDb.copy(targetDbPath);
    await _copyIfExists('$sourceDbPath-wal', '$targetDbPath-wal');
    await _copyIfExists('$sourceDbPath-shm', '$targetDbPath-shm');
    await _copyImageAssetsIfNeeded(
      sourceDirPath: path.dirname(sourceDbPath),
      targetDirPath: path.dirname(targetDbPath),
    );
  }

  /// SQLite 보조 파일(wal/shm)이 있을 때만 함께 복사한다.
  Future<void> _copyIfExists(String sourcePath, String targetPath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return;
    await source.copy(targetPath);
  }

  Future<void> _copyImageAssetsIfNeeded({
    required String sourceDirPath,
    required String targetDirPath,
  }) async {
    if (sourceDirPath == targetDirPath) return;
    final sourceDir = Directory(sourceDirPath);
    if (!await sourceDir.exists()) return;
    final targetDir = Directory(targetDirPath);
    await targetDir.create(recursive: true);

    await for (final entity in sourceDir.list(followLinks: false)) {
      if (entity is! File) continue;
      final ext = path.extension(entity.path).toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      final targetPath = path.join(targetDir.path, path.basename(entity.path));
      final targetFile = File(targetPath);
      if (await targetFile.exists()) continue;
      await entity.copy(targetPath);
    }
  }

  static const Set<String> _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.heic',
    '.webp',
  };
}

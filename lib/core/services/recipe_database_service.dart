import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class RecipeDatabaseService {
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

    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'our_recipe_data.db');
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
}

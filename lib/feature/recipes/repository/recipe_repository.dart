import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:our_recipe/core/services/app_data_path_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';
import 'package:sqflite/sqflite.dart';

class RecipeRepository {
  RecipeRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;

  Future<List<RecipeModel>> fetchRecipes() async {
    final db = await _database.db;
    final docsPath = await AppDataPathService.getAppDataDirectoryPath();
    final rows = await db.query(
      RecipeDatabaseService.recipes,
      orderBy: 'updated_at DESC',
    );
    final recipes = <RecipeModel>[];
    for (final row in rows) {
      final recipeId = row['id'] as String;
      final ingredientRows = await db.query(
        RecipeDatabaseService.recipeIngredients,
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
        orderBy: 'sort_order ASC',
      );
      final stepRows = await db.query(
        RecipeDatabaseService.recipeSteps,
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
        orderBy: 'step_order ASC',
      );
      recipes.add(_toRecipeModel(row, ingredientRows, stepRows, docsPath));
    }
    return recipes;
  }

  Future<void> saveRecipe(RecipeModel recipe) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.insert(RecipeDatabaseService.recipes, _recipeToRow(recipe),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        RecipeDatabaseService.recipeIngredients,
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );
      for (var i = 0; i < recipe.ingredients.length; i++) {
        final ingredient = recipe.ingredients[i];
        await txn.insert(
          RecipeDatabaseService.recipeIngredients,
          _ingredientToRow(recipe.id, ingredient, i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.delete(
        RecipeDatabaseService.recipeSteps,
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );
      for (final step in recipe.steps) {
        await txn.insert(
          RecipeDatabaseService.recipeSteps,
          _stepToRow(recipe.id, step),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveRecipes(List<RecipeModel> recipes) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(RecipeDatabaseService.recipeIngredients);
      await txn.delete(RecipeDatabaseService.recipeSteps);
      await txn.delete(RecipeDatabaseService.recipes);
      for (final recipe in recipes) {
        await txn.insert(RecipeDatabaseService.recipes, _recipeToRow(recipe),
            conflictAlgorithm: ConflictAlgorithm.replace);
        for (var i = 0; i < recipe.ingredients.length; i++) {
          await txn.insert(
            RecipeDatabaseService.recipeIngredients,
            _ingredientToRow(recipe.id, recipe.ingredients[i], i),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final step in recipe.steps) {
          await txn.insert(
            RecipeDatabaseService.recipeSteps,
            _stepToRow(recipe.id, step),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> deleteRecipe(String recipeId) async {
    final db = await _database.db;
    await db.delete(
      RecipeDatabaseService.recipes,
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Map<String, Object?> _recipeToRow(RecipeModel recipe) {
    return {
      'id': recipe.id,
      'name': recipe.name,
      'description': recipe.description,
      'website_link': recipe.websiteLink,
      'servings': recipe.servings,
      'cover_image_path': recipe.coverImagePath,
      'category': recipe.category,
      'is_liked': recipe.isLiked ? 1 : 0,
      'total_ingredient_cost': recipe.totalIngredientCost,
      'total_kcal': recipe.totalKcal,
      'total_water': recipe.totalWater,
      'total_protein': recipe.totalProtein,
      'total_fat': recipe.totalFat,
      'total_carbohydrate': recipe.totalCarbohydrate,
      'total_fiber': recipe.totalFiber,
      'total_ash': recipe.totalAsh,
      'total_sodium': recipe.totalSodium,
      'created_at': recipe.createdAt.toIso8601String(),
      'updated_at': recipe.updatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> _ingredientToRow(
    String recipeId,
    IngredientModel ingredient,
    int sortOrder,
  ) {
    return {
      'id': ingredient.id,
      'recipe_id': recipeId,
      'name': ingredient.name,
      'amount': ingredient.amount,
      'unit': ingredient.unit.name,
      'memo': ingredient.memo,
      'price': ingredient.price,
      'product_amount': ingredient.productAmount,
      'product_unit': ingredient.productUnit?.name,
      'kcal': ingredient.kcal,
      'water': ingredient.water,
      'protein': ingredient.protein,
      'fat': ingredient.fat,
      'carbohydrate': ingredient.carbohydrate,
      'fiber': ingredient.fiber,
      'ash': ingredient.ash,
      'sodium': ingredient.sodium,
      'sort_order': sortOrder,
    };
  }

  Map<String, Object?> _stepToRow(String recipeId, CookingStepModel step) {
    return {
      'id': step.id,
      'recipe_id': recipeId,
      'step_order': step.order,
      'instruction': step.instruction,
      'timer_sec': step.timerSec,
      'image_path': step.imagePath,
    };
  }

  RecipeModel _toRecipeModel(
    Map<String, Object?> row,
    List<Map<String, Object?>> ingredientRows,
    List<Map<String, Object?>> stepRows,
    String docsPath,
  ) {
    return RecipeModel(
      id: row['id'] as String,
      name: row['name'] as String,
      description: (row['description'] as String?) ?? '',
      websiteLink: (row['website_link'] as String?) ?? '',
      servings: (row['servings'] as int?) ?? 1,
      coverImagePath: _resolveStoredImagePath(
        row['cover_image_path'] as String?,
        docsPath,
      ),
      category: (row['category'] as String?) ?? '',
      isLiked: ((row['is_liked'] as int?) ?? 0) == 1,
      totalIngredientCost: (row['total_ingredient_cost'] as num?)?.toDouble() ?? 0,
      totalKcal: (row['total_kcal'] as num?)?.toDouble() ?? 0,
      totalWater: (row['total_water'] as num?)?.toDouble() ?? 0,
      totalProtein: (row['total_protein'] as num?)?.toDouble() ?? 0,
      totalFat: (row['total_fat'] as num?)?.toDouble() ?? 0,
      totalCarbohydrate: (row['total_carbohydrate'] as num?)?.toDouble() ?? 0,
      totalFiber: (row['total_fiber'] as num?)?.toDouble() ?? 0,
      totalAsh: (row['total_ash'] as num?)?.toDouble() ?? 0,
      totalSodium: (row['total_sodium'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((row['updated_at'] as String?) ?? '') ??
          DateTime.now(),
      ingredients: ingredientRows.map(_toIngredientModel).toList(),
      steps: stepRows.map((row) => _toStepModel(row, docsPath)).toList(),
    );
  }

  IngredientModel _toIngredientModel(Map<String, Object?> row) {
    final unit = _unitFromName((row['unit'] as String?) ?? IngredientUnit.count.name);
    final productUnitName = row['product_unit'] as String?;
    return IngredientModel(
      id: row['id'] as String,
      name: row['name'] as String,
      amount: (row['amount'] as num).toDouble(),
      unit: unit,
      memo: (row['memo'] as String?) ?? '',
      price: (row['price'] as num?)?.toDouble(),
      productAmount: (row['product_amount'] as num?)?.toDouble(),
      productUnit:
          productUnitName == null ? null : _unitFromName(productUnitName),
      kcal: (row['kcal'] as num?)?.toDouble(),
      water: (row['water'] as num?)?.toDouble(),
      protein: (row['protein'] as num?)?.toDouble(),
      fat: (row['fat'] as num?)?.toDouble(),
      carbohydrate: (row['carbohydrate'] as num?)?.toDouble(),
      fiber: (row['fiber'] as num?)?.toDouble(),
      ash: (row['ash'] as num?)?.toDouble(),
      sodium: (row['sodium'] as num?)?.toDouble(),
    );
  }

  CookingStepModel _toStepModel(Map<String, Object?> row, String docsPath) {
    return CookingStepModel(
      id: row['id'] as String,
      order: (row['step_order'] as int?) ?? 0,
      instruction: (row['instruction'] as String?) ?? '',
      timerSec: row['timer_sec'] as int?,
      imagePath: _resolveStoredImagePath(row['image_path'] as String?, docsPath),
    );
  }

  String? _resolveStoredImagePath(String? value, String docsPath) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (p.isAbsolute(trimmed) || trimmed.startsWith('/')) {
      if (File(trimmed).existsSync()) return trimmed;
      final fallback = p.join(docsPath, p.basename(trimmed));
      if (File(fallback).existsSync()) return fallback;
      return fallback;
    }
    return p.join(docsPath, trimmed);
  }

  IngredientUnit _unitFromName(String name) {
    for (final unit in IngredientUnit.values) {
      if (unit.name == name) return unit;
    }
    return IngredientUnit.count;
  }
}

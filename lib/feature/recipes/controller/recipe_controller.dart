import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/recipes/screens/detail_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/edit_recipe_screen.dart';

class RecipeController extends GetxController {
  final RecipeRepository _repository;
  RecipeController(this._repository);

  final _recipes = <RecipeModel>[].obs;
  final _filteredRecipes = <RecipeModel>[].obs;
  List<RecipeModel> get recipes => _filteredRecipes;

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  void _setUp() async {
    await _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final recipes = await _repository.fetchRecipes();
    _recipes.assignAll(recipes);
    _filteredRecipes.assignAll(recipes);
  }

  void goToEditScreen({RecipeModel? recipeModel}) async {
    final result = await Get.toNamed(
      EditRecipeScreen.name,
      arguments: recipeModel,
    );
    if (result is! RecipeModel) return;

    await _repository.saveRecipe(result);
    await _fetchRecipes();
  }

  void goToDetailScreen(RecipeModel recipeModel) async {
    final result = await Get.toNamed(
      DetailRecipeScreen.name,
      arguments: recipeModel,
    );
    if (result is! RecipeModel) return;

    await _repository.saveRecipe(result);
    await _fetchRecipes();
  }

  void deleteRecipe(RecipeModel recipe) async {
    await _repository.deleteRecipe(recipe.id);

    _fetchRecipes();
    Get.back();
  }

  Future<void> toggleLike(String recipeId) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index == -1) return;

    final recipe = _recipes[index];
    final toggled = recipe.copyWith(isLiked: !recipe.isLiked);
    await _repository.saveRecipe(toggled);
    await _fetchRecipes();
  }

  void onChanged(String? query) {
    if (query == null || query.isEmpty) {
      _filteredRecipes.assignAll(_recipes);
    } else {
      _filteredRecipes.assignAll(
        _recipes.where((recipe) {
          if (recipe.name.contains(query)) {
            return true;
          }
          return false;
        }),
      );
    }
  }
}

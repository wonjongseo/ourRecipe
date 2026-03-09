import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/recipes/screens/detail_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/edit_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/nutrition_detail_screen.dart';
import 'package:our_recipe/feature/start_cooking/screen/start_cooking_screen.dart';

enum RecipeFilterType { all, favorite, category }

class RecipeFilter {
  final RecipeFilterType type;
  final String? category;

  const RecipeFilter._(this.type, this.category);
  const RecipeFilter.all() : this._(RecipeFilterType.all, null);
  const RecipeFilter.favorite() : this._(RecipeFilterType.favorite, null);
  const RecipeFilter.category(String category)
    : this._(RecipeFilterType.category, category);

  bool matches(RecipeModel recipe) {
    switch (type) {
      case RecipeFilterType.all:
        return true;
      case RecipeFilterType.favorite:
        return recipe.isLiked;
      case RecipeFilterType.category:
        return recipe.category == category;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeFilter &&
        other.type == type &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(type, category);
}

class RecipeController extends GetxController {
  final RecipeRepository _repository;
  final RecipeCategoryRepository _categoryRepository;
  RecipeController(this._repository, this._categoryRepository);

  final _recipes = <RecipeModel>[].obs;
  final _filteredRecipes = <RecipeModel>[].obs;
  final _categories = <String>[].obs;
  List<RecipeModel> get recipes => _filteredRecipes;
  List<RecipeModel> get allRecipes => _recipes;
  List<RecipeModel> get bookmarkedRecipes =>
      _recipes.where((recipe) => recipe.isLiked).toList();
  List<String> get categories => _categories;

  final selectedFilter = const RecipeFilter.all().obs;
  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  void onChangeFilter(RecipeFilter filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  void _setUp() async {
    await _fetchCategories();
    await _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final recipes = await _repository.fetchRecipes();
    _recipes.assignAll(recipes);
    _applyFilters();
  }

  Future<void> _fetchCategories() async {
    final categories = await _categoryRepository.fetchCategories();
    categories.sort();
    _categories.assignAll(categories);
    if (selectedFilter.value.type == RecipeFilterType.category &&
        !_categories.contains(selectedFilter.value.category)) {
      selectedFilter.value = const RecipeFilter.all();
    }
  }

  Future<void> refreshCategories() async {
    await _fetchCategories();
    _applyFilters();
  }

  Future<RecipeModel?> goToEditScreen({RecipeModel? recipeModel}) async {
    final result = await Get.toNamed(
      EditRecipeScreen.name,
      arguments: recipeModel,
    );
    await _fetchCategories();
    if (result is! RecipeModel) return null;

    await _repository.saveRecipe(result);
    await _fetchRecipes();
    return result;
  }

  Future<void> goToDetailScreen(RecipeModel recipeModel) async {
    await Get.toNamed(DetailRecipeScreen.name, arguments: recipeModel);
    await _fetchCategories();
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

  Future<void> toggleBookmark(String recipeId) async {
    await toggleLike(recipeId);
  }

  void onChanged(String? query) {
    _searchQuery.value = (query ?? '').trim();
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    final filter = selectedFilter.value;

    _filteredRecipes.assignAll(
      _recipes.where((recipe) {
        final matchesFilter = filter.matches(recipe);
        if (!matchesFilter) return false;
        if (query.isEmpty) return true;
        return recipe.name.toLowerCase().contains(query);
      }),
    );
  }

  void onTapNutrition({
    required RecipeModel recipe,
    required String nutritionKey,
  }) {
    Get.to(
      () => NutritionDetailScreen(recipe: recipe, nutritionKey: nutritionKey),
    );
  }

  void goToStartCooking(RecipeModel recipeModel) {
    Get.toNamed(StartCookingScreen.name, arguments: recipeModel);
  }
}

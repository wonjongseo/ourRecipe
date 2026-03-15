import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/ad_interstitial_service.dart';
import 'package:our_recipe/core/services/analytics_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/services/image_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
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
  final ICloudSyncService _iCloudSync = ICloudSyncService();
  final ICloudSyncSettingsService _iCloudSettings = ICloudSyncSettingsService();

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
  final _isLoading = false.obs;
  final _isICloudSyncEnabled = false.obs;
  bool get isLoading => _isLoading.value;
  bool get isICloudSyncEnabled => _isICloudSyncEnabled.value;
  final searchTextCtrl = TextEditingController();
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

  Future<void> _setUp() async {
    _isLoading.value = true;
    try {
      await _refreshICloudEnabledState();
      await _fetchCategories();
      await _fetchRecipes();
    } catch (e, s) {
      _recipes.clear();
      _filteredRecipes.clear();
      LogManager.error('Recipe setup failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> reloadAll() async {
    _isLoading.value = true;
    try {
      await _refreshICloudEnabledState();
      await RecipeDatabaseService.reset();
      await _fetchCategories();
      await _fetchRecipes();
    } catch (e, s) {
      LogManager.error('Reload recipes failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchRecipes() async {
    try {
      final recipes = await _repository.fetchRecipes();
      _recipes.assignAll(recipes);
      _applyFilters();
    } catch (e, s) {
      LogManager.error('Fetch recipes failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryRepository.fetchCategories();
      categories.sort();
      _categories.assignAll(categories);
      if (selectedFilter.value.type == RecipeFilterType.category &&
          !_categories.contains(selectedFilter.value.category)) {
        selectedFilter.value = const RecipeFilter.all();
      }
    } catch (e, s) {
      LogManager.error('Fetch categories failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> refreshCategories() async {
    _isLoading.value = true;
    try {
      await _fetchCategories();
      _applyFilters();
    } catch (e, s) {
      LogManager.error('Refresh categories failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<RecipeModel?> goToEditScreen({RecipeModel? recipeModel}) async {
    final result = await Get.toNamed(
      EditRecipeScreen.name,
      arguments: recipeModel,
    );
    _isLoading.value = true;
    try {
      await _fetchCategories();
      if (result is! RecipeModel) return null;
      final isEdit = recipeModel != null;
      await _iCloudSettings.clearDeletedRecipe(result.id);
      await _repository.saveRecipe(result);
      if (isEdit) {
        await AnalyticsService.instance.recipeUpdated(
          recipeId: result.id,
          category: result.category,
          ingredientCount: result.ingredients.length,
          stepCount: result.steps.length,
        );
      } else {
        await AnalyticsService.instance.recipeCreated(
          recipeId: result.id,
          category: result.category,
          ingredientCount: result.ingredients.length,
          stepCount: result.steps.length,
        );
      }
      await _fetchRecipes();
      AdInterstitialService.instance.registerCompletion();
      return result;
    } catch (e, s) {
      LogManager.error('Save recipe failed', error: e, stackTrace: s);
      LogManager.error('Save recipe target: ${result.name}', error: e);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> goToDetailScreen(RecipeModel recipeModel) async {
    await Get.toNamed(DetailRecipeScreen.name, arguments: recipeModel);
    _isLoading.value = true;
    try {
      await _fetchCategories();
      await _fetchRecipes();
    } catch (e, s) {
      LogManager.error('Refresh after detail failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteRecipe(RecipeModel recipe) async {
    _isLoading.value = true;
    try {
      await ImageService.deleteSavedFile(recipe.coverImagePath);
      for (final step in recipe.steps) {
        await ImageService.deleteSavedFile(step.imagePath);
      }
      await _iCloudSettings.markRecipeDeleted(recipe.id, DateTime.now());
      await _repository.deleteRecipe(recipe.id);
      await AnalyticsService.instance.recipeDeleted(
        recipeId: recipe.id,
        category: recipe.category,
      );
      await _fetchRecipes();
      AdInterstitialService.instance.registerCompletion();
    } catch (e, s) {
      LogManager.error('Delete recipe failed', error: e, stackTrace: s);
      LogManager.error(
        'Delete recipe target: ${recipe.id}/${recipe.name}',
        error: e,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggleLike(String recipeId) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index == -1) return;

    final original = _recipes[index];
    final toggled = original.copyWith(
      isLiked: !original.isLiked,
      updatedAt: DateTime.now(),
    );
    _recipes[index] = toggled;
    _applyFilters();
    try {
      await _iCloudSettings.clearDeletedRecipe(toggled.id);
      await _repository.saveRecipe(toggled);
    } catch (e, s) {
      _recipes[index] = original;
      _applyFilters();
      LogManager.error('Toggle bookmark failed', error: e, stackTrace: s);
      LogManager.error('Toggle bookmark recipeId: $recipeId', error: e);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    }
  }

  Future<void> toggleBookmark(String recipeId) async {
    await toggleLike(recipeId);
  }

  void onChanged(String? query) {
    _searchQuery.value = (query ?? '').trim();
    _applyFilters();
  }

  void clearQuery() {
    searchTextCtrl.clear();
    _searchQuery.value = '';
    _applyFilters();
  }

  @override
  void onClose() {
    searchTextCtrl.dispose();
    super.onClose();
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

  Future<void> downloadFromICloud() async {
    _isLoading.value = true;
    try {
      await RecipeDatabaseService.reset();
      await _iCloudSync.pullIfEnabled();
      await RecipeDatabaseService.reset();
      await _fetchCategories();
      await _fetchRecipes();
    } catch (e, s) {
      LogManager.error('Manual iCloud download failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> _isICloudEnabledOnIOS() async {
    return await _iCloudSync.isEnabledOnIOS();
  }

  Future<void> _refreshICloudEnabledState() async {
    _isICloudSyncEnabled.value = await _isICloudEnabledOnIOS();
  }
}

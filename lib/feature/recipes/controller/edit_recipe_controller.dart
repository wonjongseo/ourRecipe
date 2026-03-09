import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:our_recipe/core/common/app_functions.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/image_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/recipe_ingredient_input_sheet.dart';
import 'package:uuid/uuid.dart';

class InputCookingStep {
  final String id = Uuid().v4();
  final TextEditingController descriptionTeCtrl = TextEditingController();
  // 0이면 타이머 미설정 상태.
  int timer = 0; // minute
  File? image;
  InputCookingStep();
}

class EditRecipeController extends GetxController {
  final RecipeCategoryRepository _categoryRepository;
  final IngredientProductRepository _ingredientProductRepository;
  RecipeModel? recipeModel;
  EditRecipeController(
    this.recipeModel,
    this._categoryRepository,
    this._ingredientProductRepository,
  );

  TextEditingController recipeNameTextCtrl = TextEditingController();
  TextEditingController descriptionTextCtrl = TextEditingController();
  TextEditingController servingsTextCtrl = TextEditingController();
  TextEditingController categoryTextCtrl = TextEditingController();

  final Rxn<File> _coverImage = Rxn();
  File? get coverImage => _coverImage.value;

  final _isPickingImage = false.obs;
  bool get isPickingImage => _isPickingImage.value;
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final ingredients = <IngredientModel>[].obs;
  final inputCookingSteps = <InputCookingStep>[].obs;
  final categories = <String>[].obs;
  final isLiked = false.obs;
  final selectedCategory = ''.obs;
  bool get isEdit => recipeModel != null;

  double get totalUseCount =>
      ingredients.fold<double>(0, (sum, item) => sum + (item.usedCost ?? 0));

  void pickImageFromLibery() async {
    if (_isPickingImage.value) return;
    final image = await ImageService.openCameraOrLibarySheet(
      Get.context!,
      onPickStart: () => _isPickingImage.value = true,
      onPickEnd: () => _isPickingImage.value = false,
    );
    _coverImage.value = image;
  }

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  Future<void> _setUp() async {
    _isLoading.value = true;
    try {
      final savedCategories = await _categoryRepository.fetchCategories();
      savedCategories.sort();
      categories.assignAll(savedCategories);

      if (recipeModel == null) {
        if (categories.isNotEmpty) {
          selectedCategory.value = categories.first;
          categoryTextCtrl.text = categories.first;
        }
        isLiked.value = false;

        if (inputCookingSteps.isEmpty) {
          inputCookingSteps.add(InputCookingStep());
        }
      } else {
        final recipe = recipeModel!;
        recipeNameTextCtrl.text = recipe.name;
        descriptionTextCtrl.text = recipe.description;
        servingsTextCtrl.text = recipe.servings.toString();
        categoryTextCtrl.text = recipe.category;
        if (recipe.category.isNotEmpty &&
            !categories.contains(recipe.category)) {
          categories.add(recipe.category);
        }
        selectedCategory.value = recipe.category;
        isLiked.value = recipe.isLiked;

        ingredients.assignAll(recipe.ingredients);
        if (recipe.coverImagePath != null &&
            recipe.coverImagePath!.isNotEmpty) {
          _coverImage.value = File(recipe.coverImagePath!);
        }

        inputCookingSteps.clear();
        for (final step in recipe.steps) {
          final input = InputCookingStep();
          input.descriptionTeCtrl.text = step.instruction;
          input.timer = step.timerSec ?? 0;
          if (step.imagePath != null && step.imagePath!.isNotEmpty) {
            input.image = File(step.imagePath!);
          }
          inputCookingSteps.add(input);
        }
        if (inputCookingSteps.isEmpty) {
          inputCookingSteps.add(InputCookingStep());
        }
      }
    } catch (e, s) {
      LogManager.error('Edit recipe setup failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  void editIngredient({int? index}) async {
    if (Get.context == null) return;
    final isEdit = index != null;
    if (isEdit && (index < 0 || index >= ingredients.length)) return;

    var result = await AppFunctions.showBottomSheet(
      context: Get.context!,
      child: RecipeIngredientInputSheet(
        initialIngredient: isEdit ? ingredients[index!] : null,
      ),
    );
    if (result.runtimeType != IngredientModel) return;

    final ingredient = await _resolveIngredientWithProduct(
      result as IngredientModel,
    );
    if (isEdit) {
      ingredients[index!] = ingredient;
      ingredients.refresh();
      return;
    }
    ingredients.add(ingredient);
  }

  void addCookingStep() {
    inputCookingSteps.add(InputCookingStep());
  }

  Future<void> addCategory(String category) async {
    final value = category.trim();
    if (value.isEmpty) return;

    await _categoryRepository.addCategory(value);
    if (!categories.contains(value)) {
      categories.add(value);
    }
    selectedCategory.value = value;
    categoryTextCtrl.text = value;
  }

  Future<void> refreshCategories() async {
    _isLoading.value = true;
    try {
      final values = await _categoryRepository.fetchCategories();
      values.sort();
      categories.assignAll(values);
      if (selectedCategory.value.isNotEmpty &&
          !categories.contains(selectedCategory.value)) {
        selectedCategory.value = '';
        categoryTextCtrl.clear();
      }
    } catch (e, s) {
      LogManager.error('Refresh categories failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> goToCategoryManagement() async {
    await Get.toNamed(CategoryManagementScreen.name);
    await refreshCategories();
  }

  void setSelectedCategory(String? category) {
    if (category == null) return;
    selectedCategory.value = category;
    categoryTextCtrl.text = category;
  }

  void deleteCookingStep(int index) {
    if (index < 0 || index >= inputCookingSteps.length) return;
    inputCookingSteps.removeAt(index);
  }

  @override
  void onClose() {
    recipeNameTextCtrl.dispose();
    descriptionTextCtrl.dispose();
    servingsTextCtrl.dispose();
    categoryTextCtrl.dispose();

    for (var inputCookingStep in inputCookingSteps) {
      inputCookingStep.descriptionTeCtrl.dispose();
    }
    super.onClose();
  }

  void pickImageToCookingStep(int index) async {
    if (_isPickingImage.value) return;
    if (index < 0 || index >= inputCookingSteps.length) return;
    final image = await ImageService.openCameraOrLibarySheet(
      Get.context!,
      onPickStart: () => _isPickingImage.value = true,
      onPickEnd: () => _isPickingImage.value = false,
    );
    if (image == null) return;
    inputCookingSteps[index].image = image;
    inputCookingSteps.refresh();
  }

  void removeImageFromCookingStep(int index) {
    if (index < 0 || index >= inputCookingSteps.length) return;
    inputCookingSteps[index].image = null;
    inputCookingSteps.refresh();
  }

  void setCookingStepTimer(int index, int minutes) {
    if (index < 0 || index >= inputCookingSteps.length) return;
    inputCookingSteps[index].timer = minutes;
    inputCookingSteps.refresh();
  }

  void toggleLike() {
    if (isLiked.value) {
      isLiked.value = false;

      return;
    }
    isLiked.value = true;
  }

  void deleteIngredient(int index) {
    if (index < 0 || index >= ingredients.length) return;
    ingredients.removeAt(index);
  }

  void onReorderIngredients(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final ingredient = ingredients.removeAt(oldIndex);
    ingredients.insert(newIndex, ingredient);
  }

  void onReorderCookingSteps(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final step = inputCookingSteps.removeAt(oldIndex);
    inputCookingSteps.insert(newIndex, step);
  }

  Future<void> saveRecipeModel() async {
    final recipeName = recipeNameTextCtrl.text.trim();
    if (recipeName.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.recipeNameRequired.tr);
      return;
    }

    _isLoading.value = true;
    try {
      final description = descriptionTextCtrl.text.trim();
      final category = selectedCategory.value.trim();
      if (category.isNotEmpty) {
        await _categoryRepository.addCategory(category);
      }

      String? savedImageCoverPath;
      if (coverImage != null) {
        savedImageCoverPath = await ImageService.saveFile(coverImage!);
      }
      // final coverImagePath = coverImage?.path;

      List<CookingStepModel> cookingStepModels = [];
      for (final inputCookingStep in inputCookingSteps) {
        final instruction = inputCookingStep.descriptionTeCtrl.text.trim();

        String? savedImagePath;
        if (inputCookingStep.image != null) {
          savedImagePath = await ImageService.saveFile(inputCookingStep.image!);
        }

        final hasImage = savedImagePath != null && savedImagePath.isNotEmpty;
        final hasTimer = inputCookingStep.timer > 0;
        final isEmptyStep = instruction.isEmpty && !hasImage && !hasTimer;
        if (isEmptyStep) continue;

        cookingStepModels.add(
          CookingStepModel(
            id: inputCookingStep.id,
            order: cookingStepModels.length + 1,
            instruction: instruction,
            imagePath: savedImagePath,
            timerSec: hasTimer ? inputCookingStep.timer : null,
          ),
        );
      }

      final products = await _ingredientProductRepository.fetchProducts();
      final resolvedIngredients =
          ingredients
              .map((ingredient) => _applyProductInfo(products, ingredient))
              .toList();

      final totalIngredientCost = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedCost ?? 0),
      );
      final totalKcal = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedKcal ?? 0),
      );
      final totalWater = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedWater ?? 0),
      );
      final totalProtein = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedProtein ?? 0),
      );
      final totalFat = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedFat ?? 0),
      );
      final totalCarbohydrate = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedCarbohydrate ?? 0),
      );
      final totalFiber = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedFiber ?? 0),
      );
      final totalAsh = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedAsh ?? 0),
      );
      final totalSodium = resolvedIngredients.fold<double>(
        0,
        (sum, ingredient) => sum + (ingredient.usedSodium ?? 0),
      );

      final recipeModel = RecipeModel(
        id: this.recipeModel?.id ?? Uuid().v4(),
        name: recipeName,
        category: category,
        isLiked: isLiked.value,

        totalIngredientCost: totalIngredientCost,
        totalKcal: totalKcal,
        totalWater: totalWater,
        totalProtein: totalProtein,
        totalFat: totalFat,
        totalCarbohydrate: totalCarbohydrate,
        totalFiber: totalFiber,
        totalAsh: totalAsh,
        totalSodium: totalSodium,
        createdAt: this.recipeModel?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        description: description,
        coverImagePath: savedImageCoverPath,
        ingredients: resolvedIngredients,
        steps: cookingStepModels,
      );
      Get.back(result: recipeModel);
    } catch (e, s) {
      LogManager.error('Save recipe model failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _cleanupReplacedImages({
    required String? newCoverImagePath,
    required Set<String> newStepImagePaths,
  }) async {
    final oldRecipe = recipeModel;
    if (oldRecipe == null) return;

    final oldCoverImagePath = oldRecipe.coverImagePath;
    if (_shouldDeleteOldPath(oldCoverImagePath, newCoverImagePath)) {
      await _safeDeleteFile(oldCoverImagePath!);
    }

    final oldStepImagePaths =
        oldRecipe.steps
            .map((step) => step.imagePath)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toSet();
    for (final oldPath in oldStepImagePaths) {
      if (newStepImagePaths.contains(oldPath)) continue;
      await _safeDeleteFile(oldPath);
    }
  }

  bool _shouldDeleteOldPath(String? oldPath, String? newPath) {
    if (oldPath == null || oldPath.isEmpty) return false;
    if (oldPath == newPath) return false;
    return true;
  }

  Future<void> _safeDeleteFile(String path) async {
    await ImageService.deleteSavedFile(path);
  }

  IngredientProductModel? _findProductByName(
    List<IngredientProductModel> products,
    String name,
  ) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final product in products) {
      if (product.name.trim().toLowerCase() == key) return product;
    }
    return null;
  }

  Future<IngredientModel> _resolveIngredientWithProduct(
    IngredientModel ingredient,
  ) async {
    final products = await _ingredientProductRepository.fetchProducts();
    return _applyProductInfo(products, ingredient);
  }

  IngredientModel _applyProductInfo(
    List<IngredientProductModel> products,
    IngredientModel ingredient,
  ) {
    final product = _findProductByName(products, ingredient.name);
    if (product == null) return ingredient;
    if (ingredient.unit != IngredientUnit.gram) return ingredient;
    if (product.baseGram <= 0) return ingredient;
    return ingredient.copyWith(
      price: product.price,
      productAmount: product.baseGram,
      productUnit: IngredientUnit.gram,
      kcal: product.kcal,
      water: product.water,
      protein: product.protein,
      fat: product.fat,
      carbohydrate: product.carbohydrate,
      fiber: product.fiber,
      ash: product.ash,
      sodium: product.sodium,
    );
  }
}

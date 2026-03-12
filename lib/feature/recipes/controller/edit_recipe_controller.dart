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
  int timerValue = 0;
  String timerUnit = 'minute';
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
  TextEditingController websiteLinkTextCtrl = TextEditingController();
  TextEditingController servingsTextCtrl = TextEditingController();
  TextEditingController categoryTextCtrl = TextEditingController();
  final ScrollController formScrollController = ScrollController();

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
    if (image != null) {
      _coverImage.value = image;
    }
  }

  Future<void> cropCoverImage() async {
    final current = _coverImage.value;
    if (current == null || _isPickingImage.value) return;
    _isPickingImage.value = true;
    try {
      final cropped = await ImageService.cropSelectedImage(current);
      if (cropped != null) {
        _coverImage.value = cropped;
      }
    } finally {
      _isPickingImage.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  Future<void> _setUp() async {
    _isLoading.value = true;
    try {
      await _loadCategories();
      if (recipeModel == null) {
        _applyDefaultsForCreate();
      } else {
        _applyRecipeForEdit(recipeModel!);
      }
      _ensureCookingStepInput();
    } catch (e, s) {
      LogManager.error('Edit recipe setup failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    final savedCategories = await _categoryRepository.fetchCategories();
    savedCategories.sort();
    categories.assignAll(savedCategories);
  }

  void _applyDefaultsForCreate() {
    isLiked.value = false;
    servingsTextCtrl.text = '2';
  }

  void _applyRecipeForEdit(RecipeModel recipe) {
    recipeNameTextCtrl.text = recipe.name;
    descriptionTextCtrl.text = recipe.description;
    websiteLinkTextCtrl.text = recipe.websiteLink;
    servingsTextCtrl.text = recipe.servings.toString();
    categoryTextCtrl.text = recipe.category;
    if (recipe.category.isNotEmpty && !categories.contains(recipe.category)) {
      categories.add(recipe.category);
    }
    selectedCategory.value = recipe.category;
    isLiked.value = recipe.isLiked;
    ingredients.assignAll(recipe.ingredients);
    _coverImage.value = _toFileOrNull(recipe.coverImagePath);
    inputCookingSteps
      ..clear()
      ..addAll(recipe.steps.map(_toInputCookingStep));
  }

  void _ensureCookingStepInput() {
    if (inputCookingSteps.isEmpty) {
      inputCookingSteps.add(InputCookingStep());
    }
  }

  File? _toFileOrNull(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  InputCookingStep _toInputCookingStep(CookingStepModel step) {
    final input = InputCookingStep();
    input.descriptionTeCtrl.text = step.instruction;
    final timerSec = step.timerSec ?? 0;
    if (timerSec > 0 && timerSec % 3600 == 0) {
      input.timerValue = timerSec ~/ 3600;
      input.timerUnit = 'hour';
    } else if (timerSec > 0 && timerSec % 60 == 0) {
      input.timerValue = timerSec ~/ 60;
      input.timerUnit = 'minute';
    } else {
      input.timerValue = timerSec;
      input.timerUnit = 'second';
    }
    input.image = _toFileOrNull(step.imagePath);
    return input;
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

  void addCookingStepAndScrollToBottom() {
    addCookingStep();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!formScrollController.hasClients) return;
      formScrollController.animateTo(
        formScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
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
    final result = await Get.toNamed(
      CategoryManagementScreen.name,
      arguments: true,
    );
    if (result != null) {
      setSelectedCategory(result);
    }
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
    websiteLinkTextCtrl.dispose();
    servingsTextCtrl.dispose();
    categoryTextCtrl.dispose();
    formScrollController.dispose();

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

  Future<void> cropCookingStepImage(int index) async {
    if (_isPickingImage.value) return;
    if (index < 0 || index >= inputCookingSteps.length) return;
    final current = inputCookingSteps[index].image;
    if (current == null) return;
    _isPickingImage.value = true;
    try {
      final cropped = await ImageService.cropSelectedImage(current);
      if (cropped == null) return;
      inputCookingSteps[index].image = cropped;
      inputCookingSteps.refresh();
    } finally {
      _isPickingImage.value = false;
    }
  }

  void removeImageFromCookingStep(int index) {
    if (index < 0 || index >= inputCookingSteps.length) return;
    inputCookingSteps[index].image = null;
    inputCookingSteps.refresh();
  }

  void setCookingStepTimer(int index, int value, String unit) {
    if (index < 0 || index >= inputCookingSteps.length) return;
    inputCookingSteps[index].timerValue = value;
    inputCookingSteps[index].timerUnit = unit;
    inputCookingSteps.refresh();
  }

  int cookingStepTimerToSeconds(InputCookingStep step) {
    if (step.timerValue <= 0) return 0;
    switch (step.timerUnit) {
      case 'hour':
        return step.timerValue * 3600;
      case 'minute':
        return step.timerValue * 60;
      case 'second':
      default:
        return step.timerValue;
    }
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
    final servingsAsInt = _validateInputs();
    if (servingsAsInt == null) {
      return;
    }

    _isLoading.value = true;
    try {
      final category = selectedCategory.value.trim();
      await _saveCategoryIfNeeded(category);
      final recipeModel = await _buildRecipeModel(
        servings: servingsAsInt,
        category: category,
      );
      Get.back(result: recipeModel);
    } catch (e, s) {
      LogManager.error('Save recipe model failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  int? _validateInputs() {
    final recipeName = recipeNameTextCtrl.text.trim();
    if (recipeName.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.recipeNameRequired.tr);
      return null;
    }
    final servingsAsInt = int.tryParse(servingsTextCtrl.text.trim());
    if (servingsAsInt == null) {
      SnackBarHelper.showErrorSnackBar(AppStrings.servingsRequired.tr);
      return null;
    }
    if (servingsAsInt < 1) {
      SnackBarHelper.showErrorSnackBar(AppStrings.servingsMinOne.tr);
      return null;
    }
    return servingsAsInt;
  }

  Future<void> _saveCategoryIfNeeded(String category) async {
    if (category.isEmpty) return;
    await _categoryRepository.addCategory(category);
  }

  Future<RecipeModel> _buildRecipeModel({
    required int servings,
    required String category,
  }) async {
    final savedImageCoverPath = await _saveCoverImageIfNeeded();
    final cookingStepModels = await _buildCookingStepModels();
    final resolvedIngredients = await _buildResolvedIngredients();
    return RecipeModel(
      id: recipeModel?.id ?? Uuid().v4(),
      name: recipeNameTextCtrl.text.trim(),
      category: category,
      isLiked: isLiked.value,
      totalIngredientCost: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedCost ?? 0,
      ),
      totalKcal: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedKcal ?? 0,
      ),
      totalWater: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedWater ?? 0,
      ),
      servings: servings,
      totalProtein: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedProtein ?? 0,
      ),
      totalFat: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedFat ?? 0,
      ),
      totalCarbohydrate: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedCarbohydrate ?? 0,
      ),
      totalFiber: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedFiber ?? 0,
      ),
      totalAsh: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedAsh ?? 0,
      ),
      totalSodium: _sumIngredients(
        resolvedIngredients,
        (ingredient) => ingredient.usedSodium ?? 0,
      ),
      createdAt: recipeModel?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      description: descriptionTextCtrl.text.trim(),
      websiteLink: websiteLinkTextCtrl.text.trim(),
      coverImagePath: savedImageCoverPath,
      ingredients: resolvedIngredients,
      steps: cookingStepModels,
    );
  }

  Future<String?> _saveCoverImageIfNeeded() async {
    final image = coverImage;
    if (image == null) return null;
    return ImageService.saveFile(image);
  }

  Future<List<CookingStepModel>> _buildCookingStepModels() async {
    final cookingStepModels = <CookingStepModel>[];
    for (final inputCookingStep in inputCookingSteps) {
      final step = await _buildCookingStepModel(
        inputCookingStep,
        order: cookingStepModels.length + 1,
      );
      if (step == null) continue;
      cookingStepModels.add(step);
    }
    return cookingStepModels;
  }

  Future<CookingStepModel?> _buildCookingStepModel(
    InputCookingStep inputCookingStep, {
    required int order,
  }) async {
    final instruction = inputCookingStep.descriptionTeCtrl.text.trim();
    String? savedImagePath;
    if (inputCookingStep.image != null) {
      savedImagePath = await ImageService.saveFile(inputCookingStep.image!);
    }
    final timerSeconds = cookingStepTimerToSeconds(inputCookingStep);
    final hasImage = savedImagePath != null && savedImagePath.isNotEmpty;
    final hasTimer = timerSeconds > 0;
    if (instruction.isEmpty && !hasImage && !hasTimer) {
      return null;
    }
    return CookingStepModel(
      id: inputCookingStep.id,
      order: order,
      instruction: instruction,
      imagePath: savedImagePath,
      timerSec: hasTimer ? timerSeconds : null,
    );
  }

  Future<List<IngredientModel>> _buildResolvedIngredients() async {
    final products = await _ingredientProductRepository.fetchProducts();
    return ingredients
        .map((ingredient) => _applyProductInfo(products, ingredient))
        .toList(growable: false);
  }

  double _sumIngredients(
    List<IngredientModel> values,
    double Function(IngredientModel ingredient) selector,
  ) {
    return values.fold<double>(0, (sum, ingredient) {
      return sum + selector(ingredient);
    });
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

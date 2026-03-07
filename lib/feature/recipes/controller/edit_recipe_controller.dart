import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:our_recipe/core/common/app_functions.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/photo_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/input_ingredient_widget.dart';
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
  RecipeModel? recipeModel;
  EditRecipeController(this.recipeModel);

  late TextEditingController recipeNameTextCtrl;
  late TextEditingController descriptionTextCtrl;
  late TextEditingController servingsTextCtrl;

  final Rxn<File> _coverImage = Rxn();
  File? get coverImage => _coverImage.value;

  final _isPickingImage = false.obs;
  bool get isPickingImage => _isPickingImage.value;

  final ingredients = <IngredientModel>[].obs;
  final inputCookingSteps = <InputCookingStep>[].obs;
  final selectedCategory = RecipeCategory.korean.obs;
  final isLiked = false.obs;

  void pickImageFromLibery() async {
    if (_isPickingImage.value) return;
    _isPickingImage.value = true;
    final image = await PhotoService.getImageFromLibery();
    _coverImage.value = image;

    _isPickingImage.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  void _setUp() {
    if (recipeModel == null) {
      recipeNameTextCtrl = TextEditingController();
      descriptionTextCtrl = TextEditingController();
      servingsTextCtrl = TextEditingController();
      selectedCategory.value = RecipeCategory.korean;
      isLiked.value = false;

      if (inputCookingSteps.isEmpty) {
        inputCookingSteps.add(InputCookingStep());
      }
    } else {
      //편집
      final recipe = recipeModel!;
      recipeNameTextCtrl = TextEditingController(text: recipe.name);
      descriptionTextCtrl = TextEditingController(text: recipe.description);
      servingsTextCtrl = TextEditingController(
        text: recipe.servings.toString(),
      );
      selectedCategory.value = recipe.category;
      isLiked.value = recipe.isLiked;

      ingredients.assignAll(recipe.ingredients);
      if (recipe.coverImagePath != null && recipe.coverImagePath!.isNotEmpty) {
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
  }

  void addIngredient() async {
    if (Get.context == null) return;
    var result = await AppFunctions.showBottomSheet(
      context: Get.context!,
      child: InputIngredientWidget(),
    );
    if (result.runtimeType != IngredientModel) return;

    ingredients.add(result as IngredientModel);
  }

  void addCookingStep() {
    inputCookingSteps.add(InputCookingStep());
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

    for (var inputCookingStep in inputCookingSteps) {
      inputCookingStep.descriptionTeCtrl.dispose();
    }
    super.onClose();
  }

  void pickImageToCookingStep(int index) async {
    if (index < 0 || index >= inputCookingSteps.length) return;
    final image = await PhotoService.getImageFromLibery();
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

  void setCategory(RecipeCategory category) {
    selectedCategory.value = category;
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

  void saveRecipeModel() {
    final recipeName = recipeNameTextCtrl.text.trim();
    if (recipeName.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.recipeNameRequired.tr);
      return;
    }

    final description = descriptionTextCtrl.text.trim();

    final coverImagePath = coverImage?.path;

    List<CookingStepModel> cookingStepModels = [];
    for (var i = 0; i < inputCookingSteps.length; i++) {
      final inputCookingStep = inputCookingSteps[i];

      final imagePath = inputCookingStep.image?.path;
      cookingStepModels.add(
        CookingStepModel(
          id: inputCookingStep.id,
          order: i + 1,
          instruction: inputCookingStep.descriptionTeCtrl.text,
          imagePath: imagePath,
          timerSec: inputCookingStep.timer,
        ),
      );
    }
    final totalIngredientCost = ingredients.fold<double>(
      0,
      (sum, ingredient) => sum + (ingredient.usedCost ?? 0),
    );

    final recipeModel = RecipeModel(
      id: this.recipeModel?.id ?? Uuid().v4(),
      name: recipeName,
      category: selectedCategory.value,
      isLiked: isLiked.value,

      totalIngredientCost: totalIngredientCost,
      createdAt: this.recipeModel?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      description: description,
      coverImagePath: coverImagePath,
      ingredients: ingredients,
      steps: cookingStepModels,
    );
    Get.back(result: recipeModel);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/analytics_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_category_management_screen.dart';
import 'package:uuid/uuid.dart';

class IngredientEditController extends GetxController {
  IngredientEditController(
    this.product,
    this._productRepository,
    this._categoryRepository,
  );

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final IngredientProductModel? product;
  final IngredientProductRepository _productRepository;
  final IngredientCategoryRepository _categoryRepository;
  final ICloudSyncSettingsService _iCloudSettings = ICloudSyncSettingsService();

  late final TextEditingController nameCtrl;
  late final TextEditingController manufacturerCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController baseGramCtrl;
  late final TextEditingController kcalCtrl;
  late final TextEditingController waterCtrl;
  late final TextEditingController proteinCtrl;
  late final TextEditingController fatCtrl;
  late final TextEditingController carbohydrateCtrl;
  late final TextEditingController fiberCtrl;
  late final TextEditingController ashCtrl;
  late final TextEditingController sodiumCtrl;

  final categories = <String>[].obs;
  final selectedCategory = RxnString();

  bool get isEdit => product != null;
  String get languageCode => Get.locale?.languageCode ?? 'ja';

  @override
  void onInit() {
    super.onInit();
    final p = product;
    nameCtrl = TextEditingController(text: p?.name ?? '');
    manufacturerCtrl = TextEditingController(text: p?.manufacturer ?? '');
    priceCtrl = TextEditingController(
      text: p == null ? '' : p.price.toStringAsFixed(0),
    );
    baseGramCtrl = TextEditingController(
      text: p == null ? '' : p.baseGram.toStringAsFixed(0),
    );
    kcalCtrl = TextEditingController(text: p?.kcal?.toString() ?? '');
    waterCtrl = TextEditingController(text: p?.water?.toString() ?? '');
    proteinCtrl = TextEditingController(text: p?.protein?.toString() ?? '');
    fatCtrl = TextEditingController(text: p?.fat?.toString() ?? '');
    carbohydrateCtrl = TextEditingController(
      text: p?.carbohydrate?.toString() ?? '',
    );
    fiberCtrl = TextEditingController(text: p?.fiber?.toString() ?? '');
    ashCtrl = TextEditingController(text: p?.ash?.toString() ?? '');
    sodiumCtrl = TextEditingController(text: p?.sodium?.toString() ?? '');
    selectedCategory.value = p?.category;
    _loadCategories();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    manufacturerCtrl.dispose();
    priceCtrl.dispose();
    baseGramCtrl.dispose();
    kcalCtrl.dispose();
    waterCtrl.dispose();
    proteinCtrl.dispose();
    fatCtrl.dispose();
    carbohydrateCtrl.dispose();
    fiberCtrl.dispose();
    ashCtrl.dispose();
    sodiumCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadCategories() async {
    try {
      _isLoading.value = true;
      final defaultValues = await _productRepository.fetchDefaultCategoryIds();
      final customValues = await _categoryRepository.fetchCustomCategories();
      final custom = <String>[];
      final defaults = <String>[];
      for (final value in defaultValues) {
        final normalized = IngredientCategoryCatalog.normalizeDefaultId(value);
        defaults.add(normalized);
      }
      for (final value in customValues) {
        custom.add(value);
      }
      custom.sort();
      categories
        ..clear()
        ..addAll(defaults.toSet())
        ..addAll(custom);

      final selected = selectedCategory.value;
      if (selected != null && !categories.contains(selected)) {
        selectedCategory.value = null;
      }
    } catch (e) {
      LogManager.error('$e');
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  void setSelectedCategory(String? value) {
    if (value == null) return;
    selectedCategory.value = value;
  }

  Future<void> goToCategoryManagement() async {
    await Get.toNamed(IngredientCategoryManagementScreen.name);
    await _loadCategories();
  }

  Future<bool> isICloudDeleteWarningVisible() async {
    if (!Platform.isIOS) return false;
    return await _iCloudSettings.isEnabled();
  }

  double? _toDouble(TextEditingController ctrl) {
    final value = ctrl.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  bool isNutritionAllEmpty() {
    return kcalCtrl.text.isEmpty &&
        waterCtrl.text.isEmpty &&
        proteinCtrl.text.isEmpty &&
        fatCtrl.text.isEmpty &&
        carbohydrateCtrl.text.isEmpty &&
        fiberCtrl.text.isEmpty &&
        ashCtrl.text.isEmpty &&
        sodiumCtrl.text.isEmpty;
  }

  Future<void> save() async {
    final previousName = product?.name;
    final name = nameCtrl.text.trim();
    final manufacturer = manufacturerCtrl.text.trim();
    final category = IngredientCategoryCatalog.normalizeDefaultId(
      (selectedCategory.value ?? '').trim(),
    );
    final price = _toDouble(priceCtrl);
    final baseGram = _toDouble(baseGramCtrl);

    if (name.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.ingredientNameRequired.tr);
      return;
    }
    if (category.isEmpty) {
      SnackBarHelper.showErrorSnackBar(
        AppStrings.ingredientCategoryRequired.tr,
      );
      return;
    }

    // if (name.isEmpty || category.isEmpty || price == null || baseGram == null) {
    //   SnackBarHelper.showErrorSnackBar(AppStrings.requiredFieldError.tr);
    //   return;
    // }
    bool result = true;
    if (isNutritionAllEmpty()) {
      result = await Get.dialog(
        barrierDismissible: false,
        AlertDialog.adaptive(
          content: Text(AppStrings.noNutritionInfoConfirmSave.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(AppStrings.no.tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(AppStrings.yes.tr),
            ),
          ],
        ),
      );
    }

    if (!result) return;

    final saved = IngredientProductModel(
      id: product?.id ?? const Uuid().v4(),
      name: name,
      category: category,
      manufacturer: manufacturer,
      price: price ?? 0,
      baseGram: baseGram ?? 0,
      kcal: _toDouble(kcalCtrl),
      water: _toDouble(waterCtrl),
      protein: _toDouble(proteinCtrl),
      fat: _toDouble(fatCtrl),
      carbohydrate: _toDouble(carbohydrateCtrl),
      fiber: _toDouble(fiberCtrl),
      ash: _toDouble(ashCtrl),
      sodium: _toDouble(sodiumCtrl),
    );

    try {
      _isLoading.value = true;
      await _productRepository.saveProduct(saved);
      await _productRepository.syncRecipeIngredientsForProduct(
        product: saved,
        previousName: previousName,
      );
      if (!isEdit) {
        await AnalyticsService.instance.ingredientCreated(
          ingredientId: saved.id,
          category: saved.category,
          isDefault: saved.isDefault,
        );
      }
      await _reloadRecipeCacheIfNeeded();
      Get.back(result: true);
    } catch (e, s) {
      LogManager.error('Save ingredient failed', error: e, stackTrace: s);
      LogManager.error(
        'Save ingredient target: ${saved.id}/${saved.name}',
        error: e,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> delete() async {
    final target = product;
    if (target == null) return;
    try {
      _isLoading.value = true;
      await _productRepository.deleteProduct(target.id);
      await _reloadRecipeCacheIfNeeded();
      Get.back(result: true);
    } catch (e, s) {
      LogManager.error('Delete ingredient failed', error: e, stackTrace: s);
      LogManager.error(
        'Delete ingredient target: ${target.id}/${target.name}',
        error: e,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _reloadRecipeCacheIfNeeded() async {
    if (!Get.isRegistered<RecipeController>()) return;
    await Get.find<RecipeController>().reloadAll();
  }
}

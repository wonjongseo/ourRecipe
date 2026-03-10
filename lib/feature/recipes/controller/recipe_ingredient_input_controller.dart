import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:uuid/uuid.dart';

class RecipeIngredientInputController extends GetxController {
  RecipeIngredientInputController(
    this._productRepository, {
    this.initialIngredient,
  });

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final IngredientProductRepository _productRepository;
  final IngredientModel? initialIngredient;
  final ICloudSyncService _iCloudSync = ICloudSyncService();

  final amountTextCtl = TextEditingController();
  final memoTextCtl = TextEditingController();

  final products = <IngredientProductModel>[].obs;
  final groupedProducts = <IngredientProductGroup>[].obs;
  final Map<String, IngredientProductModel> _productById = {};
  final selectedProductIdRx = RxnString();

  final selectedIngredientName = RxnString();
  final ingredientUnit = IngredientUnit.gram.obs;

  String? get selectedProductId {
    return selectedProductIdRx.value;
  }

  IngredientProductModel? get selectedProduct {
    final id = selectedProductIdRx.value;
    if (id == null || id.isEmpty) return null;
    return _productById[id];
  }

  bool get isAppProvidedProductSelected => selectedProduct?.isDefault ?? false;

  @override
  void onInit() {
    super.onInit();
    _applyInitialIngredient();
    loadProducts();
  }

  void _applyInitialIngredient() {
    final ingredient = initialIngredient;
    if (ingredient == null) return;
    selectedIngredientName.value = ingredient.name;
    amountTextCtl.text = ingredient.amount.toString();
    memoTextCtl.text = ingredient.memo;
    ingredientUnit.value = ingredient.unit;
    _hasPrice.value = ingredient.price != null;
    selectedProductIdRx.value = null;
  }

  @override
  void onClose() {
    amountTextCtl.dispose();
    memoTextCtl.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    try {
      _isLoading.value = true;
      await _syncFromICloudIfEnabled();
      final values = await _productRepository.fetchProducts();
      final grouped = await _productRepository.fetchGroupedProducts();
      values.sort((a, b) => a.name.compareTo(b.name));

      products.assignAll(values);
      _productById
        ..clear()
        ..addEntries(values.map((item) => MapEntry(item.id, item)));
      groupedProducts.assignAll(grouped);

      final selected = selectedIngredientName.value;
      if (selected == null) return;
      final matched = values
          .where((item) => item.name == selected)
          .toList(growable: false);
      if (matched.isEmpty) {
        selectedIngredientName.value = null;
        selectedProductIdRx.value = null;
        return;
      }
      final preferredId = selectedProductIdRx.value;
      if (preferredId != null && _productById.containsKey(preferredId)) {
        if (isAppProvidedProductSelected) {
          ingredientUnit.value = IngredientUnit.gram;
        }
        return;
      }
      selectedProductIdRx.value = matched.first.id;
      if (isAppProvidedProductSelected) {
        ingredientUnit.value = IngredientUnit.gram;
      }
    } catch (e) {
      LogManager.error('$e');
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _syncFromICloudIfEnabled() async {
    await _iCloudSync.pullIfEnabled();
  }

  void onChangeUnit(IngredientUnit? unit) {
    if (isAppProvidedProductSelected) {
      ingredientUnit.value = IngredientUnit.gram;
      SnackBarHelper.showErrorSnackBar(AppStrings.appProvidedUnitFixedGuide.tr);
      return;
    }
    if (unit == null || ingredientUnit.value == unit) return;
    ingredientUnit.value = unit;
  }

  final Rxn<bool> _hasPrice = Rxn();
  bool? get hasPrice => _hasPrice.value;

  void selectProduct(IngredientProductModel product) {
    selectedIngredientName.value = product.name;
    selectedProductIdRx.value = product.id;
    _hasPrice.value = product.price > 0;
    if (product.isDefault) {
      ingredientUnit.value = IngredientUnit.gram;
    }
  }

  List<IngredientProductGroup> filterGroupedProducts(String query) {
    if (query.isEmpty) return groupedProducts;
    final lower = query.toLowerCase();
    final results = <IngredientProductGroup>[];
    for (final group in groupedProducts) {
      final isGroupMatched = group.name.toLowerCase().contains(lower);
      if (isGroupMatched) {
        results.add(group);
        continue;
      }
      final matchedItems = <IngredientProductSubGroup>[];
      for (final item in group.items) {
        final isItemMatched = item.name.toLowerCase().contains(lower);
        final filteredProducts =
            isItemMatched
                ? item.products
                : item.products
                    .where(
                      (product) => product.name.toLowerCase().contains(lower),
                    )
                    .toList();
        if (filteredProducts.isEmpty) {
          continue;
        }
        matchedItems.add(
          IngredientProductSubGroup(
            id: item.id,
            name: item.name,
            products: filteredProducts,
          ),
        );
      }
      if (matchedItems.isEmpty) continue;
      results.add(
        IngredientProductGroup(
          id: group.id,
          name: group.name,
          items: matchedItems,
        ),
      );
    }
    return results;
  }

  IngredientModel? buildIngredient() {
    final name = (selectedIngredientName.value ?? '').trim();
    if (name.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.ingredientNameRequired.tr);
      return null;
    }

    final amount = double.tryParse(amountTextCtl.text.trim());
    if (amount == null) {
      SnackBarHelper.showErrorSnackBar(AppStrings.ingredientAmountRequired.tr);
      return null;
    }

    final product = selectedProduct;
    final resolvedUnit = ingredientUnit.value;

    return IngredientModel(
      id: initialIngredient?.id ?? Uuid().v4(),
      name: name,
      amount: amount,
      unit: resolvedUnit,
      memo: memoTextCtl.text.trim(),
      price: product?.price,
      productAmount: product?.baseGram,
      productUnit:
          product == null || product.baseGram <= 0
              ? null
              : IngredientUnit.gram,
      kcal: product?.kcal,
      water: product?.water,
      protein: product?.protein,
      fat: product?.fat,
      carbohydrate: product?.carbohydrate,
      fiber: product?.fiber,
      ash: product?.ash,
      sodium: product?.sodium,
    );
  }
}

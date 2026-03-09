import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
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

  final IngredientProductRepository _productRepository;
  final IngredientModel? initialIngredient;

  final amountTextCtl = TextEditingController();
  final memoTextCtl = TextEditingController();

  final products = <IngredientProductModel>[].obs;
  final groupedProducts = <IngredientProductGroup>[].obs;

  final selectedIngredientName = RxnString();
  final ingredientUnit = IngredientUnit.gram.obs;

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
  }

  @override
  void onClose() {
    amountTextCtl.dispose();
    memoTextCtl.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    final values = await _productRepository.fetchProducts();
    final grouped = await _productRepository.fetchGroupedProducts();
    values.sort((a, b) => a.name.compareTo(b.name));

    products.assignAll(values);
    groupedProducts.assignAll(grouped);

    final selected = selectedIngredientName.value;
    if (selected != null && !products.any((item) => item.name == selected)) {
      selectedIngredientName.value = null;
    }
  }

  void onChangeUnit(IngredientUnit? unit) {
    if (unit == null || ingredientUnit.value == unit) return;
    ingredientUnit.value = unit;
  }

  final Rxn<bool> _hasPrice = Rxn();
  bool? get hasPrice => _hasPrice.value;

  void selectProduct(IngredientProductModel product) {
    selectedIngredientName.value = product.name;
    _hasPrice.value = product.price > 0;
  }

  List<IngredientProductGroup> filterGroupedProducts(String query) {
    if (query.isEmpty) return groupedProducts;
    final lower = query.toLowerCase();
    final results = <IngredientProductGroup>[];
    for (final group in groupedProducts) {
      final matchedItems = <IngredientProductSubGroup>[];
      for (final item in group.items) {
        final filteredProducts =
            item.products
                .where((product) => product.name.toLowerCase().contains(lower))
                .toList();
        if (filteredProducts.isEmpty) continue;
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

    return IngredientModel(
      id: initialIngredient?.id ?? Uuid().v4(),
      name: name,
      amount: amount,
      unit: ingredientUnit.value,
      memo: memoTextCtl.text.trim(),
    );
  }
}

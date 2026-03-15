import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_edit_screen.dart';

class IngredientManagementController extends GetxController {
  IngredientManagementController(this._repository);

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  final searchTextCtrl = TextEditingController();
  final query = ''.obs;

  final IngredientProductRepository _repository;

  final groupedProducts = <IngredientProductGroup>[].obs;
  List<IngredientProductGroup> get filteredGroups {
    final keyword = query.value.trim().toLowerCase();
    if (keyword.isEmpty) return groupedProducts;

    final results = <IngredientProductGroup>[];
    for (final group in groupedProducts) {
      final filteredItems = <IngredientProductSubGroup>[];
      for (final item in group.items) {
        final filteredProducts = item.products
            .where((product) {
              return product.name.toLowerCase().contains(keyword) ||
                  product.category.toLowerCase().contains(keyword) ||
                  product.manufacturer.toLowerCase().contains(keyword) ||
                  item.name.toLowerCase().contains(keyword) ||
                  group.name.toLowerCase().contains(keyword);
            })
            .toList(growable: false);
        if (filteredProducts.isEmpty) continue;
        filteredItems.add(
          IngredientProductSubGroup(
            id: item.id,
            name: item.name,
            products: filteredProducts,
          ),
        );
      }
      if (filteredItems.isEmpty) continue;
      results.add(
        IngredientProductGroup(
          id: group.id,
          name: group.name,
          items: filteredItems,
        ),
      );
    }
    return results;
  }

  List<IngredientProductGroup> get appProvidedGroups =>
      filteredGroups.where((group) => !group.id.startsWith('custom_')).toList();
  List<IngredientProductGroup> get userAddedGroups =>
      filteredGroups.where((group) => group.id.startsWith('custom_')).toList();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      _isLoading.value = true;
      final values = await _repository.fetchGroupedProducts();
      groupedProducts.assignAll(values);
    } catch (e) {
      LogManager.error('$e');
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> goToEdit({IngredientProductModel? product}) async {
    print('product : ${product}');

    final changed = await Get.toNamed(
      IngredientEditScreen.name,
      arguments: product,
    );
    if (changed == true) {
      await loadProducts();
    }
  }

  void updateQuery(String? value) {
    query.value = (value ?? '').trim();
  }

  void clearQuery() {
    searchTextCtrl.clear();
    query.value = '';
  }

  @override
  void onClose() {
    searchTextCtrl.dispose();
    super.onClose();
  }
}

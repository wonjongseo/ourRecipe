import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';

class IngredientCategoryManagementController extends GetxController {
  IngredientCategoryManagementController(this._repository);
  final IngredientCategoryRepository _repository;

  final inputCtrl = TextEditingController();
  final customCategories = <String>[].obs;
  String get languageCode => Get.locale?.languageCode ?? 'ja';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final values = await _repository.fetchCustomCategories();
    values.sort();
    customCategories.assignAll(values);
  }

  Future<void> add() async {
    final value = inputCtrl.text.trim();
    if (value.isEmpty) return;
    await _repository.addCustomCategory(value);
    inputCtrl.clear();
    await load();
  }

  Future<void> remove(String value) async {
    await _repository.removeCustomCategory(value);
    await load();
  }
}

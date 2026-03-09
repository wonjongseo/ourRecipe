import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/repository/cook_log_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/recipes/screens/recipes_screen.dart';
import 'package:our_recipe/feature/settings/screens/setting_screen.dart';
import 'package:our_recipe/feature/shopping/screens/shopping_screen.dart';

class HomeController extends GetxController {
  final _pageIdx = 0.obs;
  int get pageIdx => _pageIdx.value;

  final _bodys = [RecipesScreen(), ShoppingScreen(), SettingScreen()].obs;

  List<Widget> get bodys => _bodys;

  @override
  void onInit() {
    super.onInit();

    Get.put(RecipeRepository());
    Get.put(RecipeCategoryRepository());
    Get.put(CookLogRepository());
    Get.put(IngredientProductRepository());
    Get.put(IngredientCategoryRepository());
    Get.put(RecipeController(Get.find(), Get.find()));
  }

  Widget get body => _bodys[_pageIdx.value];

  void onDestinationSelected(int value) {
    _pageIdx.value = value;
  }
}

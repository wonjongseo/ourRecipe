import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/feature/my_food/screens/my_foods_screen.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/recipes/screens/recipes_screen.dart';
import 'package:our_recipe/feature/settings/screens/setting_screen.dart';

class HomeController extends GetxController {
  final _pageIdx = 0.obs;
  int get pageIdx => _pageIdx.value;

  final _bodys = [RecipesScreen(), MyFoodsScreen(), SettingScreen()].obs;

  List<Widget> get bodys => _bodys;

  @override
  void onInit() {
    super.onInit();

    Get.put(RecipeRepository());
    Get.put(RecipeController(Get.find()));
  }

  Widget get body => _bodys[_pageIdx.value];

  void onDestinationSelected(int value) {
    _pageIdx.value = value;
  }
}

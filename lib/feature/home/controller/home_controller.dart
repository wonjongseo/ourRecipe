import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:our_recipe/feature/recipes/screens/recipes_screen.dart';
import 'package:our_recipe/feature/my_page/screens/my_page_screen.dart';
import 'package:our_recipe/feature/shopping/screens/shopping_screen.dart';

class HomeController extends GetxController {
  final _pageIdx = 0.obs;
  int get pageIdx => _pageIdx.value;

  final _bodys = [RecipesScreen(), ShoppingScreen(), MyPageScreen()].obs;

  List<Widget> get bodys => _bodys;

  Widget get body => _bodys[_pageIdx.value];

  void onDestinationSelected(int value) {
    _pageIdx.value = value;
  }
}

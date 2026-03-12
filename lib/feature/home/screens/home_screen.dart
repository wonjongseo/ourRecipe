import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/services/test_data_service.dart';
import 'package:our_recipe/feature/home/controller/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});
  static String name = '/';
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: controller.body,
        // floatingActionButton: _floatingActionButton(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.pageIdx,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onDestinationSelected: controller.onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.utensils),
              label: AppStrings.recipe.tr,
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.shoppingBag),
              label: AppStrings.shopping.tr,
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.user),
              label: AppStrings.myPage.tr,
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton _floatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        await TestDataService().seedSampleRecipes();
      },
    );
  }
}

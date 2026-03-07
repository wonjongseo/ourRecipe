import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:our_recipe/feature/home/controller/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});
  static String name = '/';
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: SafeArea(child: controller.body),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.pageIdx,
          onDestinationSelected: controller.onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.utensils),
              label: '레시피',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.bowlFood),
              label: '재료',
            ),
            NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
          ],
        ),
      ),
    );
  }
}

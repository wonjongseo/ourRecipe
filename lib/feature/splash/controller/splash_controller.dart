import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:our_recipe/feature/home/screens/home_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    super.onInit();
    _setUp();
  }

  void _setUp() async {
    await Future.delayed(Duration(milliseconds: 800));

    Get.offAllNamed(HomeScreen.name);
  }
}

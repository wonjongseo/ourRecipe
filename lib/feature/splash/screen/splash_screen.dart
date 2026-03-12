import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_images.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static String name = '/welcome';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.appImage, width: size.width * .8),
              Text(AppStrings.appTitle.tr),
            ],
          ),
        ),
      ),
    );
  }
}

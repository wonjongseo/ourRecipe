import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_images.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static String name = '/welcome';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.appImage, width: size.width * .8),
              Text(
                AppStrings.appTitle.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

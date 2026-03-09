import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static String name = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text(AppStrings.appTitle.tr)],
          ),
        ),
      ),
    );
  }
}

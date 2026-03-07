import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:get/route_manager.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/pages/app_pages.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Our Recipe',
      theme: AppTheme.lightTheme,
      getPages: AppPages.pages,
      initialRoute: SplashScreen.name,
      fallbackLocale: const Locale('ja', 'JP'),
      locale: Locale(Get.locale.toString()),
      translations: AppStrings(),
    );
  }
}

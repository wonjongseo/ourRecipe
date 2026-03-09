import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';

class SettingController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final ThemeService _themeService = ThemeService();

  @override
  void onInit() {
    super.onInit();
    _initThemeMode();
  }

  Future<void> _initThemeMode() async {
    final savedMode = await _themeService.getSavedThemeMode();
    if (savedMode != null) {
      themeMode.value = savedMode;
      return;
    }
    themeMode.value = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Locale currentLocale() {
    final code = Get.locale?.languageCode ?? 'ja';
    switch (code) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ja', 'JP');
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    await LocaleService().saveLocale(locale);
    await Get.updateLocale(locale);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _themeService.saveThemeMode(mode);
    Get.changeThemeMode(mode);
  }

  Future<void> goToCategoryManagement() async {
    await Get.toNamed(CategoryManagementScreen.name);
    await Get.find<RecipeController>().refreshCategories();
  }

  Future<void> goToIngredientManagement() async {
    await Get.toNamed(IngredientManagementScreen.name);
  }
}

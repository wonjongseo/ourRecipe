import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';

class MyPageController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final fontKey = AppFonts.system.obs;
  final textScale = 1.0.obs;
  final ThemeService _themeService = ThemeService();

  @override
  void onInit() {
    super.onInit();
    _initThemeMode();
    _initFontKey();
    _initTextScale();
  }

  Future<void> _initThemeMode() async {
    final savedMode = await _themeService.getSavedThemeMode();
    if (savedMode != null) {
      themeMode.value = savedMode;
      return;
    }
    themeMode.value = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _initFontKey() async {
    final saved = await _themeService.getSavedFontKey();
    if (saved == null || saved.isEmpty) return;
    final isValid = AppFonts.options.any((option) => option.key == saved);
    if (!isValid) return;
    fontKey.value = saved;
  }

  Future<void> _initTextScale() async {
    final saved = await _themeService.getSavedTextScale();
    final value = (saved ?? ThemeService.textScale.value).clamp(0.8, 1.4);
    textScale.value = value.toDouble();
    ThemeService.textScale.value = value.toDouble();
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
    _applyTheme(locale: locale, mode: themeMode.value);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _themeService.saveThemeMode(mode);
    _applyTheme(locale: currentLocale(), mode: mode);
    Get.changeThemeMode(mode);
  }

  Future<void> changeFont(String key) async {
    if (fontKey.value == key) return;
    fontKey.value = key;
    await _themeService.saveFontKey(key);
    _applyTheme(locale: currentLocale(), mode: themeMode.value);
  }

  void previewTextScale(double value) {
    final clamped = value.clamp(0.8, 1.4).toDouble();
    textScale.value = clamped;
    ThemeService.textScale.value = clamped;
  }

  Future<void> persistTextScale(double value) async {
    final clamped = value.clamp(0.8, 1.4).toDouble();
    textScale.value = clamped;
    ThemeService.textScale.value = clamped;
    await _themeService.saveTextScale(clamped);
  }

  void _applyTheme({required Locale locale, required ThemeMode mode}) {
    final currentFont = fontKey.value;
    if (mode == ThemeMode.dark) {
      Get.changeTheme(AppTheme.darkThemeFor(locale, fontKey: currentFont));
      return;
    }
    if (mode == ThemeMode.light) {
      Get.changeTheme(AppTheme.lightThemeFor(locale, fontKey: currentFont));
      return;
    }
    Get.changeTheme(
      Get.isDarkMode
          ? AppTheme.darkThemeFor(locale, fontKey: currentFont)
          : AppTheme.lightThemeFor(locale, fontKey: currentFont),
    );
  }

  Future<void> goToCategoryManagement() async {
    await Get.toNamed(CategoryManagementScreen.name);
    await Get.find<RecipeController>().refreshCategories();
  }

  Future<void> goToIngredientManagement() async {
    await Get.toNamed(IngredientManagementScreen.name);
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/services/app_data_path_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_migration_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';
import 'package:our_recipe/feature/my_page/screens/icloud_sync_settings_screen.dart';

class MyPageController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final fontKey = AppFonts.system.obs;
  final textScale = 1.0.obs;
  final ThemeService _themeService = ThemeService();
  final ICloudSyncSettingsService _iCloudSettings = ICloudSyncSettingsService();
  final ICloudSyncMigrationService _migrationService =
      ICloudSyncMigrationService();
  final iCloudSyncEnabled = true.obs;
  final isICloudSyncUpdating = false.obs;
  final iCloudStatusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initThemeMode();
    _initFontKey();
    _initTextScale();
    _initICloudSync();
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

  Future<void> _initICloudSync() async {
    iCloudSyncEnabled.value = await _iCloudSettings.isEnabled();
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
    await Get.toNamed(CategoryManagementScreen.name, arguments: false);
    await Get.find<RecipeController>().refreshCategories();
  }

  Future<void> goToIngredientManagement() async {
    await Get.toNamed(IngredientManagementScreen.name);
  }

  Future<void> goToICloudSyncSettings() async {
    await refreshICloudStatusMessage();
    await Get.toNamed(ICloudSyncSettingsScreen.name);
  }

  Future<void> changeICloudSync(bool enabled) async {
    if (isICloudSyncUpdating.value) return;
    if (iCloudSyncEnabled.value == enabled) return;
    iCloudSyncEnabled.value = enabled;
    isICloudSyncUpdating.value = true;

    try {
      await RecipeDatabaseService.reset();
      if (enabled) {
        await _migrationService.syncBidirectionalMerge();
      } else {
        // OFF 전환 시 현재 iCloud 내용을 로컬에 1회 반영한다.
        await _migrationService.syncFromICloudToLocalMerge();
      }

      await _iCloudSettings.setEnabled(enabled);
      await RecipeDatabaseService.reset();
      if (Get.isRegistered<RecipeController>()) {
        await Get.find<RecipeController>().reloadAll();
      }
      await refreshICloudStatusMessage();
    } on ICloudUnavailableException {
      iCloudSyncEnabled.value = !enabled;
      iCloudStatusMessage.value = AppStrings.pleaseCheckSettings.tr;
    } catch (_) {
      iCloudSyncEnabled.value = !enabled;
      iCloudStatusMessage.value = AppStrings.dbSaveFailed.tr;
    } finally {
      isICloudSyncUpdating.value = false;
    }
  }

  Future<void> deleteAllICloudData() async {
    if (isICloudSyncUpdating.value) return;
    isICloudSyncUpdating.value = true;
    try {
      // 파일 삭제 전에 DB 핸들을 먼저 닫아 잠금 이슈를 방지한다.
      await RecipeDatabaseService.reset();
      await _migrationService.deleteAllICloudData();
      await RecipeDatabaseService.reset();
      if (Get.isRegistered<RecipeController>()) {
        await Get.find<RecipeController>().reloadAll();
      }
      await refreshICloudStatusMessage();
    } on ICloudUnavailableException {
      iCloudStatusMessage.value = AppStrings.pleaseCheckSettings.tr;
    } catch (_) {
      iCloudStatusMessage.value = AppStrings.dbSaveFailed.tr;
    } finally {
      isICloudSyncUpdating.value = false;
    }
  }

  Future<void> refreshICloudStatusMessage() async {
    final status = await AppDataPathService.getICloudStatus();
    if (status == null) {
      iCloudStatusMessage.value = '';
      return;
    }
    final tokenPresent = status['tokenPresent'] == true;
    final containerAvailable = status['containerAvailable'] == true;
    iCloudStatusMessage.value =
        tokenPresent && containerAvailable ? '' : AppStrings.pleaseCheckSettings.tr;
  }
}

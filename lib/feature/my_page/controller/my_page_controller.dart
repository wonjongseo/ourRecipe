import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/icloud/app_data_path_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
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
  final ICloudSyncService _iCloudSync = ICloudSyncService();
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
      await _iCloudSettings.setEnabled(enabled);
      await refreshICloudStatusMessage();
    } catch (e, s) {
      LogManager.error('Change iCloud sync failed', error: e, stackTrace: s);
      iCloudSyncEnabled.value = !enabled;
      iCloudStatusMessage.value = AppStrings.dbSaveFailed.tr;
    } finally {
      isICloudSyncUpdating.value = false;
    }
  }

  Future<void> deleteAllICloudData() async {
    if (isICloudSyncUpdating.value) return;
    await _runICloudTask(
      title: AppStrings.deleteAllICloudData.tr,
      description: AppStrings.iCloudDeleteProgressDescription.tr,
      successMessage: AppStrings.iCloudDeleteCompleted.tr,
      task: () async {
        await RecipeDatabaseService.reset();
        await _iCloudSync.clearCloudDataIfEnabled();
        await RecipeDatabaseService.reset();
        if (Get.isRegistered<RecipeController>()) {
          await Get.find<RecipeController>().reloadAll();
        }
        await refreshICloudStatusMessage();
      },
      onError: (e, s) {
        LogManager.error(
          'Delete all CloudKit data failed',
          error: e,
          stackTrace: s,
        );
        iCloudStatusMessage.value = AppStrings.dbSaveFailed.tr;
      },
    );
  }

  Future<void> uploadLocalDataToICloud() async {
    if (isICloudSyncUpdating.value) return;
    await _runICloudTask(
      title: AppStrings.uploadToICloud.tr,
      description: AppStrings.iCloudUploadProgressDescription.tr,
      successMessage: AppStrings.iCloudUploadCompleted.tr,
      task: () async {
        await _iCloudSync.pushIfEnabled();
      },
      onError: (e, s) {
        LogManager.error(
          'Upload local data to iCloud failed',
          error: e,
          stackTrace: s,
        );
        iCloudStatusMessage.value = AppStrings.dbSaveFailed.tr;
      },
    );
  }

  Future<void> downloadICloudDataToLocal() async {
    if (isICloudSyncUpdating.value) return;
    await _runICloudTask(
      title: AppStrings.downloadFromICloud.tr,
      description: AppStrings.iCloudDownloadProgressDescription.tr,
      successMessage: AppStrings.iCloudDownloadCompleted.tr,
      task: () async {
        await RecipeDatabaseService.reset();
        await _iCloudSync.pullIfEnabled();
        await RecipeDatabaseService.reset();
        if (Get.isRegistered<RecipeController>()) {
          await Get.find<RecipeController>().reloadAll();
        }
      },
      onError: (e, s) {
        LogManager.error(
          'Download iCloud data to local failed',
          error: e,
          stackTrace: s,
        );
        iCloudStatusMessage.value = AppStrings.dbLoadFailed.tr;
      },
    );
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

  Future<void> _runICloudTask({
    required String title,
    required String description,
    required String successMessage,
    required Future<void> Function() task,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    isICloudSyncUpdating.value = true;
    _showICloudProgressDialog(title: title, description: description);

    try {
      await task();
      SnackBarHelper.showSuccessSnackBar(successMessage);
    } catch (e, s) {
      onError(e, s);
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      isICloudSyncUpdating.value = false;
    }
  }

  void _showICloudProgressDialog({
    required String title,
    required String description,
  }) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Get.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

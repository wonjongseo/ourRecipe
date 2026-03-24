import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:our_recipe/core/common/app_color_presets.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/analytics_service.dart';
import 'package:our_recipe/core/services/icloud/app_data_path_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/core/services/premium_service.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';
import 'package:our_recipe/feature/my_page/screens/font_preview_screen.dart';
import 'package:our_recipe/feature/my_page/screens/icloud_sync_settings_screen.dart';
import 'package:our_recipe/feature/my_page/screens/premium_purchase_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPageController extends GetxController {
  static const String supportEmail = 'visionwill3322@gmail.com';
  final themeMode = ThemeMode.system.obs;
  final colorPresetKey = ThemeService.colorPresetKey;
  final fontKey = AppFonts.defaultKeyFor(const Locale('ja', 'JP')).obs;
  final textScale = 1.0.obs;
  final appVersionLabel = ''.obs;
  final ThemeService _themeService = ThemeService();
  final ICloudSyncSettingsService _iCloudSettings = ICloudSyncSettingsService();
  final ICloudSyncService _iCloudSync = ICloudSyncService();
  final PremiumService premiumService = Get.find<PremiumService>();
  final iCloudSyncEnabled = true.obs;
  final isICloudSyncUpdating = false.obs;
  final iCloudStatusMessage = ''.obs;
  Worker? _premiumWorker;

  @override
  void onInit() {
    super.onInit();
    _initThemeMode();
    _initColorPreset();
    _initFontKey();
    _initTextScale();
    _initICloudSync();
    _initAppVersion();
    _bindPremiumState();
  }

  Future<void> _initThemeMode() async {
    final savedMode = await _themeService.getSavedThemeMode();
    if (savedMode != null) {
      themeMode.value = savedMode;
      ThemeService.currentThemeMode.value = savedMode;
      return;
    }
    themeMode.value = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    ThemeService.currentThemeMode.value = themeMode.value;
  }

  Future<void> _initColorPreset() async {
    final saved = await _themeService.getSavedColorPresetKey();
    colorPresetKey.value = AppColorPresets.resolve(saved).key;
  }

  Future<void> _initFontKey() async {
    final saved = await _themeService.getSavedFontKey();
    if (saved == null || saved.isEmpty) return;
    final isValid = AppFonts.isValidKey(saved);
    if (!isValid) return;
    fontKey.value = saved;
    _ensureFontMatchesLocale();
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

  void _bindPremiumState() {
    _premiumWorker = ever<bool>(premiumService.isPremium, (isPremium) async {
      if (!premiumService.canUseICloud) {
        await _iCloudSettings.setEnabled(false);
        iCloudSyncEnabled.value = false;
      } else {
        iCloudSyncEnabled.value = await _iCloudSettings.isEnabled();
      }
      await refreshICloudStatusMessage();
    });
  }

  bool get canUseICloud => premiumService.canUseICloud;

  Future<void> _initAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // appVersionLabel.value = '${info.version}+${info.buildNumber}';
      appVersionLabel.value = info.version;
    } catch (e, s) {
      LogManager.error('Load app version failed', error: e, stackTrace: s);
      appVersionLabel.value = '-';
    }
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

  String selectedFontKeyForCurrentLocale() {
    final locale = currentLocale();
    if (AppFonts.isValidKeyForLocale(fontKey.value, locale)) {
      return fontKey.value;
    }
    return AppFonts.defaultKeyFor(locale);
  }

  String selectedFontLabelForCurrentLocale() {
    final selectedKey = selectedFontKeyForCurrentLocale();
    final options = fontOptionsForCurrentLocale();
    for (final option in options) {
      if (option.key == selectedKey) return option.label;
    }
    return options.first.label;
  }

  Future<void> changeLanguage(Locale locale) async {
    await LocaleService().saveLocale(locale);
    if (!AppFonts.isValidKeyForLocale(fontKey.value, locale)) {
      fontKey.value = AppFonts.defaultKeyFor(locale);
      await _themeService.saveFontKey(fontKey.value);
    }
    await Get.updateLocale(locale);
    _applyTheme(locale: locale, mode: themeMode.value);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    ThemeService.currentThemeMode.value = mode;
    await _themeService.saveThemeMode(mode);
    _applyTheme(locale: currentLocale(), mode: mode);
    Get.changeThemeMode(mode);
  }

  Future<void> changeColorPreset(String key) async {
    final resolved = AppColorPresets.resolve(key).key;
    if (colorPresetKey.value == resolved) return;
    colorPresetKey.value = resolved;
    await _themeService.saveColorPresetKey(resolved);
    _applyTheme(locale: currentLocale(), mode: themeMode.value);
  }

  Future<void> changeFont(String key) async {
    if (fontKey.value == key) return;
    fontKey.value = key;
    await _themeService.saveFontKey(key);
    _applyTheme(locale: currentLocale(), mode: themeMode.value);
  }

  Future<void> goToFontPreview() async {
    await Get.to(() => const FontPreviewScreen());
  }

  List<AppFontOption> fontOptionsForCurrentLocale() {
    return AppFonts.optionsFor(currentLocale());
  }

  List<AppColorPreset> colorPresets() => AppColorPresets.values;

  Future<void> _ensureFontMatchesLocale() async {
    final locale = currentLocale();
    if (AppFonts.isValidKeyForLocale(fontKey.value, locale)) return;
    final fallback = AppFonts.defaultKeyFor(locale);
    if (fontKey.value == fallback) return;
    fontKey.value = fallback;
    await _themeService.saveFontKey(fallback);
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
    final presetKey = colorPresetKey.value;
    if (mode == ThemeMode.dark) {
      Get.changeTheme(
        AppTheme.darkThemeFor(
          locale,
          fontKey: currentFont,
          colorPresetKey: presetKey,
        ),
      );
      return;
    }
    if (mode == ThemeMode.light) {
      Get.changeTheme(
        AppTheme.lightThemeFor(
          locale,
          fontKey: currentFont,
          colorPresetKey: presetKey,
        ),
      );
      return;
    }
    Get.changeTheme(
      Get.isDarkMode
          ? AppTheme.darkThemeFor(
            locale,
            fontKey: currentFont,
            colorPresetKey: presetKey,
          )
          : AppTheme.lightThemeFor(
            locale,
            fontKey: currentFont,
            colorPresetKey: presetKey,
          ),
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
    if (!GetPlatform.isIOS) {
      await refreshICloudStatusMessage();
      await Get.toNamed(ICloudSyncSettingsScreen.name);
      return;
    }
    if (!canUseICloud) {
      await Get.toNamed(PremiumPurchaseScreen.name);
      return;
    }
    await refreshICloudStatusMessage();
    await Get.toNamed(ICloudSyncSettingsScreen.name);
  }

  Future<void> goToPremiumPurchase() async {
    await Get.toNamed(PremiumPurchaseScreen.name);
  }

  Future<void> openReviewPage() async {
    try {
      final review = InAppReview.instance;
      final isAvailable = await review.isAvailable();
      if (isAvailable) {
        await review.openStoreListing();
        return;
      }
    } catch (e, s) {
      LogManager.error('Open review page failed', error: e, stackTrace: s);
    }
    SnackBarHelper.showErrorSnackBar(AppStrings.reviewOpenFailed.tr);
  }

  Future<void> contactSupport() async {
    final version = appVersionLabel.value.isEmpty ? '-' : appVersionLabel.value;
    final locale = Get.locale;
    final languageTag =
        locale == null
            ? '-'
            : '${locale.languageCode}${locale.countryCode == null ? '' : '-${locale.countryCode}'}';
    final platformName =
        defaultTargetPlatform.name +
        (GetPlatform.isIOS
            ? ' / iOS'
            : GetPlatform.isAndroid
            ? ' / Android'
            : '');
    final body = [
      AppStrings.supportMailIntro.tr,
      '',
      '${AppStrings.supportMailIssueType.tr}: ',
      '  - ',
      '',
      '${AppStrings.supportMailIssueSummary.tr}: ',
      '  - ',
      '',
      '${AppStrings.supportMailReproductionSteps.tr}:',
      '1. ',
      '2. ',
      '3. ',
      '',
      '${AppStrings.supportMailExpectedResult.tr}:',
      '',
      '${AppStrings.supportMailActualResult.tr}:',
      '',
      AppStrings.supportMailAttachmentNote.tr,
      '',
      '---',
      '${AppStrings.appVersion.tr}: $version',
      'Platform: $platformName',
      'Language: $languageTag',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': '[Our Recipe] ${AppStrings.contactAndBugReport.tr}',
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e, s) {
      LogManager.error('Open support email failed', error: e, stackTrace: s);
    }

    await _showCopyEmailDialog();
  }

  Future<void> _showCopyEmailDialog() async {
    final shouldCopy =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text(AppStrings.mailAppUnavailableTitle.tr),
            content: Text(AppStrings.mailAppUnavailableMessage.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(AppStrings.cancel.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text(AppStrings.copyEmail.tr),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldCopy) return;
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    SnackBarHelper.showSuccessSnackBar(AppStrings.emailCopied.tr);
  }

  Future<void> changeICloudSync(bool enabled) async {
    if (!GetPlatform.isIOS) return;
    if (!canUseICloud) {
      await Get.toNamed(PremiumPurchaseScreen.name);
      return;
    }
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
        await AnalyticsService.instance.iCloudUploadStarted();
        await _iCloudSync.pushIfEnabled();
        await AnalyticsService.instance.iCloudUploadCompleted();
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
        await AnalyticsService.instance.iCloudDownloadCompleted();
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
    if (!GetPlatform.isIOS) {
      iCloudStatusMessage.value = AppStrings.iCloudIOSOnly.tr;
      return;
    }
    if (!canUseICloud) {
      iCloudStatusMessage.value = AppStrings.premiumICloudLocked.tr;
      return;
    }
    final status = await AppDataPathService.getICloudStatus();
    if (status == null) {
      iCloudStatusMessage.value = '';
      return;
    }
    final tokenPresent = status['tokenPresent'] == true;
    final containerAvailable = status['containerAvailable'] == true;
    iCloudStatusMessage.value =
        tokenPresent && containerAvailable
            ? ''
            : AppStrings.pleaseCheckSettings.tr;
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
    var isSuccess = false;

    try {
      await task();
      isSuccess = true;
    } catch (e, s) {
      onError(e, s);
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      isICloudSyncUpdating.value = false;
      if (isSuccess) {
        SnackBarHelper.showSuccessSnackBar(successMessage);
      }
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

  @override
  void onClose() {
    _premiumWorker?.dispose();
    super.onClose();
  }
}

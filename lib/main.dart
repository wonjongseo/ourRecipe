import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/pages/app_pages.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  final savedLocale = await LocaleService().getSavedLocale();
  final themeService = ThemeService();
  final savedThemeMode = await themeService.getSavedThemeMode();
  final savedFontKey = await themeService.getSavedFontKey();
  final savedTextScale = await themeService.getSavedTextScale();
  ThemeService.textScale.value =
      savedTextScale == null ? 1.0 : savedTextScale.clamp(0.8, 1.4).toDouble();
  runApp(
    MyApp(
      initialLocale: savedLocale,
      initialThemeMode: savedThemeMode,
      initialFontKey: savedFontKey,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialLocale,
    this.initialThemeMode,
    this.initialFontKey,
  });
  final Locale? initialLocale;
  final ThemeMode? initialThemeMode;
  final String? initialFontKey;

  @override
  Widget build(BuildContext context) {
    final locale = initialLocale ?? const Locale('ko', 'KR');
    final fontKey =
        AppFonts.options.any((option) => option.key == initialFontKey)
            ? initialFontKey!
            : AppFonts.system;
    return GetMaterialApp(
      title: AppStrings.appTitle.tr,
      theme: AppTheme.lightThemeFor(locale, fontKey: fontKey),
      darkTheme: AppTheme.darkThemeFor(locale, fontKey: fontKey),
      themeMode: initialThemeMode ?? ThemeMode.system,
      getPages: AppPages.pages,
      initialRoute: SplashScreen.name,
      fallbackLocale: const Locale('ko', 'KR'),
      locale: locale,
      translations: AppStrings(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Obx(() {
          final mediaQuery = MediaQuery.of(context);
          final scale = ThemeService.textScale.value;
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
            child: child,
          );
        });
      },
    );
  }
}

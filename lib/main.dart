import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:get/route_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/pages/app_pages.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  final savedLocale = await LocaleService().getSavedLocale();
  final savedThemeMode = await ThemeService().getSavedThemeMode();
  runApp(MyApp(initialLocale: savedLocale, initialThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialLocale, this.initialThemeMode});
  final Locale? initialLocale;
  final ThemeMode? initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appTitle.tr,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode ?? ThemeMode.system,
      getPages: AppPages.pages,
      initialRoute: SplashScreen.name,
      fallbackLocale: const Locale('ko', 'KR'),
      locale: initialLocale ?? const Locale('ko', 'KR'),
      translations: AppStrings(),
    );
  }
}

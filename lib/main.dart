import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/app_theme.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/pages/app_pages.dart';
import 'package:our_recipe/core/services/ad_interstitial_service.dart';
import 'package:our_recipe/core/services/analytics_service.dart';
import 'package:our_recipe/core/services/locale_service.dart';
import 'package:our_recipe/core/services/local_notification_service.dart';
import 'package:our_recipe/core/services/theme_service.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';
import 'package:our_recipe/firebase_options.dart';

bool canUseICloudMaster = false;
const List<Locale> _supportedLocales = [
  Locale('ja', 'JP'),
  Locale('ko', 'KR'),
  Locale('en', 'US'),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.instance.initialize();
  await MobileAds.instance.initialize();
  await LocalNotificationService.instance.initialize();
  AdInterstitialService.instance.initialize();
  final savedLocale = await LocaleService().getSavedLocale();
  final themeService = ThemeService();
  final savedThemeMode = await themeService.getSavedThemeMode();
  final savedFontKey = await themeService.getSavedFontKey();
  final savedTextScale = await themeService.getSavedTextScale();
  final initialLocale = _resolveInitialLocale(savedLocale);
  ThemeService.textScale.value =
      savedTextScale == null ? 1.0 : savedTextScale.clamp(0.8, 1.4).toDouble();
  runApp(
    MyApp(
      initialLocale: initialLocale,
      initialThemeMode: savedThemeMode,
      initialFontKey: savedFontKey,
    ),
  );
}

Locale _resolveInitialLocale(Locale? savedLocale) {
  if (savedLocale != null) return savedLocale;
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  for (final locale in _supportedLocales) {
    if (locale.languageCode == deviceLocale.languageCode) {
      return locale;
    }
  }
  return const Locale('ko', 'KR');
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
    final locale = initialLocale ?? _resolveInitialLocale(null);
    final fontKey =
        initialFontKey != null && AppFonts.isValidKey(initialFontKey!)
            ? initialFontKey!
            : AppFonts.defaultKeyFor(locale);
    return GetMaterialApp(
      title: AppStrings.appTitle.tr,
      theme: AppTheme.lightThemeFor(locale, fontKey: fontKey),
      darkTheme: AppTheme.darkThemeFor(locale, fontKey: fontKey),
      themeMode: initialThemeMode ?? ThemeMode.system,
      getPages: AppPages.pages,
      initialRoute: SplashScreen.name,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
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

/*
 
Android Command - flutter build appbundle

 */

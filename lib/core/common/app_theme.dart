import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_fonts.dart';

class AppTheme {
  static final _lightColorScheme = ColorScheme.light(
    primary: AppColors.primaryColor,
    onPrimary: AppColors.onPrimaryColor,
    secondary: AppColors.secondaryColor,
    onSecondary: AppColors.onSecondaryColor,
    primaryContainer: const Color(0xFFDDEFE4),
    onPrimaryContainer: AppColors.textPrimary,
    secondaryContainer: const Color(0xFFFAEFE4),
    onSecondaryContainer: AppColors.textPrimary,
    surface: AppColors.surfaceColor,
    onSurface: AppColors.textPrimary,
    outline: AppColors.borderColor,
  );
  static final _darkColorScheme = ColorScheme.dark(
    primary: const Color(0xFF81C784),
    onPrimary: Colors.black,
    secondary: const Color(0xFFFFB74D),
    onSecondary: Colors.black,
    surface: const Color(0xFF1E1E1E),
    onSurface: Colors.white,
    outline: const Color(0xFF424242),
  );

  static ThemeData lightThemeFor(
    Locale locale, {
    String fontKey = AppFonts.system,
  }) {
    final textTheme = AppFonts.textThemeFor(
      fontKey: fontKey,
      locale: locale,
      base: ThemeData.light(useMaterial3: true).textTheme,
    );
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: _lightColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.onSecondaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.onPrimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
      ),
      cardColor: Colors.white,
    );
  }

  static ThemeData darkThemeFor(
    Locale locale, {
    String fontKey = AppFonts.system,
  }) {
    final textTheme = AppFonts.textThemeFor(
      fontKey: fontKey,
      locale: locale,
      base: ThemeData.dark(useMaterial3: true).textTheme,
    );
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: _darkColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        // Light mode accent(#E7BE98)와 톤을 맞춘 다크 전용 AppBar 컬러.
        backgroundColor: const Color(0xFF3A2C25),
        foregroundColor: const Color(0xFFF4E4D4),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: const Color(0xFFF4E4D4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _darkColorScheme.primary),
      ),
      cardColor: const Color(0xFF1E1E1E),
    );
  }
}

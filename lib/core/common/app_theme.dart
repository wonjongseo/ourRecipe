import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_color_presets.dart';
import 'package:our_recipe/core/common/app_fonts.dart';

class AppTheme {
  static ThemeData lightThemeFor(
    Locale locale, {
    String? fontKey,
    String? colorPresetKey,
  }) {
    final palette = AppColorPresets.resolve(colorPresetKey).light;
    final colorScheme = ColorScheme.light(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      outline: palette.outline,
    );
    final textTheme = AppFonts.textThemeFor(
      fontKey: fontKey ?? AppFonts.defaultKeyFor(locale),
      locale: locale,
      base: ThemeData.light(useMaterial3: true).textTheme,
    );
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.appBarBackground,
        foregroundColor: palette.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.appBarForeground,
          fontWeight: FontWeight.w700,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.primary),
      ),
      cardColor: palette.card,
    );
  }

  static ThemeData darkThemeFor(
    Locale locale, {
    String? fontKey,
    String? colorPresetKey,
  }) {
    final palette = AppColorPresets.resolve(colorPresetKey).dark;
    final colorScheme = ColorScheme.dark(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      outline: palette.outline,
    );
    final textTheme = AppFonts.textThemeFor(
      fontKey: fontKey ?? AppFonts.defaultKeyFor(locale),
      locale: locale,
      base: ThemeData.dark(useMaterial3: true).textTheme,
    );
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.appBarBackground,
        foregroundColor: palette.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.appBarForeground,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.primary),
      ),
      cardColor: palette.card,
    );
  }
}

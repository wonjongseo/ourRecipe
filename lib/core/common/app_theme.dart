import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_colors.dart';

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

  static ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.primaryContainer,
      foregroundColor: _lightColorScheme.onPrimaryContainer,
      elevation: 0,
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

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
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

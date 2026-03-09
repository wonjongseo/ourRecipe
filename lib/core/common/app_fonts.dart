import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class AppFontOption {
  final String key;
  final String labelKey;

  const AppFontOption({required this.key, required this.labelKey});
}

class AppFonts {
  static const String system = 'system';
  static const String noto = 'noto';
  static const String modern = 'modern';
  static const String serif = 'serif';
  static const String rounded = 'rounded';

  static List<AppFontOption> options = [
    AppFontOption(key: system, labelKey: AppStrings.fontSystem),
    AppFontOption(key: noto, labelKey: AppStrings.fontNoto),
    AppFontOption(key: modern, labelKey: AppStrings.fontModern),
    AppFontOption(key: serif, labelKey: AppStrings.fontSerif),
    AppFontOption(key: rounded, labelKey: AppStrings.fontRounded),
  ];

  static TextTheme textThemeFor({
    required String fontKey,
    required Locale locale,
    required TextTheme base,
  }) {
    final family = _familyByLocale(fontKey: fontKey, locale: locale);
    return GoogleFonts.getTextTheme(family, base);
  }

  static String _familyByLocale({
    required String fontKey,
    required Locale locale,
  }) {
    final language = locale.languageCode;
    switch (fontKey) {
      case noto:
        return switch (language) {
          'ko' => 'Noto Sans KR',
          'ja' => 'Noto Sans JP',
          _ => 'Noto Sans',
        };
      case modern:
        return switch (language) {
          'ko' => 'Nanum Gothic',
          'ja' => 'M PLUS 1p',
          _ => 'Inter',
        };
      case serif:
        return switch (language) {
          'ko' => 'Noto Serif KR',
          'ja' => 'Noto Serif JP',
          _ => 'Merriweather',
        };
      case rounded:
        return switch (language) {
          'ko' => 'Jua',
          'ja' => 'Kosugi Maru',
          _ => 'Nunito',
        };
      case system:
      default:
        return switch (language) {
          'ko' => 'Noto Sans KR',
          'ja' => 'Noto Sans JP',
          _ => 'Plus Jakarta Sans',
        };
    }
  }
}

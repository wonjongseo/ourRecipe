import 'package:flutter/material.dart';

class AppColorPalette {
  const AppColorPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.outline,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.card,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color outline;
  final Color appBarBackground;
  final Color appBarForeground;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color card;
}

class AppColorPreset {
  const AppColorPreset({
    required this.key,
    required this.light,
    required this.dark,
  });

  final String key;
  final AppColorPalette light;
  final AppColorPalette dark;
}

class AppColorPresets {
  const AppColorPresets._();

  static const String defaultKey = 'warm_ivory';

  static const List<AppColorPreset> values = [
    AppColorPreset(
      key: 'warm_ivory',
      light: AppColorPalette(
        primary: Color(0xFFC65D3A),
        onPrimary: Colors.white,
        secondary: Color(0xFFE9C7AD),
        onSecondary: Color(0xFF34241C),
        background: Color(0xFFFFFDF9),
        surface: Color(0xFFFFF8F1),
        onSurface: Color(0xFF2F241F),
        outline: Color(0xFFE3D3C7),
        appBarBackground: Color(0xFFE9C7AD),
        appBarForeground: Color(0xFF34241C),
        primaryContainer: Color(0xFFF3D8CC),
        onPrimaryContainer: Color(0xFF4C2517),
        secondaryContainer: Color(0xFFF8EADF),
        onSecondaryContainer: Color(0xFF403028),
        card: Colors.white,
      ),
      dark: AppColorPalette(
        primary: Color(0xFFE07A57),
        onPrimary: Color(0xFF2A130C),
        secondary: Color(0xFF7D5A47),
        onSecondary: Color(0xFFF8ECE3),
        background: Color(0xFF1C1714),
        surface: Color(0xFF2A211D),
        onSurface: Color(0xFFF6EDE6),
        outline: Color(0xFF5C4A41),
        appBarBackground: Color(0xFF3A2B24),
        appBarForeground: Color(0xFFF6EDE6),
        primaryContainer: Color(0xFF64301D),
        onPrimaryContainer: Color(0xFFFFDCCF),
        secondaryContainer: Color(0xFF4B382F),
        onSecondaryContainer: Color(0xFFF8ECE3),
        card: Color(0xFF2A211D),
      ),
    ),
    AppColorPreset(
      key: 'sage_kitchen',
      light: AppColorPalette(
        primary: Color(0xFF6E8B74),
        onPrimary: Colors.white,
        secondary: Color(0xFFD7D9C8),
        onSecondary: Color(0xFF283127),
        background: Color(0xFFFBFAF6),
        surface: Color(0xFFF4F1E8),
        onSurface: Color(0xFF243127),
        outline: Color(0xFFD0D4C7),
        appBarBackground: Color(0xFFD7D9C8),
        appBarForeground: Color(0xFF283127),
        primaryContainer: Color(0xFFDCE7DE),
        onPrimaryContainer: Color(0xFF223126),
        secondaryContainer: Color(0xFFECEBDD),
        onSecondaryContainer: Color(0xFF32382E),
        card: Colors.white,
      ),
      dark: AppColorPalette(
        primary: Color(0xFF8FA996),
        onPrimary: Color(0xFF152119),
        secondary: Color(0xFF556A59),
        onSecondary: Color(0xFFEAF0E8),
        background: Color(0xFF171D18),
        surface: Color(0xFF1F2721),
        onSurface: Color(0xFFEEF3ED),
        outline: Color(0xFF4A5A4D),
        appBarBackground: Color(0xFF263128),
        appBarForeground: Color(0xFFEEF3ED),
        primaryContainer: Color(0xFF314136),
        onPrimaryContainer: Color(0xFFDDE9E0),
        secondaryContainer: Color(0xFF344238),
        onSecondaryContainer: Color(0xFFE7EEE7),
        card: Color(0xFF1F2721),
      ),
    ),
    AppColorPreset(
      key: 'terracotta',
      light: AppColorPalette(
        primary: Color(0xFFC96F4A),
        onPrimary: Colors.white,
        secondary: Color(0xFFF0CCB8),
        onSecondary: Color(0xFF3A271F),
        background: Color(0xFFFFF9F5),
        surface: Color(0xFFFFF3EC),
        onSurface: Color(0xFF35241D),
        outline: Color(0xFFE5CFC2),
        appBarBackground: Color(0xFFF0CCB8),
        appBarForeground: Color(0xFF3A271F),
        primaryContainer: Color(0xFFF1D3C3),
        onPrimaryContainer: Color(0xFF532C1B),
        secondaryContainer: Color(0xFFF8E8DE),
        onSecondaryContainer: Color(0xFF463128),
        card: Colors.white,
      ),
      dark: AppColorPalette(
        primary: Color(0xFFE08A65),
        onPrimary: Color(0xFF2A150D),
        secondary: Color(0xFF886251),
        onSecondary: Color(0xFFFFEFE8),
        background: Color(0xFF1D1411),
        surface: Color(0xFF2B1D18),
        onSurface: Color(0xFFFAEEE8),
        outline: Color(0xFF624A3F),
        appBarBackground: Color(0xFF38251F),
        appBarForeground: Color(0xFFFAEEE8),
        primaryContainer: Color(0xFF6B3B28),
        onPrimaryContainer: Color(0xFFFFDDCF),
        secondaryContainer: Color(0xFF4F3930),
        onSecondaryContainer: Color(0xFFF9ECE6),
        card: Color(0xFF2B1D18),
      ),
    ),
    AppColorPreset(
      key: 'charcoal_mint',
      light: AppColorPalette(
        primary: Color(0xFF3AA38F),
        onPrimary: Colors.white,
        secondary: Color(0xFFCFE8E2),
        onSecondary: Color(0xFF1F302D),
        background: Color(0xFFFCFDFC),
        surface: Color(0xFFF3F7F6),
        onSurface: Color(0xFF1F2A28),
        outline: Color(0xFFD0DDDA),
        appBarBackground: Color(0xFFCFE8E2),
        appBarForeground: Color(0xFF1F302D),
        primaryContainer: Color(0xFFD3EEE8),
        onPrimaryContainer: Color(0xFF133831),
        secondaryContainer: Color(0xFFE6F3F0),
        onSecondaryContainer: Color(0xFF29403B),
        card: Colors.white,
      ),
      dark: AppColorPalette(
        primary: Color(0xFF5FC7B3),
        onPrimary: Color(0xFF0D211D),
        secondary: Color(0xFF4F8075),
        onSecondary: Color(0xFFE9F7F3),
        background: Color(0xFF101715),
        surface: Color(0xFF18201E),
        onSurface: Color(0xFFE8F5F1),
        outline: Color(0xFF40635A),
        appBarBackground: Color(0xFF20302C),
        appBarForeground: Color(0xFFE8F5F1),
        primaryContainer: Color(0xFF1F4F46),
        onPrimaryContainer: Color(0xFFD5F3EC),
        secondaryContainer: Color(0xFF2B433E),
        onSecondaryContainer: Color(0xFFE7F4F1),
        card: Color(0xFF18201E),
      ),
    ),
    AppColorPreset(
      key: 'ocean_blue',
      light: AppColorPalette(
        primary: Color(0xFF3B82B8),
        onPrimary: Colors.white,
        secondary: Color(0xFFD4E5F2),
        onSecondary: Color(0xFF1F2F3C),
        background: Color(0xFFFAFCFE),
        surface: Color(0xFFF2F7FB),
        onSurface: Color(0xFF1D2A34),
        outline: Color(0xFFCFE0EC),
        appBarBackground: Color(0xFFD4E5F2),
        appBarForeground: Color(0xFF1F2F3C),
        primaryContainer: Color(0xFFD6E8F5),
        onPrimaryContainer: Color(0xFF17344A),
        secondaryContainer: Color(0xFFE8F1F8),
        onSecondaryContainer: Color(0xFF2A3B48),
        card: Colors.white,
      ),
      dark: AppColorPalette(
        primary: Color(0xFF68A7D4),
        onPrimary: Color(0xFF0F2130),
        secondary: Color(0xFF507A9B),
        onSecondary: Color(0xFFEAF4FB),
        background: Color(0xFF10171D),
        surface: Color(0xFF17212A),
        onSurface: Color(0xFFEAF4FB),
        outline: Color(0xFF41586A),
        appBarBackground: Color(0xFF1E2C37),
        appBarForeground: Color(0xFFEAF4FB),
        primaryContainer: Color(0xFF244660),
        onPrimaryContainer: Color(0xFFD7EBF9),
        secondaryContainer: Color(0xFF2D4455),
        onSecondaryContainer: Color(0xFFEAF4FB),
        card: Color(0xFF17212A),
      ),
    ),
  ];

  static AppColorPreset resolve(String? key) {
    for (final preset in values) {
      if (preset.key == key) return preset;
    }
    return values.first;
  }
}

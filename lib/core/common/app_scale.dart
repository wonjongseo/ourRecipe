import 'package:our_recipe/core/services/theme_service.dart';

class AppScale {
  const AppScale._();

  static double get _scale => ThemeService.textScale.value;

  static double text(double base) => base * _scale;

  static double size(double base) => base * _scale;
}

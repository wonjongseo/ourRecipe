import 'package:our_recipe/core/common/app_scale.dart';

class UiConstants {
  const UiConstants._();

  static const double formFieldHeight = 55;
  static const double formFieldRadius = 12;
  static const double formFieldFontSize = 14;
  static const double formFieldHintSize = 13;

  static double scaledFormFieldHeight() => AppScale.size(formFieldHeight);
  static double scaledFormFieldFontSize() => AppScale.text(formFieldFontSize);
  static double scaledFormFieldHintSize() => AppScale.text(formFieldHintSize);
}

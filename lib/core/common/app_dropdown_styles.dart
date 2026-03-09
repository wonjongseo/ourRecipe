import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/ui_constants.dart';

class AppDropdownStyles {
  const AppDropdownStyles._();

  static InputDecoration formFieldDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
      floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ),
      hintStyle: TextStyle(color: Colors.grey),
      fillColor: Theme.of(context).colorScheme.surface,
      border: AppInputBorders.normal(),
      enabledBorder: AppInputBorders.normal(),
      focusedBorder: AppInputBorders.focused(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      suffixIcon: suffixIcon,
    );
  }

  static ButtonStyleData dropdown2ButtonStyle({
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    return ButtonStyleData(
      height: height ?? UiConstants.formFieldHeight,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  static DropdownStyleData dropdown2MenuStyle(
    BuildContext context, {
    double? maxHeight,
    double horizontalPadding = 8,
  }) {
    return DropdownStyleData(
      maxHeight: maxHeight,
      useSafeArea: true,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
      ),
      elevation: 4,
    );
  }

  static MenuItemStyleData dropdown2ItemStyle() {
    return const MenuItemStyleData(height: UiConstants.formFieldHeight);
  }
}

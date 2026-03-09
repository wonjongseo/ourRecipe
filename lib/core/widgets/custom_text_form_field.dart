import 'package:flutter/material.dart';

import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/ui_constants.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.label,
    this.controller,
    this.maxLine = 1,
    this.hintText,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.borderRadius = UiConstants.formFieldRadius,
    this.prefixIcon,
    this.onFieldSubmitted,
  });

  final bool readOnly;
  final String? label;
  final String? hintText;
  final String? suffixText;
  final int? maxLine;
  final Widget? prefixIcon;
  final double borderRadius;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  get formFieldFontSize => null;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (maxLine ?? 1) > 1;
    final resolvedKeyboardType =
        isMultiline && keyboardType == TextInputType.text
            ? TextInputType.multiline
            : keyboardType;

    final field = TextFormField(
      style: TextStyle(fontSize: formFieldFontSize),
      maxLines: maxLine,
      readOnly: readOnly,
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        label: label != null ? Text(label!) : null,
        hintText: hintText,
        suffix:
            suffixText == null
                ? null
                : Text(
                  suffixText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
        prefixIcon: prefixIcon,
        // contentPadding:
        //     isMultiline ? null : EdgeInsets.symmetric(horizontal: 12),
        border: AppInputBorders.normal(radius: borderRadius),
        enabledBorder: AppInputBorders.normal(radius: borderRadius),
        focusedBorder: AppInputBorders.focused(radius: borderRadius),
      ),
    );

    if (isMultiline) return field;
    return SizedBox(height: UiConstants.formFieldHeight, child: field);
  }
}

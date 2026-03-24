import 'package:flutter/material.dart';

import 'package:our_recipe/core/common/app_scale.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/ui_constants.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.label,
    this.labelStyle,
    this.controller,
    this.maxLine = 1,
    this.hintText,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.autoFocus = false,
    this.borderRadius = UiConstants.formFieldRadius,
    this.onFieldSubmitted,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.height,
    this.onTap,
  });

  final bool readOnly;
  final bool autoFocus;
  final String? label;
  final TextStyle? labelStyle;
  final String? hintText;
  final String? suffixText;
  final Widget? suffixIcon;
  final int? maxLine;
  final Widget? prefixIcon;
  final double? height;
  final double borderRadius;
  final TextStyle? hintStyle;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (maxLine ?? 1) > 1;
    final resolvedKeyboardType =
        isMultiline && keyboardType == TextInputType.text
            ? TextInputType.multiline
            : keyboardType;

    final field = TextFormField(
      style: TextStyle(fontSize: UiConstants.scaledFormFieldFontSize()),
      maxLines: maxLine,
      readOnly: readOnly,
      onTap: onTap,
      controller: controller,
      keyboardType: resolvedKeyboardType,
      autofocus: autoFocus,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,

      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        label: label != null ? Text(label!) : null,

        labelStyle:
            labelStyle ??
            TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        hintText: hintText,
        hintStyle:
            hintStyle ??
            TextStyle(
              color: Colors.grey,
              fontSize: UiConstants.scaledFormFieldHintSize(),
            ),
        suffix:
            suffixText == null
                ? null
                : Text(
                  suffixText!,
                  style: TextStyle(
                    fontSize: UiConstants.scaledFormFieldHintSize(),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        contentPadding:
            height == null ? null : EdgeInsets.symmetric(horizontal: 12),
        border: AppInputBorders.normal(radius: borderRadius),
        enabledBorder: AppInputBorders.normal(radius: borderRadius),
        focusedBorder: AppInputBorders.focused(radius: borderRadius),
      ),
    );

    if (isMultiline) return field;
    return SizedBox(
      height: height ?? AppScale.size(height ?? UiConstants.formFieldHeight),
      child: field,
    );
  }
}

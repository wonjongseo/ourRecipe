import 'package:flutter/material.dart';

import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/ui_constants.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.label,
    this.controller,
    this.maxLine = 1,
    this.hintText,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.borderRadius = 8,
    this.prefixIcon,
  });

  final bool readOnly;
  final String label;
  final String? hintText;
  final String? suffixText;
  final int? maxLine;
  final Widget? prefixIcon;
  final double borderRadius;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  @override
  Widget build(BuildContext context) {
    final isMultiline = (maxLine ?? 1) > 1;
    final resolvedKeyboardType =
        isMultiline && keyboardType == TextInputType.text
            ? TextInputType.multiline
            : keyboardType;

    final field = TextFormField(
      style: TextStyle(fontSize: 12),
      maxLines: maxLine,
      readOnly: readOnly,
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textInputAction: textInputAction,

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        label: Text(label),
        hintText: hintText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        contentPadding:
            isMultiline ? null : EdgeInsets.symmetric(horizontal: 12),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(),
      ),
    );

    if (isMultiline) return field;
    return SizedBox(height: UiConstants.formFieldHeight, child: field);
  }

  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadius),
    borderSide: BorderSide(color: AppColors.borderColor),
  );
}

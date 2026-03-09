import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.suffixText,
    this.prefixIcon,
    this.onChanged,
  });

  final String? hintText;
  final String? suffixText;
  final Widget? prefixIcon;
  final TextEditingController? controller;

  final Function(String?)? onChanged;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 1,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: AppStrings.search.tr,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        border: AppInputBorders.normal(),
        enabledBorder: AppInputBorders.normal(),
        focusedBorder: AppInputBorders.focused(),
      ),
    );
  }
}

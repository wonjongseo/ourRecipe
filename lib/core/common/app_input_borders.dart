import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/ui_constants.dart';

class AppInputBorders {
  const AppInputBorders._();

  static OutlineInputBorder normal({double? radius}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        radius ?? UiConstants.formFieldRadius,
      ),
      borderSide: BorderSide(color: AppColors.borderColor),
    );
  }

  static OutlineInputBorder focused({double? radius}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        radius ?? UiConstants.formFieldRadius,
      ),
      borderSide: BorderSide(color: AppColors.primaryColor, width: 1.2),
    );
  }
}

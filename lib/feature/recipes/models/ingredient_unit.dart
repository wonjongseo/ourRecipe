import 'package:get/get_utils/get_utils.dart';
import 'package:our_recipe/core/common/app_strings.dart';

enum IngredientUnit {
  /// g
  gram,

  /// kg
  ml,

  /// tsp
  spoon,

  /// cup
  cup,

  /// 개수
  count,

  /// 한 꼬집
  pinch,
}

extension IngredientUnitE on IngredientUnit {
  String get displayName {
    switch (this) {
      case IngredientUnit.gram:
        return AppStrings.gram.tr;
      case IngredientUnit.ml:
        return AppStrings.ml.tr;
      case IngredientUnit.spoon:
        return AppStrings.spoon.tr;
      case IngredientUnit.cup:
        return AppStrings.cup.tr;
      case IngredientUnit.count:
        return AppStrings.count.tr;
      case IngredientUnit.pinch:
        return AppStrings.pinch.tr;
    }
  }
}

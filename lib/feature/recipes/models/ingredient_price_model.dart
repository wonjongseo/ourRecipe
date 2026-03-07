import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';

class IngredientPriceModel {
  /// `price/productAmount` 기준 단위.
  final IngredientUnit unit;

  /// 기준 구매 가격(원가).
  final double? price;

  /// `price`에 대응되는 기준 수량(예: 1000g에 3000원 -> productAmount=1000, price=3000).
  final double? productAmount;

  IngredientPriceModel({
    required this.unit,
    this.price,
    this.productAmount,
  });
}

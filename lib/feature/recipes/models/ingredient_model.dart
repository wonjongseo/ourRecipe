import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';

/// 레시피에 포함된 재료 모델.
class IngredientModel {
  /// 재료 고유 ID.
  final String id;

  /// 재료명.
  final String name;

  /// 수량 값.
  final double amount;

  /// 수량 단위.
  final IngredientUnit unit;

  /// 재료 추가 메모(예: 다진 것, 실온).
  final String memo;

  /// 기준 구매 가격(원가).
  final double? price;

  /// `price`에 대응되는 기준 구매 수량.
  final double? productAmount;

  /// `price/productAmount`의 기준 단위. 없으면 `unit`과 동일하게 처리.
  final IngredientUnit? productUnit;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.memo = '',
    this.price,
    this.productAmount,
    this.productUnit,
  });

  IngredientModel copyWith({
    String? id,
    String? name,
    double? amount,
    IngredientUnit? unit,
    String? memo,
    double? price,
    double? productAmount,
    IngredientUnit? productUnit,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      memo: memo ?? this.memo,
      price: price ?? this.price,
      productAmount: productAmount ?? this.productAmount,
      productUnit: productUnit ?? this.productUnit,
    );
  }

  /// 현재 레시피에서 이 재료에 사용된 추정 원가.
  /// 단위가 다르면 계산하지 않는다.
  double? get usedCost {
    final itemPrice = price;
    final baseAmount = productAmount;
    if (itemPrice == null || baseAmount == null || baseAmount <= 0) {
      return null;
    }

    final baseUnit = productUnit ?? unit;
    if (baseUnit != unit) return null;

    return (itemPrice / baseAmount) * amount;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit.name,
      'memo': memo,
      'price': price,
      'productAmount': productAmount,
      'productUnit': productUnit?.name,
    };
  }

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: _ingredientUnitFromName(
        (json['unit'] as String?) ?? IngredientUnit.count.name,
      ),
      memo: (json['memo'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble(),
      productAmount: (json['productAmount'] as num?)?.toDouble(),
      productUnit:
          (json['productUnit'] as String?) == null
              ? null
              : _ingredientUnitFromName(json['productUnit'] as String),
    );
  }
}

IngredientUnit _ingredientUnitFromName(String name) {
  for (final unit in IngredientUnit.values) {
    if (unit.name == name) {
      return unit;
    }
  }
  return IngredientUnit.count;
}

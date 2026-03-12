class IngredientProductModel {
  final String id;
  final bool isDefault;
  final String name;
  final String category;
  final String manufacturer;
  final double price;
  final double baseGram;
  final double? kcal;
  final double? water;
  final double? protein;
  final double? fat;
  final double? carbohydrate;
  final double? fiber;
  final double? ash;
  final double? sodium;

  const IngredientProductModel({
    required this.id,
    this.isDefault = false,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.price,
    required this.baseGram,
    this.kcal,
    this.water,
    this.protein,
    this.fat,
    this.carbohydrate,
    this.fiber,
    this.ash,
    this.sodium,
  });

  IngredientProductModel copyWith({
    String? id,
    bool? isDefault,
    String? name,
    String? category,
    String? manufacturer,
    double? price,
    double? baseGram,
    double? kcal,
    double? water,
    double? protein,
    double? fat,
    double? carbohydrate,
    double? fiber,
    double? ash,
    double? sodium,
  }) {
    return IngredientProductModel(
      id: id ?? this.id,
      isDefault: isDefault ?? this.isDefault,
      name: name ?? this.name,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      price: price ?? this.price,
      baseGram: baseGram ?? this.baseGram,
      kcal: kcal ?? this.kcal,
      water: water ?? this.water,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbohydrate: carbohydrate ?? this.carbohydrate,
      fiber: fiber ?? this.fiber,
      ash: ash ?? this.ash,
      sodium: sodium ?? this.sodium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isDefault': isDefault,
      'name': name,
      'category': category,
      'manufacturer': manufacturer,
      'price': price,
      'baseGram': baseGram,
      'kcal': kcal,
      'water': water,
      'protein': protein,
      'fat': fat,
      'carbohydrate': carbohydrate,
      'fiber': fiber,
      'ash': ash,
      'sodium': sodium,
    };
  }

  factory IngredientProductModel.fromJson(Map<String, dynamic> json) {
    return IngredientProductModel(
      id: json['id'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      name: (json['name'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      manufacturer: (json['manufacturer'] as String? ?? '').trim(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      baseGram: (json['baseGram'] as num?)?.toDouble() ?? 0,
      kcal: (json['kcal'] as num?)?.toDouble(),
      water: (json['water'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      carbohydrate: (json['carbohydrate'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      ash: (json['ash'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'IngredientProductModel(id: $id, isDefault: $isDefault, name: $name, category: $category, manufacturer: $manufacturer, price: $price, baseGram: $baseGram, kcal: $kcal, water: $water, protein: $protein, fat: $fat, carbohydrate: $carbohydrate, fiber: $fiber, ash: $ash, sodium: $sodium)';
  }
}

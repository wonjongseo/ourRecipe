class IngredientCategoryItem {
  final String id;
  final String ja;
  final String ko;
  final String en;

  const IngredientCategoryItem({
    required this.id,
    required this.ja,
    required this.ko,
    required this.en,
  });

  String displayName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return ko;
      case 'en':
        return en;
      default:
        return ja;
    }
  }
}

class IngredientCategoryCatalog {
  const IngredientCategoryCatalog._();

  static const List<IngredientCategoryItem> defaults = [
    IngredientCategoryItem(id: 'grain', ja: '穀類', ko: '곡류', en: 'Grains'),
    IngredientCategoryItem(
      id: 'potato_starch',
      ja: 'いも及びでん粉類',
      ko: '감자 및 전분류',
      en: 'Potatoes and Starches',
    ),
    IngredientCategoryItem(
      id: 'sugar_sweetener',
      ja: '砂糖及び甘味類',
      ko: '설탕 및 감미류',
      en: 'Sugars and Sweeteners',
    ),
    IngredientCategoryItem(id: 'beans', ja: '豆類', ko: '두류', en: 'Legumes'),
    IngredientCategoryItem(id: 'nuts', ja: '種実類', ko: '종실류', en: 'Nuts and Seeds'),
    IngredientCategoryItem(id: 'vegetables', ja: '野菜類', ko: '채소류', en: 'Vegetables'),
    IngredientCategoryItem(id: 'fruits', ja: '果実類', ko: '과일류', en: 'Fruits'),
    IngredientCategoryItem(id: 'mushrooms', ja: 'きのこ類', ko: '버섯류', en: 'Mushrooms'),
    IngredientCategoryItem(id: 'seaweeds', ja: '藻類', ko: '해조류', en: 'Seaweeds'),
    IngredientCategoryItem(id: 'seafood', ja: '魚介類', ko: '어패류', en: 'Seafood'),
    IngredientCategoryItem(id: 'meat', ja: '肉類', ko: '육류', en: 'Meat'),
    IngredientCategoryItem(id: 'eggs', ja: '卵類', ko: '난류', en: 'Eggs'),
    IngredientCategoryItem(id: 'dairy', ja: '乳類', ko: '유류', en: 'Dairy'),
    IngredientCategoryItem(id: 'fats_oils', ja: '油脂類', ko: '유지류', en: 'Fats and Oils'),
    IngredientCategoryItem(id: 'sweets', ja: '菓子類', ko: '과자류', en: 'Confectionery'),
    IngredientCategoryItem(
      id: 'beverages',
      ja: 'し好飲料類',
      ko: '기호음료류',
      en: 'Beverages',
    ),
    IngredientCategoryItem(
      id: 'seasoning_spice',
      ja: '調味料及び香辛料類',
      ko: '조미료 및 향신료류',
      en: 'Seasonings and Spices',
    ),
    IngredientCategoryItem(
      id: 'prepared_food',
      ja: '調理済み流通食品類',
      ko: '조리식품류',
      en: 'Prepared Foods',
    ),
  ];

  static List<String> get defaultIds => defaults.map((e) => e.id).toList();

  static bool isDefaultId(String value) {
    return defaults.any((item) => item.id == value);
  }

  static String normalizeDefaultId(String value) {
    final key = value.trim();
    if (key.isEmpty) return key;
    for (final item in defaults) {
      if (item.id == key) return item.id;
      if (item.ja == key) return item.id;
      if (item.ko == key) return item.id;
      if (item.en.toLowerCase() == key.toLowerCase()) return item.id;
    }
    return key;
  }

  static String displayName(String value, String languageCode) {
    final key = value.trim();
    for (final item in defaults) {
      if (item.id == key ||
          item.ja == key ||
          item.ko == key ||
          item.en.toLowerCase() == key.toLowerCase()) {
        return item.displayName(languageCode);
      }
    }
    return value;
  }
}

import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';

class TestDataService {
  TestDataService({
    RecipeRepository? recipeRepository,
    RecipeCategoryRepository? categoryRepository,
    IngredientProductRepository? ingredientProductRepository,
  }) : _recipeRepository = recipeRepository ?? RecipeRepository(),
       _categoryRepository = categoryRepository ?? RecipeCategoryRepository(),
       _ingredientProductRepository =
           ingredientProductRepository ?? IngredientProductRepository();

  final RecipeRepository _recipeRepository;
  final RecipeCategoryRepository _categoryRepository;
  final IngredientProductRepository _ingredientProductRepository;

  Future<void> seedSampleRecipes() async {
    switch (Get.locale?.languageCode ?? 'ja') {
      case 'ko':
        await _seedSampleRecipesKr();
        break;
      case 'en':
        await _seedSampleRecipesEn();
        break;
      default:
        await _seedSampleRecipesJp();
        break;
    }
  }

  Future<void> _seedSampleRecipesKr() async {
    await _seedRecipes(
      categories: const ['치킨', '찌개', '볶음밥', '탕/조림'],
      products: [
        ..._sharedProducts,
        ..._koreanProducts,
      ],
      buildRecipes: _buildKoreanRecipes,
    );
  }

  Future<void> _seedSampleRecipesJp() async {
    await _seedRecipes(
      categories: const ['麺料理', 'ご飯もの', '鉄板料理', '丼もの'],
      products: [
        ..._localizedJapaneseProducts,
      ],
      buildRecipes: _buildJapaneseRecipes,
    );
  }

  Future<void> _seedSampleRecipesEn() async {
    await _seedRecipes(
      categories: const ['Burgers', 'Pasta', 'Chicken', 'Brunch'],
      products: [
        ..._localizedAmericanProducts,
      ],
      buildRecipes: _buildAmericanRecipes,
    );
  }

  Future<void> _seedRecipes({
    required List<String> categories,
    required List<IngredientProductModel> products,
    required List<RecipeModel> Function(Map<String, IngredientProductModel>)
    buildRecipes,
  }) async {
    final existingCategories = await _categoryRepository.fetchCategories();
    final mergedCategories = {...existingCategories, ...categories}.toList()
      ..sort();
    await _categoryRepository.saveCategories(mergedCategories);

    for (final product in products) {
      await _ingredientProductRepository.saveProduct(product);
    }

    final productById = {for (final item in products) item.id: item};
    final recipes = buildRecipes(productById);
    for (final recipe in recipes) {
      await _recipeRepository.saveRecipe(recipe);
    }
  }

  List<RecipeModel> _buildKoreanRecipes(
    Map<String, IngredientProductModel> products,
  ) {
    return [
      _recipe(
        id: 'sample_recipe_old_tongdak',
        name: '옛날통닭',
        category: '치킨',
        description: '시장 스타일의 바삭한 통닭 테스트 레시피',
        ingredients: [
          _ingredient('sample_recipe_old_tongdak', products, 'sample_product_whole_chicken', 1200),
          _ingredient('sample_recipe_old_tongdak', products, 'sample_product_frying_mix', 180),
          _ingredient(
            'sample_recipe_old_tongdak',
            products,
            'sample_product_cooking_oil',
            80,
            unit: IngredientUnit.ml,
          ),
          _ingredient('sample_recipe_old_tongdak', products, 'sample_product_garlic', 20),
        ],
        steps: [
          _step('sample_recipe_old_tongdak', 1, '닭은 물기를 제거한 뒤 마늘을 곁들여 10분 정도 둡니다.'),
          _step('sample_recipe_old_tongdak', 2, '튀김가루를 고르게 묻히고 식용유를 넉넉히 달군 뒤 바삭하게 튀깁니다.'),
          _step('sample_recipe_old_tongdak', 3, '한 번 더 짧게 튀겨 바삭함을 살린 뒤 먹기 좋게 잘라 냅니다.'),
        ],
        createdAt: DateTime(2024, 1, 10),
      ),
      _recipe(
        id: 'sample_recipe_doenjang_jjigae',
        name: '된장찌개',
        category: '찌개',
        description: '두부와 애호박, 감자가 들어간 기본 된장찌개',
        ingredients: [
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_doenjang', 80),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_tofu', 300),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_potato', 180),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_onion', 120),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_zucchini', 120),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_green_chili', 20),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_green_onion', 40),
          _ingredient('sample_recipe_doenjang_jjigae', products, 'sample_product_garlic', 15),
        ],
        steps: [
          _step('sample_recipe_doenjang_jjigae', 1, '냄비에 물과 감자, 양파, 애호박, 마늘을 넣고 끓입니다.'),
          _step('sample_recipe_doenjang_jjigae', 2, '된장을 풀어 넣고 감자가 반쯤 익을 때까지 끓입니다.'),
          _step('sample_recipe_doenjang_jjigae', 3, '두부와 청양고추를 넣고 5분 더 끓인 뒤 대파를 넣어 마무리합니다.'),
        ],
        createdAt: DateTime(2024, 1, 11),
      ),
      _recipe(
        id: 'sample_recipe_kimchi_fried_rice',
        name: '김치볶음밥',
        category: '볶음밥',
        description: '잘 익은 김치와 밥으로 만드는 간단한 볶음밥',
        ingredients: [
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_cooked_rice', 600),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_kimchi', 180),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_pork_belly', 120),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_onion', 80),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_green_onion', 30),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_gochujang', 35),
          _ingredient(
            'sample_recipe_kimchi_fried_rice',
            products,
            'sample_product_cooking_oil',
            15,
            unit: IngredientUnit.ml,
          ),
          _ingredient('sample_recipe_kimchi_fried_rice', products, 'sample_product_egg', 55),
        ],
        steps: [
          _step('sample_recipe_kimchi_fried_rice', 1, '팬에 식용유를 두르고 돼지고기와 양파를 먼저 볶습니다.'),
          _step('sample_recipe_kimchi_fried_rice', 2, '김치와 고추장을 넣어 볶다가 밥을 넣고 고르게 섞습니다.'),
          _step('sample_recipe_kimchi_fried_rice', 3, '대파를 넣고 마무리한 뒤 계란을 곁들입니다.'),
        ],
        createdAt: DateTime(2024, 1, 12),
      ),
      _recipe(
        id: 'sample_recipe_dakdoritang',
        name: '닭도리탕',
        category: '탕/조림',
        description: '감자와 채소를 넣고 칼칼하게 끓인 닭도리탕',
        ingredients: [
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_whole_chicken', 1000),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_potato', 250),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_carrot', 120),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_onion', 150),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_green_onion', 60),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_garlic', 25),
          _ingredient(
            'sample_recipe_dakdoritang',
            products,
            'sample_product_soy_sauce',
            60,
            unit: IngredientUnit.ml,
          ),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_gochujang', 45),
          _ingredient('sample_recipe_dakdoritang', products, 'sample_product_sugar', 15),
        ],
        steps: [
          _step('sample_recipe_dakdoritang', 1, '닭과 감자, 당근, 양파를 냄비에 담고 물을 부어 끓입니다.'),
          _step('sample_recipe_dakdoritang', 2, '간장, 고추장, 설탕, 마늘을 섞어 양념을 만든 뒤 넣습니다.'),
          _step('sample_recipe_dakdoritang', 3, '중약불에서 졸이듯 끓이고 마지막에 대파를 넣어 마무리합니다.'),
        ],
        createdAt: DateTime(2024, 1, 13),
      ),
    ];
  }

  List<RecipeModel> _buildJapaneseRecipes(
    Map<String, IngredientProductModel> products,
  ) {
    return [
      _recipe(
        id: 'sample_recipe_shoyu_ramen',
        name: '醤油ラーメン',
        category: '麺料理',
        description: '醤油ベースのスープで作る定番ラーメン',
        ingredients: [
          _ingredient('sample_recipe_shoyu_ramen', products, 'sample_product_ramen_noodle', 220),
          _ingredient('sample_recipe_shoyu_ramen', products, 'sample_product_pork_belly', 120),
          _ingredient('sample_recipe_shoyu_ramen', products, 'sample_product_egg', 55),
          _ingredient('sample_recipe_shoyu_ramen', products, 'sample_product_green_onion', 20),
          _ingredient(
            'sample_recipe_shoyu_ramen',
            products,
            'sample_product_soy_sauce',
            35,
            unit: IngredientUnit.ml,
          ),
        ],
        steps: [
          _step('sample_recipe_shoyu_ramen', 1, '麺をゆでて湯を切り、別にしておきます。'),
          _step('sample_recipe_shoyu_ramen', 2, '醤油と水で簡単なスープを作り、豚肉を温めてのせます。'),
          _step('sample_recipe_shoyu_ramen', 3, '麺、スープ、卵、ねぎを盛り付けて仕上げます。'),
        ],
        createdAt: DateTime(2024, 2, 1),
      ),
      _recipe(
        id: 'sample_recipe_curry_rice',
        name: 'カレーライス',
        category: 'ご飯もの',
        description: 'カレールーとご飯で作る定番のカレーライス',
        ingredients: [
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_cooked_rice', 500),
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_curry_roux', 100),
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_potato', 180),
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_carrot', 100),
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_onion', 120),
          _ingredient('sample_recipe_curry_rice', products, 'sample_product_beef_patty', 150),
        ],
        steps: [
          _step('sample_recipe_curry_rice', 1, '玉ねぎ、じゃがいも、にんじん、肉を先に炒めます。'),
          _step('sample_recipe_curry_rice', 2, '水を加えて具材がやわらかくなるまで煮て、カレールーを溶かします。'),
          _step('sample_recipe_curry_rice', 3, 'とろみがついたらご飯と一緒に盛り付けます。'),
        ],
        createdAt: DateTime(2024, 2, 2),
      ),
      _recipe(
        id: 'sample_recipe_okonomiyaki',
        name: 'お好み焼き',
        category: '鉄板料理',
        description: 'キャベツ入りの生地を焼き上げる定番のお好み焼き',
        ingredients: [
          _ingredient('sample_recipe_okonomiyaki', products, 'sample_product_cabbage', 180),
          _ingredient('sample_recipe_okonomiyaki', products, 'sample_product_flour', 120),
          _ingredient('sample_recipe_okonomiyaki', products, 'sample_product_egg', 110),
          _ingredient('sample_recipe_okonomiyaki', products, 'sample_product_pork_belly', 80),
          _ingredient(
            'sample_recipe_okonomiyaki',
            products,
            'sample_product_cooking_oil',
            15,
            unit: IngredientUnit.ml,
          ),
        ],
        steps: [
          _step('sample_recipe_okonomiyaki', 1, 'キャベツを細かく切り、小麦粉と卵を混ぜて生地を作ります。'),
          _step('sample_recipe_okonomiyaki', 2, 'フライパンに油をひき、生地と豚肉をのせて両面を焼きます。'),
          _step('sample_recipe_okonomiyaki', 3, 'こんがり焼けたら皿に盛って完成です。'),
        ],
        createdAt: DateTime(2024, 2, 3),
      ),
      _recipe(
        id: 'sample_recipe_oyakodon',
        name: '親子丼',
        category: '丼もの',
        description: '鶏肉と卵をのせた定番の丼もの',
        ingredients: [
          _ingredient('sample_recipe_oyakodon', products, 'sample_product_cooked_rice', 500),
          _ingredient('sample_recipe_oyakodon', products, 'sample_product_whole_chicken', 250),
          _ingredient('sample_recipe_oyakodon', products, 'sample_product_egg', 110),
          _ingredient('sample_recipe_oyakodon', products, 'sample_product_onion', 100),
          _ingredient(
            'sample_recipe_oyakodon',
            products,
            'sample_product_soy_sauce',
            25,
            unit: IngredientUnit.ml,
          ),
        ],
        steps: [
          _step('sample_recipe_oyakodon', 1, '玉ねぎと鶏肉を醤油と少量の水で煮ます。'),
          _step('sample_recipe_oyakodon', 2, '溶き卵を流し入れ、半熟状に火を通します。'),
          _step('sample_recipe_oyakodon', 3, 'ご飯の上にのせて丼に仕上げます。'),
        ],
        createdAt: DateTime(2024, 2, 4),
      ),
    ];
  }

  List<RecipeModel> _buildAmericanRecipes(
    Map<String, IngredientProductModel> products,
  ) {
    return [
      _recipe(
        id: 'sample_recipe_cheeseburger',
        name: 'Cheeseburger',
        category: 'Burgers',
        description: 'A classic burger made with a beef patty and cheddar cheese.',
        ingredients: [
          _ingredient('sample_recipe_cheeseburger', products, 'sample_product_burger_bun', 150),
          _ingredient('sample_recipe_cheeseburger', products, 'sample_product_beef_patty', 150),
          _ingredient('sample_recipe_cheeseburger', products, 'sample_product_cheddar_cheese', 40),
          _ingredient('sample_recipe_cheeseburger', products, 'sample_product_onion', 30),
          _ingredient('sample_recipe_cheeseburger', products, 'sample_product_cabbage', 20),
        ],
        steps: [
          _step('sample_recipe_cheeseburger', 1, 'Cook the patty in a pan and melt the cheese on top at the end.'),
          _step('sample_recipe_cheeseburger', 2, 'Lightly toast the buns and prepare the onion and cabbage.'),
          _step('sample_recipe_cheeseburger', 3, 'Assemble the patty, cheese, and vegetables between the buns.'),
        ],
        createdAt: DateTime(2024, 3, 1),
      ),
      _recipe(
        id: 'sample_recipe_mac_and_cheese',
        name: 'Mac and Cheese',
        category: 'Pasta',
        description: 'A rich and creamy pasta made with macaroni and cheddar cheese.',
        ingredients: [
          _ingredient('sample_recipe_mac_and_cheese', products, 'sample_product_macaroni', 200),
          _ingredient('sample_recipe_mac_and_cheese', products, 'sample_product_cheddar_cheese', 120),
          _ingredient('sample_recipe_mac_and_cheese', products, 'sample_product_milk', 250, unit: IngredientUnit.ml),
          _ingredient('sample_recipe_mac_and_cheese', products, 'sample_product_butter', 20),
          _ingredient('sample_recipe_mac_and_cheese', products, 'sample_product_flour', 20),
        ],
        steps: [
          _step('sample_recipe_mac_and_cheese', 1, 'Boil the macaroni until tender and set it aside.'),
          _step('sample_recipe_mac_and_cheese', 2, 'Cook the butter and flour, then add milk to make a sauce.'),
          _step('sample_recipe_mac_and_cheese', 3, 'Melt in the cheese and stir in the cooked macaroni.'),
        ],
        createdAt: DateTime(2024, 3, 2),
      ),
      _recipe(
        id: 'sample_recipe_buffalo_wings',
        name: 'Buffalo Wings',
        category: 'Chicken',
        description: 'American-style chicken wings coated in a spicy hot sauce.',
        ingredients: [
          _ingredient('sample_recipe_buffalo_wings', products, 'sample_product_whole_chicken', 800),
          _ingredient('sample_recipe_buffalo_wings', products, 'sample_product_hot_sauce', 70, unit: IngredientUnit.ml),
          _ingredient('sample_recipe_buffalo_wings', products, 'sample_product_butter', 30),
          _ingredient(
            'sample_recipe_buffalo_wings',
            products,
            'sample_product_cooking_oil',
            40,
            unit: IngredientUnit.ml,
          ),
        ],
        steps: [
          _step('sample_recipe_buffalo_wings', 1, 'Cut the chicken into wing portions and cook until golden.'),
          _step('sample_recipe_buffalo_wings', 2, 'Mix the butter and hot sauce to make the wing sauce.'),
          _step('sample_recipe_buffalo_wings', 3, 'Toss the cooked wings in the sauce and serve.'),
        ],
        createdAt: DateTime(2024, 3, 3),
      ),
      _recipe(
        id: 'sample_recipe_pancake',
        name: 'Pancakes',
        category: 'Brunch',
        description: 'Classic pancakes served with butter and maple syrup.',
        ingredients: [
          _ingredient('sample_recipe_pancake', products, 'sample_product_flour', 180),
          _ingredient('sample_recipe_pancake', products, 'sample_product_egg', 110),
          _ingredient('sample_recipe_pancake', products, 'sample_product_milk', 220, unit: IngredientUnit.ml),
          _ingredient('sample_recipe_pancake', products, 'sample_product_sugar', 25),
          _ingredient('sample_recipe_pancake', products, 'sample_product_butter', 20),
          _ingredient('sample_recipe_pancake', products, 'sample_product_maple_syrup', 40, unit: IngredientUnit.ml),
        ],
        steps: [
          _step('sample_recipe_pancake', 1, 'Mix the flour, eggs, milk, and sugar into a smooth batter.'),
          _step('sample_recipe_pancake', 2, 'Melt butter in a pan and cook the batter on both sides until golden.'),
          _step('sample_recipe_pancake', 3, 'Serve with maple syrup to finish.'),
        ],
        createdAt: DateTime(2024, 3, 4),
      ),
    ];
  }

  RecipeModel _recipe({
    required String id,
    required String name,
    required String category,
    required String description,
    required List<IngredientModel> ingredients,
    required List<CookingStepModel> steps,
    required DateTime createdAt,
  }) {
    return RecipeModel(
      id: id,
      name: name,
      category: category,
      description: description,
      servings: 2,
      ingredients: ingredients,
      steps: steps,
      totalIngredientCost: _sum(ingredients, (item) => item.usedCost ?? 0),
      totalKcal: _sum(ingredients, (item) => item.usedKcal ?? 0),
      totalWater: _sum(ingredients, (item) => item.usedWater ?? 0),
      totalProtein: _sum(ingredients, (item) => item.usedProtein ?? 0),
      totalFat: _sum(ingredients, (item) => item.usedFat ?? 0),
      totalCarbohydrate: _sum(ingredients, (item) => item.usedCarbohydrate ?? 0),
      totalFiber: _sum(ingredients, (item) => item.usedFiber ?? 0),
      totalAsh: _sum(ingredients, (item) => item.usedAsh ?? 0),
      totalSodium: _sum(ingredients, (item) => item.usedSodium ?? 0),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  CookingStepModel _step(String recipeId, int order, String instruction) {
    return CookingStepModel(
      id: '${recipeId}_step_$order',
      order: order,
      instruction: instruction,
    );
  }

  IngredientModel _ingredient(
    String recipeId,
    Map<String, IngredientProductModel> products,
    String productId,
    double amount, {
    IngredientUnit unit = IngredientUnit.gram,
    String memo = '',
  }) {
    final product = products[productId]!;
    return IngredientModel(
      id: '${recipeId}_${product.id}_${amount.toStringAsFixed(0)}_${unit.name}',
      name: product.name,
      amount: amount,
      unit: unit,
      memo: memo,
      price: product.price,
      productAmount: product.baseGram,
      productUnit: unit,
      kcal: product.kcal,
      water: product.water,
      protein: product.protein,
      fat: product.fat,
      carbohydrate: product.carbohydrate,
      fiber: product.fiber,
      ash: product.ash,
      sodium: product.sodium,
    );
  }

  double _sum(
    List<IngredientModel> items,
    double Function(IngredientModel item) selector,
  ) {
    return items.fold<double>(0, (sum, item) => sum + selector(item));
  }

  static final List<IngredientProductModel> _sharedProducts = [
    IngredientProductModel(
      id: 'sample_product_whole_chicken',
      name: '닭 한마리',
      category: '육류',
      manufacturer: '테스트 정육점',
      price: 8900,
      baseGram: 1200,
      kcal: 215,
      water: 64.9,
      protein: 18.3,
      fat: 15.1,
      carbohydrate: 0,
      fiber: 0,
      ash: 1.0,
      sodium: 82,
    ),
    IngredientProductModel(
      id: 'sample_product_cooking_oil',
      name: '식용유',
      category: '오일/소스',
      manufacturer: '테스트오일',
      price: 6000,
      baseGram: 900,
      kcal: 884,
      water: 0,
      protein: 0,
      fat: 100,
      carbohydrate: 0,
      fiber: 0,
      ash: 0,
      sodium: 0,
    ),
    IngredientProductModel(
      id: 'sample_product_garlic',
      name: '마늘',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 4000,
      baseGram: 500,
      kcal: 149,
      water: 58.6,
      protein: 6.4,
      fat: 0.5,
      carbohydrate: 33.1,
      fiber: 2.1,
      ash: 1.5,
      sodium: 17,
    ),
    IngredientProductModel(
      id: 'sample_product_potato',
      name: '감자',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 4500,
      baseGram: 1000,
      kcal: 77,
      water: 79.3,
      protein: 2.0,
      fat: 0.1,
      carbohydrate: 17.5,
      fiber: 2.2,
      ash: 1.0,
      sodium: 6,
    ),
    IngredientProductModel(
      id: 'sample_product_onion',
      name: '양파',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 3000,
      baseGram: 1000,
      kcal: 40,
      water: 89.1,
      protein: 1.1,
      fat: 0.1,
      carbohydrate: 9.3,
      fiber: 1.7,
      ash: 0.4,
      sodium: 4,
    ),
    IngredientProductModel(
      id: 'sample_product_green_onion',
      name: '대파',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 2800,
      baseGram: 300,
      kcal: 32,
      water: 89.8,
      protein: 1.8,
      fat: 0.2,
      carbohydrate: 7.3,
      fiber: 2.6,
      ash: 0.9,
      sodium: 16,
    ),
    IngredientProductModel(
      id: 'sample_product_cooked_rice',
      name: '밥',
      category: '곡류',
      manufacturer: '테스트주방',
      price: 2500,
      baseGram: 1000,
      kcal: 130,
      water: 68.5,
      protein: 2.4,
      fat: 0.3,
      carbohydrate: 28.6,
      fiber: 0.4,
      ash: 0.2,
      sodium: 1,
    ),
    IngredientProductModel(
      id: 'sample_product_egg',
      name: '계란',
      category: '난류',
      manufacturer: '테스트팜',
      price: 4500,
      baseGram: 500,
      kcal: 143,
      water: 76.2,
      protein: 12.6,
      fat: 9.5,
      carbohydrate: 0.7,
      fiber: 0,
      ash: 1.1,
      sodium: 142,
    ),
    IngredientProductModel(
      id: 'sample_product_carrot',
      name: '당근',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 2200,
      baseGram: 1000,
      kcal: 41,
      water: 88.3,
      protein: 0.9,
      fat: 0.2,
      carbohydrate: 9.6,
      fiber: 2.8,
      ash: 1.0,
      sodium: 69,
    ),
    IngredientProductModel(
      id: 'sample_product_soy_sauce',
      name: '간장',
      category: '오일/소스',
      manufacturer: '테스트장',
      price: 3500,
      baseGram: 500,
      kcal: 53,
      water: 66,
      protein: 8.1,
      fat: 0,
      carbohydrate: 4.9,
      fiber: 0.8,
      ash: 14,
      sodium: 5493,
    ),
    IngredientProductModel(
      id: 'sample_product_sugar',
      name: '설탕',
      category: '가루/양념',
      manufacturer: '테스트슈가',
      price: 2500,
      baseGram: 1000,
      kcal: 387,
      water: 0,
      protein: 0,
      fat: 0,
      carbohydrate: 100,
      fiber: 0,
      ash: 0,
      sodium: 1,
    ),
    IngredientProductModel(
      id: 'sample_product_flour',
      name: '밀가루',
      category: '가루/양념',
      manufacturer: '테스트푸드',
      price: 2800,
      baseGram: 1000,
      kcal: 364,
      water: 11,
      protein: 10,
      fat: 1,
      carbohydrate: 76,
      fiber: 2.7,
      ash: 0.5,
      sodium: 2,
    ),
    IngredientProductModel(
      id: 'sample_product_milk',
      name: '우유',
      category: '유제품',
      manufacturer: '테스트밀크',
      price: 2600,
      baseGram: 1000,
      kcal: 61,
      water: 88,
      protein: 3.2,
      fat: 3.3,
      carbohydrate: 4.8,
      fiber: 0,
      ash: 0.7,
      sodium: 43,
    ),
    IngredientProductModel(
      id: 'sample_product_butter',
      name: '버터',
      category: '유제품',
      manufacturer: '테스트밀크',
      price: 6200,
      baseGram: 450,
      kcal: 717,
      water: 16,
      protein: 0.9,
      fat: 81,
      carbohydrate: 0.1,
      fiber: 0,
      ash: 0.1,
      sodium: 11,
    ),
  ];

  static final List<IngredientProductModel> _koreanProducts = [
    IngredientProductModel(
      id: 'sample_product_frying_mix',
      name: '튀김가루',
      category: '가루/양념',
      manufacturer: '테스트푸드',
      price: 3000,
      baseGram: 500,
      kcal: 364,
      water: 10,
      protein: 8,
      fat: 2,
      carbohydrate: 76,
      fiber: 2,
      ash: 1,
      sodium: 900,
    ),
    IngredientProductModel(
      id: 'sample_product_doenjang',
      name: '된장',
      category: '장류',
      manufacturer: '테스트장',
      price: 6500,
      baseGram: 500,
      kcal: 199,
      water: 53,
      protein: 22.2,
      fat: 6.0,
      carbohydrate: 14.1,
      fiber: 5.0,
      ash: 4.0,
      sodium: 4431,
    ),
    IngredientProductModel(
      id: 'sample_product_tofu',
      name: '두부',
      category: '두류',
      manufacturer: '테스트두부',
      price: 1500,
      baseGram: 300,
      kcal: 76,
      water: 84.6,
      protein: 8.1,
      fat: 4.8,
      carbohydrate: 1.9,
      fiber: 0.3,
      ash: 0.7,
      sodium: 7,
    ),
    IngredientProductModel(
      id: 'sample_product_zucchini',
      name: '애호박',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 1800,
      baseGram: 300,
      kcal: 17,
      water: 94.8,
      protein: 1.2,
      fat: 0.3,
      carbohydrate: 3.1,
      fiber: 1.0,
      ash: 0.5,
      sodium: 8,
    ),
    IngredientProductModel(
      id: 'sample_product_green_chili',
      name: '청양고추',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 1800,
      baseGram: 150,
      kcal: 40,
      water: 88,
      protein: 2.0,
      fat: 0.4,
      carbohydrate: 8.8,
      fiber: 1.5,
      ash: 0.8,
      sodium: 7,
    ),
    IngredientProductModel(
      id: 'sample_product_kimchi',
      name: '김치',
      category: '반찬류',
      manufacturer: '테스트김치',
      price: 8500,
      baseGram: 1000,
      kcal: 18,
      water: 91,
      protein: 1.5,
      fat: 0.6,
      carbohydrate: 2.4,
      fiber: 1.6,
      ash: 2.2,
      sodium: 781,
    ),
    IngredientProductModel(
      id: 'sample_product_pork_belly',
      name: '돼지고기',
      category: '육류',
      manufacturer: '테스트 정육점',
      price: 12000,
      baseGram: 500,
      kcal: 320,
      water: 47,
      protein: 16,
      fat: 28,
      carbohydrate: 0,
      fiber: 0,
      ash: 0.9,
      sodium: 62,
    ),
    IngredientProductModel(
      id: 'sample_product_gochujang',
      name: '고추장',
      category: '장류',
      manufacturer: '테스트장',
      price: 4500,
      baseGram: 500,
      kcal: 195,
      water: 45,
      protein: 4.9,
      fat: 1.4,
      carbohydrate: 43.4,
      fiber: 3.0,
      ash: 5.0,
      sodium: 2400,
    ),
  ];

  static final List<IngredientProductModel> _japaneseProducts = [
    IngredientProductModel(
      id: 'sample_product_ramen_noodle',
      name: '라멘 면',
      category: '면류',
      manufacturer: '테스트누들',
      price: 3200,
      baseGram: 300,
      kcal: 281,
      water: 32,
      protein: 8.2,
      fat: 1.8,
      carbohydrate: 56,
      fiber: 2.1,
      ash: 1.1,
      sodium: 150,
    ),
    IngredientProductModel(
      id: 'sample_product_curry_roux',
      name: '카레 루',
      category: '소스/장류',
      manufacturer: '테스트카레',
      price: 4800,
      baseGram: 200,
      kcal: 512,
      water: 3,
      protein: 6,
      fat: 31,
      carbohydrate: 50,
      fiber: 3,
      ash: 7,
      sodium: 2900,
    ),
    IngredientProductModel(
      id: 'sample_product_cabbage',
      name: '양배추',
      category: '채소류',
      manufacturer: '테스트마트',
      price: 3500,
      baseGram: 1000,
      kcal: 25,
      water: 92,
      protein: 1.3,
      fat: 0.1,
      carbohydrate: 5.8,
      fiber: 2.5,
      ash: 0.6,
      sodium: 18,
    ),
    IngredientProductModel(
      id: 'sample_product_beef_patty',
      name: '소고기 패티',
      category: '육류',
      manufacturer: '테스트미트',
      price: 7800,
      baseGram: 300,
      kcal: 250,
      water: 60,
      protein: 17,
      fat: 20,
      carbohydrate: 0,
      fiber: 0,
      ash: 1.1,
      sodium: 75,
    ),
  ];

  static final List<IngredientProductModel> _americanProducts = [
    IngredientProductModel(
      id: 'sample_product_burger_bun',
      name: '버거 번',
      category: '빵류',
      manufacturer: '테스트베이커리',
      price: 3800,
      baseGram: 300,
      kcal: 270,
      water: 32,
      protein: 8.5,
      fat: 4.5,
      carbohydrate: 49,
      fiber: 2.3,
      ash: 1.8,
      sodium: 430,
    ),
    IngredientProductModel(
      id: 'sample_product_cheddar_cheese',
      name: '체다치즈',
      category: '유제품',
      manufacturer: '테스트치즈',
      price: 5200,
      baseGram: 200,
      kcal: 403,
      water: 37,
      protein: 25,
      fat: 33,
      carbohydrate: 1.3,
      fiber: 0,
      ash: 3.8,
      sodium: 621,
    ),
    IngredientProductModel(
      id: 'sample_product_macaroni',
      name: '마카로니',
      category: '면류',
      manufacturer: '테스트파스타',
      price: 2900,
      baseGram: 500,
      kcal: 371,
      water: 10,
      protein: 13,
      fat: 1.5,
      carbohydrate: 75,
      fiber: 3,
      ash: 0.8,
      sodium: 6,
    ),
    IngredientProductModel(
      id: 'sample_product_hot_sauce',
      name: '핫소스',
      category: '소스/장류',
      manufacturer: '테스트소스',
      price: 4500,
      baseGram: 350,
      kcal: 35,
      water: 75,
      protein: 1.0,
      fat: 0.4,
      carbohydrate: 7.0,
      fiber: 1.2,
      ash: 2.1,
      sodium: 1800,
    ),
    IngredientProductModel(
      id: 'sample_product_maple_syrup',
      name: '메이플 시럽',
      category: '소스/장류',
      manufacturer: '테스트시럽',
      price: 8900,
      baseGram: 250,
      kcal: 260,
      water: 32,
      protein: 0,
      fat: 0,
      carbohydrate: 67,
      fiber: 0,
      ash: 0.5,
      sodium: 12,
    ),
  ];

  static final List<IngredientProductModel> _localizedJapaneseProducts =
      _localizeJapanesePrices(
        _localizeProducts([
          ..._sharedProducts,
          ..._japaneseProducts,
          _koreanProducts.firstWhere(
            (product) => product.id == 'sample_product_pork_belly',
          ),
        ], _jpProductNames, _jpCategoryNames, _jpManufacturers),
      );

  static final List<IngredientProductModel> _localizedAmericanProducts =
      _localizeAmericanPrices(
        _localizeProducts([
          ..._sharedProducts,
          ..._americanProducts,
          _japaneseProducts.firstWhere(
            (product) => product.id == 'sample_product_cabbage',
          ),
          _japaneseProducts.firstWhere(
            (product) => product.id == 'sample_product_beef_patty',
          ),
        ], _enProductNames, _enCategoryNames, _enManufacturers),
      );

  static List<IngredientProductModel> _localizeProducts(
    List<IngredientProductModel> products,
    Map<String, String> names,
    Map<String, String> categories,
    Map<String, String> manufacturers,
  ) {
    return products
        .map(
          (product) => product.copyWith(
            name: names[product.id] ?? product.name,
            category: categories[product.category] ?? product.category,
            manufacturer:
                manufacturers[product.manufacturer] ?? product.manufacturer,
          ),
        )
        .toList();
  }

  static List<IngredientProductModel> _localizeAmericanPrices(
    List<IngredientProductModel> products,
  ) {
    return products
        .map(
          (product) => product.copyWith(
            price: _enPrices[product.id] ?? product.price,
          ),
        )
        .toList();
  }

  static List<IngredientProductModel> _localizeJapanesePrices(
    List<IngredientProductModel> products,
  ) {
    return products
        .map(
          (product) => product.copyWith(
            price: _jpPrices[product.id] ?? product.price,
          ),
        )
        .toList();
  }

  static const Map<String, String> _jpProductNames = {
    'sample_product_whole_chicken': '鶏丸ごと一羽',
    'sample_product_cooking_oil': '食用油',
    'sample_product_garlic': 'にんにく',
    'sample_product_potato': 'じゃがいも',
    'sample_product_onion': '玉ねぎ',
    'sample_product_green_onion': '長ねぎ',
    'sample_product_cooked_rice': 'ご飯',
    'sample_product_egg': '卵',
    'sample_product_carrot': 'にんじん',
    'sample_product_soy_sauce': 'しょうゆ',
    'sample_product_sugar': '砂糖',
    'sample_product_flour': '小麦粉',
    'sample_product_milk': '牛乳',
    'sample_product_butter': 'バター',
    'sample_product_ramen_noodle': 'ラーメン麺',
    'sample_product_curry_roux': 'カレールー',
    'sample_product_cabbage': 'キャベツ',
    'sample_product_beef_patty': 'ビーフパティ',
  };

  static const Map<String, String> _enProductNames = {
    'sample_product_whole_chicken': 'Whole Chicken',
    'sample_product_cooking_oil': 'Cooking Oil',
    'sample_product_garlic': 'Garlic',
    'sample_product_potato': 'Potato',
    'sample_product_onion': 'Onion',
    'sample_product_green_onion': 'Green Onion',
    'sample_product_cooked_rice': 'Cooked Rice',
    'sample_product_egg': 'Egg',
    'sample_product_carrot': 'Carrot',
    'sample_product_soy_sauce': 'Soy Sauce',
    'sample_product_sugar': 'Sugar',
    'sample_product_flour': 'Flour',
    'sample_product_milk': 'Milk',
    'sample_product_butter': 'Butter',
    'sample_product_burger_bun': 'Burger Bun',
    'sample_product_cheddar_cheese': 'Cheddar Cheese',
    'sample_product_macaroni': 'Macaroni',
    'sample_product_hot_sauce': 'Hot Sauce',
    'sample_product_maple_syrup': 'Maple Syrup',
  };

  static const Map<String, String> _jpCategoryNames = {
    '육류': '肉類',
    '오일/소스': '油・ソース類',
    '채소류': '野菜類',
    '곡류': '穀類',
    '난류': '卵類',
    '가루/양념': '粉・調味料',
    '유제품': '乳製品',
    '면류': '麺類',
    '소스/장류': 'ソース・調味料',
  };

  static const Map<String, String> _enCategoryNames = {
    '육류': 'Meat',
    '오일/소스': 'Oil & Sauce',
    '채소류': 'Vegetables',
    '곡류': 'Grains',
    '난류': 'Eggs',
    '가루/양념': 'Flour & Seasoning',
    '유제품': 'Dairy',
    '빵류': 'Bread',
    '면류': 'Pasta & Noodles',
    '소스/장류': 'Sauce & Condiments',
  };

  static const Map<String, String> _jpManufacturers = {
    '테스트 정육점': 'テスト精肉店',
    '테스트오일': 'テストオイル',
    '테스트마트': 'テストマート',
    '테스트주방': 'テストキッチン',
    '테스트팜': 'テストファーム',
    '테스트장': 'テスト醸造',
    '테스트푸드': 'テストフード',
    '테스트밀크': 'テストミルク',
    '테스트누들': 'テストヌードル',
    '테스트카레': 'テストカレー',
    '테스트미트': 'テストミート',
  };

  static const Map<String, String> _enManufacturers = {
    '테스트 정육점': 'Test Butcher',
    '테스트오일': 'Test Oil',
    '테스트마트': 'Test Market',
    '테스트주방': 'Test Kitchen',
    '테스트팜': 'Test Farm',
    '테스트장': 'Test Pantry',
    '테스트푸드': 'Test Foods',
    '테스트밀크': 'Test Milk',
    '테스트베이커리': 'Test Bakery',
    '테스트치즈': 'Test Cheese',
    '테스트파스타': 'Test Pasta',
    '테스트소스': 'Test Sauce',
    '테스트시럽': 'Test Syrup',
  };

  static const Map<String, double> _jpPrices = {
    'sample_product_whole_chicken': 980,
    'sample_product_cooking_oil': 680,
    'sample_product_garlic': 260,
    'sample_product_potato': 320,
    'sample_product_onion': 220,
    'sample_product_green_onion': 198,
    'sample_product_cooked_rice': 280,
    'sample_product_egg': 320,
    'sample_product_carrot': 180,
    'sample_product_soy_sauce': 320,
    'sample_product_sugar': 210,
    'sample_product_flour': 240,
    'sample_product_milk': 240,
    'sample_product_butter': 540,
    'sample_product_ramen_noodle': 260,
    'sample_product_curry_roux': 380,
    'sample_product_cabbage': 260,
    'sample_product_beef_patty': 620,
    'sample_product_pork_belly': 680,
  };

  static const Map<String, double> _enPrices = {
    'sample_product_whole_chicken': 8.9,
    'sample_product_cooking_oil': 6.5,
    'sample_product_garlic': 2.8,
    'sample_product_potato': 3.5,
    'sample_product_onion': 2.5,
    'sample_product_green_onion': 1.9,
    'sample_product_cooked_rice': 3.0,
    'sample_product_egg': 4.2,
    'sample_product_carrot': 2.2,
    'sample_product_soy_sauce': 3.8,
    'sample_product_sugar': 2.4,
    'sample_product_flour': 2.9,
    'sample_product_milk': 2.7,
    'sample_product_butter': 5.2,
    'sample_product_burger_bun': 3.6,
    'sample_product_cheddar_cheese': 4.8,
    'sample_product_macaroni': 2.6,
    'sample_product_hot_sauce': 4.1,
    'sample_product_maple_syrup': 8.5,
    'sample_product_cabbage': 3.1,
    'sample_product_beef_patty': 6.9,
  };
}

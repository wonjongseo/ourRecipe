class RecipeModel {
  final String recipeName;
  final List<String> imagePaths;
  final List<IngredientModel> ingredients;
  final List<CookingMethod> cookingMethods;
  final DateTime createdAt;
}

enum IngredientType { gram, count }

class IngredientModel {
  final String name;
  final IngredientType type;
  final double gramOrCnt;
}

class CookingMethod {
  final String method;
  final String? imagePath;
  final Duration? cookingTime;
}

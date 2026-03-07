import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';
import 'package:our_recipe/core/common/app_strings.dart';

enum RecipeCategory { korean, western, japanese, chinese, etc }

extension RecipeCategoryE on RecipeCategory {
  String get displayName {
    switch (this) {
      case RecipeCategory.korean:
        return AppStrings.koreanCategory;
      case RecipeCategory.western:
        return AppStrings.westernCategory;
      case RecipeCategory.japanese:
        return AppStrings.japaneseCategory;
      case RecipeCategory.chinese:
        return AppStrings.chineseCategory;
      case RecipeCategory.etc:
        return AppStrings.etcCategory;
    }
  }
}

/// 레시피 원본 정보 모델.
class RecipeModel {
  /// 레시피 고유 ID.
  final String id;

  /// 레시피 제목.
  final String name;

  /// 레시피 설명(메모, 소개).
  final String description;

  /// 기준 인분 수.
  final int servings;

  /// 대표 이미지 경로(없을 수 있음).
  final String? coverImagePath;

  /// 재료 목록.
  final List<IngredientModel> ingredients;

  /// 조리 순서 목록.
  final List<CookingStepModel> steps;

  /// 레시피 카테고리.
  final RecipeCategory category;

  /// 현재 사용자 좋아요 여부.
  final bool isLiked;

  /// 저장된 총 재료비.
  final double totalIngredientCost;

  /// 최초 생성 시각.
  final DateTime createdAt;

  /// 마지막 수정 시각.
  final DateTime updatedAt;

  const RecipeModel({
    required this.id,
    required this.name,
    this.description = '',
    this.servings = 1,
    this.coverImagePath,
    this.ingredients = const [],
    this.steps = const [],
    this.category = RecipeCategory.korean,
    this.isLiked = false,
    this.totalIngredientCost = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  RecipeModel copyWith({
    String? id,
    String? name,
    String? description,
    int? servings,
    String? coverImagePath,
    List<IngredientModel>? ingredients,
    List<CookingStepModel>? steps,
    RecipeCategory? category,
    bool? isLiked,
    double? totalIngredientCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      category: category ?? this.category,
      isLiked: isLiked ?? this.isLiked,
      totalIngredientCost: totalIngredientCost ?? this.totalIngredientCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'servings': servings,
      'coverImagePath': coverImagePath,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps.map((item) => item.toJson()).toList(),
      'category': category.name,
      'isLiked': isLiked,
      'totalIngredientCost': totalIngredientCost,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      servings: (json['servings'] as int?) ?? 1,
      coverImagePath: json['coverImagePath'] as String?,
      ingredients:
          (json['ingredients'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    IngredientModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      steps:
          (json['steps'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    CookingStepModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      category: _recipeCategoryFromName(
        (json['category'] as String?) ?? RecipeCategory.korean.name,
      ),
      isLiked: (json['isLiked'] as bool?) ?? false,
      totalIngredientCost:
          (json['totalIngredientCost'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 레시피에 사용된 재료 원가 총합.
  /// 계산 불가능한 재료(`usedCost == null`)는 합산에서 제외된다.
  double get ingredientCostTotal {
    if (totalIngredientCost > 0) return totalIngredientCost;
    return ingredients.fold<double>(
      0,
      (sum, item) => sum + (item.usedCost ?? 0),
    );
  }
}

RecipeCategory _recipeCategoryFromName(String name) {
  for (final category in RecipeCategory.values) {
    if (category.name == name) return category;
  }
  return RecipeCategory.korean;
}

/// 실제 요리 수행 기록 모델.
class CookLogModel {
  /// 조리 기록 고유 ID.
  final String id;

  /// 어떤 레시피를 요리했는지 연결하는 레시피 ID.
  final String recipeId;

  /// 요리한 일시.
  final DateTime cookedAt;

  /// 평점(1~5 같은 규칙으로 앱에서 관리), 없을 수 있음.
  final int? rating;

  /// 조리 후기 메모.
  final String memo;

  /// 완성 사진 경로(없을 수 있음).
  final String? resultImagePath;

  /// 실제로 만든 인분 수(없을 수 있음).
  final int? actualServings;

  const CookLogModel({
    required this.id,
    required this.recipeId,
    required this.cookedAt,
    this.rating,
    this.memo = '',
    this.resultImagePath,
    this.actualServings,
  });

  CookLogModel copyWith({
    String? id,
    String? recipeId,
    DateTime? cookedAt,
    int? rating,
    String? memo,
    String? resultImagePath,
    int? actualServings,
  }) {
    return CookLogModel(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      cookedAt: cookedAt ?? this.cookedAt,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
      resultImagePath: resultImagePath ?? this.resultImagePath,
      actualServings: actualServings ?? this.actualServings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'cookedAt': cookedAt.toIso8601String(),
      'rating': rating,
      'memo': memo,
      'resultImagePath': resultImagePath,
      'actualServings': actualServings,
    };
  }

  factory CookLogModel.fromJson(Map<String, dynamic> json) {
    return CookLogModel(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      cookedAt: DateTime.parse(json['cookedAt'] as String),
      rating: json['rating'] as int?,
      memo: (json['memo'] as String?) ?? '',
      resultImagePath: json['resultImagePath'] as String?,
      actualServings: json['actualServings'] as int?,
    );
  }
}

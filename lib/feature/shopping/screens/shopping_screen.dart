import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/services/shared_preferences_service.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_storage_keys.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final RecipeController controller = Get.find<RecipeController>();
  final SharedPreferencesService _storage = SharedPreferencesService();
  final RxSet<String> checkedKeys = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    _loadCheckedKeys();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.35);
    final primary = Theme.of(context).colorScheme.primary;

    return Obx(() {
      final bookmarked = controller.bookmarkedRecipes;
      return Scaffold(
        bottomNavigationBar: const AdBannerBottomSheet(),
        appBar: AppBar(centerTitle: true, title: Text(AppStrings.shopping.tr)),
        body: SafeArea(
          child:
              bookmarked.isEmpty
                  ? Center(
                    child: Text(
                      AppStrings.noBookmarkedRecipes.tr,
                      style: TextStyle(color: AppColors.noRegisteredItemColor),
                    ),
                  )
                  : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...bookmarked.map(
                        (recipe) => _recipeChecklistCard(
                          context: context,
                          recipe: recipe,
                          borderColor: borderColor,
                          accent: primary,
                        ),
                      ),
                    ],
                  ),
        ),
      );
    });
  }

  Widget _recipeChecklistCard({
    required BuildContext context,
    required RecipeModel recipe,
    required Color borderColor,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              color: accent.withValues(alpha: 0.10),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 16, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${recipe.ingredients.length}${AppStrings.count.tr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (recipe.ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppStrings.noRegisteredIngredient.tr,
                style: TextStyle(color: AppColors.noRegisteredItemColor),
              ),
            )
          else
            ...List.generate(recipe.ingredients.length, (index) {
              final ingredient = recipe.ingredients[index];
              final key = _ingredientCheckKey(recipe, ingredient, index);
              return Column(
                children: [
                  Obx(
                    () => CheckboxListTile(
                      value: checkedKeys.contains(key),
                      onChanged: (_) => _toggleCheck(key),
                      controlAffinity: ListTileControlAffinity.leading,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        ingredient.name,
                        style: TextStyle(
                          decoration:
                              checkedKeys.contains(key)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color:
                              checkedKeys.contains(key)
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle:
                          ingredient.memo.isEmpty
                              ? null
                              : Text(
                                ingredient.memo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      secondary: Text(
                        '${ingredient.amount.toStringAsFixed(1)} ${ingredient.unit.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (index != recipe.ingredients.length - 1)
                    Divider(
                      height: 1,
                      color: borderColor,
                      indent: 12,
                      endIndent: 12,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _ingredientCheckKey(
    RecipeModel recipe,
    IngredientModel ingredient,
    int index,
  ) {
    return '${recipe.id}_${ingredient.id}_$index';
  }

  void _toggleCheck(String key) {
    if (checkedKeys.contains(key)) {
      checkedKeys.remove(key);
    } else {
      checkedKeys.add(key);
    }
    checkedKeys.refresh();
    _persistCheckedKeys();
  }

  Future<void> _loadCheckedKeys() async {
    final saved = await _storage.getJson<List<String>>(
      RecipeStorageKeys.shoppingCheckedIngredients,
      (decoded) {
        if (decoded is! List<dynamic>) return <String>[];
        return decoded.map((item) => item.toString()).toList();
      },
    );
    if (saved == null || saved.isEmpty) return;
    checkedKeys.addAll(saved);
    checkedKeys.refresh();
  }

  Future<void> _persistCheckedKeys() async {
    await _storage.setJson(
      RecipeStorageKeys.shoppingCheckedIngredients,
      checkedKeys.toList(),
    );
  }
}

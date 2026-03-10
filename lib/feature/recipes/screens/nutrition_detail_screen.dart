import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';

class NutritionDetailScreen extends StatelessWidget {
  const NutritionDetailScreen({
    super.key,
    required this.recipe,
    required this.nutritionKey,
  });

  final RecipeModel recipe;
  final String nutritionKey;

  String _nutritionLabel() {
    if (nutritionKey == AppStrings.kcal) return AppStrings.kcal.tr;
    if (nutritionKey == AppStrings.water) return AppStrings.water.tr;
    if (nutritionKey == AppStrings.protein) return AppStrings.protein.tr;
    if (nutritionKey == AppStrings.fat) return AppStrings.fat.tr;
    if (nutritionKey == AppStrings.carbohydrate) {
      return AppStrings.carbohydrate.tr;
    }
    if (nutritionKey == AppStrings.fiber) return AppStrings.fiber.tr;
    if (nutritionKey == AppStrings.ash) return AppStrings.ash.tr;
    if (nutritionKey == AppStrings.sodium) return AppStrings.sodium.tr;
    return nutritionKey;
  }

  double _nutritionValue(IngredientModel ingredient) {
    if (nutritionKey == AppStrings.kcal) return ingredient.usedKcal ?? 0;
    if (nutritionKey == AppStrings.water) return ingredient.usedWater ?? 0;
    if (nutritionKey == AppStrings.protein) return ingredient.usedProtein ?? 0;
    if (nutritionKey == AppStrings.fat) return ingredient.usedFat ?? 0;
    if (nutritionKey == AppStrings.carbohydrate) {
      return ingredient.usedCarbohydrate ?? 0;
    }
    if (nutritionKey == AppStrings.fiber) return ingredient.usedFiber ?? 0;
    if (nutritionKey == AppStrings.ash) return ingredient.usedAsh ?? 0;
    if (nutritionKey == AppStrings.sodium) return ingredient.usedSodium ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final label = _nutritionLabel();
    final servings = recipe.servings <= 0 ? 1 : recipe.servings;
    final total = recipe.ingredients.fold<double>(
      0,
      (sum, item) => sum + _nutritionValue(item),
    );
    final perServingTotal = total / servings;
    final outline = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.35);
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      bottomNavigationBar: const AdBannerBottomSheet(),
      appBar: AppBar(title: Text('${AppStrings.nutrition.tr} - $label')),
      body:
          recipe.ingredients.isEmpty
              ? Center(child: Text(AppStrings.noRegisteredIngredient.tr))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summaryChip(
                            context: context,
                            title: AppStrings.quantity.tr,
                            value: total.toStringAsFixed(2),
                            accent: primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryChip(
                            context: context,
                            title: AppStrings.perServing.tr,
                            value: perServingTotal.toStringAsFixed(2),
                            accent: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(5),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            horizontalInside: BorderSide(color: outline),
                            verticalInside: BorderSide(color: outline),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.10),
                              ),
                              children: [
                                _th(
                                  '${AppStrings.ingredientName.tr} / ${AppStrings.gram.tr}',
                                ),
                                _th(
                                  AppStrings.quantity.tr,
                                  align: TextAlign.center,
                                ),
                                _th(
                                  AppStrings.perServing.tr,
                                  align: TextAlign.center,
                                ),
                              ],
                            ),
                            ...List.generate(recipe.ingredients.length, (
                              index,
                            ) {
                              final ingredient = recipe.ingredients[index];
                              final value = _nutritionValue(ingredient);
                              final perServing = value / servings;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color:
                                      index.isEven
                                          ? surface
                                          : onSurface.withValues(alpha: 0.03),
                                ),
                                children: [
                                  _ingredientAndGramCell(ingredient),
                                  _td(
                                    value.toStringAsFixed(2),
                                    align: TextAlign.right,
                                  ),
                                  _td(
                                    perServing.toStringAsFixed(2),
                                    align: TextAlign.right,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _summaryChip({
    required BuildContext context,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _th(
    String value, {
    TextAlign align = TextAlign.left,
    bool colSpanHint = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        value,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: colSpanHint ? Colors.black87 : null,
        ),
      ),
    );
  }

  Widget _td(String value, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(value, textAlign: align),
    );
  }

  Widget _ingredientAndGramCell(IngredientModel ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ingredient.name),
          const SizedBox(height: 2),
          Text(
            '${ingredient.amount} ${ingredient.unit.displayName}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

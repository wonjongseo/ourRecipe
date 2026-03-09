import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService._();

  static Future<void> shareRecipe(RecipeModel recipe) async {
    final ingredientsText = recipe.ingredients
        .map((item) => '- ${item.name}: ${item.amount} ${item.unit.name}')
        .join('\n');

    final stepsText = recipe.steps
        .map((step) => '${step.order}. ${step.instruction}')
        .join('\n');

    final text = [
      recipe.name,
      if (recipe.description.isNotEmpty) recipe.description,
      '',
      '[${AppStrings.ingredient.tr}]',
      ingredientsText,
      '',
      '[${AppStrings.cookingStep.tr}]',
      stepsText,
      '',
      '${AppStrings.totalIngredientCost.tr}: ${recipe.ingredientCostTotal.toStringAsFixed(0)}${AppStrings.won.tr}',
    ].join('\n');

    await Share.share(text);
  }

  static Future<void> shareRecipeFullImage(
    BuildContext context,
    RecipeModel recipe,
  ) async {
    try {
      final screenshotController = ScreenshotController();
      final theme = Theme.of(context);

      final bytes = await screenshotController.captureFromLongWidget(
        Material(
          color: theme.scaffoldBackgroundColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _RecipeShareContent(recipe: recipe),
            ),
          ),
        ),
        context: context,
        delay: const Duration(milliseconds: 80),
      );

      await _sharePngBytes(bytes, recipe);
    } catch (_) {
      await shareRecipe(recipe);
    }
  }

  static Future<void> _sharePngBytes(
    Uint8List bytes,
    RecipeModel recipe,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/recipe_share_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: recipe.name);
  }
}

class _RecipeShareContent extends StatelessWidget {
  const _RecipeShareContent({required this.recipe});
  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final divider = Divider(color: Theme.of(context).colorScheme.outline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.coverImagePath != null &&
            recipe.coverImagePath!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(recipe.coverImagePath!),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          recipe.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (recipe.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(recipe.description, style: textTheme.bodyMedium),
        ],
        const SizedBox(height: 18),
        _sectionTitle(AppStrings.ingredient.tr),
        const SizedBox(height: 8),
        ...recipe.ingredients.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.name)),
                const SizedBox(width: 10),
                Text('${item.amount} ${item.unit.name}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle(AppStrings.nutrition.tr),
        const SizedBox(height: 8),
        _nutritionRow(AppStrings.kcal.tr, recipe.kcalTotal),
        _nutritionRow(AppStrings.water.tr, recipe.waterTotal),
        _nutritionRow(AppStrings.protein.tr, recipe.proteinTotal),
        _nutritionRow(AppStrings.fat.tr, recipe.fatTotal),
        _nutritionRow(AppStrings.carbohydrate.tr, recipe.carbohydrateTotal),
        _nutritionRow(AppStrings.fiber.tr, recipe.fiberTotal),
        _nutritionRow(AppStrings.ash.tr, recipe.ashTotal),
        _nutritionRow(AppStrings.sodium.tr, recipe.sodiumTotal),
        const SizedBox(height: 16),
        _sectionTitle(AppStrings.cookingStep.tr),
        const SizedBox(height: 8),
        ...recipe.steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${step.order}. ${step.instruction}'),
                if (step.imagePath != null && step.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(step.imagePath!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        divider,
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${AppStrings.totalIngredientCost.tr}: ${recipe.ingredientCostTotal.toStringAsFixed(0)}${AppStrings.won.tr}',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }

  Widget _nutritionRow(String name, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(name), Text(value.toStringAsFixed(2))],
      ),
    );
  }
}

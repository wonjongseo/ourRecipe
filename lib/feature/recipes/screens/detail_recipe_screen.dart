import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/services/share_service.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';

class DetailRecipeScreen extends StatefulWidget {
  const DetailRecipeScreen({super.key, required this.recipeModel});
  static String name = '/detail_recipe';

  final RecipeModel recipeModel;

  @override
  State<DetailRecipeScreen> createState() => _DetailRecipeScreenState();
}

class _DetailRecipeScreenState extends State<DetailRecipeScreen> {
  late RecipeModel recipeModel;
  late RecipeController controller;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ingredientKey = GlobalKey();
  final GlobalKey _nutritionKey = GlobalKey();
  final GlobalKey _cookingStepKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    recipeModel = widget.recipeModel;
    controller = Get.find<RecipeController>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AdBannerBottomSheet(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _appBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeModel.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  if (recipeModel.description.isNotEmpty) ...[
                    SizedBox(height: 12),

                    Text(
                      recipeModel.description,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                  SizedBox(height: 14),
                  _sectionNavigator(),
                  SizedBox(height: 30),
                  _titleAndContent(
                    key: _ingredientKey,
                    context: context,
                    title: AppStrings.ingredient.tr,
                    content:
                        recipeModel.ingredients.isEmpty
                            ? Center(
                              child: Text(
                                AppStrings.noRegisteredIngredient.tr,
                                style: TextStyle(
                                  color: AppColors.noRegisteredItemColor,
                                ),
                              ),
                            )
                            : _ingredientContent(),
                  ),

                  SizedBox(height: 30),
                  _titleAndContent(
                    key: _nutritionKey,
                    context: context,
                    title: AppStrings.nutrition.tr,
                    content: _nutritionContent(),
                  ),
                  SizedBox(height: 30),
                  _titleAndContent(
                    key: _cookingStepKey,
                    context: context,
                    title: AppStrings.cookingStep.tr,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(recipeModel.steps.length, (
                        index,
                      ) {
                        final step = recipeModel.steps[index];
                        return SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.secondartColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(step.instruction),
                              SizedBox(height: 12),
                              if (step.imagePath != null)
                                Image.file(File(step.imagePath!)),

                              if (index != recipeModel.steps.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 8,
                                  ),
                                  child: Divider(color: AppColors.borderColor),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionNavigator() {
    return Row(
      children: [
        _sectionChip(
          label: AppStrings.ingredient.tr,
          onTap: () => _scrollToKey(_ingredientKey),
        ),
        const SizedBox(width: 8),
        _sectionChip(
          label: AppStrings.nutrition.tr,
          onTap: () => _scrollToKey(_nutritionKey),
        ),
        const SizedBox(width: 8),
        _sectionChip(
          label: AppStrings.cookingStep.tr,
          onTap: () => _scrollToKey(_cookingStepKey),
        ),
      ],
    );
  }

  Widget _sectionChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  Widget _ingredientContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(recipeModel.ingredients.length, (index) {
        final ingredient = recipeModel.ingredients[index];
        return ListTile(
          dense: true,
          minLeadingWidth: 10,
          leading: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber,
            ),
          ),
          title: Text(ingredient.name),
          subtitle: ingredient.memo.isNotEmpty ? Text(ingredient.memo) : null,
          trailing: Text('${ingredient.amount} ${ingredient.unit.displayName}'),
        );
      }),
    );
  }

  Widget _nutritionContent() {
    final nutritionItems = <_NutritionRowItem>[
      _NutritionRowItem(
        label: AppStrings.kcal.tr,
        value: recipeModel.kcalTotal,
        key: AppStrings.kcal,
      ),
      _NutritionRowItem(
        label: AppStrings.water.tr,
        value: recipeModel.waterTotal,
        key: AppStrings.water,
      ),
      _NutritionRowItem(
        label: AppStrings.protein.tr,
        value: recipeModel.proteinTotal,
        key: AppStrings.protein,
      ),
      _NutritionRowItem(
        label: AppStrings.fat.tr,
        value: recipeModel.fatTotal,
        key: AppStrings.fat,
      ),
      _NutritionRowItem(
        label: AppStrings.carbohydrate.tr,
        value: recipeModel.carbohydrateTotal,
        key: AppStrings.carbohydrate,
      ),
      _NutritionRowItem(
        label: AppStrings.fiber.tr,
        value: recipeModel.fiberTotal,
        key: AppStrings.fiber,
      ),
      _NutritionRowItem(
        label: AppStrings.ash.tr,
        value: recipeModel.ashTotal,
        key: AppStrings.ash,
      ),
      _NutritionRowItem(
        label: AppStrings.sodium.tr,
        value: recipeModel.sodiumTotal,
        key: AppStrings.sodium,
      ),
    ];

    return Column(
      children:
          nutritionItems.map((item) {
            return ListTile(
              onTap:
                  () => controller.onTapNutrition(
                    recipe: recipeModel,
                    nutritionKey: item.key,
                  ),
              minTileHeight: 40,
              title: Text(item.label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.value.toStringAsFixed(2)),
                  SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey,
                  ),
                ],
              ),
              // contentPadding: const EdgeInsets.only(left: 44, right: 12),
            );
          }).toList(),
    );
  }

  SliverAppBar _appBar() {
    final hasCoverImage =
        recipeModel.coverImagePath != null &&
        recipeModel.coverImagePath!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,

      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: recipeModel.id,
          child:
              hasCoverImage
                  ? Image.file(
                    File(recipeModel.coverImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            _emptyCoverPlaceholder(context),
                  )
                  : _emptyCoverPlaceholder(context),
        ),
      ),
      actions: _adctions,
    );
  }

  Widget _emptyCoverPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.18),
            AppColors.secondaryColor.withValues(alpha: 0.28),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.88),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            FontAwesomeIcons.utensils,
            size: 28,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  List<Widget> get _adctions {
    return [
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'share':
              ShareService.shareRecipeFullImage(context, recipeModel);
              break;
            case 'edit':
              _editRecipe();
              break;
            case 'delete':
              controller.deleteRecipe(recipeModel);
              break;
          }
        },
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.share.tr),
                    SizedBox(width: 4),
                    Icon(Icons.share_outlined, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.edit.tr),
                    SizedBox(width: 4),
                    Icon(FontAwesomeIcons.edit, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.delete.tr),
                    SizedBox(width: 4),
                    Icon(FontAwesomeIcons.circleMinus, size: 18),
                  ],
                ),
              ),
            ],
      ),
    ];
  }

  Column _titleAndContent({
    Key? key,
    required BuildContext context,
    required String title,
    required Widget content,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.35),
              ),
            ],
            color: Theme.of(context).cardColor,
          ),
          padding: EdgeInsets.all(16),
          child: content,
        ),
      ],
    );
  }

  Future<void> _editRecipe() async {
    final updated = await controller.goToEditScreen(recipeModel: recipeModel);
    if (updated == null) return;
    if (!mounted) return;
    setState(() {
      recipeModel = updated;
    });
  }
}

class _NutritionRowItem {
  final String label;
  final double value;
  final String key;

  const _NutritionRowItem({
    required this.label,
    required this.value,
    required this.key,
  });
}

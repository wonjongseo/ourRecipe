import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/share_service.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/start_cooking/screen/start_cooking_screen.dart';

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
  late final TextEditingController _servingsController;
  late int _selectedServings;

  @override
  void initState() {
    super.initState();
    recipeModel = widget.recipeModel;
    controller = Get.find<RecipeController>();
    _selectedServings = recipeModel.servings <= 0 ? 1 : recipeModel.servings;
    _servingsController = TextEditingController(
      text: _selectedServings.toString(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _canStartCooking ? _goToStartCooking : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(AppStrings.startCooking.tr),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ),
            ),
            const AdBannerBottomSheet(),
          ],
        ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    if (recipeModel.description.isNotEmpty) ...[
                      SizedBox(height: 12),

                      Text(
                        recipeModel.description,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 12),

                    _sectionNavigator(),
                    SizedBox(height: 30),
                    _servingsField(),
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
                      content:
                          recipeModel.steps.isEmpty
                              ? Center(
                                child: Text(
                                  AppStrings.noRegisteredCookingStep.tr,
                                  style: TextStyle(
                                    color: AppColors.noRegisteredItemColor,
                                  ),
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  recipeModel.steps.length,
                                  (index) {
                                    final step = recipeModel.steps[index];
                                    return SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondartColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(step.instruction),
                                          SizedBox(height: 12),
                                          if (step.imagePath != null)
                                            Image.file(File(step.imagePath!)),

                                          if (index !=
                                              recipeModel.steps.length - 1)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 8,
                                                  ),
                                              child: Divider(
                                                color: AppColors.borderColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final factor = _servingFactor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(recipeModel.ingredients.length, (index) {
        final ingredient = recipeModel.ingredients[index];
        final scaledAmount = ingredient.amount * factor;
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
          trailing: Text(
            '${scaledAmount.toStringAsFixed(1)} ${ingredient.unit.displayName}',
          ),
        );
      }),
    );
  }

  Widget _nutritionContent() {
    final factor = _servingFactor;
    final nutritionItems = <_NutritionRowItem>[
      _NutritionRowItem(
        label: AppStrings.kcal.tr,
        value: recipeModel.kcalTotal * factor,
        key: AppStrings.kcal,
      ),
      _NutritionRowItem(
        label: AppStrings.water.tr,
        value: recipeModel.waterTotal * factor,
        key: AppStrings.water,
      ),
      _NutritionRowItem(
        label: AppStrings.protein.tr,
        value: recipeModel.proteinTotal * factor,
        key: AppStrings.protein,
      ),
      _NutritionRowItem(
        label: AppStrings.fat.tr,
        value: recipeModel.fatTotal * factor,
        key: AppStrings.fat,
      ),
      _NutritionRowItem(
        label: AppStrings.carbohydrate.tr,
        value: recipeModel.carbohydrateTotal * factor,
        key: AppStrings.carbohydrate,
      ),
      _NutritionRowItem(
        label: AppStrings.fiber.tr,
        value: recipeModel.fiberTotal * factor,
        key: AppStrings.fiber,
      ),
      _NutritionRowItem(
        label: AppStrings.ash.tr,
        value: recipeModel.ashTotal * factor,
        key: AppStrings.ash,
      ),
      _NutritionRowItem(
        label: AppStrings.sodium.tr,
        value: recipeModel.sodiumTotal * factor,
        key: AppStrings.sodium,
      ),
    ];

    return Column(
      children:
          nutritionItems.map((item) {
            return ListTile(
              onTap:
                  () => controller.onTapNutrition(
                    recipe: _scaledRecipeForServing(),
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

  Widget _servingsField() {
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              AppStrings.adjustServings.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  autoFocus: true,
                  height: 40,
                  borderRadius: 8,
                  keyboardType: TextInputType.number,
                  controller: _servingsController,
                  suffixText: AppStrings.servingsUnit.tr,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final value = _servingsController.text;
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) return;
                  setState(() {
                    _selectedServings = parsed;
                  });
                },
                child: Icon(FontAwesomeIcons.check),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _servingFactor {
    final base = recipeModel.servings <= 0 ? 1 : recipeModel.servings;
    return _selectedServings / base;
  }

  RecipeModel _scaledRecipeForServing() {
    final factor = _servingFactor;
    if ((factor - 1).abs() < 0.000001) {
      return recipeModel.copyWith(servings: _selectedServings);
    }
    final scaledIngredients =
        recipeModel.ingredients
            .map(
              (ingredient) =>
                  ingredient.copyWith(amount: ingredient.amount * factor),
            )
            .toList();

    return recipeModel.copyWith(
      servings: _selectedServings,
      ingredients: scaledIngredients,
      totalIngredientCost: recipeModel.totalIngredientCost * factor,
      totalKcal: recipeModel.totalKcal * factor,
      totalWater: recipeModel.totalWater * factor,
      totalProtein: recipeModel.totalProtein * factor,
      totalFat: recipeModel.totalFat * factor,
      totalCarbohydrate: recipeModel.totalCarbohydrate * factor,
      totalFiber: recipeModel.totalFiber * factor,
      totalAsh: recipeModel.totalAsh * factor,
      totalSodium: recipeModel.totalSodium * factor,
    );
  }

  SliverAppBar _appBar() {
    final hasCoverImage =
        recipeModel.coverImagePath != null &&
        recipeModel.coverImagePath!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      foregroundColor: Colors.white,

      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
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
            if (recipeModel.coverImagePath != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x88000000), Color(0x00000000)],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: _actions,
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

  List<Widget> get _actions {
    return [
      IconButton(
        onPressed: _toggleBookmark,
        icon: Icon(
          recipeModel.isLiked
              ? FontAwesomeIcons.solidBookmark
              : FontAwesomeIcons.bookmark,
          color: recipeModel.isLiked ? AppColors.primaryColor : null,
        ),
      ),
      PopupMenuButton<String>(
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
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
                    Text(
                      AppStrings.share.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.edit.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      FontAwesomeIcons.edit,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.delete.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      FontAwesomeIcons.circleMinus,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
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
      _selectedServings = updated.servings <= 0 ? 1 : updated.servings;
      _servingsController.text = _selectedServings.toString();
    });
  }

  Future<void> _toggleBookmark() async {
    await controller.toggleBookmark(recipeModel.id);
    if (!mounted) return;
    setState(() {
      recipeModel = recipeModel.copyWith(isLiked: !recipeModel.isLiked);
    });
  }

  bool get _canStartCooking => recipeModel.steps.isNotEmpty;

  void _goToStartCooking() {
    if (!_canStartCooking) {
      SnackBarHelper.showErrorSnackBar(AppStrings.noCookingStepsToStart.tr);
      return;
    }
    Get.toNamed(StartCookingScreen.name, arguments: recipeModel);
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

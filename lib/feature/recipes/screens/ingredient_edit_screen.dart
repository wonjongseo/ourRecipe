import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_edit_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';

class IngredientEditScreen extends GetView<IngredientEditController> {
  const IngredientEditScreen({super.key});
  static String name = '/ingredient_edit';

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Obx(
      () => Scaffold(
        bottomNavigationBar: const AdBannerBottomSheet(),
        appBar: _appBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              _sectionCard(
                context: context,
                title: AppStrings.ingredient.tr,
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    CustomTextFormField(
                      label: AppStrings.ingredientName.tr,
                      controller: controller.nameCtrl,
                    ),
                    gap,
                    SizedBox(
                      height: UiConstants.formFieldHeight,
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedCategory.value,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(
                          UiConstants.formFieldRadius,
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.ingredientCategory.tr,
                          filled: true,
                          hintMaxLines: 300,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: AppInputBorders.normal(),
                          enabledBorder: AppInputBorders.normal(),
                          focusedBorder: AppInputBorders.focused(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          suffixIcon: IconButton(
                            onPressed: controller.goToCategoryManagement,
                            icon: const Icon(Icons.settings_outlined, size: 18),
                          ),
                        ),
                        items: [
                          ...controller.categories.map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                IngredientCategoryCatalog.displayName(
                                  category,
                                  controller.languageCode,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: controller.setSelectedCategory,
                      ),
                    ),
                    gap,
                    CustomTextFormField(
                      label: AppStrings.manufacturerName.tr,
                      controller: controller.manufacturerCtrl,
                    ),
                    gap,
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            label: AppStrings.price.tr,
                            controller: controller.priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextFormField(
                            label: AppStrings.productGram.tr,
                            controller: controller.baseGramCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                context: context,
                title: AppStrings.nutrition.tr,
                icon: Icons.monitor_heart_outlined,
                child: Column(
                  children: [
                    _nutritionRow(
                      left: CustomTextFormField(
                        label: AppStrings.kcal.tr,
                        controller: controller.kcalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      right: CustomTextFormField(
                        label: AppStrings.water.tr,
                        controller: controller.waterCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    gap,
                    _nutritionRow(
                      left: CustomTextFormField(
                        label: AppStrings.protein.tr,
                        controller: controller.proteinCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      right: CustomTextFormField(
                        label: AppStrings.fat.tr,
                        controller: controller.fatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    gap,
                    _nutritionRow(
                      left: CustomTextFormField(
                        label: AppStrings.carbohydrate.tr,
                        controller: controller.carbohydrateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      right: CustomTextFormField(
                        label: AppStrings.fiber.tr,
                        controller: controller.fiberCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    gap,
                    _nutritionRow(
                      left: CustomTextFormField(
                        label: AppStrings.ash.tr,
                        controller: controller.ashCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      right: CustomTextFormField(
                        label: AppStrings.sodium.tr,
                        controller: controller.sodiumCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final outline = Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(
        controller.isEdit
            ? AppStrings.ingredientEdit.tr
            : AppStrings.ingredientCreate.tr,
      ),
      actions: [
        if (controller.isEdit)
          IconButton(
            onPressed: controller.delete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        TextButton(onPressed: controller.save, child: Text(AppStrings.save.tr)),
      ],
    );
  }
}

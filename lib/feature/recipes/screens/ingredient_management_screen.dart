import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_scale.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/app_refresh_indicator.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_management_controller.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/ingredient_product_grouped_expansion_list.dart';

class IngredientManagementScreen
    extends GetView<IngredientManagementController> {
  const IngredientManagementScreen({super.key});
  static String name = '/ingredient_management';

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        bottomNavigationBar: const AdBannerBottomSheet(),
        appBar: AppBar(title: Text(AppStrings.ingredientManagement.tr)),
        body:
            controller.isLoading
                ? Center(child: CircularProgressIndicator.adaptive())
                : controller.groupedProducts.isEmpty
                ? Center(
                  child: Text(
                    AppStrings.noRegisteredIngredient.tr,
                    style: TextStyle(color: AppColors.noRegisteredItemColor),
                  ),
                )
                : AppRefreshIndicator(
                  onRefresh: controller.loadProducts,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomTextFormField(
                        autoFocus: true,
                        onChanged: controller.updateQuery,
                        label: AppStrings.ingredientName.tr,
                        prefixIcon: Icon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: AppScale.size(13),
                        ),
                      ),

                      const SizedBox(height: 12),
                      if (controller.userAddedGroups.isEmpty &&
                          controller.appProvidedGroups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: _emptyLabel(context),
                        ),
                      if (controller.userAddedGroups.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _sectionTitle(AppStrings.userAddedIngredients.tr),
                        const SizedBox(height: 8),
                        IngredientProductGroupedExpansionList(
                          groups: controller.userAddedGroups,
                          query: controller.query.value,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          subtitleBuilder:
                              (item) =>
                                  '${item.manufacturer} · ${item.baseGram}${AppStrings.gram.tr} / ${item.price.toStringAsFixed(0)}${AppStrings.won.tr}',
                          trailingBuilder:
                              (_) => const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                              ),
                          onTapProduct:
                              (item) => controller.goToEdit(product: item),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (controller.appProvidedGroups.isNotEmpty) ...[
                        _sectionTitle(AppStrings.appProvidedIngredients.tr),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.nutritionPer100gGuide.tr,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: AppScale.text(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IngredientProductGroupedExpansionList(
                          groups: controller.appProvidedGroups,
                          query: controller.query.value,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          subtitleBuilder:
                              (item) =>
                                  '${item.baseGram}${AppStrings.gram.tr} / ${item.price.toStringAsFixed(0)}${AppStrings.won.tr}',
                          trailingBuilder:
                              (_) => const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                              ),
                          onTapProduct:
                              (item) => controller.goToEdit(product: item),
                        ),
                      ],
                    ],
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'ingredient_management_add_fab',
          onPressed: controller.goToEdit,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: AppScale.text(15),
      ),
    );
  }

  Widget _emptyLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        AppStrings.noRegisteredIngredient.tr,
        style: TextStyle(color: AppColors.noRegisteredItemColor),
      ),
    );
  }
}

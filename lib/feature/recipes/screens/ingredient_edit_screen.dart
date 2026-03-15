import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_dropdown_styles.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_bottom_button.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_edit_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';

class IngredientEditScreen extends StatefulWidget {
  const IngredientEditScreen({super.key});
  static String name = '/ingredient_edit';

  @override
  State<IngredientEditScreen> createState() => _IngredientEditScreenState();
}

class _IngredientEditScreenState extends State<IngredientEditScreen> {
  final controller = Get.find<IngredientEditController>();
  final TextEditingController _categorySearchCtrl = TextEditingController();

  @override
  void dispose() {
    _categorySearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Obx(
      () => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          bottomNavigationBar: const AdBannerBottomSheet(),
          appBar: _appBar(),
          body: SafeArea(
            child:
                controller.isLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : ListView(
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
                              // gap,
                              Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed:
                                          () =>
                                              controller
                                                  .goToCategoryManagement(),
                                      label: Text(AppStrings.addCategory.tr),
                                      icon: Icon(Icons.add),
                                    ),
                                  ),
                                  _category(context),
                                ],
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
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomTextFormField(
                                      label: AppStrings.productGram.tr,
                                      controller: controller.baseGramCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
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
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                right: CustomTextFormField(
                                  label: AppStrings.water.tr,
                                  controller: controller.waterCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              gap,
                              _nutritionRow(
                                left: CustomTextFormField(
                                  label: AppStrings.protein.tr,
                                  controller: controller.proteinCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                right: CustomTextFormField(
                                  label: AppStrings.fat.tr,
                                  controller: controller.fatCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              gap,
                              _nutritionRow(
                                left: CustomTextFormField(
                                  label: AppStrings.carbohydrate.tr,
                                  controller: controller.carbohydrateCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                right: CustomTextFormField(
                                  label: AppStrings.fiber.tr,
                                  controller: controller.fiberCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              gap,
                              _nutritionRow(
                                left: CustomTextFormField(
                                  label: AppStrings.ash.tr,
                                  controller: controller.ashCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                right: CustomTextFormField(
                                  label: AppStrings.sodium.tr,
                                  controller: controller.sodiumCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
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
      ),
    );
  }

  SizedBox _category(BuildContext context) {
    return SizedBox(
      height: UiConstants.formFieldHeight,
      child: DropdownButtonFormField2<String>(
        value: controller.selectedCategory.value,
        isExpanded: true,
        buttonStyleData: AppDropdownStyles.dropdown2ButtonStyle(
          height: UiConstants.formFieldHeight,
          padding: const EdgeInsets.only(left: 2, right: 8),
        ),
        dropdownStyleData: AppDropdownStyles.dropdown2MenuStyle(
          context,
          maxHeight: 400,
          horizontalPadding: 0,
        ),
        menuItemStyleData: AppDropdownStyles.dropdown2ItemStyle(),
        decoration: AppDropdownStyles.formFieldDecoration(
          context,
          labelText: '  ${AppStrings.ingredientCategory.tr}',
          isPaddingZero: true,
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: _categorySearchCtrl,

          searchInnerWidgetHeight: 56,

          searchInnerWidget: Container(
            height: 65,
            padding: EdgeInsets.only(top: 8, left: 12, right: 12),
            child: TextFormField(
              controller: _categorySearchCtrl,
              expands: true,
              maxLines: null,
              decoration: AppDropdownStyles.formFieldDecoration(
                context,
                hintText: AppStrings.search.tr,
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            final value = item.value ?? '';
            final query = searchValue.trim().toLowerCase();
            if (query.isEmpty) return true;
            final displayName =
                IngredientCategoryCatalog.displayName(
                  value,
                  controller.languageCode,
                ).toLowerCase();
            return displayName.contains(query) ||
                value.toLowerCase().contains(query);
          },
        ),
        items:
            controller.categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      IngredientCategoryCatalog.displayName(
                        category,
                        controller.languageCode,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: controller.setSelectedCategory,
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _categorySearchCtrl.clear();
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final showICloudWarning = await controller.isICloudDeleteWarningVisible();
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog.adaptive(
            title: Text(AppStrings.delete.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(AppStrings.deleteIngredientConfirmMessage.tr),
                if (showICloudWarning) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.deleteIngredientICloudWarning.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppStrings.cancel.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppStrings.delete.tr),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await controller.delete();
    }
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
    final outline = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.35);
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  AppBar _appBar() {
    final appBarForegroundColor =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;
    return AppBar(
      title: Text(
        controller.isEdit
            ? AppStrings.ingredientEdit.tr
            : AppStrings.ingredientCreate.tr,
      ),
      actions: [
        if (controller.isEdit)
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        TextButton(
          style: TextButton.styleFrom(
            iconColor: appBarForegroundColor,
            foregroundColor: appBarForegroundColor,
          ),

          onPressed: controller.save,
          child: Text(
            controller.isEdit ? AppStrings.edit.tr : AppStrings.save.tr,
          ),
        ),
        // CustomBottomButton(
        //   label: controller.isEdit ? AppStrings.edit.tr : AppStrings.save.tr,
        //   onPressed: controller.save,
        //   icon: controller.isEdit ? Icons.edit : Icons.add,
        // ),
      ],
    );
  }
}

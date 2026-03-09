import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_category_management_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';

class IngredientCategoryManagementScreen
    extends GetView<IngredientCategoryManagementController> {
  const IngredientCategoryManagementScreen({super.key});
  static String name = '/ingredient_category_management';

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          bottomNavigationBar: const AdBannerBottomSheet(),
          appBar: AppBar(
            title: Text(AppStrings.ingredientCategoryManagement.tr),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      label: AppStrings.addCategory.tr,
                      controller: controller.inputCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    height: 50,
                    child: FilledButton(
                      onPressed: controller.add,
                      child: Text(AppStrings.add.tr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(AppStrings.defaultCategory.tr),
              const SizedBox(height: 8),
              ...IngredientCategoryCatalog.defaults.map(
                (item) => ListTile(
                  tileColor: Theme.of(context).cardColor,
                  title: Text(item.displayName(controller.languageCode)),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.userCategory.tr),
              const SizedBox(height: 8),
              if (controller.isLoading)
                Center(child: CircularProgressIndicator.adaptive())
              else if (controller.customCategories.isEmpty)
                ListTile(title: Text(AppStrings.noRegisteredUserCategory.tr))
              else
                ...controller.customCategories.map(
                  (item) => ListTile(
                    tileColor: Theme.of(context).cardColor,
                    title: Text(item),
                    trailing: IconButton(
                      onPressed: () => controller.remove(item),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

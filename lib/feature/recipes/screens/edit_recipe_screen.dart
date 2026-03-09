import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_dropdown_styles.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/edit_recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/editable_cooking_step_list_tile.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/editable_ingredient_list_tile.dart';

class EditRecipeScreen extends GetView<EditRecipeController> {
  const EditRecipeScreen({super.key});
  static String name = '/edit_recipe';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isLoading
                            ? null
                            : () => controller.saveRecipeModel(),
                    label: Text(
                      controller.isEdit
                          ? AppStrings.edit.tr
                          : AppStrings.save.tr,
                    ),
                    icon: Icon(Icons.add),
                  ),
                ),
              ),
              const AdBannerBottomSheet(),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(AppStrings.addRecipe.tr),
          actions: [
            TextButton(
              onPressed:
                  controller.isLoading
                      ? null
                      : () => controller.saveRecipeModel(),
              child: Text(
                controller.isEdit ? AppStrings.edit.tr : AppStrings.save.tr,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(
            () =>
                controller.isLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _coverImage(),
                          SizedBox(height: 24),
                          _recipeCategory(context),
                          SizedBox(height: 12),
                          CustomTextFormField(
                            label: AppStrings.recipeName.tr,
                            controller: controller.recipeNameTextCtrl,
                          ),
                          SizedBox(height: 12),
                          CustomTextFormField(
                            label: AppStrings.description.tr,
                            maxLine: 3,
                            controller: controller.descriptionTextCtrl,
                          ),
                          SizedBox(height: 12),
                          CustomTextFormField(
                            label: AppStrings.servings.tr,
                            controller: controller.servingsTextCtrl,
                            keyboardType: TextInputType.number,
                            hintText: AppStrings.servingsExample.tr,
                            suffixText: AppStrings.servingsUnit.tr,
                          ),

                          SizedBox(height: 24),
                          _ingredients(),
                          SizedBox(height: 24),
                          _cookingSteps(),

                          SizedBox(height: 30),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _recipeCategory(BuildContext context) {
    return SizedBox(
      height: UiConstants.formFieldHeight,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color:
              controller.categories.isEmpty
                  ? Colors.grey
                  : Colors.grey.shade700,
        ),
        borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
        dropdownColor: Get.theme.colorScheme.surface,
        menuMaxHeight: 300,
        value:
            controller.selectedCategory.value.isEmpty
                ? null
                : controller.selectedCategory.value,
        decoration: AppDropdownStyles.formFieldDecoration(
          context,
          labelText: AppStrings.category.tr,
          suffixIcon: IconButton(
            onPressed: () => controller.goToCategoryManagement(),
            icon: const Icon(Icons.settings_outlined, size: 18),
          ),
        ),
        hint: Text(
          controller.categories.isEmpty
              ? '카테고리를 등록해주세요'
              : AppStrings.selectCategoryHint.tr,
          style: TextStyle(
            fontSize: UiConstants.formFieldHintSize,
            color: Colors.grey.shade600,
          ),
        ),
        items: [
          ...controller.categories.map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // DropdownMenuItem(
          //   child: Text('카테고리 추가'),
          //   value: 'add',
          //   onTap: () => controller.goToCategoryManagement(),
          // ),
        ],
        onChanged: (value) {
          if (value == null) return;
          controller.setSelectedCategory(value);
        },
      ),
    );
  }

  Widget _cookingSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppStrings.cookingStep.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,

          itemBuilder: (context, index) {
            final inputCookingStep = controller.inputCookingSteps[index];
            return EditableCookingStepListTile(
              key: Key(inputCookingStep.id),
              inputCookingStep: inputCookingStep,
              index: index,
              onDelete:
                  controller.inputCookingSteps.length == 1
                      ? null
                      : controller.deleteCookingStep,
              pickImage: (index) {
                controller.pickImageToCookingStep(index);
              },
              removeImage: (index) {
                controller.removeImageFromCookingStep(index);
              },
              setTimer: (index, minute) {
                controller.setCookingStepTimer(index, minute);
              },
            );
          },

          itemCount: controller.inputCookingSteps.length,
          onReorder: controller.onReorderCookingSteps,
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => controller.addCookingStep(),
            label: Text(AppStrings.addStep.tr),
            icon: Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Column _ingredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppStrings.ingredient.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),

        SizedBox(height: 8),
        if (controller.ingredients.isEmpty)
          Center(
            child: Text(
              AppStrings.pleaseAddIngredient.tr,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final ingredient = controller.ingredients[index];
              return EditableIngredientListTile(
                key: Key(ingredient.id),
                ingredient: ingredient,
                index: index,
                onTap: (index) {
                  controller.editIngredient(index: index);
                },
                onDelete: (index) => controller.deleteIngredient(index),
              );
            },
            itemCount: controller.ingredients.length,
            onReorder: controller.onReorderIngredients,
          ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.totalIngredientCost.tr}: ${controller.totalUseCount.toStringAsFixed(0)}${AppStrings.won.tr}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            TextButton.icon(
              onPressed: () => controller.editIngredient(),
              icon: Icon(Icons.add),
              label: Text(AppStrings.addIngredient.tr),
            ),
          ],
        ),
      ],
    );
  }

  Widget _coverImage() {
    return Material(
      color:
          controller.isPickingImage
              ? Colors.grey.shade100
              : Get.theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.pickImageFromLibery(),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
            image:
                controller.coverImage == null
                    ? null
                    : DecorationImage(
                      image: FileImage(controller.coverImage!),
                      fit: BoxFit.cover,
                    ),
          ),
          child:
              controller.coverImage == null
                  ? controller.isPickingImage
                      ? Center(child: CircularProgressIndicator.adaptive())
                      : _pickImageWidget()
                  : SizedBox(),
        ),
      ),
    );
  }

  Column _pickImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FontAwesomeIcons.camera, color: Colors.grey, size: 36),
        SizedBox(height: 6),
        Text(AppStrings.addPhoto.tr, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

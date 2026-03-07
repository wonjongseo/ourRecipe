import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/edit_recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/dialog/set_timer_dialog.dart';

class EditRecipeScreen extends GetView<EditRecipeController> {
  const EditRecipeScreen({super.key});
  static String name = '/edit_recipe';
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.addRecipe.tr),
          actions: [
            TextButton(
              onPressed: () => controller.saveRecipeModel(),
              child: Text(AppStrings.save.tr),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(
            () => SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  _coverImage(),
                  SizedBox(height: 36),
                  _recipeCategory(),
                  SizedBox(height: 24),
                  CustomTextFormField(
                    label: AppStrings.name.tr,
                    controller: controller.recipeNameTextCtrl,
                  ),
                  SizedBox(height: 18),
                  CustomTextFormField(
                    label: AppStrings.description.tr,
                    maxLine: 3,
                    controller: controller.descriptionTextCtrl,
                  ),

                  SizedBox(height: 24),
                  _ingredients(),
                  SizedBox(height: 30),
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

  Widget _recipeCategory() {
    return SizedBox(
      height: UiConstants.formFieldHeight,
      child: DropdownButtonFormField<RecipeCategory>(
        value: controller.selectedCategory.value,
        isDense: true,
        decoration: InputDecoration(
          labelText: AppStrings.category.tr,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
        ),
        items:
            RecipeCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName.tr),
                  ),
                )
                .toList(),
        onChanged: (category) {
          if (category == null) return;
          controller.setCategory(category);
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.cookingStep.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: () => controller.addCookingStep(),
                child: Text(AppStrings.addStep.tr),
              ),
            ],
          ),
        ),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,

          itemBuilder: (context, index) {
            final inputCookingStep = controller.inputCookingSteps[index];
            return _cookingStepListTile(context, inputCookingStep, index);
          },

          itemCount: controller.inputCookingSteps.length,
          onReorder: controller.onReorderCookingSteps,
        ),
      ],
    );
  }

  Widget _cookingStepListTile(
    BuildContext context,
    InputCookingStep inputCookingStep,
    int index,
  ) {
    return Container(
      key: Key(inputCookingStep.id),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showTimerDialog(context, index),
                    icon: Icon(FontAwesomeIcons.clock),
                    label:
                        inputCookingStep.timer == 0
                            ? Text(AppStrings.timer.tr)
                            : Text(
                              '${inputCookingStep.timer}${AppStrings.minute.tr}',
                            ),
                  ),
                  IconButton(
                    onPressed:
                        controller.inputCookingSteps.length == 1
                            ? null
                            : () => controller.deleteCookingStep(index),
                    icon: Icon(
                      FontAwesomeIcons.circleMinus,
                      size: 20,
                      color:
                          controller.inputCookingSteps.length == 1
                              ? Colors.grey
                              : Colors.pinkAccent,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),
          CustomTextFormField(
            label: AppStrings.description.tr,
            maxLine: 3,
            controller: inputCookingStep.descriptionTeCtrl,
          ),
          SizedBox(height: 24),

          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child:
                controller.inputCookingSteps[index].image == null
                    ? InkWell(
                      onTap: () => controller.pickImageToCookingStep(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.image),
                            SizedBox(width: 10),
                            Text(AppStrings.addPhoto.tr),
                          ],
                        ),
                      ),
                    )
                    : Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 120,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FileImage(
                                controller.inputCookingSteps[index].image!,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap:
                                  () => controller.removeImageFromCookingStep(
                                    index,
                                  ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  FontAwesomeIcons.xmark,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Column _ingredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.ingredient.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: () => controller.addIngredient(),
                child: Text(AppStrings.addIngredient.tr),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '${AppStrings.totalIngredientCost.tr}: ${controller.ingredients.fold<double>(0, (sum, item) => sum + (item.usedCost ?? 0)).toStringAsFixed(0)}${AppStrings.won.tr}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        SizedBox(height: 8),
        if (controller.ingredients.isEmpty)
          Center(child: Text(AppStrings.pleaseAddIngredient.tr))
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final ingredient = controller.ingredients[index];
              return _ingredientListTIle(ingredient, index);
            },
            itemCount: controller.ingredients.length,
            onReorder: controller.onReorderIngredients,
          ),
      ],
    );
  }

  ListTile _ingredientListTIle(IngredientModel ingredient, int index) {
    return ListTile(
      key: Key(ingredient.id),
      leading: Text('${index + 1}'),
      title: Text(ingredient.name, style: TextStyle(fontSize: 13)),
      subtitle: Row(
        children: [
          Text('${ingredient.amount}', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(ingredient.unit.displayName, style: TextStyle(fontSize: 12)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => controller.deleteIngredient(index),
            icon: Icon(
              FontAwesomeIcons.circleMinus,
              size: 20,
              color: Colors.pinkAccent,
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
  }

  Widget _coverImage() {
    return Material(
      color: controller.isPickingImage ? Colors.grey.shade100 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            controller.coverImage == null
                ? () => controller.pickImageFromLibery()
                : null,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 8),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
            image:
                controller.coverImage == null
                    ? null
                    : DecorationImage(
                      image: FileImage(controller.coverImage!),
                      fit: BoxFit.fill,
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

  Future<void> _showTimerDialog(BuildContext context, int index) async {
    final result = await Get.dialog(SetTimerDialog());

    if (result == null) return;

    int? minute = int.tryParse(result);
    if (minute == null) return;
    controller.setCookingStepTimer(index, minute);
  }
}

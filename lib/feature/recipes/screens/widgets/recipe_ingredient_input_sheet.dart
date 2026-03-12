import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_dropdown_styles.dart';
import 'package:our_recipe/core/common/app_functions.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_ingredient_input_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/ingredient_product_picker_sheet.dart';

class RecipeIngredientInputSheet extends StatefulWidget {
  const RecipeIngredientInputSheet({super.key, this.initialIngredient});

  final IngredientModel? initialIngredient;

  @override
  State<RecipeIngredientInputSheet> createState() =>
      _RecipeIngredientInputSheetState();
}

class _RecipeIngredientInputSheetState
    extends State<RecipeIngredientInputSheet> {
  late final RecipeIngredientInputController controller;
  String get _controllerTag => '${runtimeType}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      RecipeIngredientInputController(
        Get.find<IngredientProductRepository>(),
        initialIngredient: widget.initialIngredient,
      ),
      tag: _controllerTag,
    );
  }

  Future<void> _goToIngredientManagementScreen() async {
    await Get.toNamed(
      IngredientManagementScreen.name,
      preventDuplicates: false,
    );
    await controller.loadProducts();
  }

  Future<void> _showIngredientPickerSheet() async {
    final selected = await AppFunctions.showBottomSheet(
      context: context,
      child: IngredientProductPickerSheet(
        filterGroups: controller.filterGroupedProducts,
        onTapManage: _goToIngredientManagementScreen,
        selectedProductId: controller.selectedProductId,
      ),
    );

    if (selected == null) return;
    controller.selectProduct(selected);
  }

  void _add() {
    final ingredientModel = controller.buildIngredient();
    if (ingredientModel == null) return;
    Get.back(result: ingredientModel);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: size.height * .7),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading
                      ? Center(child: CircularProgressIndicator.adaptive())
                      : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: _formContent(context),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _formContent(BuildContext context) {
    return Column(
      children: [
        _IngredientNameField(
          selectedIngredientNameRx: controller.selectedIngredientName,
          onTapField: _showIngredientPickerSheet,
        ),
        const SizedBox(height: 10),
        _ingredientAmountField(),
        _appProvidedGuide(context),
        const SizedBox(height: 20),
        CustomTextFormField(
          label: AppStrings.memo.tr,
          maxLine: 2,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          controller: controller.memoTextCtl,
        ),
        const SizedBox(height: 20),
        _priceGuide(context),
      ],
    );
  }

  Widget _appProvidedGuide(BuildContext context) {
    return Obx(
      () =>
          controller.isAppProvidedProductSelected
              ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.appProvidedUnitFixedGuide.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _priceGuide(BuildContext context) {
    return Obx(
      () =>
          controller.hasPrice == false
              ? Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(text: '${AppStrings.priceNotRegistered.tr}\n'),
                    TextSpan(text: AppStrings.recipePriceGuide.tr),
                  ],
                ),
              )
              : const SizedBox(),
    );
  }

  Widget _submitButton() {
    final label =
        widget.initialIngredient == null
            ? AppStrings.addIngredient.tr
            : AppStrings.ingredientEdit.tr;
    return InkWell(
      onTap: _add,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _ingredientAmountField() {
    return SizedBox(
      height: UiConstants.formFieldHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
          border: Border.all(color: AppColors.borderColor),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller.amountTextCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(fontSize: UiConstants.formFieldFontSize),
                decoration: InputDecoration(
                  label: Text(AppStrings.quantity.tr),
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Obx(
                () => _ingredientUnitDropdown(
                  enabled: !controller.isAppProvidedProductSelected,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  DropdownButton2<IngredientUnit> _ingredientUnitDropdown({
    required bool enabled,
  }) {
    return DropdownButton2(
      buttonStyleData: AppDropdownStyles.dropdown2ButtonStyle(),
      dropdownStyleData: AppDropdownStyles.dropdown2MenuStyle(context),
      menuItemStyleData: AppDropdownStyles.dropdown2ItemStyle(),
      underline: const SizedBox(),
      isExpanded: true,
      value: controller.ingredientUnit.value,
      onChanged: enabled ? controller.onChangeUnit : null,
      items:
          IngredientUnit.values
              .map(
                (unit) => DropdownMenuItem(
                  value: unit,
                  child: Text(
                    unit.displayName,
                    style: TextStyle(fontSize: UiConstants.formFieldFontSize),
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  void dispose() {
    Get.delete<RecipeIngredientInputController>(
      tag: _controllerTag,
    );
    super.dispose();
  }
}

class _IngredientNameField extends StatelessWidget {
  const _IngredientNameField({
    required this.selectedIngredientNameRx,
    required this.onTapField,
  });

  final RxnString selectedIngredientNameRx;
  final VoidCallback onTapField;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: UiConstants.formFieldHeight,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
        onTap: onTapField,
        child: Obx(
          () => InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              constraints: const BoxConstraints(
                minHeight: UiConstants.formFieldHeight,
                maxHeight: UiConstants.formFieldHeight,
              ),
              labelText: AppStrings.ingredientName.tr,
              filled: true,
              hintStyle: TextStyle(color: Colors.grey),
              hintText: AppStrings.ingredientSearchHint.tr,
              labelStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              floatingLabelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              fillColor: Theme.of(context).colorScheme.surface,
              border: AppInputBorders.normal(),
              enabledBorder: AppInputBorders.normal(),
              focusedBorder: AppInputBorders.focused(),
              prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 13),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              selectedIngredientNameRx.value ??
                  AppStrings.ingredientSearchHint.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color:
                    selectedIngredientNameRx.value == null
                        ? Colors.grey.shade600
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

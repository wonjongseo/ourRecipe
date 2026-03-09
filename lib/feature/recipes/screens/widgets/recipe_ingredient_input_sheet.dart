import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_ingredient_input_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
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

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      RecipeIngredientInputController(
        Get.find<IngredientProductRepository>(),
        initialIngredient: widget.initialIngredient,
      ),
      tag: '${runtimeType}_${identityHashCode(this)}',
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
    final selected = await showModalBottomSheet<IngredientProductModel>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => IngredientProductPickerSheet(
            filterGroups: controller.filterGroupedProducts,
            onTapManage: _goToIngredientManagementScreen,
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
      height: size.height * .6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Column(
            children: [
              _IngredientNameField(
                selectedIngredientNameRx: controller.selectedIngredientName,
                onTapField: _showIngredientPickerSheet,
                onTapManage: _goToIngredientManagementScreen,
              ),
              const SizedBox(height: 10),
              _ingredientAmountField(),
              const SizedBox(height: 20),
              CustomTextFormField(
                label: AppStrings.memo.tr,
                maxLine: 2,
                textInputAction: TextInputAction.newline,
                controller: controller.memoTextCtl,
              ),
              const SizedBox(height: 20),
              Obx(
                () =>
                    controller.hasPrice == false
                        ? Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                            ),

                            children: [
                              TextSpan(text: '재품의 가격이 등록되어있지 않습니다.\n'),
                              TextSpan(
                                text:
                                    '재품의 가격을 등록하면 레시피에 들어가는 총 가격을 확인할 수 있습니다.',
                              ),
                            ],
                          ),
                        )
                        : SizedBox(),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
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
                widget.initialIngredient == null
                    ? AppStrings.addIngredient.tr
                    : '재료 수정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
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
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(flex: 2, child: Obx(() => _ingredientUnitDropdown())),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  DropdownButton2<IngredientUnit> _ingredientUnitDropdown() {
    return DropdownButton2(
      buttonStyleData: ButtonStyleData(height: UiConstants.formFieldHeight),
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
        ),
      ),
      underline: const SizedBox(),
      isExpanded: true,
      value: controller.ingredientUnit.value,
      onChanged: controller.onChangeUnit,
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
      tag: '${runtimeType}_${identityHashCode(this)}',
    );
    super.dispose();
  }
}

class _IngredientNameField extends StatelessWidget {
  const _IngredientNameField({
    required this.selectedIngredientNameRx,
    required this.onTapField,
    required this.onTapManage,
  });

  final RxnString selectedIngredientNameRx;
  final VoidCallback onTapField;
  final VoidCallback onTapManage;

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
              hintText: '재료명을 검색해주세요',
              fillColor: Theme.of(context).colorScheme.surface,

              border: AppInputBorders.normal(),
              enabledBorder: AppInputBorders.normal(),
              focusedBorder: AppInputBorders.focused(),
              prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 13),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onTapManage,
                    icon: const Icon(Icons.settings_outlined, size: 18),
                  ),
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            child: Text(
              selectedIngredientNameRx.value ?? '재료명을 검색해주세요',
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

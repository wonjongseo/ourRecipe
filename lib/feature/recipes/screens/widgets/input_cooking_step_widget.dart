import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_dropdown_styles.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:uuid/uuid.dart';

class InputCookingStepWidget extends StatefulWidget {
  const InputCookingStepWidget({super.key});

  @override
  State<InputCookingStepWidget> createState() => _InputCookingStepWidgetState();
}

class _InputCookingStepWidgetState extends State<InputCookingStepWidget> {
  final nameTextCtl = TextEditingController();
  final amountTextCtl = TextEditingController();
  IngredientUnit ingredientUnit = IngredientUnit.gram;

  final memoTextCtl = TextEditingController();
  IngredientUnit productIngredientUnit = IngredientUnit.gram;
  final priceTextCtl = TextEditingController();
  final productAmountTextCtl = TextEditingController();

  void onChangeUnit(IngredientUnit? unit) {
    if (unit == null) return;
    if (ingredientUnit == unit) return;
    setState(() {
      ingredientUnit = unit;
    });
  }

  void onChangeProductUnit(IngredientUnit? unit) {
    if (unit == null) return;
    if (productIngredientUnit == unit) return;
    setState(() {
      productIngredientUnit = unit;
    });
  }

  @override
  void dispose() {
    nameTextCtl.dispose();
    amountTextCtl.dispose();
    memoTextCtl.dispose();
    priceTextCtl.dispose();
    productAmountTextCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height * .6,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    CustomTextFormField(
                      label: AppStrings.name.tr,
                      controller: nameTextCtl,
                    ),
                    SizedBox(height: 10),
                    _inputIngredientAmount(onChangeUnit, amountTextCtl),
                    SizedBox(height: 10),
                    CustomTextFormField(
                      label: AppStrings.memo.tr,
                      maxLine: 2,
                      textInputAction: TextInputAction.newline,
                      controller: memoTextCtl,
                    ),
                  ],
                ),

                _inputProduct(),
              ],
            ),
          ),

          InkWell(
            onTap: _add,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(
                  UiConstants.formFieldRadius,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                AppStrings.addIngredient.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _add() {
    final name = nameTextCtl.text.trim();
    if (name.isEmpty) {
      SnackBarHelper.showErrorSnackBar(AppStrings.ingredientNameRequired.tr);
      return;
    }
    final amount = amountTextCtl.text.trim();
    double? amountAsNum = double.tryParse(amount);
    if (amountAsNum == null) {
      SnackBarHelper.showErrorSnackBar(AppStrings.ingredientAmountRequired.tr);
      return;
    }
    final memo = memoTextCtl.text.trim();
    final price = priceTextCtl.text.trim();
    final priceAsNum = double.tryParse(price);
    final productAmount = productAmountTextCtl.text.trim();
    final productAmountAsNum = double.tryParse(productAmount);

    final ingredientModel = IngredientModel(
      id: Uuid().v4(),
      name: name,
      amount: amountAsNum,
      unit: ingredientUnit,
      memo: memo,
      price: priceAsNum,
      productAmount: productAmountAsNum,
    );

    Get.back(result: ingredientModel);
  }

  Widget _inputProduct() {
    const double inputHeight = 48;
    return Column(
      children: [
        Text(
          AppStrings.recipePriceGuide.tr,
          style: TextStyle(fontSize: 13, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(height: inputHeight, child: _inputPrice()),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: inputHeight,
                child: _inputIngredientAmount(
                  onChangeProductUnit,
                  productAmountTextCtl,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Container _inputIngredientAmount(
    Function(IngredientUnit?) onChanged,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _ingredientUnitDropdown(onChanged)),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _inputPrice() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiConstants.formFieldRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TextFormField(
        controller: priceTextCtl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey),
          hintText: AppStrings.price.tr,
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }

  DropdownButton2<IngredientUnit> _ingredientUnitDropdown(
    Function(IngredientUnit?) onChanged,
  ) {
    return DropdownButton2(
      buttonStyleData: AppDropdownStyles.dropdown2ButtonStyle(),
      dropdownStyleData: AppDropdownStyles.dropdown2MenuStyle(context),
      menuItemStyleData: AppDropdownStyles.dropdown2ItemStyle(),
      underline: SizedBox(),
      isExpanded: true,
      value: productIngredientUnit,
      onChanged: onChanged,
      items: List.generate(IngredientUnit.values.length, (i) {
        final unit = IngredientUnit.values[i];
        return DropdownMenuItem(
          value: unit,
          child: Text(
            unit.displayName,
            style: TextStyle(fontSize: UiConstants.formFieldFontSize),
          ),
        );
      }),
    );
  }
}

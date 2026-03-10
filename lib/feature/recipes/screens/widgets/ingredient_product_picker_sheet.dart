import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_input_borders.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/ingredient_product_grouped_expansion_list.dart';

class IngredientProductPickerSheet extends StatefulWidget {
  const IngredientProductPickerSheet({
    super.key,
    required this.filterGroups,
    this.onTapManage,
    this.selectedProductId,
  });

  final List<IngredientProductGroup> Function(String query) filterGroups;
  final Future<void> Function()? onTapManage;
  final String? selectedProductId;

  @override
  State<IngredientProductPickerSheet> createState() =>
      _IngredientProductPickerSheetState();
}

class _IngredientProductPickerSheetState
    extends State<IngredientProductPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    debugPrint('Called IngredientProductPickerSheet');
    final filteredGroups = widget.filterGroups(query);
    final appProvidedGroups =
        filteredGroups
            .where((group) => !group.id.startsWith('custom_'))
            .toList();
    final userAddedGroups =
        filteredGroups
            .where((group) => group.id.startsWith('custom_'))
            .toList();

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(FontAwesomeIcons.xmark),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Get.back();
                      await widget.onTapManage?.call();
                    },
                    label: Text(AppStrings.ingredientManageScreen.tr),
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
            ),

            SizedBox(height: 18),
            _searchForm(context),
            SizedBox(height: 6),
            Expanded(
              child:
                  filteredGroups.isEmpty
                      ? _emptyForSearch(context)
                      : _filteredIngredient(
                        context,
                        appProvidedGroups,
                        userAddedGroups,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  ListView _filteredIngredient(
    BuildContext context,
    List<IngredientProductGroup> appProvidedGroups,
    List<IngredientProductGroup> userAddedGroups,
  ) {
    return ListView(
      // padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      padding: EdgeInsets.symmetric(horizontal: 12),
      children: [
        _appDataOrUserData(
          context,
          AppStrings.appProvidedIngredients.tr,
          AppStrings.nutritionPer100gGuide.tr,
        ),
        SizedBox(height: 4),

        if (appProvidedGroups.isEmpty)
          _sectionEmpty(context)
        else
          IngredientProductGroupedExpansionList(
            groups: appProvidedGroups,
            query: query,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            selectedProductId: widget.selectedProductId,
            onTapProduct: (product) {
              Navigator.of(context).pop(product);
            },
          ),

        const SizedBox(height: 16),
        _appDataOrUserData(context, AppStrings.userAddedIngredients.tr, null),
        if (userAddedGroups.isEmpty)
          _sectionEmpty(context)
        else
          IngredientProductGroupedExpansionList(
            groups: userAddedGroups,
            query: query,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            selectedProductId: widget.selectedProductId,
            onTapProduct: (product) {
              Navigator.of(context).pop(product);
            },
          ),
      ],
    );
  }

  Padding _searchForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextFormField(
        autofocus: true,
        onChanged: (value) {
          setState(() {
            query = value.trim();
          });
        },
        decoration: InputDecoration(
          isDense: true,
          constraints: const BoxConstraints(
            minHeight: UiConstants.formFieldHeight,
            maxHeight: UiConstants.formFieldHeight,
          ),
          labelText: AppStrings.ingredientName.tr,
          filled: true,
          hintText: AppStrings.search.tr,
          fillColor: Theme.of(context).colorScheme.surface,
          hintStyle: TextStyle(color: Colors.grey),
          border: AppInputBorders.normal(),
          enabledBorder: AppInputBorders.normal(),
          focusedBorder: AppInputBorders.focused(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 13),
        ),
      ),
    );
  }

  Padding _appDataOrUserData(
    BuildContext context,
    String appOrData,
    String? description,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appOrData,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (description != null)
            Text(
              description,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        AppStrings.noRegisteredIngredient.tr,
        style: TextStyle(color: AppColors.noRegisteredItemColor),
      ),
    );
  }

  Widget _emptyForSearch(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.search_off_rounded, size: 28, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          Text(
            AppStrings.noRegisteredIngredient.tr,
            style: TextStyle(color: AppColors.noRegisteredItemColor),
          ),

          // if (widget.onTapManage != null) ...[
          //   const SizedBox(height: 4),
          //   ElevatedButton.icon(
          //     onPressed: () async {
          //       Navigator.of(context).pop();
          //       await widget.onTapManage?.call();
          //     },
          //     label: Text(AppStrings.ingredientManagement.tr),
          //     icon: const Icon(Icons.arrow_forward_ios_rounded),
          //   ),
          // ],
        ],
      ),
    );
  }
}

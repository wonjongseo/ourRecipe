import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/app_refresh_indicator.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/custom_search_bar.dart';

class RecipesScreen extends GetView<RecipeController> {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        bottomNavigationBar: const AdBannerBottomSheet(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.goToEditScreen(),
          child: Icon(Icons.add),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: AppBar(
            backgroundColor:
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            centerTitle: true,
            title: Text(
              AppStrings.recipe.tr,
              style: TextStyle(
                color:
                    Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ).copyWith(bottom: 20),
                child: Obx(
                  () => CustomSearchBar(
                    controller: controller.searchTextCtrl,
                    onChanged: controller.onChanged,
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 20,
                    ),
                    suffixIcon:
                        controller.searchQuery.isEmpty
                            ? null
                            : IconButton(
                              onPressed: () => controller.clearQuery(),
                              icon: Icon(FontAwesomeIcons.xmark),
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Obx(
            () =>
                controller.isLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Obx(() => _filterChips()),
                          ),

                          SizedBox(height: 10),
                          Obx(
                            () => Expanded(
                              child:
                                  controller.recipes.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '등록된 레시피가 없습니다',
                                              style: TextStyle(
                                                color:
                                                    AppColors.noRegisteredItemColor,
                                              ),
                                            ),
                                            if (controller.isICloudSyncEnabled) ...[
                                              const SizedBox(height: 16),
                                              OutlinedButton.icon(
                                                onPressed: controller.downloadFromICloud,
                                                icon: const Icon(Icons.sync_rounded),
                                                label: Text(
                                                  AppStrings.downloadFromICloud.tr,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                      : AppRefreshIndicator(
                                        onRefresh: controller.reloadAll,
                                        child: ListView.separated(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          separatorBuilder:
                                              (context, index) =>
                                                  SizedBox(height: 12),
                                          shrinkWrap: false,
                                          itemCount: controller.recipes.length,
                                          itemBuilder: (context, index) {
                                            final recipe =
                                                controller.recipes[index];

                                            return recipeListTIle(recipe);
                                          },
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final selected = controller.selectedFilter.value;
    final chips = <Widget>[
      _filterChip(
        label: AppStrings.all.tr,
        selected: selected == const RecipeFilter.all(),
        onTap: () => controller.onChangeFilter(const RecipeFilter.all()),
      ),
      _filterChip(
        label: AppStrings.favorite.tr,
        selected: selected == const RecipeFilter.favorite(),
        onTap: () => controller.onChangeFilter(const RecipeFilter.favorite()),
      ),
      ...controller.categories.map((category) {
        final filter = RecipeFilter.category(category);
        return _filterChip(
          label: category,
          selected: selected == filter,
          onTap: () => controller.onChangeFilter(filter),
        );
      }),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color:
                selected
                    ? AppColors.primaryColor
                    : Get.theme.colorScheme.surface,
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Get.theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget recipeListTIle(RecipeModel recipe) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final coverPath = recipe.coverImagePath;
    final hasValidCoverImage =
        coverPath != null &&
        coverPath.isNotEmpty &&
        File(coverPath).existsSync() &&
        File(coverPath).lengthSync() > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => controller.goToDetailScreen(recipe),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.10),
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Hero(
                  tag: recipe.id,
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image:
                          !hasValidCoverImage
                              ? null
                              : DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(File(coverPath!)),
                              ),
                    ),
                    child:
                        !hasValidCoverImage
                            ? Icon(FontAwesomeIcons.utensils)
                            : null,
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(recipe.name),
                    SizedBox(height: 2),
                    Text(recipe.description, style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          recipe.category.isEmpty ? '-' : recipe.category,
                          style: TextStyle(fontSize: 11),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${recipe.ingredientCostTotal.toStringAsFixed(0)}${AppStrings.won.tr}',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () => controller.toggleBookmark(recipe.id),
              icon: Icon(
                recipe.isLiked
                    ? FontAwesomeIcons.solidBookmark
                    : FontAwesomeIcons.bookmark,
                size: 20,
                color: recipe.isLiked ? AppColors.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

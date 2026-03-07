import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/custom_search_bar.dart';

class RecipesScreen extends GetView<RecipeController> {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: TextButton.icon(
        onPressed: () => controller.goToEditScreen(),
        icon: Icon(Icons.add),
        label: Text(AppStrings.addRecipe.tr),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          centerTitle: true,
          title: Text(AppStrings.recipe.tr),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSearchBar(
                onChanged: controller.onChanged,
                prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 20),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          child: Column(
            children: [
              SizedBox(height: 20),
              Obx(
                () => Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    shrinkWrap: false,
                    itemCount: controller.recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = controller.recipes[index];

                      return recipeListTIle(recipe);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget recipeListTIle(RecipeModel recipe) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => controller.goToDetailScreen(recipe),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
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
                          recipe.coverImagePath == null
                              ? null
                              : DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(File(recipe.coverImagePath!)),
                              ),
                    ),
                    child:
                        recipe.coverImagePath == null
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
                          recipe.category.displayName.tr,
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
              onPressed: () => controller.toggleLike(recipe.id),
              icon: Icon(
                recipe.isLiked
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                size: 20,
                color: recipe.isLiked ? Colors.pinkAccent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

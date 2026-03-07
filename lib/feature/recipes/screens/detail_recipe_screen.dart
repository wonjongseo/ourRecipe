import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_unit.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';

class DetailRecipeScreen extends GetView<RecipeController> {
  const DetailRecipeScreen({super.key, required this.recipeModel});
  static String name = '/detail_recipe';

  final RecipeModel recipeModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  recipeModel.coverImagePath == null
                      ? null
                      : Hero(
                        tag: recipeModel.id,
                        child: Image.file(
                          File(recipeModel.coverImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeModel.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  SizedBox(height: 12),
                  Text(recipeModel.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 30),
                  _titleAndContent(
                    title: '재료',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(recipeModel.ingredients.length, (
                        index,
                      ) {
                        final ingredient = recipeModel.ingredients[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(ingredient.name),
                                ],
                              ),
                              Text(
                                '${ingredient.amount} ${ingredient.unit.displayName}',
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: 30),
                  _titleAndContent(
                    title: '조리 방법',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(recipeModel.steps.length, (
                        index,
                      ) {
                        final step = recipeModel.steps[index];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              SizedBox(height: 6),
                              Text(step.instruction),
                              SizedBox(height: 12),
                              if (step.imagePath != null)
                                Image.file(File(step.imagePath!)),
                              SizedBox(height: 12),
                              Divider(),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column _titleAndContent({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(blurRadius: 1, color: Colors.grey)],
            color: Colors.white,
          ),
          padding: EdgeInsets.all(16),
          child: content,
        ),
      ],
    );
  }
}

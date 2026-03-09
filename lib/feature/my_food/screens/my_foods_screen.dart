import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';

class MyFoodsScreen extends StatelessWidget {
  const MyFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(child: Text(AppStrings.myFood.tr));
  }
}

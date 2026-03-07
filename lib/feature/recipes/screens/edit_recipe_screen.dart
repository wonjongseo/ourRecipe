import 'package:flutter/material.dart';

class EditRecipeScreen extends StatelessWidget {
  const EditRecipeScreen({super.key});
  static String name = '/edit_recipe';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text("Add")],
          ),
        ),
      ),
    );
  }
}

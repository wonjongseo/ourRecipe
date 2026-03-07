import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 10,
          right: 10,
          child: TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add),
            label: Text("레시피 추가"),
          ),
        ),
      ],
    );
  }
}

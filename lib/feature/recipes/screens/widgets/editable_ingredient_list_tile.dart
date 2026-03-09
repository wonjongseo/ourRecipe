import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_model.dart';

class EditableIngredientListTile extends StatelessWidget {
  const EditableIngredientListTile({
    super.key,
    required this.ingredient,
    required this.index,
    required this.onDelete,
    required this.onTap,
  });
  final IngredientModel ingredient;
  final int index;
  final Function(int) onDelete;
  final Function(int) onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTap(index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
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
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}'),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ingredient.name, style: TextStyle(fontSize: 13)),
                      Row(
                        children: [
                          Text(
                            '${ingredient.amount}',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(width: 4),
                          Text(
                            ingredient.unit.name,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onDelete(index),
                    icon: Icon(
                      FontAwesomeIcons.circleMinus,
                      size: 20,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_scale.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';

class IngredientProductGroupedExpansionList extends StatelessWidget {
  const IngredientProductGroupedExpansionList({
    super.key,
    required this.groups,
    required this.onTapProduct,
    this.query = '',
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 16),
    this.subtitleBuilder,
    this.trailingBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.selectedProductId,
  });

  final List<IngredientProductGroup> groups;
  final String query;
  final EdgeInsetsGeometry padding;
  final String? Function(IngredientProductModel product)? subtitleBuilder;
  final Widget? Function(IngredientProductModel product)? trailingBuilder;
  final void Function(IngredientProductModel product) onTapProduct;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? selectedProductId;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.55);
    final languageCode = Get.locale?.languageCode ?? 'ja';
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        final totalProducts = group.items.fold<int>(0, (sum, item) {
          return sum + item.products.length;
        });
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ExpansionTile(
            key: ValueKey('group_${group.id}_$query'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            initiallyExpanded: query.isNotEmpty,
            leading: Icon(
              Icons.folder_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              IngredientCategoryCatalog.displayName(group.name, languageCode),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '$totalProducts',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: AppScale.text(11),
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children:
                group.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(left: 8, right: 4, bottom: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: ExpansionTile(
                      key: ValueKey('item_${item.id}_$query'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      initiallyExpanded: query.isNotEmpty,
                      leading: Icon(
                        Icons.label_outline_rounded,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      title: Text(
                        IngredientCategoryCatalog.displayName(
                          item.name,
                          languageCode,
                        ),
                        style: TextStyle(fontSize: AppScale.text(13)),
                      ),
                      subtitle: Text(
                        '${item.products.length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: AppScale.text(11),
                        ),
                      ),
                      children:
                          item.products.map((product) {
                            final subtitle = subtitleBuilder?.call(product);
                            final isSelected = selectedProductId == product.id;
                            final itemDisplayName =
                                IngredientCategoryCatalog.displayName(
                                  item.name,
                                  languageCode,
                                );
                            return ListTile(
                              dense: true,
                              tileColor:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.10)
                                      : null,
                              contentPadding: const EdgeInsets.only(
                                left: 44,
                                right: 12,
                              ),
                              title: Text(
                                product.name,
                                style: TextStyle(fontSize: AppScale.text(13)),
                              ),
                              subtitle:
                                  subtitle == null ? null : Text(subtitle),
                              trailing:
                                  trailingBuilder?.call(product) ??
                                  (isSelected
                                      ? Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      )
                                      : const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                      )),
                              onTap:
                                  () => onTapProduct(
                                    product.copyWith(
                                      name: _selectedDisplayName(
                                        itemName: itemDisplayName,
                                        productName: product.name,
                                      ),
                                    ),
                                  ),
                            );
                          }).toList(),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  String _selectedDisplayName({
    required String itemName,
    required String productName,
  }) {
    final normalizedItemName = itemName.trim();
    final normalizedProductName = productName.trim();
    if (normalizedItemName.isEmpty || normalizedProductName.isEmpty) {
      return normalizedProductName;
    }
    if (normalizedProductName.startsWith(normalizedItemName)) {
      return normalizedProductName;
    }
    return '$normalizedItemName $normalizedProductName';
  }
}

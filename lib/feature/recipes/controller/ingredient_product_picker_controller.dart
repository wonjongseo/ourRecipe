import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';

class IngredientProductPickerController extends GetxController {
  IngredientProductPickerController({
    required List<IngredientProductGroup> Function(String query) filterGroups,
  }) : _filterGroups = filterGroups;

  final List<IngredientProductGroup> Function(String query) _filterGroups;

  final query = ''.obs;

  List<IngredientProductGroup> get filteredGroups {
    return _filterGroups(query.value);
  }

  List<IngredientProductGroup> get appProvidedGroups {
    return filteredGroups
        .where((group) => !group.id.startsWith('custom_'))
        .toList(growable: false);
  }

  List<IngredientProductGroup> get userAddedGroups {
    return filteredGroups
        .where((group) => group.id.startsWith('custom_'))
        .toList(growable: false);
  }

  bool get hasFilteredGroups => filteredGroups.isNotEmpty;

  void updateQuery(String value) {
    query.value = value.trim();
  }
}

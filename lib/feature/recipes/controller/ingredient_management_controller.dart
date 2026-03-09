import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_edit_screen.dart';

class IngredientManagementController extends GetxController {
  IngredientManagementController(this._repository);
  final IngredientProductRepository _repository;

  final groupedProducts = <IngredientProductGroup>[].obs;
  List<IngredientProductGroup> get appProvidedGroups =>
      groupedProducts
          .where((group) => !group.id.startsWith('custom_'))
          .toList();
  List<IngredientProductGroup> get userAddedGroups =>
      groupedProducts
          .where((group) => group.id.startsWith('custom_'))
          .toList();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final values = await _repository.fetchGroupedProducts();
    groupedProducts.assignAll(values);
  }

  Future<void> goToEdit({IngredientProductModel? product}) async {
    final changed = await Get.toNamed(
      IngredientEditScreen.name,
      arguments: product,
    );
    if (changed == true) {
      await loadProducts();
    }
  }
}

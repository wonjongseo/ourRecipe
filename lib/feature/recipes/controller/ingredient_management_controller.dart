import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_edit_screen.dart';

class IngredientManagementController extends GetxController {
  IngredientManagementController(this._repository);

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final IngredientProductRepository _repository;
  final ICloudSyncService _iCloudSync = ICloudSyncService();

  final groupedProducts = <IngredientProductGroup>[].obs;
  List<IngredientProductGroup> get appProvidedGroups =>
      groupedProducts
          .where((group) => !group.id.startsWith('custom_'))
          .toList();
  List<IngredientProductGroup> get userAddedGroups =>
      groupedProducts.where((group) => group.id.startsWith('custom_')).toList();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      _isLoading.value = true;
      await _syncFromICloudIfEnabled();
      final values = await _repository.fetchGroupedProducts();
      groupedProducts.assignAll(values);
    } catch (e) {
      LogManager.error('$e');
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      _isLoading.value = false;
    }
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

  Future<void> _syncFromICloudIfEnabled() async {
    await _iCloudSync.pullIfEnabled();
  }
}

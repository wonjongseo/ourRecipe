import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:our_recipe/feature/home/controller/home_controller.dart';
import 'package:our_recipe/feature/home/screens/home_screen.dart';
import 'package:our_recipe/feature/recipes/controller/edit_recipe_controller.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_category_management_controller.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_edit_controller.dart';
import 'package:our_recipe/feature/recipes/controller/ingredient_management_controller.dart';
import 'package:our_recipe/feature/recipes/controller/recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/cook_log_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/recipes/screens/category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/detail_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/edit_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_category_management_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_edit_screen.dart';
import 'package:our_recipe/feature/recipes/screens/ingredient_management_screen.dart';
import 'package:our_recipe/feature/my_page/controller/my_page_controller.dart';
import 'package:our_recipe/feature/my_page/screens/icloud_sync_settings_screen.dart';
import 'package:our_recipe/feature/my_page/screens/premium_purchase_screen.dart';
import 'package:our_recipe/feature/splash/controller/splash_controller.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';
import 'package:our_recipe/feature/start_cooking/controller/start_cooking_controller.dart';
import 'package:our_recipe/feature/start_cooking/screen/start_cooking_screen.dart';
import 'package:our_recipe/core/services/premium_service.dart';

class AppPages {
  const AppPages._();
  static List<GetPage> pages = [
    GetPage(
      name: SplashScreen.name,
      page: () => SplashScreen(),
      binding: BindingsBuilder.put(() => SplashController()),
    ),
    GetPage(
      name: HomeScreen.name,
      page: () => HomeScreen(),
      binding: BindingsBuilder.put(() {
        final homeController = HomeController();
        if (!Get.isRegistered<MyPageController>()) {
          Get.put(RecipeRepository());
          Get.put(RecipeCategoryRepository());
          Get.put(CookLogRepository());
          Get.put(IngredientProductRepository());
          Get.put(IngredientCategoryRepository());
          Get.put(PremiumService(), permanent: true);
          Get.put(RecipeController(Get.find(), Get.find()));
          Get.put(MyPageController(), permanent: true);
        }
        return homeController;
      }),
    ),
    GetPage(
      name: EditRecipeScreen.name,
      page: () => EditRecipeScreen(),
      binding: BindingsBuilder.put(() {
        final recipeModel = Get.arguments as RecipeModel?;
        return EditRecipeController(
          recipeModel,
          Get.find<RecipeCategoryRepository>(),
          Get.find<IngredientProductRepository>(),
        );
      }),
    ),
    GetPage(
      name: DetailRecipeScreen.name,
      page: () {
        final recipeModel = Get.arguments as RecipeModel;
        return DetailRecipeScreen(recipeModel: recipeModel);
      },
    ),
    GetPage(
      name: CategoryManagementScreen.name,
      page: () {
        final isCameToEditRecipeScreen = Get.arguments as bool;
        return CategoryManagementScreen(
          isCameToEditRecipeScreen: isCameToEditRecipeScreen,
        );
      },
    ),
    GetPage(
      name: IngredientManagementScreen.name,
      page: () => const IngredientManagementScreen(),
      binding: BindingsBuilder.put(
        () => IngredientManagementController(
          Get.find<IngredientProductRepository>(),
        ),
      ),
    ),
    GetPage(
      name: IngredientEditScreen.name,
      page: () => const IngredientEditScreen(),
      binding: BindingsBuilder.put(() {
        final product = Get.arguments as IngredientProductModel?;
        return IngredientEditController(
          product,
          Get.find<IngredientProductRepository>(),
          Get.find<IngredientCategoryRepository>(),
        );
      }),
    ),
    GetPage(
      name: IngredientCategoryManagementScreen.name,
      page: () => const IngredientCategoryManagementScreen(),
      binding: BindingsBuilder.put(
        () => IngredientCategoryManagementController(
          Get.find<IngredientCategoryRepository>(),
        ),
      ),
    ),
    GetPage(
      name: StartCookingScreen.name,
      page: () => StartCookingScreen(),
      binding: BindingsBuilder.put(() {
        final recipeModel = Get.arguments as RecipeModel;
        return StartCookingController(recipeModel);
      }),
    ),
    GetPage(
      name: ICloudSyncSettingsScreen.name,
      page: () => const ICloudSyncSettingsScreen(),
    ),
    GetPage(
      name: PremiumPurchaseScreen.name,
      page: () => const PremiumPurchaseScreen(),
    ),
  ];
}

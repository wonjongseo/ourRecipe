import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:our_recipe/feature/home/controller/home_controller.dart';
import 'package:our_recipe/feature/home/screens/home_screen.dart';
import 'package:our_recipe/feature/recipes/controller/edit_recipe_controller.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/screens/detail_recipe_screen.dart';
import 'package:our_recipe/feature/recipes/screens/edit_recipe_screen.dart';
import 'package:our_recipe/feature/splash/controller/splash_controller.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';

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
      binding: BindingsBuilder.put(() => HomeController()),
    ),
    GetPage(
      name: EditRecipeScreen.name,
      page: () => EditRecipeScreen(),
      binding: BindingsBuilder.put(() {
        final recipeModel = Get.arguments as RecipeModel?;
        return EditRecipeController(recipeModel);
      }),
    ),
    GetPage(
      name: DetailRecipeScreen.name,
      page: () {
        final recipeModel = Get.arguments as RecipeModel;
        return DetailRecipeScreen(recipeModel: recipeModel);
      },
    ),
  ];
}

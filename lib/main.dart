import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:our_recipe/core/pages/app_pages.dart';
import 'package:our_recipe/feature/splash/screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Our Recipe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      getPages: AppPages.pages,
      initialRoute: SplashScreen.name,
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/my_page/controller/my_page_controller.dart';

class MyPageScreen extends GetView<MyPageController> {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).colorScheme.outline;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondartColor,
        centerTitle: true,
        title: Text(
          AppStrings.myPage.tr,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (kDebugMode)
              ListTile(
                tileColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                leading: const Icon(Icons.language_outlined),
                title: Text(AppStrings.language.tr),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: controller.currentLocale(),
                    items: [
                      DropdownMenuItem(
                        value: Locale('ja', 'JP'),
                        child: Text(AppStrings.languageJapanese.tr),
                      ),
                      DropdownMenuItem(
                        value: Locale('ko', 'KR'),
                        child: Text(AppStrings.languageKorean.tr),
                      ),
                      DropdownMenuItem(
                        value: Locale('en', 'US'),
                        child: Text(AppStrings.languageEnglish.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      controller.changeLanguage(value);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Obx(
              () => ListTile(
                tileColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(AppStrings.theme.tr),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: controller.themeMode.value,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(AppStrings.systemMode.tr),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(AppStrings.lightMode.tr),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(AppStrings.darkMode.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      controller.changeThemeMode(value);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => ListTile(
                tileColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                leading: const Icon(Icons.font_download_outlined),
                title: Text(AppStrings.font.tr),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.fontKey.value,
                    items:
                        AppFonts.options
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option.key,
                                child: Text(option.labelKey.tr),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      controller.changeFont(value);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_size_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.fontSize.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(controller.textScale.value * 100).round()}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: controller.textScale.value,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (value) => controller.changeTextScale(value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              leading: const Icon(Icons.category_outlined),
              title: Text(AppStrings.categoryManagement.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.goToCategoryManagement,
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(AppStrings.ingredientManagement.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.goToIngredientManagement,
            ),
          ],
        ),
      ),
    );
  }
}

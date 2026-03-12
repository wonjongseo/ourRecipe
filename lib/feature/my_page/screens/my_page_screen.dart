import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/ui_constants.dart';
import 'package:our_recipe/feature/my_page/controller/my_page_controller.dart';

class MyPageScreen extends GetView<MyPageController> {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).colorScheme.outline;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.myPage.tr,
          style: TextStyle(
            color:
                Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _settingsManagement(cardColor, borderColor),
            const SizedBox(height: 24),
            _settingsGeneral(cardColor, borderColor, context),
            const SizedBox(height: 24),
            _settingsSupport(cardColor, borderColor),
            const SizedBox(height: 24),
            _settingsAppearance(cardColor, borderColor, context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Column _settingsManagement(Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.settingsManagement.tr),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(AppStrings.categoryManagement.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.goToCategoryManagement,
          ),
        ),
        const SizedBox(height: 8),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(AppStrings.ingredientManagement.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.goToIngredientManagement,
          ),
        ),
      ],
    );
  }

  Column _settingsAppearance(
    Color cardColor,
    Color borderColor,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.settingsAppearance.tr),
        Obx(
          () => _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(AppStrings.theme.tr),
              trailing: _styledDropdown(
                context: context,
                child: DropdownButton<ThemeMode>(
                  value: controller.themeMode.value,
                  isDense: true,
                  borderRadius: BorderRadius.circular(
                    UiConstants.formFieldRadius,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
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
        ),
        const SizedBox(height: 8),
        Obx(
          () => _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: ListTile(
              leading: const Icon(Icons.font_download_outlined),
              title: Text(AppStrings.font.tr),
              trailing: _styledDropdown(
                context: context,
                child: DropdownButton<String>(
                  value: controller.selectedFontKeyForCurrentLocale(),
                  isDense: true,
                  borderRadius: BorderRadius.circular(
                    UiConstants.formFieldRadius,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items:
                      controller
                          .fontOptionsForCurrentLocale()
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.key,
                              child: Text(option.label),
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
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                  onChanged: controller.previewTextScale,
                  onChangeEnd: controller.persistTextScale,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Column _settingsGeneral(
    Color cardColor,
    Color borderColor,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.settingsGeneral.tr),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            onTap: controller.goToICloudSyncSettings,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(AppStrings.iCloudSync.tr),
            subtitle: Text(AppStrings.iCloudSyncDescription.tr),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 8),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(AppStrings.language.tr),
            trailing: _styledDropdown(
              context: context,
              child: DropdownButton<Locale>(
                value: controller.currentLocale(),
                isDense: true,
                borderRadius: BorderRadius.circular(
                  UiConstants.formFieldRadius,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
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
        ),
      ],
    );
  }

  Column _settingsSupport(Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.appInfo.tr),
        Obx(
          () => _card(
            cardColor: cardColor,
            borderColor: borderColor,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppStrings.appVersion.tr),
              trailing: Text(controller.appVersionLabel.value),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: Text(AppStrings.leaveReview.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.openReviewPage,
          ),
        ),
        const SizedBox(height: 8),
        _card(
          cardColor: cardColor,
          borderColor: borderColor,
          child: ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(AppStrings.contactAndBugReport.tr),
            subtitle: Text(MyPageController.supportEmail),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.contactSupport,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _card({
    required Color cardColor,
    required Color borderColor,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _styledDropdown({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      height: UiConstants.formFieldHeight - 10,
      padding: const EdgeInsets.symmetric(horizontal: 10),

      child: DropdownButtonHideUnderline(child: child),
    );
  }
}

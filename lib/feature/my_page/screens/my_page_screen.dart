import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_color_presets.dart';
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
            const SizedBox(height: 8),
            _settingsGeneral(cardColor, borderColor, context),
            const SizedBox(height: 24),
            _settingsManagement(cardColor, borderColor),
            const SizedBox(height: 24),
            _settingsAppearance(cardColor, borderColor, context),
            const SizedBox(height: 24),
            _settingsSupport(cardColor, borderColor),
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
      children: <Widget>[
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
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(AppStrings.colorTheme.tr),
                  trailing: _styledDropdown(
                    context: context,
                    child: DropdownButton<String>(
                      value: controller.colorPresetKey.value,
                      isDense: true,
                      borderRadius: BorderRadius.circular(
                        UiConstants.formFieldRadius,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: controller.colorPresets().map((preset) {
                        return DropdownMenuItem<String>(
                          value: preset.key,
                          child: Text(_colorPresetLabel(preset)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        controller.changeColorPreset(value);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _colorThemePreview(context),
                ),
              ],
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
              subtitle: Text(controller.selectedFontLabelForCurrentLocale()),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.goToFontPreview,
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
              children: <Widget>[
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

  String _colorPresetLabel(AppColorPreset preset) {
    switch (preset.key) {
      case 'sage_kitchen':
        return AppStrings.colorPresetSageKitchen.tr;
      case 'terracotta':
        return AppStrings.colorPresetTerracotta.tr;
      case 'charcoal_mint':
        return AppStrings.colorPresetCharcoalMint.tr;
      case 'ocean_blue':
        return AppStrings.colorPresetOceanBlue.tr;
      case 'warm_ivory':
      default:
        return AppStrings.colorPresetWarmIvory.tr;
    }
  }

  Widget _colorThemePreview(BuildContext context) {
    final preset = AppColorPresets.resolve(controller.colorPresetKey.value);
    final mode = controller.themeMode.value;
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final palette = isDark ? preset.dark : preset.light;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _colorPresetLabel(preset),
                  style: TextStyle(
                    color: palette.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDark ? AppStrings.darkMode.tr : AppStrings.lightMode.tr,
                  style: TextStyle(
                    color: palette.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _swatch(palette.primary, palette.onPrimary),
              const SizedBox(width: 8),
              _swatch(palette.secondary, palette.onSecondary),
              const SizedBox(width: 8),
              _swatch(palette.background, palette.onSurface),
              const SizedBox(width: 8),
              _swatch(palette.surface, palette.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appTitle.tr,
                        style: TextStyle(
                          color: palette.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.recipe.tr,
                        style: TextStyle(
                          color: palette.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: null,
                  child: Text(AppStrings.save.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color color, Color borderColor) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor.withValues(alpha: 0.22)),
      ),
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
        Obx(() {
          final isPremium = controller.premiumService.isPremium.value;
          final canUseICloud = Platform.isIOS && controller.canUseICloud;
          final tiles = <Widget>[];

          if (canUseICloud) {
            tiles.add(
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
            );
          }

          if (!isPremium) {
            if (tiles.isNotEmpty) {
              tiles.add(const SizedBox(height: 8));
            }
            tiles.add(
              _card(
                cardColor: cardColor,
                borderColor: borderColor,
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(AppStrings.premiumPurchase.tr),
                  subtitle: Text(
                    Platform.isIOS
                        ? AppStrings.premiumDescriptionIOS.tr
                        : AppStrings.premiumDescriptionAndroid.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.goToPremiumPurchase,
                ),
              ),
            );
          }

          if (tiles.isNotEmpty) {
            tiles.add(const SizedBox(height: 8));
          }

          tiles.add(
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
          );

          return Column(children: tiles);
        }),
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

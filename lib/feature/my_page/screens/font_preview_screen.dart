import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_fonts.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/feature/my_page/controller/my_page_controller.dart';

class FontPreviewScreen extends GetView<MyPageController> {
  const FontPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = controller.currentLocale();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.font.tr),
      ),
      body: Obx(() {
        final selectedKey = controller.selectedFontKeyForCurrentLocale();
        final options = controller.fontOptionsForCurrentLocale();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option.key == selectedKey;
            final previewTextTheme = AppFonts.textThemeFor(
              fontKey: option.key,
              locale: locale,
              base: Theme.of(context).textTheme,
            );
            final colorScheme = Theme.of(context).colorScheme;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => controller.changeFont(option.key),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? colorScheme.primaryContainer
                          : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.outline,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: previewTextTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.appTitle.tr,
                      style: previewTextTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _sampleText(locale),
                      style: previewTextTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1234567890  ABC abc',
                      style: previewTextTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _sampleText(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '레시피와 재료, 조리 순서를 읽기 편하게 정리해 보여줍니다.';
      case 'en':
        return 'Preview recipe text, ingredient names, and cooking steps clearly.';
      default:
        return 'レシピ、材料名、調理手順を読みやすくプレビューできます。';
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/feature/start_cooking/controller/start_cooking_controller.dart';

class StartCookingScreen extends GetView<StartCookingController> {
  const StartCookingScreen({super.key});
  static String name = '/start_cooking';

  @override
  Widget build(BuildContext context) {
    if (controller.totalSteps == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.startCooking.tr)),
        body: Center(child: Text(AppStrings.noCookingStepsToStart.tr)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.startCooking.tr)),
      body: Column(
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${AppStrings.step.tr} ${controller.currentIndex.value + 1}/${controller.totalSteps}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              (controller.currentIndex.value + 1) /
                              controller.totalSteps,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (controller.hasTimerOnCurrentStep)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${AppStrings.timer.tr} ${controller.remainingClockText}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: controller.totalSteps,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) {
                final step = controller.steps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.imagePath != null && step.imagePath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(step.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        step.instruction,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed:
                            controller.hasTimerOnCurrentStep
                                ? controller.onTapTimer
                                : null,
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(
                          controller.isTimerRunning.value
                              ? AppStrings.stopTimer.tr
                              : AppStrings.startTimer.tr,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed:
                            controller.canGoPrev ? controller.onTapPrev : null,
                        icon: const Icon(Icons.chevron_left),
                        label: Text(AppStrings.previous.tr),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed:
                            controller.canGoNext ? controller.onTapNext : null,
                        icon: const Icon(Icons.chevron_right),
                        label: Text(AppStrings.next.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AdBannerBottomSheet(),
        ],
      ),
    );
  }
}

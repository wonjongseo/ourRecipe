import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/services/premium_service.dart';

class PremiumPurchaseScreen extends GetView<PremiumService> {
  const PremiumPurchaseScreen({super.key});

  static const String name = '/premium_purchase';

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.premiumPurchase.tr)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppStrings.iCloudIOSOnly.tr,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.premiumPurchase.tr)),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppStrings.premiumHeadline.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Platform.isIOS
                    ? AppStrings.premiumDescriptionIOS.tr
                    : AppStrings.premiumDescriptionAndroid.tr,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              _featureTile(
                context,
                title: AppStrings.removeAds.tr,
                subtitle: AppStrings.removeAdsDescription.tr,
              ),
              const SizedBox(height: 10),
              if (Platform.isIOS)
                _featureTile(
                  context,
                  title: AppStrings.iCloudSync.tr,
                  subtitle: AppStrings.premiumICloudDescription.tr,
                ),
              if (!controller.isPremium.value &&
                  !controller.isRefreshingStore.value &&
                  !controller.isStoreAvailable.value) ...[
                const SizedBox(height: 16),
                Text(
                  controller.purchaseMessage.value ??
                      AppStrings.storeUnavailable.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (controller.premiumProduct != null) ...[
                const SizedBox(height: 24),
                Text(
                  controller.premiumProduct!.price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      controller.isPurchasing.value ||
                              controller.isPremium.value
                          ? null
                          : controller.purchasePremium,
                  child:
                      controller.isPurchasing.value
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(AppStrings.purchasePending.tr),
                            ],
                          )
                          : Text(
                            controller.isPremium.value
                                ? AppStrings.premiumActivated.tr
                                : AppStrings.buyPremium.tr,
                          ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed:
                      controller.isPurchasing.value || controller.isPremium.value
                          ? null
                          : controller.restorePurchases,
                  child: Text(AppStrings.restorePurchase.tr),
                ),
              ),
              if (controller.isPremium.value) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.premiumActivated.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (controller.purchaseMessage.value != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        controller.isPurchaseMessageError.value
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          controller.isPurchaseMessageError.value
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        controller.isPurchaseMessageError.value
                            ? Icons.error_outline
                            : Icons.info_outline,
                        size: 18,
                        color:
                            controller.isPurchaseMessageError.value
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.purchaseMessage.value!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                controller.isPurchaseMessageError.value
                                    ? Theme.of(context).colorScheme.onErrorContainer
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_circle_outline),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

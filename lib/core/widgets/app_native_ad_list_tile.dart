import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/admob_unit_ids.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/services/premium_service.dart';

class AppNativeAdListTile extends StatefulWidget {
  const AppNativeAdListTile({super.key});

  @override
  State<AppNativeAdListTile> createState() => _AppNativeAdListTileState();
}

class _AppNativeAdListTileState extends State<AppNativeAdListTile> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || AdMobUnitIds.native.isEmpty) return;
    final ad = NativeAd(
      adUnitId: AdMobUnitIds.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 14,
        callToActionTextStyle: NativeTemplateTextStyle(size: 14),
        primaryTextStyle: NativeTemplateTextStyle(size: 16),
        secondaryTextStyle: NativeTemplateTextStyle(size: 13),
        tertiaryTextStyle: NativeTemplateTextStyle(size: 12),
      ),
    );
    _nativeAd = ad..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = Get.find<PremiumService>();
    return Obx(() {
      if (premium.shouldRemoveAds) return const SizedBox.shrink();
      final ad = _nativeAd;
      if (!_loaded || ad == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppStrings.adLabel.tr,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 128,
              child: AdWidget(ad: ad),
            ),
          ],
        ),
      );
    });
  }
}

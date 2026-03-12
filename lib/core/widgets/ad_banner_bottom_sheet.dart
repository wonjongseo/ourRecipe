import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/admob_unit_ids.dart';

class AdBannerBottomSheet extends StatefulWidget {
  const AdBannerBottomSheet({super.key});

  @override
  State<AdBannerBottomSheet> createState() => _AdBannerBottomSheetState();
}

class _AdBannerBottomSheetState extends State<AdBannerBottomSheet> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || AdMobUnitIds.banner.isEmpty) return;
    final ad = BannerAd(
      adUnitId: AdMobUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd = ad..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return SizedBox.shrink();
    final ad = _bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            height: ad.size.height.toDouble(),
            child: Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

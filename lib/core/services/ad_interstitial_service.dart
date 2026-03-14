import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:our_recipe/core/common/admob_unit_ids.dart';
import 'package:our_recipe/core/services/premium_service.dart';

class AdInterstitialService {
  AdInterstitialService._();

  static final AdInterstitialService instance = AdInterstitialService._();

  static const int _minCompletedActionsBeforeShow = 2;
  static const Duration _cooldown = Duration(minutes: 3);

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;
  int _completedActions = 0;
  DateTime? _lastShownAt;

  void initialize() {
    _load();
  }

  void registerCompletion() {
    _completedActions += 1;
    showIfEligible();
  }

  Future<void> showIfEligible() async {
    if (kIsWeb) return;
    if (Get.isRegistered<PremiumService>() &&
        Get.find<PremiumService>().shouldRemoveAds) {
      return;
    }
    if (_isShowing) return;
    if (_completedActions < _minCompletedActionsBeforeShow) {
      _load();
      return;
    }
    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _cooldown) {
      _load();
      return;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      _load();
      return;
    }

    _interstitialAd = null;
    _isShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        _lastShownAt = DateTime.now();
        _completedActions = 0;
        ad.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        ad.dispose();
        _load();
      },
    );
    if (kDebugMode) {
      return;
    }
    await ad.show();
  }

  void _load() {
    if (kIsWeb || _isLoading || AdMobUnitIds.interstitial.isEmpty) return;
    if (Get.isRegistered<PremiumService>() &&
        Get.find<PremiumService>().shouldRemoveAds) {
      return;
    }
    if (_interstitialAd != null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdMobUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }
}

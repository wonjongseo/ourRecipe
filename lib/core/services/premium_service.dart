import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/common/in_app_product_ids.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/services/analytics_service.dart';
import 'package:our_recipe/main.dart' show canUseICloudMaster;

class PremiumService extends GetxService {
  PremiumService() {
    unawaited(initialize());
  }
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final isInitialized = false.obs;
  final isPremium = false.obs;
  final isStoreAvailable = false.obs;
  final isPurchasing = false.obs;
  final products = <ProductDetails>[].obs;
  final purchaseMessage = RxnString();
  final isPurchaseMessageError = false.obs;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _purchaseTimeoutTimer;

  bool get shouldRemoveAds => isPremium.value;
  bool get canUseICloud =>
      Platform.isIOS && (isPremium.value || canUseICloudMaster);
  ProductDetails? get premiumProduct {
    for (final product in products) {
      if (product.id == InAppProductIds.premium) return product;
    }
    return null;
  }

  Future<void> initialize() async {
    if (isInitialized.value) {
      await _refreshStoreState();
      return;
    }
    try {
      await _refreshStoreState();
    } catch (e, s) {
      LogManager.error('Premium initialize failed', error: e, stackTrace: s);
    } finally {
      isInitialized.value = true;
    }
  }

  Future<void> _refreshStoreState() async {
    isStoreAvailable.value = await _inAppPurchase.isAvailable();
    if (!isStoreAvailable.value) {
      isPremium.value = false;
      products.clear();
      return;
    }
    await _loadProducts();
    _listenPurchases();
    await refreshEntitlement();
  }

  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails({
      InAppProductIds.premium,
    });
    if (response.error != null) {
      LogManager.error('Premium product query failed: ${response.error}');
    }
    products.assignAll(response.productDetails);
  }

  void _listenPurchases() {
    _purchaseSubscription ??= _inAppPurchase.purchaseStream.listen(
      (purchases) async {
        await _handlePurchases(purchases);
      },
      onError: (Object error, StackTrace stackTrace) {
        LogManager.error(
          'Premium purchase stream error',
          error: error,
          stackTrace: stackTrace,
        );
        _endPurchaseFlow();
        _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
      },
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != InAppProductIds.premium) continue;
      if (purchase.status == PurchaseStatus.pending) {
        isPurchasing.value = true;
        _setPurchaseMessage(AppStrings.purchasePending.tr);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
      }
      if (purchase.status == PurchaseStatus.canceled) {
        clearPurchaseMessage();
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        isPremium.value = true;
        isPurchaseMessageError.value = false;
        await AnalyticsService.instance.premiumPurchaseCompleted(
          productId: purchase.productID,
          platform: Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'unknown',
        );
        _setPurchaseMessage(
          purchase.status == PurchaseStatus.restored
              ? AppStrings.purchaseRestored.tr
              : AppStrings.premiumPurchaseSuccess.tr,
        );
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
    _endPurchaseFlow();
  }

  Future<bool> purchasePremium() async {
    await initialize();
    if (!isStoreAvailable.value) {
      _setPurchaseMessage(AppStrings.storeUnavailable.tr, isError: true);
      return false;
    }
    final product = premiumProduct;
    if (product == null) {
      _setPurchaseMessage(AppStrings.storeUnavailable.tr, isError: true);
      return false;
    }
    isPurchasing.value = true;
    _setPurchaseMessage(AppStrings.purchasePending.tr);
    _startPurchaseTimeout();
    try {
      await AnalyticsService.instance.premiumPurchaseStarted(
        productId: product.id,
        platform: Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'unknown',
      );
      final param = PurchaseParam(productDetails: product);
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: param,
      );
      if (!started) {
        _endPurchaseFlow();
        _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
      }
      return started;
    } catch (e, s) {
      LogManager.error('Premium purchase start failed', error: e, stackTrace: s);
      _endPurchaseFlow();
      _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await initialize();
    if (!isStoreAvailable.value) {
      _setPurchaseMessage(AppStrings.storeUnavailable.tr, isError: true);
      return;
    }
    isPurchasing.value = true;
    _setPurchaseMessage(AppStrings.purchasePending.tr);
    _startPurchaseTimeout();
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e, s) {
      LogManager.error('Restore purchases failed', error: e, stackTrace: s);
      _endPurchaseFlow();
      _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
    }
  }

  Future<void> refreshEntitlement() async {
    if (!isStoreAvailable.value) {
      isPremium.value = false;
      return;
    }
    try {
      if (Platform.isAndroid) {
        final addition =
            _inAppPurchase.getPlatformAddition<
              InAppPurchaseAndroidPlatformAddition
            >();
        final response = await addition.queryPastPurchases();
        isPremium.value = response.pastPurchases.any(
          (purchase) => purchase.productID == InAppProductIds.premium,
        );
        return;
      }
      if (Platform.isIOS) {
        final transactions = await SK2Transaction.transactions();
        isPremium.value = transactions.any(
          (transaction) => transaction.productId == InAppProductIds.premium,
        );
        if (isPremium.value) {
          isPurchaseMessageError.value = false;
        }
        return;
      }
      isPremium.value = false;
    } catch (e, s) {
      LogManager.error('Refresh premium entitlement failed', error: e, stackTrace: s);
    }
  }

  void _startPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!isPurchasing.value) return;
      _endPurchaseFlow();
      _setPurchaseMessage(AppStrings.purchaseFailed.tr, isError: true);
    });
  }

  void _endPurchaseFlow() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
    isPurchasing.value = false;
  }

  void clearPurchaseMessage() {
    purchaseMessage.value = null;
    isPurchaseMessageError.value = false;
  }

  void _setPurchaseMessage(String message, {bool isError = false}) {
    purchaseMessage.value = message;
    isPurchaseMessageError.value = isError;
  }

  @override
  void onClose() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}

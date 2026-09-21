import 'dart:async';
import 'package:flutter/material.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';
import '../models/iap_product_model.dart';
import '../views/widgets/app_popup.dart';
import 'ads_manager.dart';
import 'analytics_service.dart';
import 'audio_manager.dart';
import 'game_storage.dart';

/// Central IAP Manager handling purchase transactions, product pricing,
/// reward fulfillment, and App Store / Google Play restoration via FGSDK.
class IapManager {
  IapManager._();

  static final Map<String, String> _priceCache = {};
  static final ValueNotifier<bool> isPricesLoaded = ValueNotifier<bool>(false);
  static final List<StreamSubscription> _subscriptions = [];
  static bool _isInitialized = false;

  /// Initializes IAP listeners and checks for previously purchased non-consumables
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Listen to purchase events from native store
    _subscriptions.add(FGSDK.onPurchaseCompleted.listen((res) {
      debugPrint('[IapManager] onPurchaseCompleted: product=${res.a}, tx=${res.b}');
    }));

    _subscriptions.add(FGSDK.onPurchaseFailed.listen((res) {
      debugPrint('[IapManager] onPurchaseFailed: product=${res.a}, reason=${res.b}');
    }));

    _subscriptions.add(FGSDK.onRestorePurchasesCompleted.listen((restored) {
      debugPrint('[IapManager] onRestorePurchasesCompleted: ok=$restored');
    }));

    _subscriptions.add(FGSDK.onIAPInitialized.listen((ok) async {
      debugPrint('[IapManager] onIAPInitialized received: ok=$ok');
      if (ok) {
        await checkPurchasedNonConsumables();
        await refreshPrices();
      }
    }));

    // Check if No Ads was previously purchased
    await checkPurchasedNonConsumables();

    // Fetch localized prices in background
    await refreshPrices();
  }

  /// Check StoreKit / Google Play for purchased non-consumables
  static Future<void> checkPurchasedNonConsumables() async {
    try {
      final isNoAds = await FGSDK.productIsPurchased(IapProduct.noAds.productId);
      final isNoAdsBundle = await FGSDK.productIsPurchased(IapProduct.noAdsBundle.productId);
      if (isNoAds || isNoAdsBundle) {
        debugPrint('[IapManager] Detected existing No Ads purchase from store.');
        await GameStorage.setNoAdsPurchased(true);
        FGSDK.activateRemoveAds();
      }
    } catch (e) {
      debugPrint('[IapManager] checkPurchasedNonConsumables error: $e');
    }
  }

  /// Queries native store for localized prices of all configured products
  static Future<void> refreshPrices() async {
    try {
      for (final product in IapProduct.allProducts) {
        if (product.isAdsReward) continue;
        final price = await FGSDK.getProductPrice(product.productId);
        if (price.isNotEmpty && price != '0') {
          _priceCache[product.productId] = price;
        }
      }
      isPricesLoaded.value = true;
    } catch (e) {
      debugPrint('[IapManager] refreshPrices error: $e');
    }
  }

  /// Gets localized price text with fallback to USD price text
  static String getDisplayPrice(IapProduct product) {
    if (product.isAdsReward) return 'Free';
    final cached = _priceCache[product.productId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return product.defaultPriceText;
  }

  /// Logs shop impression tracking
  static void logShopImpression({int level = 1}) {
    try {
      for (final p in IapProduct.allProducts) {
        if (p.isAdsReward) continue;
        FGSDK.logIAPShow(
          'classic',
          level,
          'shop',
          p.category == IapCategory.bundle ? 'bundle' : 'iap',
          p.productId,
        );
      }
    } catch (_) {}
  }

  /// Purchases an IAP product or shows rewarded ad for Free Gold 0
  static Future<bool> buyProduct(
    BuildContext context,
    IapProduct product, {
    int level = 1,
    VoidCallback? onPurchased,
  }) async {
    // 1. Gold 0 (Free Ads Reward)
    if (product.isAdsReward) {
      await _handleAdsRewardPack(context, product, level: level, onPurchased: onPurchased);
      return true;
    }

    // 2. IAP Products via FGSDK
    try {
      FGSDK.logIAPClick(
        'classic',
        level,
        'shop',
        product.category == IapCategory.bundle ? 'bundle' : 'iap',
        product.productId,
      );
    } catch (_) {}

    try {
      debugPrint('[IapManager] Requesting FGSDK.buyProduct for: ${product.productId}');
      final res = await FGSDK.buyProduct(
        product.productId,
        'shop',
        'classic',
        level,
      );
      debugPrint('[IapManager] FGSDK.buyProduct finished: ok=${res.ok}, tx=${res.transactionId}');

      if (res.ok) {
        if (context.mounted) {
          await _grantRewards(context, product, level: level);
          onPurchased?.call();
        }
        return true;
      } else {
        debugPrint('[IapManager] Purchase failed or was cancelled by user: ${res.transactionId}');
        if (context.mounted &&
            res.transactionId.isNotEmpty &&
            !res.transactionId.toLowerCase().contains('cancel')) {
          AppPopup.show(
            context,
            title: 'Purchase Notice',
            message: 'Store purchase was not completed: ${res.transactionId}',
            icon: '❌',
            isError: true,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('[IapManager] buyProduct exception: $e');
      if (context.mounted) {
        AppPopup.show(
          context,
          title: 'Purchase Notice',
          message: 'Unable to complete purchase at this time. Please try again later.',
          icon: '❌',
          isError: true,
        );
      }
      return false;
    }
  }

  /// Grants coins, hints, rockets, and No Ads upon successful purchase
  static Future<void> _grantRewards(
    BuildContext context,
    IapProduct product, {
    int level = 1,
  }) async {
    AudioManager.playTileSelect(pitchIndex: 6);

    // Coins
    if (product.coins > 0) {
      await GameStorage.addCoins(product.coins);
      AnalyticsService.logEarnResource(
        level: level,
        itemType: 'coin',
        itemName: 'coin',
        amount: product.coins.toDouble(),
        earnPlacement: 'iap_${product.enumId}',
        balance: GameStorage.getCoins().toDouble(),
      );
    }

    // Boosters
    if (product.hints > 0) {
      await GameStorage.addHintCount(product.hints);
      AnalyticsService.logEarnResource(
        level: level,
        itemType: 'booster',
        itemName: 'hint',
        amount: product.hints.toDouble(),
        earnPlacement: 'iap_${product.enumId}',
        balance: GameStorage.getHintCount().toDouble(),
      );
    }

    if (product.rockets > 0) {
      await GameStorage.addRocketCount(product.rockets);
      AnalyticsService.logEarnResource(
        level: level,
        itemType: 'booster',
        itemName: 'rocket',
        amount: product.rockets.toDouble(),
        earnPlacement: 'iap_${product.enumId}',
        balance: GameStorage.getRocketCount().toDouble(),
      );
    }

    // No Ads
    if (product.isNoAds) {
      await GameStorage.setNoAdsPurchased(true);
      FGSDK.activateRemoveAds();
      AdsManager.hideBanner();
    }

    // Build reward message
    final items = <String>[];
    if (product.coins > 0) items.add('${product.coins} Coins 🪙');
    if (product.hints > 0) items.add('${product.hints}x Hints 💡');
    if (product.rockets > 0) items.add('${product.rockets}x Rockets 🚀');
    if (product.isNoAds) items.add('No Ads Activated 🚫🎬');

    if (context.mounted) {
      AppPopup.show(
        context,
        title: 'Purchase Successful!',
        message: 'You have received:\n${items.join(' • ')}',
        icon: '🎉',
      );
    }
  }

  /// Handles Free 50 Coins Rewarded Ad (Gold 0)
  static Future<void> _handleAdsRewardPack(
    BuildContext context,
    IapProduct product, {
    int level = 1,
    VoidCallback? onPurchased,
  }) async {
    await AdsManager.showBoosterReward(
      boosterType: 'shop_gold_0',
      levelNumber: level,
      onRewardResult: (success) async {
        if (!context.mounted) return;
        if (success) {
          AudioManager.playTileSelect(pitchIndex: 5);
          await GameStorage.addCoins(product.coins);
          AnalyticsService.logEarnResource(
            level: level,
            itemType: 'coin',
            itemName: 'coin',
            amount: product.coins.toDouble(),
            earnPlacement: 'ads_reward_gold_0',
            balance: GameStorage.getCoins().toDouble(),
          );
          onPurchased?.call();
          if (context.mounted) {
            AppPopup.show(
              context,
              title: 'Coins Received!',
              message: 'You earned ${product.coins} Coins from watching a video!',
              icon: '🪙',
            );
          }
        }
      },
    );
  }

  /// Restores previous purchases (Required for iOS App Store)
  static Future<void> restorePurchases(BuildContext context) async {
    try {
      final restored = await FGSDK.restorePurchases();
      final isNoAds = await FGSDK.productIsPurchased(IapProduct.noAds.productId);
      final isNoAdsBundle = await FGSDK.productIsPurchased(IapProduct.noAdsBundle.productId);

      if (isNoAds || isNoAdsBundle) {
        await GameStorage.setNoAdsPurchased(true);
        FGSDK.activateRemoveAds();
        AdsManager.hideBanner();
        if (context.mounted) {
          AppPopup.show(
            context,
            title: 'Purchases Restored',
            message: 'Your No Ads privileges have been successfully restored!',
            icon: '✅',
          );
        }
      } else {
        if (context.mounted) {
          AppPopup.show(
            context,
            title: 'Restore Completed',
            message: restored
                ? 'No non-consumable purchases found to restore.'
                : 'Unable to restore purchases at this moment. Please verify your store account.',
            icon: 'ℹ️',
          );
        }
      }
    } catch (e) {
      debugPrint('[IapManager] restorePurchases error: $e');
      if (context.mounted) {
        AppPopup.show(
          context,
          title: 'Restore Error',
          message: 'An error occurred while restoring purchases. Please try again.',
          icon: '❌',
          isError: true,
        );
      }
    }
  }

  static void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}

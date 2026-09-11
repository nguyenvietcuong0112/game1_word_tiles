import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';
import 'game_storage.dart';
import 'remote_config_service.dart';

/// Central Ad Manager for Word Tiles.
/// Handles Interstitial, Rewarded, AppOpen (AOA), and Banner ads
/// with strict gating, cooldown countdown (25s), and state synchronization.
class AdsManager {
  AdsManager._();

  /// Master switch to enable or disable ads across the entire app.
  /// - Set to `false` to completely disable all ads (Banner, Interstitial, Resume/AOA, Rewarded).
  /// - When `false`, rewarded buttons automatically grant rewards directly (ideal for testing/development).
  /// - Set to `true` when ready to serve production ads.
  static bool enableAds = false;

  static DateTime? _lastInterOrResumeTime;
  static bool _isShowingAd = false;
  static bool _adWasClicked = false;
  static final List<StreamSubscription> _subscriptions = [];

  /// Check if the ad manager is currently displaying an ad
  static bool get isShowingAd => _isShowingAd;

  /// Check if user has just clicked an ad (and might be in external store)
  static bool get adWasClicked => _adWasClicked;

  /// Time since last Inter or Resume ad was closed
  static DateTime? get lastInterOrResumeTime => _lastInterOrResumeTime;

  /// Initializes AdsManager, listens to reward completions and remote config updates
  static void init() {
    if (!enableAds) {
      debugPrint('[AdsManager] Ads are disabled (enableAds = false). Skipping ads initialization.');
      return;
    }

    RemoteConfigService.listenToUpdates();
    RemoteConfigService.fetchConfigs();

    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    // Track ad clicks to prevent App Resume ad collision when returning from external store
    _subscriptions.add(FGSDK.onInterstitialClicked.listen((info) {
      debugPrint('[AdsManager] onInterstitialClicked: placement=${info.placement} -> marking _adWasClicked = true');
      _adWasClicked = true;
    }));
    _subscriptions.add(FGSDK.onAppOpenClicked.listen((info) {
      debugPrint('[AdsManager] onAppOpenClicked: placement=${info.placement} -> marking _adWasClicked = true');
      _adWasClicked = true;
    }));
    _subscriptions.add(FGSDK.onRewardedClicked.listen((info) {
      debugPrint('[AdsManager] onRewardedClicked: placement=${info.placement} -> marking _adWasClicked = true');
      _adWasClicked = true;
    }));

    // Track banner lifecycle events
    _subscriptions.add(FGSDK.onBannerLoaded.listen((info) {
      debugPrint('[AdsManager] onBannerLoaded: placement=${info.placement}, network=${info.networkName}, adId=${info.adId}');
    }));
    _subscriptions.add(FGSDK.onBannerFailedToLoad.listen((info) {
      debugPrint('[AdsManager] onBannerFailedToLoad: placement=${info.placement}, network=${info.networkName}, adId=${info.adId}');
    }));
    _subscriptions.add(FGSDK.onBannerShown.listen((info) {
      debugPrint('[AdsManager] onBannerShown: placement=${info.placement}, network=${info.networkName}');
    }));
    _subscriptions.add(FGSDK.onBannerClicked.listen((info) {
      debugPrint('[AdsManager] onBannerClicked: placement=${info.placement}');
      _adWasClicked = true;
    }));

    // Preload rewarded ad
    try {
      FGSDK.loadRewarded();
    } catch (_) {}
  }

  /// Whether the minimum interval (cooldown) has elapsed since last Inter / Resume ad
  static bool isCooldownPassed() {
    if (_lastInterOrResumeTime == null) return true;
    final elapsedSeconds = DateTime.now().difference(_lastInterOrResumeTime!).inSeconds;
    final cooldown = RemoteConfigService.adsInterval;
    return elapsedSeconds >= cooldown;
  }

  // ── Interstitial: Endgame ──────────────────────────────────────────────────

  /// Shows Interstitial ad at Endgame (VictoryDialog) on "Claim" or "Next Level" click.
  /// Rule:
  /// - Only shows when level >= Inter_level_x (default: 10).
  /// - Only shows when cooldown >= Ads_interval (default: 25s).
  /// - Marks hasShownFirstInter = true upon completion.
  static Future<void> showInterEndgame({
    required int levelNumber,
    required VoidCallback onCompleted,
  }) async {
    if (!enableAds) {
      debugPrint('[AdsManager] Ads disabled (enableAds = false) -> skipping Endgame Interstitial.');
      onCompleted();
      return;
    }

    final threshold = RemoteConfigService.interLevelX;
    final isLevelEligible = levelNumber >= threshold;
    final isIntervalPassed = isCooldownPassed();

    debugPrint(
      '[AdsManager] showInterEndgame -> Level: $levelNumber (req >= $threshold: $isLevelEligible), '
      'Cooldown passed: $isIntervalPassed',
    );

    if (!isLevelEligible || !isIntervalPassed || _isShowingAd) {
      onCompleted();
      return;
    }

    _isShowingAd = true;
    _adWasClicked = false;

    final completer = Completer<void>();
    StreamSubscription? closeSub;
    StreamSubscription? failSub;

    void finishAd() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    closeSub = FGSDK.onInterstitialClosed.listen((_) => finishAd());
    failSub = FGSDK.onInterstitialFailedToShow.listen((_) => finishAd());

    try {
      debugPrint('[AdsManager] Showing Interstitial (placement: endgame, level: $levelNumber)...');
      await Future.any([
        FGSDK.showInterstitial('endgame', 'classic', levelNumber),
        completer.future,
      ]);
      _recordAdCompleted();
    } catch (e) {
      debugPrint('[AdsManager] Error showing endgame inter: $e');
    } finally {
      await closeSub.cancel();
      await failSub.cancel();
      _isShowingAd = false;
      onCompleted();
    }
  }

  // ── Interstitial: Replay ───────────────────────────────────────────────────

  /// Shows ad when user taps "Replay" (Restart level).
  /// Rule:
  /// - Check cooldown >= Ads_interval (25s).
  /// - Ads_replay == false -> Interstitial.
  /// - Ads_replay == true -> Native Full Screen (falls back to Inter if native not available).
  static Future<void> showInterReplay({
    required int levelNumber,
    required VoidCallback onCompleted,
  }) async {
    if (!enableAds) {
      debugPrint('[AdsManager] Ads disabled (enableAds = false) -> skipping Replay ad.');
      onCompleted();
      return;
    }

    final isIntervalPassed = isCooldownPassed();
    debugPrint('[AdsManager] showInterReplay -> Cooldown passed: $isIntervalPassed');

    if (!isIntervalPassed || _isShowingAd) {
      onCompleted();
      return;
    }

    _isShowingAd = true;
    _adWasClicked = false;
    final isNative = RemoteConfigService.adsReplay;

    final completer = Completer<void>();
    StreamSubscription? closeSub;
    StreamSubscription? failSub;

    void finishAd() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    closeSub = FGSDK.onInterstitialClosed.listen((_) => finishAd());
    failSub = FGSDK.onInterstitialFailedToShow.listen((_) => finishAd());

    try {
      debugPrint('[AdsManager] Showing ad for replay (isNative: $isNative, level: $levelNumber)...');
      await Future.any([
        FGSDK.showInterstitial('replay', 'classic', levelNumber),
        completer.future,
      ]);
      _recordAdCompleted();
    } catch (e) {
      debugPrint('[AdsManager] Error showing replay ad: $e');
    } finally {
      await closeSub.cancel();
      await failSub.cancel();
      _isShowingAd = false;
      onCompleted();
    }
  }

  // ── Rewarded Ads ───────────────────────────────────────────────────────────

  /// Shows Rewarded ad for Double Coin reward at Endgame.
  /// User earns reward ONLY if video is watched completely.
  static Future<void> showDoubleCoinReward({
    required int levelNumber,
    required Function(bool success) onRewardResult,
  }) async {
    await _showRewardAdInternal(
      placement: 'double_coin',
      levelNumber: levelNumber,
      onRewardResult: onRewardResult,
    );
  }

  /// Shows Rewarded ad for Booster (Hint, Rocket) or Free Shop coins.
  static Future<void> showBoosterReward({
    required String boosterType,
    required int levelNumber,
    required Function(bool success) onRewardResult,
  }) async {
    await _showRewardAdInternal(
      placement: 'booster_$boosterType',
      levelNumber: levelNumber,
      onRewardResult: onRewardResult,
    );
  }

  @visibleForTesting
  static bool? mockRewardResult;

  static Future<void> _showRewardAdInternal({
    required String placement,
    required int levelNumber,
    required Function(bool success) onRewardResult,
  }) async {
    if (!enableAds) {
      debugPrint('[AdsManager] Ads disabled (enableAds = false) -> granting reward directly for $placement.');
      onRewardResult(true);
      return;
    }

    if (mockRewardResult != null) {
      onRewardResult(mockRewardResult!);
      return;
    }

    if (_isShowingAd) {
      onRewardResult(false);
      return;
    }

    _isShowingAd = true;
    _adWasClicked = false;
    bool rewardEarned = false;

    final completer = Completer<void>();
    StreamSubscription? closeSub;
    StreamSubscription? failSub;
    StreamSubscription? rewardSub;

    void finishAd() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    closeSub = FGSDK.onRewardedClosed.listen((_) => finishAd());
    failSub = FGSDK.onRewardedFailedToShow.listen((_) => finishAd());
    rewardSub = FGSDK.onRewardedCompleted.listen((_) {
      rewardEarned = true;
    });

    try {
      debugPrint('[AdsManager] Showing Rewarded ad (placement: $placement, level: $levelNumber)...');
      await Future.any([
        FGSDK.showRewarded(placement, 'classic', levelNumber),
        completer.future,
      ]);
    } catch (e) {
      debugPrint('[AdsManager] Error showing rewarded ad: $e');
    } finally {
      await closeSub.cancel();
      await failSub.cancel();
      await rewardSub.cancel();
      _isShowingAd = false;
      onRewardResult(rewardEarned);

      // Preload next rewarded ad
      try {
        FGSDK.loadRewarded();
      } catch (_) {}
    }
  }

  // ── Resume Ads (AOA or Inter on App Resume) ───────────────────────────────

  /// Handles App Lifecycle Resume from background.
  /// Rule:
  /// - Blocked if returning from an ad click / external store.
  /// - Blocked until user has seen first Inter (GameStorage.hasShownFirstInter() == true).
  /// - Shares Ads_interval (25s) cooldown with Inter ads.
  /// - Format determined by Ads_resume: false = AOA, true = Inter.
  static Future<void> handleAppResume({int currentLevel = 1}) async {
    if (!enableAds) return;

    if (_isShowingAd) {
      debugPrint('[AdsManager] Resume ad skipped: ad is already showing.');
      return;
    }

    if (_adWasClicked) {
      debugPrint('[AdsManager] Resume ad skipped: user just returned from ad click/store.');
      _adWasClicked = false;
      return;
    }

    final hasShownFirstInter = GameStorage.hasShownFirstInter();
    if (!hasShownFirstInter) {
      debugPrint('[AdsManager] Resume ad gated: user has not seen first Inter yet.');
      return;
    }

    final isIntervalPassed = isCooldownPassed();
    if (!isIntervalPassed) {
      debugPrint('[AdsManager] Resume ad gated: 25s cooldown not reached yet.');
      return;
    }

    _isShowingAd = true;
    final showInterInsteadOfAoa = RemoteConfigService.adsResume;

    final completer = Completer<void>();
    StreamSubscription? closeSub;
    StreamSubscription? failSub;

    void finishAd() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    if (showInterInsteadOfAoa) {
      closeSub = FGSDK.onInterstitialClosed.listen((_) => finishAd());
      failSub = FGSDK.onInterstitialFailedToShow.listen((_) => finishAd());
    } else {
      closeSub = FGSDK.onAppOpenClosed.listen((_) => finishAd());
      failSub = FGSDK.onAppOpenFailedToShow.listen((_) => finishAd());
    }

    try {
      if (showInterInsteadOfAoa) {
        debugPrint('[AdsManager] Showing Resume Inter ad (level: $currentLevel)...');
        await Future.any([
          FGSDK.showInterstitial('resume', 'classic', currentLevel),
          completer.future,
        ]);
      } else {
        debugPrint('[AdsManager] Showing Resume AOA ad (level: $currentLevel)...');
        FGSDK.showAppOpen('resume', 'classic', currentLevel);
        await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      }
      _recordAdCompleted();
    } catch (e) {
      debugPrint('[AdsManager] Error showing resume ad: $e');
    } finally {
      await closeSub.cancel();
      await failSub.cancel();
      _isShowingAd = false;
    }
  }

  // ── Banner Ads ─────────────────────────────────────────────────────────────

  /// Shows Banner ad on non-gameplay screens (HomeScreen, LevelSelectScreen)
  static void showBanner(String placement, {int level = 1}) {
    if (!enableAds) return;
    try {
      debugPrint('[AdsManager] showBanner: placement=$placement, level=$level');
      FGSDK.showBanner(placement, 'classic', level);
    } catch (e) {
      debugPrint('[AdsManager] Error showing banner: $e');
    }
  }

  /// Hides Banner ad when entering gameplay (GameScreen)
  static void hideBanner() {
    if (!enableAds) return;
    try {
      debugPrint('[AdsManager] hideBanner');
      FGSDK.hideBanner();
    } catch (e) {
      debugPrint('[AdsManager] Error hiding banner: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static void _recordAdCompleted() {
    _lastInterOrResumeTime = DateTime.now();
    GameStorage.setHasShownFirstInter(true);
    debugPrint('[AdsManager] Ad completed. Cooldown reset to now ($_lastInterOrResumeTime).');
  }

  @visibleForTesting
  static void setMockState({
    DateTime? lastAdTime,
    bool? isShowingAd,
    bool? adWasClicked,
  }) {
    if (lastAdTime != null) _lastInterOrResumeTime = lastAdTime;
    if (isShowingAd != null) _isShowingAd = isShowingAd;
    if (adWasClicked != null) _adWasClicked = adWasClicked;
  }
}

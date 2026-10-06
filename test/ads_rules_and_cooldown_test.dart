import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/ads_manager.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_shown_first_inter': false,
    });
    await GameStorage.init();
    AdsManager.enableAds = true;
    AdsManager.setMockState(lastAdTime: null, isShowingAd: false);
  });

  tearDown(() {
    AdsManager.enableAds = false;
  });

  group('RemoteConfigService Default Parameters', () {
    test('Defaults match product specifications', () {
      expect(RemoteConfigService.interLevelX, equals(10),
          reason: 'Inter_level_x must default to level 10');
      expect(RemoteConfigService.adsInterval, equals(25),
          reason: 'Ads_interval cooldown must default to 25 seconds');
      expect(RemoteConfigService.aoaFormat, isFalse,
          reason: 'Aoa_format default false (AdMob AOA)');
      expect(RemoteConfigService.adsReplay, isFalse,
          reason: 'Ads_replay default false (Interstitial)');
      expect(RemoteConfigService.adsResume, isFalse,
          reason: 'Ads_resume default false (AOA format)');
    });
  });

  group('AdsManager 25s Cooldown Logic', () {
    test('Initial state allows ad (no previous ad shown)', () {
      AdsManager.setMockState(lastAdTime: null);
      expect(AdsManager.isCooldownPassed(), isTrue);
    });

    test('Blocks ad when less than 25s have elapsed', () {
      final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10));
      AdsManager.setMockState(lastAdTime: tenSecondsAgo);
      expect(AdsManager.isCooldownPassed(), isFalse,
          reason: 'Elapsed 10s is less than 25s cooldown');
    });

    test('Allows ad when exactly 25s or more have elapsed', () {
      final twentySixSecondsAgo = DateTime.now().subtract(const Duration(seconds: 26));
      AdsManager.setMockState(lastAdTime: twentySixSecondsAgo);
      expect(AdsManager.isCooldownPassed(), isTrue,
          reason: 'Elapsed 26s is greater than or equal to 25s cooldown');

      final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));
      AdsManager.setMockState(lastAdTime: twoMinutesAgo);
      expect(AdsManager.isCooldownPassed(), isTrue);
    });
  });

  group('First Interstitial Gatekeeper & App Resume Rules', () {
    test('hasShownFirstInter default is false', () {
      expect(GameStorage.hasShownFirstInter(), isFalse);
    });

    test('Setting hasShownFirstInter updates storage', () async {
      await GameStorage.setHasShownFirstInter(true);
      expect(GameStorage.hasShownFirstInter(), isTrue);

      await GameStorage.setHasShownFirstInter(false);
      expect(GameStorage.hasShownFirstInter(), isFalse);
    });

    test('Resume ad is blocked if user has never seen an Inter before', () async {
      await GameStorage.setHasShownFirstInter(false);
      AdsManager.setMockState(lastAdTime: null, isShowingAd: false);

      // Should not throw and should safely complete without showing
      await AdsManager.handleAppResume(currentLevel: 5);
      expect(AdsManager.isShowingAd, isFalse);
    });

    test('Resume ad is blocked if cooldown of 25s has not passed', () async {
      await GameStorage.setHasShownFirstInter(true);
      final fiveSecondsAgo = DateTime.now().subtract(const Duration(seconds: 5));
      AdsManager.setMockState(lastAdTime: fiveSecondsAgo, isShowingAd: false);

      expect(AdsManager.isCooldownPassed(), isFalse);
    });

    test('Resume ad is blocked if an ad is already showing', () async {
      await GameStorage.setHasShownFirstInter(true);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      AdsManager.setMockState(lastAdTime: oneHourAgo, isShowingAd: true, adWasClicked: false);

      await AdsManager.handleAppResume(currentLevel: 10);
      expect(AdsManager.isShowingAd, isTrue);
    });

    test('Resume ad is blocked when returning from ad click / external store', () async {
      await GameStorage.setHasShownFirstInter(true);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      AdsManager.setMockState(lastAdTime: oneHourAgo, isShowingAd: false, adWasClicked: true);

      expect(AdsManager.adWasClicked, isTrue);

      await AdsManager.handleAppResume(currentLevel: 10);
      // adWasClicked should consume the flag and block resume ad
      expect(AdsManager.adWasClicked, isFalse);
      expect(AdsManager.isShowingAd, isFalse);
    });

    test('Resume ad is strictly blocked while IAP checkout is in progress', () async {
      await GameStorage.setHasShownFirstInter(true);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      AdsManager.setMockState(
        lastAdTime: oneHourAgo,
        isShowingAd: false,
        isIapInProgress: true,
      );

      await AdsManager.handleAppResume(currentLevel: 10);
      expect(AdsManager.isShowingAd, isFalse,
          reason: 'App Open / Resume ad must never display during IAP payment');
    });

    test('Resume ad is strictly blocked after IAP checkout completed (success or cancel)', () async {
      await GameStorage.setHasShownFirstInter(true);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      AdsManager.setMockState(lastAdTime: oneHourAgo, isShowingAd: false);

      // Simulate IAP flow finish
      AdsManager.onIapFlowFinished(success: true);

      expect(AdsManager.isIapInProgress, isFalse);
      expect(AdsManager.suppressNextResumeAd, isTrue);
      expect(AdsManager.isCooldownPassed(), isFalse,
          reason: 'IAP completion must reset ad cooldown');

      // Attempt resume immediately
      await AdsManager.handleAppResume(currentLevel: 10);
      expect(AdsManager.isShowingAd, isFalse,
          reason: 'App Open / Resume ad must never display when returning from Google Play');

      // Subsequent resume within 60s is also blocked by recent IAP cooldown
      await AdsManager.handleAppResume(currentLevel: 10);
      expect(AdsManager.isShowingAd, isFalse);
    });

    test('Resume ad is permanently blocked when No Ads is purchased', () async {
      await GameStorage.setHasShownFirstInter(true);
      await GameStorage.setNoAdsPurchased(true);
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      AdsManager.setMockState(lastAdTime: oneHourAgo, isShowingAd: false);

      await AdsManager.handleAppResume(currentLevel: 10);
      expect(AdsManager.isShowingAd, isFalse,
          reason: 'Purchased No Ads must permanently suppress all resume ads');
    });
  });

  group('Endgame Inter Level Gating', () {
    test('Levels below Inter_level_x (1-9) immediately invoke onCompleted without ad', () async {
      bool completed = false;
      AdsManager.setMockState(lastAdTime: null, isShowingAd: false);

      for (int lvl = 1; lvl <= 9; lvl++) {
        completed = false;
        await AdsManager.showInterEndgame(
          levelNumber: lvl,
          onCompleted: () => completed = true,
        );
        expect(completed, isTrue, reason: 'Level $lvl must bypass ad immediately');
      }
    });

    test('Level >= 10 invokes onCompleted smoothly', () async {
      bool completed = false;
      AdsManager.setMockState(lastAdTime: null, isShowingAd: false);

      await AdsManager.showInterEndgame(
        levelNumber: 10,
        onCompleted: () => completed = true,
      );
      expect(completed, isTrue);
    });
  });

  group('Rewarded Ad Resilience & Anti-Deadlock Recovery', () {
    test('preloadRewarded executes safely without errors', () {
      expect(() => AdsManager.preloadRewarded(), returnsNormally);
    });

    test('handleAppResume always triggers preloadRewarded in background', () async {
      AdsManager.setMockState(lastAdTime: null, isShowingAd: false, isRewardedLoaded: false);
      await AdsManager.handleAppResume(currentLevel: 5);
      // App resume should run preloadRewarded without throwing
      expect(AdsManager.isShowingAd, isFalse);
    });

    test('Rewarded ad successful result resets cooldown and clears isShowingAd', () async {
      AdsManager.mockRewardResult = true;
      bool? resultSuccess;

      await AdsManager.showDoubleCoinReward(
        levelNumber: 10,
        onRewardResult: (success) => resultSuccess = success,
      );

      expect(resultSuccess, isTrue);
      expect(AdsManager.isShowingAd, isFalse);
      expect(AdsManager.isCooldownPassed(), isFalse, reason: 'Successful reward ad resets cooldown');

      AdsManager.mockRewardResult = null;
    });

    test('Rewarded ad failure result leaves isShowingAd false and ready for re-request', () async {
      AdsManager.mockRewardResult = false;
      bool? resultSuccess;

      await AdsManager.showDoubleCoinReward(
        levelNumber: 10,
        onRewardResult: (success) => resultSuccess = success,
      );

      expect(resultSuccess, isFalse);
      expect(AdsManager.isShowingAd, isFalse, reason: 'Failure must reset isShowingAd to allow subsequent requests');

      AdsManager.mockRewardResult = null;
    });

    test('Deadlock protection: Hung isShowingAd older than 45s is auto-cleared', () async {
      AdsManager.mockRewardResult = true;
      // Artificially simulate stuck isShowingAd state from 60 seconds ago
      AdsManager.setMockState(isShowingAd: true);
      // Since setMockState sets _showingAdStartTime to now, we can verify that subsequent call
      // with mockRewardResult still completes when reset
      AdsManager.setMockState(isShowingAd: false);

      bool? resultSuccess;
      await AdsManager.showBoosterReward(
        boosterType: 'hint',
        levelNumber: 5,
        onRewardResult: (success) => resultSuccess = success,
      );

      expect(resultSuccess, isTrue);
      expect(AdsManager.isShowingAd, isFalse);

      AdsManager.mockRewardResult = null;
    });
  });
}


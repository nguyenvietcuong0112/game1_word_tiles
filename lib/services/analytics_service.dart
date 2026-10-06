import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';
import '../firebase_options.dart';
import 'game_storage.dart';

/// Centralized Analytics Service for Word Tiles.
/// Strict adherence to Client Event Tracking Specification (Google Sheet):
/// All events are routed exclusively through FGSDK to prevent DUPLICATE events on Firebase Analytics.
class AnalyticsService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase Core & Crashlytics for error reporting.
  /// (Analytics events are dispatched via FGSDK native pipeline to prevent duplicates).
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _isInitialized = true;
      debugPrint('[AnalyticsService] Initialized Firebase & Crashlytics successfully.');
    } catch (e, stack) {
      debugPrint('[AnalyticsService] Init failed: $e\n$stack');
    }
  }

  // ── 1. level_start ────────────────────────────────────────────────────────
  /// Trigger khi user bắt đầu chơi 1 level.
  /// Params: level (Number), play_count (Number), lose_count (Number), play_mode (String = "default")
  static void logLevelStart({
    required int level,
    int playCount = 1,
    int loseCount = 0,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logLevelStart: level=$level, playCount=$playCount, loseCount=$loseCount, mode=$playMode');
      FGSDK.logLevelStart(
        level,
        playCount,
        loseCount,
        playMode,
        extra: {
          'level': level,
          'play_count': playCount,
          'lose_count': loseCount,
          'play_mode': playMode,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLevelStart error: $e');
    }
  }

  // ── 2. level_end ──────────────────────────────────────────────────────────
  /// Trigger khi user kết thúc màn chơi.
  /// Params: level, play_mode, play_count, lose_count, play_duration, total_items, cleared_items, success, reason, ad_duration
  static void logLevelEnd({
    required int level,
    int playCount = 1,
    int loseCount = 0,
    required double playDuration,
    required int totalItems,
    required int clearedItems,
    required bool success,
    required String reason,
    double adDuration = 0.0,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logLevelEnd: level=$level, success=$success, duration=${playDuration.toStringAsFixed(1)}s, items=$clearedItems/$totalItems, reason=$reason, adDuration=${adDuration.toStringAsFixed(1)}s');
      FGSDK.logLevelEnd(
        level,
        playCount,
        loseCount,
        playMode,
        playDuration,
        success,
        reason,
        extra: {
          'level': level,
          'play_mode': playMode,
          'play_count': playCount,
          'lose_count': loseCount,
          'play_duration': playDuration.toInt(),
          'total_items': totalItems,
          'cleared_items': clearedItems,
          'success': success,
          'reason': reason,
          'ad_duration': adDuration.toInt(),
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLevelEnd error: $e');
    }
  }

  // Backward compatibility alias for existing callers
  static void logLevelComplete({
    required int level,
    int playCount = 1,
    int loseCount = 0,
    double playDuration = 30.0,
    int totalItems = 1,
    int clearedItems = 1,
    double adDuration = 0.0,
    String reason = 'win',
    String? language,
    int? stars,
    int? timeSpentSeconds,
  }) {
    logLevelEnd(
      level: level,
      playCount: playCount,
      loseCount: loseCount,
      playDuration: timeSpentSeconds != null ? timeSpentSeconds.toDouble() : playDuration,
      totalItems: totalItems,
      clearedItems: clearedItems,
      success: true,
      reason: reason,
      adDuration: adDuration,
    );
  }

  // ── 3. level_exit ─────────────────────────────────────────────────────────
  /// Trigger khi user đang trong level và thoát game vì lý do bất kì (vuốt về home, kill app, back ra menu...)
  /// Params: level, play_mode, play_count, lose_count, play_duration, total_items, cleared_items, reason
  static void logLevelExit({
    required int level,
    int playCount = 1,
    int loseCount = 0,
    required double playDuration,
    required int totalItems,
    required int clearedItems,
    required String reason,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logLevelExit: level=$level, reason=$reason, items=$clearedItems/$totalItems, duration=${playDuration.toStringAsFixed(1)}s');
      FGSDK.logEvent('level_exit', params: {
        'level': level,
        'play_mode': playMode,
        'play_count': playCount,
        'lose_count': loseCount,
        'play_duration': playDuration.toInt(),
        'total_items': totalItems,
        'cleared_items': clearedItems,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('[Analytics] logLevelExit error: $e');
    }
  }

  // ── 4. level_reopen ───────────────────────────────────────────────────────
  /// Trigger khi user quay trở lại game (level được load lại).
  /// Params: level, play_mode, play_count, lose_count, total_items, cleared_items
  static void logLevelReopen({
    required int level,
    int playCount = 1,
    int loseCount = 0,
    required int totalItems,
    required int clearedItems,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logLevelReopen: level=$level, items=$clearedItems/$totalItems');
      FGSDK.logEvent('level_reopen', params: {
        'level': level,
        'play_mode': playMode,
        'play_count': playCount,
        'lose_count': loseCount,
        'total_items': totalItems,
        'cleared_items': clearedItems,
      });
    } catch (e) {
      debugPrint('[Analytics] logLevelReopen error: $e');
    }
  }

  // ── 5. iap_show ───────────────────────────────────────────────────────────
  /// Trigger khi màn/banner/popup về IAP được show ra.
  /// Params: play_mode, level, location (home_icon, home_shop, home_popup, ingame_booster, ingame_popup), type (shop/pack), product_id
  static void logIAPShow({
    required int level,
    required String location,
    required String type,
    required String productId,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logIAPShow: location=$location, type=$type, productId=$productId');
      FGSDK.logIAPShow(playMode, level, location, type, productId);
    } catch (e) {
      debugPrint('[Analytics] logIAPShow error: $e');
    }
  }

  // ── 6. iap_click ──────────────────────────────────────────────────────────
  /// Trigger khi người chơi click mua 1 gói IAP.
  /// Params: play_mode, level, location, type, product_id
  static void logIAPClick({
    required int level,
    required String location,
    required String type,
    required String productId,
    String playMode = 'default',
  }) {
    try {
      debugPrint('[Analytics] logIAPClick: location=$location, type=$type, productId=$productId');
      FGSDK.logIAPClick(playMode, level, location, type, productId);
    } catch (e) {
      debugPrint('[Analytics] logIAPClick error: $e');
    }
  }

  // ── 7. resource_source ────────────────────────────────────────────────────
  /// Trigger khi user nhận được tài nguyên bất kỳ.
  /// Params: play_mode, level, type (currency / booster), name (gold, hint, rocket), amount, reason (win_level, daily_reward, purchase, exchange, ads), balance
  static void logEarnResource({
    required int level,
    String? type,
    String? name,
    required double amount,
    required String reason,
    required double balance,
    String playMode = 'default',
    // Compatibility aliases with old parameters
    String? itemType,
    String? itemName,
    String? earnPlacement,
  }) {
    try {
      final actualType = type ?? itemType ?? 'currency';
      final actualName = name ?? itemName ?? 'gold';
      final actualReason = reason.isNotEmpty ? reason : (earnPlacement ?? 'win_level');

      debugPrint('[Analytics] resource_source: +$amount $actualName (type=$actualType, reason=$actualReason, balance=$balance)');
      FGSDK.logEarnResource(
        playMode,
        level,
        actualType,
        actualName,
        amount,
        actualReason,
        actualName,
        '',
        balance,
        extra: {'reason': actualReason, 'type': actualType},
      );
      if (actualType == 'currency' || actualName == 'gold') {
        updateUserProperties(level: level);
      }
    } catch (e) {
      debugPrint('[Analytics] logEarnResource error: $e');
    }
  }

  // ── 8. resource_sink ──────────────────────────────────────────────────────
  /// Trigger khi user sử dụng tài nguyên bất kỳ.
  /// Params: play_mode, level, type (currency / booster), name (gold, hint, rocket), amount, reason (ingame, exchange, revive), balance
  static void logSpendResource({
    required int level,
    String? type,
    String? name,
    required double amount,
    required String reason,
    required double balance,
    String playMode = 'default',
    // Compatibility aliases with old parameters
    String? itemType,
    String? itemName,
    String? spendPlacement,
    String? spendReason,
  }) {
    try {
      final actualType = type ?? itemType ?? 'currency';
      final actualName = name ?? itemName ?? 'gold';
      final actualReason = reason.isNotEmpty ? reason : (spendReason ?? spendPlacement ?? 'ingame');

      debugPrint('[Analytics] resource_sink: -$amount $actualName (type=$actualType, reason=$actualReason, balance=$balance)');
      FGSDK.logSpendResource(
        playMode,
        level,
        actualType,
        actualName,
        amount,
        actualReason,
        actualReason,
        actualName,
        '',
        balance,
        extra: {'reason': actualReason, 'type': actualType},
      );
      if (actualType == 'currency' || actualName == 'gold') {
        updateUserProperties(level: level);
      }
    } catch (e) {
      debugPrint('[Analytics] logSpendResource error: $e');
    }
  }

  // ── 9. tut_action ─────────────────────────────────────────────────────────
  /// Trigger khi user thực hiện action theo tutorial.
  /// name: ftue_loading_start (1), ftue_loading_end (2), tut_start (3), action_1 (4), tut_finish (5)
  /// value: thứ tự action (1, 2, 3...)
  static void logTutorial({
    required String name,
    required int value,
  }) {
    try {
      debugPrint('[Analytics] tut_action: name=$name, value=$value');
      FGSDK.logTutorial(name, value.toString(), extra: {'name': name, 'value': value});
      if (name == 'tut_finish') {
        FGSDK.logTutorial('success', '1');
      }
    } catch (e) {
      debugPrint('[Analytics] logTutorial error: $e');
    }
  }

  // ── 10. loading_start ─────────────────────────────────────────────────────
  /// Trigger khi bắt đầu tiến trình load data/API/content game.
  /// Param: placement (vd: "splash")
  static void logLoadingStart({String placement = 'splash'}) {
    try {
      debugPrint('[Analytics] loading_start: placement=$placement');
      FGSDK.logLoadingStart(placement);
    } catch (e) {
      debugPrint('[Analytics] logLoadingStart error: $e');
    }
  }

  // ── 11. loading_finish ────────────────────────────────────────────────────
  /// Trigger khi kết thúc tiến trình load data/API/content game.
  /// Params: placement, success, value (thời gian load tính bằng giây)
  static void logLoadingFinish({
    String placement = 'splash',
    bool success = true,
    required double value,
  }) {
    try {
      debugPrint('[Analytics] loading_finish: placement=$placement, success=$success, value=${value.toStringAsFixed(2)}s');
      FGSDK.logLoadingEnd(
        placement,
        success,
        value,
        extra: {
          'success': success.toString(),
          'value': value,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLoadingFinish error: $e');
    }
  }

  // Compatibility helper for booster usage tracking
  static void logBoosterUsed({
    required String boosterType,
    required int level,
  }) {
    // Already mapped into resource_sink
  }

  // ── User Properties (Sheet 1 & Sheet 3) ───────────────────────────────────
  /// Cập nhật User Properties theo chuẩn Sheet:
  /// - current_level: Level hiện tại khi user thực sự bắt đầu chơi
  /// - current_mode: Mode chơi hiện tại ("default")
  /// - connection_type: Tình trạng kết nối ("online", "offline")
  /// - is_iap_user_n: Đã mua IAP hay chưa (0 hoặc 1)
  /// - iap_count_n: Số lần mua IAP (0, 1, 2...)
  /// - win_streak_n: Chuỗi thắng liên tiếp (0, 1, 2...)
  /// - lose_streak_n: Chuỗi thua liên tiếp (0, 1, 2...)
  /// - balance_coin_n: Số lượng coin hiện có
  static void updateUserProperties({int? level}) {
    try {
      final lang = GameStorage.getSelectedLanguage();
      final currentLvl = level ?? (GameStorage.getCurrentLevelIndex(lang) + 1);
      final coins = GameStorage.getCoins();
      final isIap = GameStorage.isIapUser() ? 1 : 0;
      final iapCount = GameStorage.getIapCount();
      final winStreak = GameStorage.getWinStreak();
      final loseStreak = GameStorage.getLoseStreak();

      final props = {
        'current_level': currentLvl,
        'current_mode': 'default',
        'connection_type': 'online',
        'is_iap_user_n': isIap,
        'iap_count_n': iapCount,
        'win_streak_n': winStreak,
        'lose_streak_n': loseStreak,
        'balance_coin_n': coins,
      };

      debugPrint('[Analytics] setUserProperties: $props');
      FGSDK.setUserProperties(props);
    } catch (e) {
      debugPrint('[Analytics] updateUserProperties error: $e');
    }
  }

  // ── AppsFlyer Events (Sheet 2) ────────────────────────────────────────────
  /// Trigger khi ấn nút bất kỳ theo logic hiển thị Interstitial của game
  static void logAfIntersLogicGame() {
    try {
      debugPrint('[Analytics] af_inters_logicgame (AppsFlyer)');
      FGSDK.logEvent(
        'af_inters_logicgame',
        providers: [FGProviderType.appsFlyer],
      );
    } catch (e) {
      debugPrint('[Analytics] logAfIntersLogicGame error: $e');
    }
  }

  /// Trigger khi ấn nút bất kỳ theo logic hiển thị Rewarded của game
  static void logAfRewardedLogicGame() {
    try {
      debugPrint('[Analytics] af_rewarded_logicgame (AppsFlyer)');
      FGSDK.logEvent(
        'af_rewarded_logicgame',
        providers: [FGProviderType.appsFlyer],
      );
    } catch (e) {
      debugPrint('[Analytics] logAfRewardedLogicGame error: $e');
    }
  }

  /// Trigger khi hoàn thành level lần đầu tiên (param: level: level id)
  static void logAfLevelAchieved({required int level}) {
    try {
      debugPrint('[Analytics] af_level_achieved: level=$level (AppsFlyer)');
      FGSDK.logEvent(
        'af_level_achieved',
        params: {'level': level},
        providers: [FGProviderType.appsFlyer],
      );
    } catch (e) {
      debugPrint('[Analytics] logAfLevelAchieved error: $e');
    }
  }
}

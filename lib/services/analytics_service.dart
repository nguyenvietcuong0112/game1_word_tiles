import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _isInitialized = false;

  static FirebaseAnalytics? get analytics => _analytics;

  /// Initialize Firebase Core, Analytics, and Crashlytics
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _analytics = FirebaseAnalytics.instance;

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _isInitialized = true;
      debugPrint('[Firebase] Initialized successfully.');
    } catch (e, stack) {
      debugPrint('[Firebase] Init failed: $e\n$stack');
    }
  }

  /// Log Level Started Event
  static Future<void> logLevelStart({
    required int level,
    required String language,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'level_start',
        parameters: {
          'level_number': level,
          'language': language,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLevelStart error: $e');
    }
  }

  /// Log Level Completed Event
  static Future<void> logLevelComplete({
    required int level,
    required String language,
    required int stars,
    int? timeSpentSeconds,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'level_complete',
        parameters: {
          'level_number': level,
          'language': language,
          'stars': stars,
          'time_spent_sec': ?timeSpentSeconds,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLevelComplete error: $e');
    }
  }

  /// Log Level Failed / Retried Event
  static Future<void> logLevelFail({
    required int level,
    required String language,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'level_fail',
        parameters: {
          'level_number': level,
          'language': language,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLevelFail error: $e');
    }
  }

  /// Log Booster Used (Hint, Shuffle, Undo, etc.)
  static Future<void> logBoosterUsed({
    required String boosterType,
    required int level,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'booster_used',
        parameters: {
          'booster_type': boosterType,
          'level_number': level,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logBoosterUsed error: $e');
    }
  }

  /// Log Extra Bonus Word Found
  static Future<void> logExtraWordFound({
    required String word,
    required int totalCount,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'extra_word_found',
        parameters: {
          'word': word,
          'total_count': totalCount,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logExtraWordFound error: $e');
    }
  }

  /// Log Language Selected
  static Future<void> logLanguageSelected({
    required String language,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'language_selected',
        parameters: {
          'language': language,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logLanguageSelected error: $e');
    }
  }

  /// Log Shop Purchase
  static Future<void> logShopPurchase({
    required String itemId,
    required int cost,
  }) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'spend_virtual_currency',
        parameters: {
          'item_name': itemId,
          'value': cost,
          'virtual_currency_name': 'coins',
        },
      );
    } catch (e) {
      debugPrint('[Analytics] logShopPurchase error: $e');
    }
  }

  /// Log Screen View
  static Future<void> logScreenView(String screenName) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[Analytics] logScreenView error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static late SharedPreferences _prefs;
  static bool _isInitialized = false;

  static int? _cachedCoins;
  static final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(250);

  static int? _cachedExtraWordsChestCount;
  static int? _cachedHintCount;
  static int? _cachedRocketCount;

  static bool? _cachedTutorialCompleted;
  static bool? _cachedCountTutorialShown;
  static bool? _cachedReverseTutorialShown;
  static bool? _cachedHintTutorialShown;
  static bool? _cachedExtraWordsTutorialShown;

  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    _cachedCoins = _prefs.getInt('player_coins') ?? 250;
    coinsNotifier.value = _cachedCoins!;

    _cachedExtraWordsChestCount = _prefs.getInt('extra_words_chest_count') ?? 0;
    _cachedHintCount = _prefs.getInt('inventory_hint_count') ?? 2;
    _cachedRocketCount = _prefs.getInt('inventory_rocket_count') ?? 1;

    _cachedTutorialCompleted = _prefs.getBool('tutorial_completed') ?? false;
    _cachedCountTutorialShown = _prefs.getBool('count_tutorial_shown') ?? false;
    _cachedReverseTutorialShown = _prefs.getBool('reverse_tutorial_shown') ?? false;
    _cachedHintTutorialShown = _prefs.getBool('hint_tutorial_shown') ?? false;
    _cachedExtraWordsTutorialShown = _prefs.getBool('extra_words_tutorial_shown') ?? false;
  }

  // Selected Language
  static String getSelectedLanguage() {
    return _prefs.getString('selected_language') ?? 'english';
  }

  static String getLanguage() => getSelectedLanguage();

  static Future<void> setSelectedLanguage(String lang) async {
    await _prefs.setString('selected_language', lang);
  }

  // Current Level Index in Progression List (0-indexed)
  static int getCurrentLevelIndex(String language) {
    return _prefs.getInt('current_level_index_$language') ?? 0;
  }

  static Future<void> setCurrentLevelIndex(String language, int index) async {
    await _prefs.setInt('current_level_index_$language', index);
  }

  // Max Unlocked Level Index
  static int getMaxUnlockedLevelIndex(String language) {
    return _prefs.getInt('max_unlocked_level_index_$language') ?? 0;
  }

  static Future<void> setMaxUnlockedLevelIndex(String language, int index) async {
    final current = getMaxUnlockedLevelIndex(language);
    if (index > current) {
      await _prefs.setInt('max_unlocked_level_index_$language', index);
    }
  }

  // Level Stars (Map of Level ID -> Stars 1-3)
  static Map<int, int> getLevelStars(String language) {
    final raw = _prefs.getString('level_stars_$language');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveLevelStars(String language, int levelId, int stars) async {
    final currentMap = getLevelStars(language);
    if ((currentMap[levelId] ?? 0) < stars) {
      currentMap[levelId] = stars;
      final encoded = jsonEncode(currentMap.map((k, v) => MapEntry(k.toString(), v)));
      await _prefs.setString('level_stars_$language', encoded);
    }
  }

  // Coins (Start with 250 coins so player can test boosters)
  static int getCoins() {
    _cachedCoins ??= _prefs.getInt('player_coins') ?? 250;
    return _cachedCoins!;
  }

  static Future<void> addCoins(int amount) async {
    final current = getCoins();
    final updated = current + amount;
    _cachedCoins = updated;
    coinsNotifier.value = updated;
    await _prefs.setInt('player_coins', updated);
  }

  static Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current >= amount) {
      final updated = current - amount;
      _cachedCoins = updated;
      coinsNotifier.value = updated;
      await _prefs.setInt('player_coins', updated);
      return true;
    }
    return false;
  }

  // Extra Words Bank (Milestone: 10 words = 10 Coins Reward)
  static int getExtraWordsChestCount() {
    return _cachedExtraWordsChestCount ?? _prefs.getInt('extra_words_chest_count') ?? 0;
  }

  static Future<void> setExtraWordsChestCount(int count) async {
    _cachedExtraWordsChestCount = count;
    await _prefs.setInt('extra_words_chest_count', count);
  }

  static int addExtraWordToBank() {
    final current = getExtraWordsChestCount();
    final newCount = (current + 1).clamp(0, 10);
    setExtraWordsChestCount(newCount);
    return newCount;
  }

  static Future<bool> claimExtraWordsBankReward() async {
    final current = getExtraWordsChestCount();
    if (current >= 10) {
      await addCoins(10);
      await setExtraWordsChestCount(0);
      return true;
    }
    return false;
  }

  // Free Booster Inventory: 💡 Hint (80 Coins) & 🚀 Rocket (240 Coins)
  static int getHintCount() {
    return _cachedHintCount ?? _prefs.getInt('inventory_hint_count') ?? 2;
  }

  static Future<void> addHintCount(int amount) async {
    final current = getHintCount();
    final updated = current + amount;
    _cachedHintCount = updated;
    await _prefs.setInt('inventory_hint_count', updated);
  }

  static Future<bool> useHintItem() async {
    final current = getHintCount();
    if (current > 0) {
      final updated = current - 1;
      _cachedHintCount = updated;
      await _prefs.setInt('inventory_hint_count', updated);
      return true;
    }
    return false;
  }

  static int getRocketCount() {
    return _cachedRocketCount ?? _prefs.getInt('inventory_rocket_count') ?? 1;
  }

  static Future<void> addRocketCount(int amount) async {
    final current = getRocketCount();
    final updated = current + amount;
    _cachedRocketCount = updated;
    await _prefs.setInt('inventory_rocket_count', updated);
  }

  static Future<bool> useRocketItem() async {
    final current = getRocketCount();
    if (current > 0) {
      final updated = current - 1;
      _cachedRocketCount = updated;
      await _prefs.setInt('inventory_rocket_count', updated);
      return true;
    }
    return false;
  }

  // Daily Free Gift (24h Cooldown)
  static int getLastDailyGiftClaimTime() {
    return _prefs.getInt('last_daily_gift_claim_ms') ?? 0;
  }

  static Future<void> setLastDailyGiftClaimTime(int timestampMs) async {
    await _prefs.setInt('last_daily_gift_claim_ms', timestampMs);
  }

  static bool canClaimDailyGift() {
    final lastMs = getLastDailyGiftClaimTime();
    if (lastMs <= 0) return true;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final diff = DateTime.now().difference(lastTime);
    return diff.inMilliseconds >= const Duration(hours: 24).inMilliseconds;
  }

  static Duration getRemainingDailyGiftCooldown() {
    final lastMs = getLastDailyGiftClaimTime();
    if (lastMs <= 0) return Duration.zero;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final elapsed = DateTime.now().difference(lastTime);
    const totalDuration = Duration(hours: 24);
    if (elapsed >= totalDuration) return Duration.zero;
    return totalDuration - elapsed;
  }

  // Sound & Haptic Settings
  static bool getSoundEnabled() {
    return _prefs.getBool('sound_enabled') ?? true;
  }

  static bool isSoundEnabled() => getSoundEnabled();

  static Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool('sound_enabled', enabled);
  }

  static bool getHapticEnabled() {
    return _prefs.getBool('haptic_enabled') ?? true;
  }

  static bool isHapticEnabled() => getHapticEnabled();

  static Future<void> setHapticEnabled(bool enabled) async {
    await _prefs.setBool('haptic_enabled', enabled);
  }

  // In-Game Tutorial Progress
  static bool isTutorialCompleted() {
    return _cachedTutorialCompleted ?? _prefs.getBool('tutorial_completed') ?? false;
  }

  static Future<void> setTutorialCompleted(bool completed) async {
    _cachedTutorialCompleted = completed;
    await _prefs.setBool('tutorial_completed', completed);
  }

  static bool isCountTutorialShown() {
    return _cachedCountTutorialShown ?? _prefs.getBool('count_tutorial_shown') ?? false;
  }

  static Future<void> setCountTutorialShown(bool shown) async {
    _cachedCountTutorialShown = shown;
    await _prefs.setBool('count_tutorial_shown', shown);
  }

  static bool isReverseTutorialShown() {
    return _cachedReverseTutorialShown ?? _prefs.getBool('reverse_tutorial_shown') ?? false;
  }

  static Future<void> setReverseTutorialShown(bool shown) async {
    _cachedReverseTutorialShown = shown;
    await _prefs.setBool('reverse_tutorial_shown', shown);
  }

  static bool isHintTutorialShown() {
    return _cachedHintTutorialShown ?? _prefs.getBool('hint_tutorial_shown') ?? false;
  }

  static Future<void> setHintTutorialShown(bool shown) async {
    _cachedHintTutorialShown = shown;
    await _prefs.setBool('hint_tutorial_shown', shown);
  }

  static bool isExtraWordsTutorialShown() {
    return _cachedExtraWordsTutorialShown ?? _prefs.getBool('extra_words_tutorial_shown') ?? false;
  }

  static Future<void> setExtraWordsTutorialShown(bool shown) async {
    _cachedExtraWordsTutorialShown = shown;
    await _prefs.setBool('extra_words_tutorial_shown', shown);
  }

  // Ads Interstitial Gatekeeper
  static bool hasShownFirstInter() {
    return _prefs.getBool('has_shown_first_inter') ?? false;
  }

  static Future<void> setHasShownFirstInter(bool shown) async {
    await _prefs.setBool('has_shown_first_inter', shown);
  }

  // Reset Progress
  static Future<void> resetLanguageProgress(String language) async {
    await _prefs.remove('current_level_index_$language');
    await _prefs.remove('max_unlocked_level_index_$language');
    await _prefs.remove('level_stars_$language');
    await _prefs.remove('tutorial_completed');
    await _prefs.remove('count_tutorial_shown');
    await _prefs.remove('reverse_tutorial_shown');
    await _prefs.remove('hint_tutorial_shown');
    await _prefs.remove('extra_words_tutorial_shown');
    await _prefs.remove('has_shown_first_inter');

    _cachedTutorialCompleted = false;
    _cachedCountTutorialShown = false;
    _cachedReverseTutorialShown = false;
    _cachedHintTutorialShown = false;
    _cachedExtraWordsTutorialShown = false;
  }
}

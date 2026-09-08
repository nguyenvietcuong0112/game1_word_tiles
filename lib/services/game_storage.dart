import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static late SharedPreferences _prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
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
    return _prefs.getInt('player_coins') ?? 250;
  }

  static Future<void> addCoins(int amount) async {
    final current = getCoins();
    await _prefs.setInt('player_coins', current + amount);
  }

  static Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current >= amount) {
      await _prefs.setInt('player_coins', current - amount);
      return true;
    }
    return false;
  }

  // Extra Words Bank (Milestone: 10 words = 10 Coins Reward)
  static int getExtraWordsChestCount() {
    return _prefs.getInt('extra_words_chest_count') ?? 0;
  }

  static Future<void> setExtraWordsChestCount(int count) async {
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
    return _prefs.getInt('inventory_hint_count') ?? 2;
  }

  static Future<void> addHintCount(int amount) async {
    final current = getHintCount();
    await _prefs.setInt('inventory_hint_count', current + amount);
  }

  static Future<bool> useHintItem() async {
    final current = getHintCount();
    if (current > 0) {
      await _prefs.setInt('inventory_hint_count', current - 1);
      return true;
    }
    return false;
  }

  static int getRocketCount() {
    return _prefs.getInt('inventory_rocket_count') ?? 1;
  }

  static Future<void> addRocketCount(int amount) async {
    final current = getRocketCount();
    await _prefs.setInt('inventory_rocket_count', current + amount);
  }

  static Future<bool> useRocketItem() async {
    final current = getRocketCount();
    if (current > 0) {
      await _prefs.setInt('inventory_rocket_count', current - 1);
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
    return _prefs.getBool('tutorial_completed') ?? false;
  }

  static Future<void> setTutorialCompleted(bool completed) async {
    await _prefs.setBool('tutorial_completed', completed);
  }

  static bool isCountTutorialShown() {
    return _prefs.getBool('count_tutorial_shown') ?? false;
  }

  static Future<void> setCountTutorialShown(bool shown) async {
    await _prefs.setBool('count_tutorial_shown', shown);
  }

  // Reset Progress
  static Future<void> resetLanguageProgress(String language) async {
    await _prefs.remove('current_level_index_$language');
    await _prefs.remove('max_unlocked_level_index_$language');
    await _prefs.remove('level_stars_$language');
    await _prefs.remove('tutorial_completed');
    await _prefs.remove('count_tutorial_shown');
  }
}

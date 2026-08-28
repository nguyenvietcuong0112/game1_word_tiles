import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _language = 'english';
  int _currentLevelIndex = 0;
  int _coins = 0;
  List<int> _levelList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    await GameStorage.init();

    _language = GameStorage.getSelectedLanguage();
    _currentLevelIndex = GameStorage.getCurrentLevelIndex(_language);
    _coins = GameStorage.getCoins();

    _levelList = await LevelLoader.loadLevelList(_language);
    if (_currentLevelIndex >= _levelList.length && _levelList.isNotEmpty) {
      _currentLevelIndex = 0;
    }

    setState(() => _isLoading = false);
  }

  void _playCurrentLevel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          language: _language,
          levelIndex: _currentLevelIndex,
        ),
      ),
    ).then((_) => _loadState());
  }

  void _openLevelSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(language: _language),
      ),
    ).then((_) => _loadState());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(onLanguageChanged: _loadState),
      ),
    ).then((_) => _loadState());
  }

  void _openShop() {
    showDialog(
      context: context,
      builder: (_) => ShopDialog(onUpdated: () => _loadState()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }

    final levelNumber = _currentLevelIndex + 1;
    final nextMilestone = ((levelNumber ~/ 10) + 1) * 10;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings Button
                  InkWell(
                    onTap: _openSettings,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.cardPeachLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.settings_rounded, color: AppColors.textDark, size: 24),
                    ),
                  ),

                  // Coins Pill
                  InkWell(
                    onTap: _openShop,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardPeachLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            '$_coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Title: "WORD TILES"
              _buildTitle(),

              const Spacer(flex: 1),

              // Single Progress & Milestone Badge (1:1 with Original Game)
              InkWell(
                onTap: _openLevelSelect,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.cardPeachLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderDark, width: 1.5),
                        ),
                        child: const Icon(Icons.emoji_events_outlined, size: 28, color: AppColors.terracotta),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Milestone: Level $nextMilestone',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level $levelNumber of ${_levelList.length} • Tap to view all',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Big Terracotta Action Button: "LEVEL X"
              InkWell(
                onTap: _playCurrentLevel,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LEVEL $levelNumber',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    ],
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOut),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'WORD',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppColors.terracotta,
            letterSpacing: 6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['T', 'I', 'L', 'E', 'S'].map((letter) {
            return Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.tileFace,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderDark.withOpacity(0.15),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

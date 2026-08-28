import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/game_controller.dart';
import '../models/level_model.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/booster_bar.dart';
import 'widgets/shop_dialog.dart';
import 'widgets/target_words_bar.dart';
import 'widgets/victory_dialog.dart';

class GameScreen extends StatefulWidget {
  final String? language;
  final int? levelIndex;
  final int? levelId;

  const GameScreen({
    super.key,
    this.language,
    this.levelIndex,
    this.levelId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late String _language;
  late int _levelIndex;
  int? _levelId;

  GameController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  List<int> _levelList = [];

  @override
  void initState() {
    super.initState();
    _language = widget.language ?? GameStorage.getSelectedLanguage();
    _levelIndex = widget.levelIndex ?? GameStorage.getCurrentLevelIndex(_language);
    _levelId = widget.levelId;
    _loadGame();
  }

  Future<void> _loadGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _levelList = await LevelLoader.loadLevelList(_language);

      if (_levelList.isEmpty) {
        setState(() {
          _errorMessage = 'No levels found for $_language.';
          _isLoading = false;
        });
        return;
      }

      if (_levelIndex >= _levelList.length) {
        _levelIndex = 0;
      }

      _levelId = _levelList[_levelIndex];
      final levelModel = await LevelLoader.loadLevel(_language, _levelId!);

      if (levelModel == null) {
        setState(() {
          _errorMessage = 'Could not load Level $_levelId for $_language.';
          _isLoading = false;
        });
        return;
      }

      await GameStorage.setCurrentLevelIndex(_language, _levelIndex);

      _controller = GameController(
        language: _language,
        levelId: _levelId!,
        levelNumber: _levelIndex + 1,
        level: levelModel,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _nextLevel() {
    final nextIndex = _levelIndex + 1;
    if (nextIndex < _levelList.length) {
      _levelIndex = nextIndex;
      _levelId = _levelList[nextIndex];
      _loadGame();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Congratulations! You completed all levels!')),
      );
    }
  }

  void _replayLevel() {
    _loadGame();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onLanguageChanged: () {
            _language = GameStorage.getSelectedLanguage();
            _levelIndex = GameStorage.getCurrentLevelIndex(_language);
            _loadGame();
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openLevelSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(language: _language),
      ),
    ).then((_) {
      _levelIndex = GameStorage.getCurrentLevelIndex(_language);
      _loadGame();
    });
  }

  void _openShop() {
    showDialog(
      context: context,
      builder: (_) => ShopDialog(onUpdated: () => setState(() {})),
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

    if (_errorMessage != null || _controller == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Unknown error', style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadGame,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller!,
          builder: (context, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    // Top Navigation Bar
                    _buildHeader(),

                    // Crossword Target Words Stack
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: SingleChildScrollView(
                          child: TargetWordsBar(controller: _controller!),
                        ),
                      ),
                    ),

                    // Floating Live Word Preview Bubble
                    _buildPreviewAndFeedback(),

                    // Letter Board Container
                    Expanded(
                      flex: 4,
                      child: BoardWidget(controller: _controller!),
                    ),

                    // Bottom Action Bar
                    BoosterBar(
                      controller: _controller!,
                      onOpenShop: _openShop,
                      onOpenLevelSelect: _openLevelSelect,
                    ),
                  ],
                ),

                // Victory Overlay Modal
                if (_controller!.isWon)
                  VictoryOverlay(
                    controller: _controller!,
                    onNextLevel: _nextLevel,
                    onReplay: _replayLevel,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final coins = GameStorage.getCoins();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back & Settings Circular Buttons with 2px dark borders
              Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardPeachLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Settings Button
                  InkWell(
                    onTap: _openSettings,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardPeachLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.settings_rounded, color: AppColors.textDark, size: 24),
                    ),
                  ),
                ],
              ),

              // Title: Level X
              Text(
                'Level ${_controller!.levelNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),

              // Right: Coin Pill
              InkWell(
                onTap: _openShop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewAndFeedback() {
    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final currentWord = _controller!.currentWord;

        return Container(
          height: 42,
          alignment: Alignment.center,
          child: currentWord.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderDark, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.borderDark.withOpacity(0.2),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    currentWord,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ).animate().scale(duration: 90.ms, curve: Curves.easeOut)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

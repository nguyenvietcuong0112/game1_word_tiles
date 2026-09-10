import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../services/ads_manager.dart';
import '../services/analytics_service.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import '../utils/game_transitions.dart';
import '../widgets/common/game_background.dart';
import '../widgets/common/game_button.dart';
import '../widgets/common/game_dialog.dart';
import '../widgets/common/game_icon_button.dart';
import '../widgets/common/game_scaffold.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/booster_bar.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/extra_words_dialog.dart';
import 'widgets/shop_dialog.dart';
import 'widgets/target_words_bar.dart';
import 'widgets/tutorial_overlay.dart';
import 'widgets/victory_dialog.dart';

class GameScreen extends StatefulWidget {
  final String language;
  final int levelIndex;

  const GameScreen({
    super.key,
    required this.language,
    required this.levelIndex,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController? _controller;
  late ConfettiController _confettiController;
  bool _isLoading = true;
  String? _errorMessage;
  late int _currentLevelIndex;

  @override
  void initState() {
    super.initState();
    AdsManager.hideBanner();
    _currentLevelIndex = widget.levelIndex;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final levelIds = await LevelLoader.loadLevelList(widget.language);
      if (levelIds.isEmpty) {
        throw Exception('No levels found for ${widget.language}');
      }

      if (_currentLevelIndex >= levelIds.length) {
        _currentLevelIndex = levelIds.length - 1;
      }

      final levelId = levelIds[_currentLevelIndex];
      final level = await LevelLoader.loadLevel(widget.language, levelId);
      if (level == null) {
        throw Exception('Failed to load level $levelId');
      }

      await GameStorage.setCurrentLevelIndex(widget.language, _currentLevelIndex);

      _controller = GameController(
        language: widget.language,
        levelId: levelId,
        levelNumber: _currentLevelIndex + 1,
        level: level,
      );

      AnalyticsService.logLevelStart(
        level: _currentLevelIndex + 1,
        language: widget.language,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load level: $e';
      });
    }
  }

  void _nextLevel() {
    setState(() {
      _currentLevelIndex++;
    });
    _loadGame();
  }

  void _replayLevel() {
    _loadGame();
  }

  void _openSettings() {
    AudioManager.playTileSelect(pitchIndex: 4);
    Navigator.push(
      context,
      GamePageRoute(
        child: SettingsScreen(
          onLanguageChanged: () {
            _loadGame();
          },
        ),
      ),
    );
  }

  void _openExtraWords() {
    if (_controller == null) return;
    ExtraWordsDialog.show(
      context,
      controller: _controller!,
      onUpdated: () => setState(() {}),
    );
  }

  void _openShop() {
    AudioManager.playTileSelect(pitchIndex: 4);
    showGameDialog(
      context: context,
      builder: (_) => ShopDialog(
        onUpdated: () => setState(() {}),
      ),
    );
  }

  void _openLevelSelect() async {
    AudioManager.playTileSelect(pitchIndex: 3);
    final selectedIndex = await Navigator.push<int>(
      context,
      GamePageRoute(
        child: LevelSelectScreen(
          language: widget.language,
          isFromGame: true,
        ),
      ),
    );

    AdsManager.hideBanner();

    if (selectedIndex != null && selectedIndex != _currentLevelIndex && mounted) {
      setState(() {
        _currentLevelIndex = selectedIndex;
      });
      _loadGame();
    }
  }

  Future<void> _handleBackConfirmation() async {
    AudioManager.playTileSelect(pitchIndex: 2);
    final shouldResume = await GameDialog.showConfirm(
      context,
      icon: '⏸️',
      title: 'Pause Game',
      message: 'Do you want to pause the game and return to the main menu?',
      cancelText: 'Quit',
      confirmText: 'Resume',
    );

    if (shouldResume == false && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GameScaffold(
        backgroundVariant: GameBackgroundVariant.gameplay,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.btnFaceBrown),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return GameScaffold(
        backgroundVariant: GameBackgroundVariant.gameplay,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Unknown error',
                  style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              GameButton.primary(
                text: 'Retry',
                size: GameButtonSize.small,
                onTap: _loadGame,
              ),
            ],
          ),
        ),
      );
    }

    final isMountainChapter = _controller?.chapterNumber == 2;

    return GameScaffold(
      backgroundVariant: isMountainChapter ? GameBackgroundVariant.mountainRoad : GameBackgroundVariant.gameplay,
      onWillPop: () async {
        await _handleBackConfirmation();
        return false;
      },
      body: ListenableBuilder(
        listenable: _controller!,
        builder: (context, _) {
          final isLevel1Tut = !_controller!.isWon &&
              !GameStorage.isTutorialCompleted() &&
              _controller!.levelNumber == 1 &&
              _controller!.solvedTargetWords.length < 2;

          final isCountTut = !_controller!.isWon &&
              _controller!.levelNumber == 2 &&
              !GameStorage.isCountTutorialShown() &&
              _controller!.getFirstTileWithCountGreaterThanOne() != null;

          final isReverseTut = !_controller!.isWon &&
              _controller!.levelNumber == 4 &&
              !GameStorage.isReverseTutorialShown() &&
              _controller!.solvedTargetWords.isEmpty;

          if (_controller!.levelNumber == 4 &&
              _controller!.solvedTargetWords.isNotEmpty &&
              !GameStorage.isReverseTutorialShown()) {
            GameStorage.setReverseTutorialShown(true);
          }

          final isHintTut = !_controller!.isWon &&
              _controller!.levelNumber == 5 &&
              !GameStorage.isHintTutorialShown();

          final isExtraWordsTut = !_controller!.isWon &&
              _controller!.levelNumber == 7 &&
              !GameStorage.isExtraWordsTutorialShown();

          final isDarkScrimTut = isLevel1Tut || isCountTut || isReverseTut || isHintTut || isExtraWordsTut;

          return Stack(
            children: [
              // Dark background scrim behind gameplay when any tutorial is active
              if (isDarkScrimTut)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),

              // Main Playing Interface with Smooth Level Transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('level-$_currentLevelIndex'),
                  child: Column(
                    children: [
                      // Header (dimmed when tutorial is active)
                      AnimatedOpacity(
                        opacity: isDarkScrimTut ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: _buildHeader(),
                      ),
                      // TargetWordsBar (dimmed when tutorial is active)
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: SingleChildScrollView(
                            child: AnimatedOpacity(
                              opacity: isDarkScrimTut ? 0.20 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: TargetWordsBar(controller: _controller!),
                            ),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isDarkScrimTut ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: _buildPreviewAndFeedback(),
                      ),
                      // BoardWidget (Dimmed only on Level 5 & Level 7, full 100% on Level 1, 2, 4)
                      Expanded(
                        flex: 4,
                        child: AnimatedOpacity(
                          opacity: (isHintTut || isExtraWordsTut) ? 0.20 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: BoardWidget(controller: _controller!),
                        ),
                      ),
                      // BoosterBar (Spotlighted on Level 5 & Level 7, dimmed on other tutorials)
                      AnimatedOpacity(
                        opacity: (isDarkScrimTut && !isHintTut && !isExtraWordsTut) ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: BoosterBar(
                          controller: _controller!,
                          onOpenShop: _openShop,
                          onOpenExtraWords: _openExtraWords,
                          isHintSpotlighted: isHintTut,
                          isExtraWordsSpotlighted: isExtraWordsTut,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Level 1: Centered Floating Swipe Tutorial Card (Step 1 & Step 2)
              if (isLevel1Tut)
                Builder(
                  builder: (_) {
                    final solvedCount = _controller!.solvedTargetWords.length;
                    final nextWord = _controller!.getNextUnsolvedTargetWord() ?? 'SUN';
                    return SwipeTutorialCard(
                      spans: solvedCount == 1
                          ? [
                              const TextSpan(text: 'You can go left, right, up, or down.\nSwipe the Word '),
                              TextSpan(
                                text: '"$nextWord"',
                                style: const TextStyle(
                                  color: Color(0xFFE11D48),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ]
                          : [
                              const TextSpan(text: 'Swipe the Word '),
                              TextSpan(
                                text: '"$nextWord"',
                                style: const TextStyle(
                                  color: Color(0xFFE11D48),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                    );
                  },
                ),

              // Level 2: Centered Tile Usage Count Explanation Modal
              if (isCountTut)
                TileCountTutorialModal(
                  onDismiss: () => setState(() {}),
                ),

              // Level 4: Centered Reverse Swipe Tutorial Card
              if (isReverseTut)
                const SwipeTutorialCard(
                  spans: [
                    TextSpan(text: 'You can also swipe\nwords '),
                    TextSpan(
                      text: 'backwards',
                      style: TextStyle(
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),

              // Level 5 Hint Booster Tutorial Overlay
              if (isHintTut)
                HintBoosterTutorialOverlay(
                  onDismiss: () => setState(() {}),
                ),

              // Level 7 Extra Words Tutorial Overlay
              if (isExtraWordsTut)
                ExtraWordsTutorialOverlay(
                  onDismiss: () => setState(() {}),
                ),

              // Single Unified 120fps Victory Orchestration (Dark Scrim + Gold WELL DONE + Victory Card + Confetti)
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
    );
  }

  Widget _buildHeader() {
    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final coins = GameStorage.getCoins();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GameIconButton.back(
                    context,
                    onTap: _handleBackConfirmation,
                  ),
                  SizedBox(width: 10.w),
                  GameIconButton.settings(
                    onTap: _openSettings,
                  ),
                ],
              ),
              BouncyButton(
                onTap: _openLevelSelect,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE8DAC8),
                        offset: Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'LEVEL ${_controller!.levelNumber}',
                    style: GoogleFonts.fredoka(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headerBrown,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              BouncyButton(
                onTap: _openShop,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE8DAC8),
                        offset: Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🪙', style: TextStyle(fontSize: 16.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        '$coins',
                        style: GoogleFonts.fredoka(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
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
        final word = _controller!.currentWord;
        final feedback = _controller!.feedbackMessage;
        final feedbackColor = _controller!.feedbackColor ?? AppColors.btnFaceBrown;

        if (feedback != null) {
          return Container(
            height: 52.h,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: feedbackColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE8DAC8),
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                feedback,
                style: GoogleFonts.fredoka(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            )
                .animate()
                .scale(duration: 150.ms, curve: Curves.easeOutBack)
                .shake(duration: 300.ms),
          );
        }

        if (word.isNotEmpty) {
          return Container(
            height: 52.h,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.btnFaceBrown,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.btnBorderBrown, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.btnShadowBrown,
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                word,
                style: GoogleFonts.fredoka(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ).animate().scale(duration: 100.ms, curve: Curves.easeOut),
          );
        }

        return SizedBox(height: 52.h);
      },
    );
  }
}

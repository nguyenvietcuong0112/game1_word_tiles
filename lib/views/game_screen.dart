import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../models/chapter_model.dart';
import '../services/ads_manager.dart';
import '../services/analytics_service.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import '../utils/game_transitions.dart';
import '../widgets/common/game_button.dart';
import '../widgets/common/game_scaffold.dart';
import 'level_select_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/booster_bar.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/extra_word_fly_effect.dart';
import 'widgets/extra_words_dialog.dart';
import 'widgets/settings_dialog.dart';
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
  GlobalKey<BoardWidgetState> _boardKey = GlobalKey<BoardWidgetState>();
  GlobalKey<ExtraWordsButtonState> _extraWordsBtnKey = GlobalKey<ExtraWordsButtonState>();

  GameController? _controller;
  late ConfettiController _confettiController;
  bool _isLoading = true;
  String? _errorMessage;
  late int _currentLevelIndex;

  int _lastSolvedWordsCount = 0;
  bool _lastIsWon = false;
  List<Point<int>>? _lastFailSafeHintPath;
  int _lastExtraFoundCount = 0;

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
    _controller?.removeListener(_onGameControllerStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onGameControllerStateChanged() {
    if (!mounted || _controller == null) return;
    final isWon = _controller!.isWon;
    final solvedCount = _controller!.solvedTargetWords.length;
    final failSafePath = _controller!.failSafeHintPath;
    final extraFoundCount = _controller!.foundExtraWords.length;

    if (isWon != _lastIsWon ||
        solvedCount != _lastSolvedWordsCount ||
        failSafePath != _lastFailSafeHintPath ||
        extraFoundCount != _lastExtraFoundCount) {
      _lastIsWon = isWon;
      _lastSolvedWordsCount = solvedCount;
      _lastFailSafeHintPath = failSafePath;
      _lastExtraFoundCount = extraFoundCount;
      setState(() {});
    }
  }

  Future<void> _loadGame({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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

      _controller?.removeListener(_onGameControllerStateChanged);
      _controller?.dispose();

      _controller = GameController(
        language: widget.language,
        levelId: levelId,
        levelNumber: _currentLevelIndex + 1,
        level: level,
      );
      _lastSolvedWordsCount = 0;
      _lastIsWon = false;
      _lastFailSafeHintPath = null;
      _lastExtraFoundCount = 0;
      _controller!.addListener(_onGameControllerStateChanged);

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
      _boardKey = GlobalKey<BoardWidgetState>();
      _extraWordsBtnKey = GlobalKey<ExtraWordsButtonState>();
    });
    _loadGame(showLoading: false);
  }

  void _replayLevel() {
    setState(() {
      _boardKey = GlobalKey<BoardWidgetState>();
      _extraWordsBtnKey = GlobalKey<ExtraWordsButtonState>();
    });
    _loadGame();
  }

  void _openSettings() {
    AudioManager.playTileSelect(pitchIndex: 4);
    showGameDialog(
      context: context,
      builder: (context) => SettingsDialog(
        isHomeScreen: false,
        onRestartLevel: () {
          _replayLevel();
        },
        onGoHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
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

  Widget _buildBackground() {
    final chapterNumber = _controller?.chapterNumber ?? 1;
    final bgPath = ChapterTheme.getImagePath(chapterNumber);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Image.asset(
        bgPath,
        key: ValueKey<String>(bgPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/bg_home.webp',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _controller == null) {
      return GameScaffold(
        useSafeArea: false,
        background: _buildBackground(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.btnFaceBrown),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return GameScaffold(
        background: _buildBackground(),
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

    final isRocketTut = !_controller!.isWon &&
        _controller!.levelNumber == 7 &&
        !isExtraWordsTut &&
        !GameStorage.isRocketTutorialShown();

    final isDarkScrimTut = isLevel1Tut || isCountTut || isReverseTut || isHintTut || isExtraWordsTut || isRocketTut;

    return GameScaffold(
      useSafeArea: false,
      background: _buildBackground(),
      canPop: false,
      body: Stack(
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
                      // TargetWordsBar with Side Buttons (Gift & Star Progress)
                      Expanded(
                        flex: 5,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: SingleChildScrollView(
                                child: AnimatedOpacity(
                                  opacity: isDarkScrimTut ? 0.20 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: TargetWordsBar(controller: _controller!),
                                ),
                              ),
                            ),
                            // Left Gift Box Button
                            Positioned(
                              top: 8.h,
                              left: 16.w,
                              child: AnimatedOpacity(
                                opacity: isDarkScrimTut ? 0.20 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: _buildGiftButton(),
                              ),
                            ),
                            // Right Star / Extra Words Button (Spotlighted and lit up on Level 7)
                            Positioned(
                              top: 8.h,
                              right: 16.w,
                              child: AnimatedOpacity(
                                opacity: (isDarkScrimTut && !isExtraWordsTut) ? 0.20 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: ExtraWordsButton(
                                  key: _extraWordsBtnKey,
                                  extraCount: GameStorage.getExtraWordsChestCount(),
                                  onTap: () {
                                    if (isExtraWordsTut) {
                                      GameStorage.setExtraWordsTutorialShown(true);
                                      setState(() {});
                                    }
                                    _openExtraWords();
                                  },
                                  isSpotlighted: isExtraWordsTut,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isDarkScrimTut ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: _buildPreviewAndFeedback(),
                      ),
                      // BoardWidget (Dimmed on Level 5 & Level 7 tutorials, full 100% on Level 1, 2, 4)
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: (isHintTut || isExtraWordsTut || isRocketTut) ? 0.20 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: BoardWidget(
                              key: _boardKey,
                              controller: _controller!,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // BoosterBar (Spotlighted on Level 5 Hint & Level 7 Rocket, dimmed on other tutorials including Extra Words)
                      AnimatedOpacity(
                        opacity: (isDarkScrimTut && !isHintTut && !isRocketTut) ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: isDarkScrimTut && !isHintTut && !isRocketTut,
                          child: BoosterBar(
                            controller: _controller!,
                            onOpenShop: _openShop,
                            onOpenExtraWords: _openExtraWords,
                            onHintTap: () {
                              if (isHintTut) {
                                GameStorage.setHintTutorialShown(true);
                                setState(() {});
                              }
                            },
                            onRocketTap: () {
                              if (isRocketTut) {
                                GameStorage.setRocketTutorialShown(true);
                                setState(() {});
                              }
                            },
                            isHintSpotlighted: isHintTut,
                            isRocketSpotlighted: isRocketTut,
                            extraWordsBtnKey: _extraWordsBtnKey,
                          ),
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
                                  color: Color(0xFFDD4C8E),
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
                                  color: Color(0xFFDD4C8E),
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
                        color: Color(0xFFDD4C8E),
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

              // Level 7 Rocket Booster Tutorial Overlay
              if (isRocketTut)
                RocketBoosterTutorialOverlay(
                  onDismiss: () => setState(() {}),
                ),

              // Single Unified 120fps Victory Orchestration (Dark Scrim + Gold WELL DONE + Victory Card + Confetti)
              if (_controller!.isWon)
                VictoryOverlay(
                  controller: _controller!,
                  onNextLevel: _nextLevel,
                  onReplay: _replayLevel,
                ),

              // Flying Extra Word Jump Animation & Visual FX Layer
              Positioned.fill(
                child: ExtraWordFlyOverlay(
                  controller: _controller!,
                  boardKey: _boardKey,
                  extraWordsBtnKey: _extraWordsBtnKey,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SizedBox(
          height: 44.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Perfectly centered Level Text
              Center(
                child: BouncyButton(
                  onTap: _openLevelSelect,
                  child: Text(
                    'LEVEL ${_controller!.levelNumber}',
                    style: GoogleFonts.fredoka(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 1.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 2. Left Coins Capsule
              Align(
                alignment: Alignment.centerLeft,
                child: _buildCoinCapsule(),
              ),
              // 3. Right Settings Button
              Align(
                alignment: Alignment.centerRight,
                child: BouncyButton(
                  onTap: _openSettings,
                  child: Image.asset(
                    'assets/icons/icon_setting.webp',
                    width: 44.r,
                    height: 44.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinCapsule() {
    return BouncyButton(
      // onTap: _openShop,
      child: SizedBox(
        height: 44.h,
        child: IntrinsicWidth(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                margin: EdgeInsets.only(left: 18.w),
                height: 34.h,
                constraints: BoxConstraints(minWidth: 78.w),
                padding: EdgeInsets.only(left: 20.w, right: 14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF26499D),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: ValueListenableBuilder<int>(
                  valueListenable: GameStorage.coinsNotifier,
                  builder: (context, coins, _) {
                    return Text(
                      '$coins',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    );
                  },
                ),
              ),
              Image.asset(
                'assets/icons/icon_coin.webp',
                width: 44.r,
                height: 44.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftButton() {
    final canClaim = GameStorage.canClaimDailyGift();
    return BouncyButton(
      onTap: _openShop,
      child: SizedBox(
        width: 54.r,
        height: 64.r,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              child: Image.asset(
                'assets/icons/icon_gift_box.webp',
                width: 48.r,
                height: 48.r,
                fit: BoxFit.contain,
              ),
            ),
            if (canClaim)
              Positioned(
                top: -2.h,
                right: 0,
                child: Image.asset(
                  'assets/icons/icon_notice.webp',
                  width: 20.r,
                  height: 20.r,
                  fit: BoxFit.contain,
                ),
              ),
            Positioned(
              bottom: 5.h,
              child: GreenPillBadge.text(text: 'GIFT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAndFeedback() {
    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final word = _controller!.currentWord;
        final feedback = _controller!.feedbackMessage;
        final theme = _controller!.chapterTheme;
        final feedbackColor = _controller!.feedbackColor ?? theme.primaryColor;

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
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: theme.borderColor, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.bevelColor,
                    offset: const Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                word,
                style: GoogleFonts.fredoka(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
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

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../services/analytics_service.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import 'common/app_background.dart';
import 'common/wood_widgets.dart';
import '../theme/app_theme.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/booster_bar.dart';
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
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
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
    showDialog(
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
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(
          language: widget.language,
          isFromGame: true,
        ),
      ),
    );

    if (selectedIndex != null && selectedIndex != _currentLevelIndex && mounted) {
      setState(() {
        _currentLevelIndex = selectedIndex;
      });
      _loadGame();
    }
  }

  Future<void> _handleBackConfirmation() async {
    AudioManager.playTileSelect(pitchIndex: 2);
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WoodSignboardDialog(
        title: 'WANT TO EXIT?',
        onClose: () => Navigator.of(ctx).pop(false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Text(
              'Do you want to pause and return to the main menu?',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFE8CC),
                height: 1.35,
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: WoodCtaButton(
                    text: 'YES',
                    isGreen: true,
                    onTap: () {
                      AudioManager.playTileSelect(pitchIndex: 1);
                      Navigator.of(ctx).pop(true);
                    },
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: WoodCtaButton(
                    text: 'NO',
                    onTap: () {
                      AudioManager.playBooster();
                      Navigator.of(ctx).pop(false);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.terracotta),
          ),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage ?? 'Unknown error',
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                WoodenButton(
                  text: 'RETRY',
                  width: 140.w,
                  height: 48.h,
                  textColor: Colors.white,
                  onTap: _loadGame,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackConfirmation();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: ListenableBuilder(
            listenable: _controller!,
            builder: (context, _) {
              final isCountTutorialActive = !_controller!.isWon &&
                  !GameStorage.isCountTutorialShown() &&
                  _controller!.getFirstTileWithCountGreaterThanOne() != null;

              return Stack(
                children: [
                  // Main Playing Interface
                  Column(
                    children: [
                      AnimatedOpacity(
                        opacity: isCountTutorialActive ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: isCountTutorialActive,
                          child: _buildHeader(),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: AnimatedOpacity(
                          opacity: isCountTutorialActive ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: IgnorePointer(
                            ignoring: isCountTutorialActive,
                            child: TargetWordsBar(controller: _controller!),
                          ),
                        ),
                      ),
                      AnimatedOpacity( 
                        opacity: isCountTutorialActive ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: isCountTutorialActive,
                          child: _buildPreviewAndFeedback(),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: IgnorePointer(
                          ignoring: isCountTutorialActive,
                          child: BoardWidget(controller: _controller!),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isCountTutorialActive ? 0.20 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: isCountTutorialActive,
                          child: BoosterBar(
                            controller: _controller!,
                            onOpenShop: _openShop,
                            onOpenExtraWords: _openExtraWords,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tile Usage Count Explanation Modal (Only shown once when count > 1, spotlighting 1 single letter)
                  if (!_controller!.isWon &&
                      !GameStorage.isCountTutorialShown() &&
                      _controller!.getFirstTileWithCountGreaterThanOne() != null)
                    Builder(
                      builder: (_) {
                        final pt = _controller!.getFirstTileWithCountGreaterThanOne()!;
                        final tile = _controller!.grid[pt.y][pt.x];
                        return TileCountTutorialModal(
                          sampleLetter: tile.letter,
                          count: tile.count,
                          onDismiss: () => setState(() {}),
                        );
                      },
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
        ),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  WoodCarvedIconButton(
                    size: 44.r,
                    assetPath: WoodGameIcons.btnBack,
                    onTap: _handleBackConfirmation,
                  ),
                  SizedBox(width: 10.w),
                  WoodCarvedIconButton(
                    size: 44.r,
                    assetPath: WoodGameIcons.btnSettings,
                    onTap: _openSettings,
                  ),
                ],
              ),
              WoodenBadge(
                text: 'LEVEL ${_controller!.levelNumber}',
                textColor: const Color(0xFFAEF82C),
                onTap: _openLevelSelect,
              ),
              WoodenCurrency(
                coins: coins,
                onTap: _openShop,
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
        final feedbackColor = _controller!.feedbackColor ?? WoodenStyle.rubyMid;

        if (feedback != null) {
          return Container(
            height: 52.h,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: feedbackColor,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: WoodenStyle.woodExtrusion, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: WoodenStyle.woodExtrusion,
                    offset: Offset(0, 3.0),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                feedback,
                style: GoogleFonts.fredoka(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: const [
                    Shadow(color: Color(0xFF260C00), offset: Offset(0, 1.5)),
                  ],
                ),
              ),
            )
                .animate(key: ValueKey(feedback))
                .scale(
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.75, 0.75),
                  end: const Offset(1.0, 1.0),
                )
                .shake(duration: 250.ms),
          );
        }

        if (word.isNotEmpty) {
          return Container(
            height: 52.h,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    WoodenStyle.woodHighlight,
                    WoodenStyle.woodTop,
                    WoodenStyle.woodMid,
                    WoodenStyle.woodDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: WoodenStyle.woodBevel, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: WoodenStyle.woodExtrusion,
                    offset: Offset(0, 3.0),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                word,
                style: GoogleFonts.fredoka(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.5,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF260C00),
                      offset: Offset(0, 1.8),
                    ),
                  ],
                ),
              ),
            ).animate().scale(duration: 100.ms, curve: Curves.easeOut),
          );
        }

        // In-Game Tutorial Banner (Level 1 only, placed seamlessly between TargetWords and Board)
        if (!GameStorage.isTutorialCompleted() && _controller!.levelNumber == 1 && !_controller!.isWon) {
          final nextWord = _controller!.getNextUnsolvedTargetWord();
          if (nextWord != null) {
            final isStep2 = _controller!.solvedTargetWords.isNotEmpty;
            return Container(
              height: 52.h,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: GoldenWoodColors.woodBevel, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: GoldenWoodColors.woodExtrusion,
                      offset: Offset(0, 2.5),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Golden Honey Oak wood gradient
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFD868),
                                Color(0xFFF3942B),
                                Color(0xFFD97213),
                                Color(0xFFAC4B04),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Real wood grain texture
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.32,
                          child: Image.asset(
                            'assets/images/golden_wood_texture.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      // Top highlight specular rim
                      Positioned(
                        top: 0,
                        left: 10,
                        right: 10,
                        height: 1.2,
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                        child: isStep2
                            ? RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.fredoka(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: GoldenWoodColors.carvedDark,
                                    shadows: const [
                                      Shadow(
                                        color: GoldenWoodColors.carvedShadowLight,
                                        offset: Offset(0, 1.2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  children: [
                                    const TextSpan(text: 'Swipe in any direction: '),
                                    TextSpan(
                                      text: '"$nextWord"',
                                      style: const TextStyle(
                                        color: Color(0xFF4A1A02),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: GoldenWoodColors.carvedDark,
                                    shadows: const [
                                      Shadow(
                                        color: GoldenWoodColors.carvedShadowLight,
                                        offset: Offset(0, 1.2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  children: [
                                    const TextSpan(text: 'Swipe the Word '),
                                    TextSpan(
                                      text: '"$nextWord"',
                                      style: const TextStyle(
                                        color: Color(0xFF4A1A02),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 250.ms, curve: Curves.easeOutBack)
                  .shimmer(duration: 1600.ms, color: Colors.white.withValues(alpha: 0.35)),
            );
          }
        }

        return SizedBox(height: 52.h);
      },
    );
  }
}

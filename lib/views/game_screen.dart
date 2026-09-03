import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_controller.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.borderSubtle, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE8DAC8),
                offset: Offset(0, 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: AppColors.butterCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFCD34D),
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⏸️', style: TextStyle(fontSize: 26)),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Pause Game',
                style: GoogleFonts.fredoka(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Do you want to pause the game and return to the main menu?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioManager.playTileSelect(pitchIndex: 1);
                        Navigator.of(ctx).pop(true);
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.cardPeachLight,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: AppColors.borderSubtle, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFE8DAC8),
                              offset: Offset(0, 2.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Quit',
                            style: GoogleFonts.fredoka(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.headerBrown,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () {
                        AudioManager.playBooster();
                        Navigator.of(ctx).pop(false);
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFCA9370),
                              AppColors.btnFaceBrown,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: AppColors.btnBorderBrown, width: 1.8),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 4.w),
                            Text(
                              'Resume',
                              style: GoogleFonts.fredoka(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.btnFaceBrown),
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
              Text(_errorMessage ?? 'Unknown error',
                  style: const TextStyle(color: Colors.redAccent)),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller!,
            builder: (context, _) {
              return Stack(
                children: [
                  // Main Playing Interface
                  Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: SingleChildScrollView(
                            child: TargetWordsBar(controller: _controller!),
                          ),
                        ),
                      ),
                      _buildPreviewAndFeedback(),
                      Expanded(
                        flex: 4,
                        child: BoardWidget(controller: _controller!),
                      ),
                      BoosterBar(
                        controller: _controller!,
                        onOpenShop: _openShop,
                        onOpenExtraWords: _openExtraWords,
                      ),
                    ],
                  ),

                  // Tile Usage Count Explanation Modal (Only shown once when count > 1)
                  if (!_controller!.isWon &&
                      !GameStorage.isCountTutorialShown() &&
                      _controller!.getFirstTileWithCountGreaterThanOne() != null)
                    TileCountTutorialModal(
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
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _handleBackConfirmation,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: AppColors.btnRingBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.btnRingBorder, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.btnRingShadow,
                            offset: Offset(0, 2.0),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.btnFaceBrown,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.btnBorderBrown, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  InkWell(
                    onTap: _openSettings,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: AppColors.btnRingBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.btnRingBorder, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.btnRingShadow,
                            offset: Offset(0, 2.0),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.btnFaceBrown,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.btnBorderBrown, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _openLevelSelect,
                borderRadius: BorderRadius.circular(16.r),
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
              InkWell(
                onTap: _openShop,
                borderRadius: BorderRadius.circular(20.r),
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

        // In-Game Tutorial Banner (Level 1 only, placed seamlessly between TargetWords and Board)
        if (!GameStorage.isTutorialCompleted() && _controller!.levelNumber == 1 && !_controller!.isWon) {
          final nextWord = _controller!.getNextUnsolvedTargetWord();
          if (nextWord != null) {
            final isStep2 = _controller!.solvedTargetWords.isNotEmpty;
            return Container(
              height: 52.h,
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFE8DAC8),
                      offset: Offset(0, 2.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: isStep2
                    ? RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.fredoka(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          children: [
                            const TextSpan(text: 'Swipe in any direction: '),
                            TextSpan(
                              text: '"$nextWord"',
                              style: const TextStyle(
                                color: AppColors.btnFaceBrown,
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
                            color: AppColors.textDark,
                          ),
                          children: [
                            const TextSpan(text: 'Swipe the Word '),
                            TextSpan(
                              text: '"$nextWord"',
                              style: const TextStyle(
                                color: AppColors.btnFaceBrown,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
              )
                  .animate()
                  .scale(duration: 250.ms, curve: Curves.easeOutBack)
                  .shimmer(duration: 1600.ms, color: Colors.white.withValues(alpha: 0.5)),
            );
          }
        }

        return SizedBox(height: 52.h);
      },
    );
  }
}

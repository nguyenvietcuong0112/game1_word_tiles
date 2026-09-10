import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/ads_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/game_button.dart';
import '../../widgets/common/game_icon_button.dart';
import 'artwork/next_chapter_menu_view.dart';

class VictoryOverlay extends StatefulWidget {
  final GameController controller;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;

  const VictoryOverlay({
    super.key,
    required this.controller,
    required this.onNextLevel,
    required this.onReplay,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  late ConfettiController _confettiController;
  bool _claimedDouble = false;
  bool _isLoadingReward = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    AdsManager.showInterEndgame(
      levelNumber: widget.controller.levelNumber,
      onCompleted: () {
        if (!mounted) return;
        if (widget.controller.isLastLevelOfChapter) {
          NextChapterMenuView.show(
            context,
            completedChapterNumber: widget.controller.chapterNumber,
            onNextChapter: widget.onNextLevel,
          );
        } else {
          widget.onNextLevel();
        }
      },
    );
  }

  void _handleReplay() {
    AdsManager.showInterReplay(
      levelNumber: widget.controller.levelNumber,
      onCompleted: () {
        if (!mounted) return;
        widget.onReplay();
      },
    );
  }

  void _claimDoubleCoins() {
    setState(() => _isLoadingReward = true);

    AdsManager.showDoubleCoinReward(
      levelNumber: widget.controller.levelNumber,
      onRewardResult: (success) {
        if (!mounted) return;
        setState(() => _isLoadingReward = false);
        if (success) {
          final bonusCoins = widget.controller.coinsReward;
          GameStorage.addCoins(bonusCoins);
          setState(() => _claimedDouble = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Awesome! +$bonusCoins bonus coins added!',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF059669),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ad not completed. Could not claim double coins.',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Hardware-Accelerated Smooth Dark Scrim
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
          ).animate().fadeIn(duration: 250.ms),
        ),

        // 2. Celebratory Confetti Explosion
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFBA805D),
              Color(0xFFE5A638),
              Color(0xFF5B8E67),
              Color(0xFFDEC5AE),
              Color(0xFF5C2E14),
              Color(0xFFFFFDF9),
            ],
            numberOfParticles: 35,
            gravity: 0.15,
          ),
        ),

        // 3. Victory Dialog Card (Spring entrance from top)
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: AppColors.cardPeach,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: AppColors.borderSubtle, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD4C2AE),
                  offset: Offset(0, 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Title (Large, Bold, Woodcraft Style)
                  Text(
                    widget.controller.victoryCelebrationText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headerBrown,
                      letterSpacing: 2.0,
                    ),
                  ),

                  SizedBox(height: 4.h),
                  Text(
                    'Level ${widget.controller.levelNumber} Completed! 🎉',
                    style: GoogleFonts.fredoka(
                      fontSize: 15.sp,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 18.h),

                // 3 Stars Row (3D Glowing Gold Stars with Staggered Animation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < widget.controller.starsEarned;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Icon(
                        Icons.star_rounded,
                        size: 58.r,
                        color: isEarned
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE2E8F0),
                        shadows: isEarned
                            ? [
                                const Shadow(
                                  color: Color(0xFFD97706),
                                  offset: Offset(0, 2.0),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                    )
                        .animate(delay: (150 * index).ms)
                        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 350.ms, curve: Curves.elasticOut);
                  }),
                ),
                SizedBox(height: 8.h),

                // Star Rating Performance Label
                Text(
                  widget.controller.starsEarned == 3
                      ? '⭐ ⭐ ⭐  PERFECT!'
                      : (widget.controller.starsEarned == 2
                          ? '⭐ ⭐  GREAT JOB!'
                          : '⭐  LEVEL CLEARED!'),
                  style: GoogleFonts.fredoka(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: widget.controller.starsEarned == 3
                        ? const Color(0xFFD97706)
                        : (widget.controller.starsEarned == 2
                            ? AppColors.headerBrown
                            : AppColors.textMuted),
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 16.h),

                // Coin Reward Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.borderSubtle, width: 2.0),
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
                      const Text('🪙', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8.w),
                      Text(
                        '+${widget.controller.coinsReward} COINS',
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 450.ms)
                    .scale(curve: Curves.easeOutBack),
                SizedBox(height: 14.h),

                // 2X Coins with Reward Ad Button
                if (!_claimedDouble)
                  GameButton.gold(
                    size: GameButtonSize.medium,
                    text: _isLoadingReward ? 'LOADING...' : 'CLAIM 2X COINS',
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20, color: Colors.white),
                    trailingIcon: const Text('🪙', style: TextStyle(fontSize: 18)),
                    onTap: _isLoadingReward ? null : _claimDoubleCoins,
                  ).animate(delay: 500.ms).fadeIn().scale(curve: Curves.easeOutBack)
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                        SizedBox(width: 6.w),
                        Text(
                          '2X COIN CLAIMED! (+${widget.controller.coinsReward})',
                          style: GoogleFonts.fredoka(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20.h),

                // Action Buttons
                Row(
                  children: [
                    // Replay Button (with Replay Ad check)
                    GameIconButton.replay(
                      onTap: _handleReplay,
                    ),
                    SizedBox(width: 14.w),

                    // Next Level Button (with Endgame Inter check)
                    Expanded(
                      child: GameButton.primary(
                        size: GameButtonSize.large,
                        text: 'CONTINUE',
                        trailingIcon: const Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white),
                        onTap: _handleContinue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .slideY(begin: -0.3, end: 0.0, duration: 400.ms, curve: Curves.easeOutBack)
            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 400.ms, curve: Curves.easeOutBack),
      ),
    ],
  );
  }
}

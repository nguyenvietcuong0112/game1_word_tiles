import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../theme/app_theme.dart';

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
            margin: EdgeInsets.symmetric(horizontal: 28.w),
            padding: EdgeInsets.all(28.r),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Title (Large, Bold, Woodcraft Style)
                Text(
                  widget.controller.victoryCelebrationText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.headerBrown,
                    letterSpacing: 2.0,
                  ),
                ),

                SizedBox(height: 6.h),
                Text(
                  'Level ${widget.controller.levelNumber} Completed! 🎉',
                  style: GoogleFonts.fredoka(
                    fontSize: 16.sp,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20.h),

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

                // Coins Reward Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(22.r),
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
                SizedBox(height: 26.h),

                // Action Buttons
                Row(
                  children: [
                    // Replay Button (Unified 3D Cocoa-Caramel Round Button)
                    InkWell(
                      onTap: widget.onReplay,
                      borderRadius: BorderRadius.circular(28.r),
                      child: Container(
                        width: 54.r,
                        height: 54.r,
                        decoration: BoxDecoration(
                          color: AppColors.btnRingBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.btnRingBorder, width: 1.8),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.btnRingShadow,
                              offset: Offset(0, 2.0),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4.5),
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
                              Icons.replay_rounded,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Next Level Button (3D Cocoa Caramel CTA)
                    Expanded(
                      child: InkWell(
                        onTap: widget.onNextLevel,
                        borderRadius: BorderRadius.circular(26.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(26.r),
                            border: Border.all(color: AppColors.btnBorderBrown, width: 2.0),
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
                              Text(
                                'CONTINUE',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.8,
                                  shadows: const [
                                    Shadow(
                                      color: AppColors.btnShadowBrown,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              const Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

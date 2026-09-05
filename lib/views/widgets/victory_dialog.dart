import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../common/wood_widgets.dart';

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

        // 3. Victory Wood Signboard Dialog Card
        Center(
          child: WoodSignboardDialog(
            title: widget.controller.victoryCelebrationText,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 6.h),
                Text(
                  'Level ${widget.controller.levelNumber} Completed! 🎉',
                  style: GoogleFonts.fredoka(
                    fontSize: 17.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Color(0xFF1F0900), offset: Offset(0, 1.5)),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // 3 Stars Row (3D Wooden Stars with Staggered Animation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < widget.controller.starsEarned;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: WoodenStar(
                        isEarned: isEarned,
                        size: 56.r,
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(color: Color(0xFF1F0900), offset: Offset(0, 1.5)),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Coins Reward Badge in Wood Style (Single Wood Badge)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: WoodenStyle.woodBevel, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: WoodenStyle.woodExtrusion,
                        offset: Offset(0, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFF7EA),
                                  Color(0xFFF3DFBE),
                                  Color(0xFFE2C498),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Wood Grain Texture Overlay
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.25,
                            child: Image.asset(
                              'assets/images/golden_wood_texture.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Top Specular Highlight Rim
                        Positioned(
                          top: 0,
                          left: 8,
                          right: 8,
                          height: 1.2,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WoodGameIcons.coin(size: 22.sp),
                              SizedBox(width: 8.w),
                              Text(
                                '+${widget.controller.coinsReward} COINS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: WoodenStyle.carvedDark,
                                  letterSpacing: 1.0,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x60FFFFFF),
                                      offset: Offset(0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 450.ms)
                    .scale(curve: Curves.easeOutBack),
                SizedBox(height: 22.h),

                // Action Buttons
                Row(
                  children: [
                    // Replay Wooden Carved Button (100% matched to reference)
                    WoodCarvedIconButton(
                      size: 52.r,
                      assetPath: WoodGameIcons.btnRestart,
                      onTap: widget.onReplay,
                    ),
                    SizedBox(width: 14.w),

                    // Next Level Button (Vibrant Green Wood CTA)
                    Expanded(
                      child: WoodenButton(
                        text: 'CONTINUE',
                        icon: Icons.arrow_forward_rounded,
                        variant: WoodenButtonVariant.action,
                        height: 52.h,
                        fontSize: 17.sp,
                        onTap: widget.onNextLevel,
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

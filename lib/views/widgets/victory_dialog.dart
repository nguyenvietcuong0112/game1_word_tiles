import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/ads_manager.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../utils/game_transitions.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/shop_dialog.dart';
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
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
                '🎉 +$bonusCoins coins added!',
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
                'Ad not completed.',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
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

  @override
  Widget build(BuildContext context) {
    final chapterInfo = widget.controller.chapterInfo;
    final currentLvlInChapter = min(chapterInfo.levelInChapter, chapterInfo.totalLevelsInChapter);
    final totalLevelsInChapter = chapterInfo.totalLevelsInChapter;
    final progressFraction = (currentLvlInChapter / totalLevelsInChapter).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 1. Deep Ocean Navy / Dark Blue Fullscreen Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF020E24),
                      Color(0xFF02173B),
                      Color(0xFF01091A),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Celebratory Confetti Cascade (Vibrant arcade colors)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFF00E5FF), // Cyan
                  Color(0xFFFF4081), // Pink
                  Color(0xFFFFD700), // Gold
                  Color(0xFF00E676), // Green
                  Color(0xFFFF9100), // Orange
                  Colors.white,
                ],
                numberOfParticles: 35,
                gravity: 0.12,
              ),
            ),

            // 3. Foreground Layout
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // Top Bar: Coins Capsule on Left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BouncyButton(
                        onTap: _openShop,
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
                                    color: const Color(0xFF041026).withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(color: Colors.white, width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
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
                                  'assets/icons/icon_coin.png',
                                  width: 44.r,
                                  height: 44.r,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 12),

                    // Center: Golden Crown & Congrats graphic with glowing light aura
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft golden/white radial ambient glow
                        Container(
                          width: 280.w,
                          height: 180.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFE082).withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Crown graphic
                        Image.asset(
                          'assets/icons/icon_congrats.png',
                          width: 290.w,
                          fit: BoxFit.contain,
                        ),
                      ],
                    )
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1.0, 1.0),
                        ),

                    const Spacer(flex: 8),

                    // Message Capsule: "This level was no match for you!"
                    Container(
                      constraints: BoxConstraints(maxWidth: 240.w),
                      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF041026).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28.r),
                        border: Border.all(color: Colors.white, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'This level was\nno match for you!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),

                    const Spacer(flex: 12),

                    // Chapter Progress Bar with Coin Reward Stack
                    SizedBox(
                      width: 250.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Progress Bar Track Capsule
                          Container(
                            width: 226.w,
                            height: 22.h,
                            padding: EdgeInsets.all(2.5.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF041026).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(11.r),
                              border: Border.all(color: Colors.white, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxW = constraints.maxWidth;
                                return Stack(
                                  children: [
                                    // Green Progress Fill
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: maxW * progressFraction,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF3EEC62),
                                              Color(0xFF23D046),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Centered "2/5" Text
                                    Center(
                                      child: Text(
                                        '$currentLvlInChapter/$totalLevelsInChapter',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Gold Coin Stack Anchor at Right Edge
                          Positioned(
                            right: 0,
                            top: -14.h,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/icon_coin_victory.png',
                                  width: 48.w,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  '${widget.controller.coinsReward}',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0xFF0D2540),
                                        offset: Offset(0, 1.5),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

                    const Spacer(flex: 18),

                    // Bottom Action Row: Yellow "Level X" Button + Green Ad Coins Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        children: [
                          // Left Button: Yellow Next Level
                          Expanded(
                            child: BouncyButton(
                              onTap: _handleContinue,
                              child: SizedBox(
                                height: 56.h,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/btn_yellow.png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Blue Stroke Outline
                                        Text(
                                          'Level ${widget.controller.levelNumber + 1}',
                                          style: GoogleFonts.fredoka(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w900,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 3.5
                                              ..color = const Color(0xFF245F8A),
                                          ),
                                        ),
                                        // White Letter Fill
                                        Text(
                                          'Level ${widget.controller.levelNumber + 1}',
                                          style: GoogleFonts.fredoka(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 14.w),

                          // Right Button: Green Watch Ad for Double Coins
                          Expanded(
                            child: BouncyButton(
                              onTap: _isLoadingReward || _claimedDouble ? null : _claimDoubleCoins,
                              child: SizedBox(
                                height: 56.h,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/btn_green.png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                    if (_isLoadingReward)
                                      SizedBox(
                                        width: 22.r,
                                        height: 22.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else if (_claimedDouble)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Claimed!',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/icons/icon_ads.png',
                                            width: 32.r,
                                            height: 32.r,
                                            fit: BoxFit.contain,
                                          ),
                                          SizedBox(width: 6.w),
                                          Image.asset(
                                            'assets/icons/icon_coin.png',
                                            width: 22.r,
                                            height: 22.r,
                                            fit: BoxFit.contain,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '${widget.controller.coinsReward}',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0xFF135025),
                                                  offset: Offset(0, 1.5),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 450.ms),

                    SizedBox(height: 28.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

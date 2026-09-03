import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import 'app_popup.dart';

class ExtraWordsDialog extends StatefulWidget {
  final GameController controller;
  final VoidCallback onUpdated;

  const ExtraWordsDialog({
    super.key,
    required this.controller,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required GameController controller,
    required VoidCallback onUpdated,
  }) {
    AudioManager.playTileSelect(pitchIndex: 4);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ExtraWordsDialog(
        controller: controller,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<ExtraWordsDialog> createState() => _ExtraWordsDialogState();
}

class _ExtraWordsDialogState extends State<ExtraWordsDialog> {
  void _claimReward() async {
    final success = await GameStorage.claimExtraWordsBankReward();
    if (success) {
      AudioManager.playVictory();
      widget.onUpdated();
      setState(() {});
      if (mounted) {
        AppPopup.show(
          context,
          title: 'Extra Words Reward Claimed!',
          message: 'You received +10 🪙 for finding 10 extra bonus words!\nKeep finding hidden words!',
          icon: '🎁',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankCount = GameStorage.getExtraWordsChestCount();
    final canClaim = bankCount >= 10;
    final foundWords = widget.controller.foundExtraWords;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.cardPeach,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 32.r),
                Text(
                  'Extra Words',
                  style: GoogleFonts.fredoka(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.headerBrown,
                    letterSpacing: 0.5,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppColors.cardPeachLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.headerBrown,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Graphic Illustration: 3D Scrabble / Word Tiles Tray
            _buildLetterTrayIllustration(),
            SizedBox(height: 16.h),

            // "Found This Level:" Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE8DAC8),
                    offset: Offset(0, 2.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Woodcraft Header Pill
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.r),
                        topRight: Radius.circular(18.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Found This Level:',
                        style: GoogleFonts.fredoka(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: const [
                            Shadow(
                              color: AppColors.btnShadowBrown,
                              offset: Offset(0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Words List Container
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 80.h, maxHeight: 130.h),
                    padding: EdgeInsets.all(12.r),
                    child: foundWords.isEmpty
                        ? Center(
                            child: Text(
                              'Find hidden bonus words on the board\nto fill the Extra Words Bank!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 12.sp,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              alignment: WrapAlignment.center,
                              children: foundWords.map((word) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardPeachLight,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFFE8DAC8),
                                        offset: Offset(0, 1.0),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    word,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.headerBrown,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Progress Bar & 10 Coins Reward
            _buildProgressBar(bankCount, canClaim),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterTrayIllustration() {
    final letters = [
      ['A₁', 'B₄', 'C₃', 'E₁', 'F₄', 'G₂', 'H₄'],
      ['J₈', 'M₃', 'N₁', 'P₃', 'Q₁₀', 'T₁', 'Z₁₀'],
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF8B4D26),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF5C2E14), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF421E0B),
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: letters.map((row) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((char) {
                return Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFE6D6C4), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF5C2E14),
                        offset: Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      char,
                      style: GoogleFonts.fredoka(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4A2610),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressBar(int count, bool canClaim) {
    final progress = (count / 10).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE8DAC8),
            offset: Offset(0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Honey Gold Indicator Dot
          Container(
            width: 22.r,
            height: 22.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD97706),
                  offset: Offset(0, 1.0),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Progress Bar Track
          Expanded(
            child: Stack(
              children: [
                // Track Container
                Container(
                  height: 22.h,
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                  ),
                ),

                // Fill Bar
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 22.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),

                // Progress Text (e.g. 1/10)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '$count/10',
                      style: GoogleFonts.fredoka(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: count > 4 ? Colors.white : AppColors.headerBrown,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Reward Claim or Coin Stack Badge
          canClaim
              ? InkWell(
                  onTap: _claimReward,
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.btnBorderBrown, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.btnShadowBrown,
                          offset: Offset(0, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'CLAIM',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.06, 1.06), duration: 600.ms),
                )
              : Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      child: Text('🪙', style: TextStyle(fontSize: 24.sp)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        '10',
                        style: GoogleFonts.fredoka(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

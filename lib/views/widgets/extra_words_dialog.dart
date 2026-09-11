import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../utils/game_transitions.dart';
import '../../widgets/common/game_icon_button.dart';
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
    return showGameDialog(
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
          message: 'You received +50 🪙 for finding 10 extra bonus words!\nKeep finding hidden words!',
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
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Main White Card Frame
          Container(
            constraints: BoxConstraints(maxWidth: 340.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 10),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 28.h),

                // Top Illustration: Blue letter tiles tray
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Image.asset(
                    'assets/images/img_extra_asset.webp',
                    width: 290.w,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 12.h),

                // "Found this level:" Section Container
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAF7),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFC6D9EC),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Title
                      Text(
                        'Found this level:',
                        style: GoogleFonts.fredoka(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A5F7D),
                        ),
                      ),
                      SizedBox(height: 6.h),

                      // Decorative Divider with dots
                      Row(
                        children: [
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Container(
                              height: 2.h,
                              color: const Color(0xFF5A7090),
                            ),
                          ),
                          Container(
                            width: 5.r,
                            height: 5.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5A7090),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 44.w),
                          Container(
                            width: 5.r,
                            height: 5.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5A7090),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2.h,
                              color: const Color(0xFF5A7090),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Words List or Empty State
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 85.h,
                          maxHeight: 120.h,
                        ),
                        alignment: Alignment.center,
                        child: foundWords.isEmpty
                            ? Text(
                                'Find hidden bonus words\non the board!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF758CA7),
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              )
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  alignment: WrapAlignment.center,
                                  children: foundWords.map((word) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: const Color(0xFFBACFE2),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          const BoxShadow(
                                            color: Color(0xFFC0D5E8),
                                            offset: Offset(0, 2.0),
                                            blurRadius: 0,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            offset: const Offset(0, 3.0),
                                            blurRadius: 2.5,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        word,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF3B506D),
                                          letterSpacing: 0.8,
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

                // Bottom Progress Bar & 50 Coins Reward
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: _buildProgressBar(bankCount, canClaim),
                ),
              ],
            ),
          ),

          // 2. Purple Pill Header Badge ("Extra Words")
          Positioned(
            top: -16.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8B7DF8),
                    Color(0xFF6B5AE8),
                  ],
                ),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF4B3AA8),
                    offset: Offset(0, 3.0),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 4.0),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'Extra Words',
                style: GoogleFonts.fredoka(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF3D2E95),
                      offset: Offset(0, 1.5),
                      blurRadius: 1.0,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Red Circular Close Button
          Positioned(
            top: -10.h,
            right: 0.w,
            child: GameIconButton.close(
              context,
              size: GameIconButtonSize.dialogClose,
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildProgressBar(int count, bool canClaim) {
    final progress = (count / 10).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: canClaim ? _claimReward : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Capsule Track
          Container(
            height: 24.h,
            margin: EdgeInsets.only(right: 22.w),
            decoration: BoxDecoration(
              color: const Color(0xFF3E4850),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Green Progress Fill
                if (progress > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF26DE50),
                            Color(0xFF19B83E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),

                // Centered Progress Count (e.g. 6/10)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '$count/10',
                      style: GoogleFonts.fredoka(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF1E3A8A),
                            offset: Offset(0, 1.2),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Color(0xFF1E3A8A),
                            offset: Offset(1.2, 0),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Color(0xFF1E3A8A),
                            offset: Offset(-1.2, 0),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Color(0xFF1E3A8A),
                            offset: Offset(0, -1.2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Coin Stack with "50" badge on the right
          Positioned(
            right: -6.w,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icons/icon_coin_victory.webp',
                  width: 48.r,
                  height: 48.r,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: -2.w,
                  bottom: -4.h,
                  child: Text(
                    '50',
                    style: GoogleFonts.fredoka(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF1E3A8A),
                          offset: Offset(0, 1.5),
                          blurRadius: 1,
                        ),
                        Shadow(
                          color: Color(0xFF1E3A8A),
                          offset: Offset(1.5, 0),
                          blurRadius: 1,
                        ),
                        Shadow(
                          color: Color(0xFF1E3A8A),
                          offset: Offset(-1.5, 0),
                          blurRadius: 1,
                        ),
                        Shadow(
                          color: Color(0xFF1E3A8A),
                          offset: Offset(0, -1.5),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Claim Badge Animation when claimable
                if (canClaim)
                  Positioned(
                    top: -8.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.white, width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFB45309),
                            offset: Offset(0, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'CLAIM!',
                        style: GoogleFonts.fredoka(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.15, 1.15),
                          duration: 500.ms,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

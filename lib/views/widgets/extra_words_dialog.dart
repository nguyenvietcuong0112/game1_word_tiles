import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/game_controller.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';
import 'bouncy_button.dart';
import 'pressable_3d_button.dart';

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
        showGameDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => const _ExtraWordsRewardClaimDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankCount = GameStorage.getExtraWordsChestCount();
    final canClaim = bankCount >= 10;
    final foundWords = widget.controller.foundExtraWords;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 336.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. Main White Card Frame
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFFE5EFF5), width: 3.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38000000),
                      offset: Offset(0, 12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0xFFB0C9DA),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 50.h),

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
                        style: AppTypography.font(
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
                                style: AppTypography.font(
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
                                        style: AppTypography.font(
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

                // Bottom Progress Bar & 50 Coins Reward (Full width inside card)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
                  child: _buildProgressBar(bankCount, canClaim),
                ),
              ],
            ),
          ),

          // 2. Purple Pill Header Badge ("Extra Words")
          Positioned(
            top: -18.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 6.h),
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
                border: Border.all(color: Colors.white, width: 2.2),
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
              child: const CartoonText(
                text: 'Extra Words',
                fontSize: 22,
                textColor: Colors.white,
                outlineColor: Color(0xFF3D2E95),
                strokeWidth: 3.4,
                shadowOffset: 1.5,
              ),
            ),
          ),

          // 3. Floating 3D Red Circular Close "X" Button
          Positioned(
            top: -15.h,
            right: -13.w,
            child: BouncyButton(
              onTap: () {
                AudioManager.playTileSelect(pitchIndex: 1);
                Navigator.of(context).pop();
              },
              child: Image.asset(
                'assets/icons/icon_close.webp',
                width: 44.r,
                height: 44.r,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    ),
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
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // Capsule Track (stretches full width, continues underneath coins)
            Container(
              height: 32.h,
              width: double.infinity,
              margin: EdgeInsets.only(right: 18.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3B35),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 3),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: Color(0xFF9EACB6),
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13.5.r),
                child: Stack(
                  children: [
                    // Vibrant Bright Green Progress Fill
                    if (progress > 0)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF3EEC62),
                                Color(0xFF1FCF44),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Centered Progress Text (e.g. 6/10) with dark navy stroke
                    Positioned.fill(
                      child: Center(
                        child: CartoonText(
                          text: '$count/10',
                          fontSize: 16.sp,
                          textColor: Colors.white,
                          outlineColor: const Color(0xFF1E3A8A),
                          strokeWidth: 3.2,
                          shadowOffset: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Coin Stack with "50" badge on the right end
            Positioned(
              right: -6.w,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icons/icon_coin_victory.webp',
                    width: 52.r,
                    height: 52.r,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    right: 0,
                    bottom: -2.h,
                    child: CartoonText(
                      text: '50',
                      fontSize: 16.sp,
                      textColor: Colors.white,
                      outlineColor: const Color(0xFF1E3A8A),
                      strokeWidth: 3.2,
                      shadowOffset: 1.0,
                    ),
                  ),

                  // Claim Badge Animation when claimable
                  if (canClaim)
                    Positioned(
                      top: -12.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFB45309),
                              offset: Offset(0, 1.8),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x33000000),
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(
                          'CLAIM!',
                          style: AppTypography.font(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.15, 1.15),
                            duration: 450.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D Cartoon Reward Claim Dialog for Extra Words
class _ExtraWordsRewardClaimDialog extends StatelessWidget {
  const _ExtraWordsRewardClaimDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 336.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Outer White Card with Soft 3D Shadow
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFFE5EFF5), width: 3.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38000000),
                      offset: Offset(0, 12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0xFFB0C9DA),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sunken Pastel Showcase Panel
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E7F3),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFBED7E8), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                      child: Column(
                        children: [
                          // Hero Coin Stack with gentle celebration animation
                          Image.asset(
                            'assets/icons/icon_coin_victory.webp',
                            width: 82.r,
                            height: 82.r,
                            fit: BoxFit.contain,
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.05, 1.05),
                                duration: 1200.ms,
                                curve: Curves.easeInOut,
                              ),
                          SizedBox(height: 12.h),

                          // Reward Amount Badge Pill (+50 Coins)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF132A1F),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color(0xFF3EEC62).withValues(alpha: 0.8),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x20000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/icon_coin.webp',
                                  width: 22.r,
                                  height: 22.r,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 6.w),
                                CartoonText(
                                  text: '+50 COINS',
                                  fontSize: 18.sp,
                                  textColor: const Color(0xFFFFD700),
                                  outlineColor: const Color(0xFF78350F),
                                  strokeWidth: 2.8,
                                  shadowOffset: 1.2,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Description
                          Text(
                            'Congratulations!\nYou found 10 hidden extra words!\nKeep finding bonus words for more coins!',
                            textAlign: TextAlign.center,
                            style: AppTypography.font(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B4868),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Big Vivid Green 3D Pressable Button
                    Pressable3DButton(
                      width: double.infinity,
                      height: 52.h,
                      scaleDown: false,
                      borderRadius: 18,
                      bevelOffset: 4.5,
                      borderWidth: 1.2,
                      faceColor: const Color(0xFF46dc28),
                      bevelColor: const Color(0xFF2DC419),
                      borderColor: const Color(0xFF19BA05),
                      onTap: () {
                        AudioManager.playTileSelect(pitchIndex: 5);
                        Navigator.of(context).pop();
                      },
                      child: CartoonText(
                        text: 'COLLECT',
                        fontSize: 20.sp,
                        textColor: Colors.white,
                        outlineColor: const Color(0xFF179A09),
                        strokeWidth: 3.2,
                        shadowOffset: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Header Pill: "REWARD!" with bg_btn_setting.webp
              Positioned(
                top: -20.h,
                child: Container(
                  width: 220.w,
                  height: 48.h,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icons/bg_btn_setting.webp'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: const CartoonText(
                    text: 'REWARD!',
                    fontSize: 22,
                    textColor: Colors.white,
                    outlineColor: Color(0xFF380662),
                    strokeWidth: 3.4,
                    shadowOffset: 1.6,
                  ),
                ),
              ),

              // Floating 3D Red Circular Close "X" Button
              Positioned(
                top: -15.h,
                right: -13.w,
                child: BouncyButton(
                  onTap: () {
                    AudioManager.playTileSelect(pitchIndex: 1);
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    'assets/icons/icon_close.webp',
                    width: 44.r,
                    height: 44.r,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.78, 0.78),
          end: const Offset(1.0, 1.0),
          duration: 260.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 180.ms);
  }
}

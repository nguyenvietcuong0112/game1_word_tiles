import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import 'booster_unlock_dialog.dart';
import 'bouncy_button.dart';

class BoosterBar extends StatelessWidget {
  final GameController controller;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenExtraWords;
  final bool isHintSpotlighted;
  final bool isExtraWordsSpotlighted;
  final GlobalKey<ExtraWordsButtonState>? extraWordsBtnKey;

  const BoosterBar({
    super.key,
    required this.controller,
    this.onOpenShop,
    this.onOpenExtraWords,
    this.isHintSpotlighted = false,
    this.isExtraWordsSpotlighted = false,
    this.extraWordsBtnKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isBoosterBarVisible) {
          return const SizedBox.shrink();
        }

        final extraCount = GameStorage.getExtraWordsChestCount();
        final hintCount = GameStorage.getHintCount();
        final rocketCount = GameStorage.getRocketCount();

        // Level 5 - 6: Only Hint is unlocked, centered at bottom
        if (!controller.isRocketUnlocked) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBoosterBtn(
                  emoji: '💡',
                  inventoryCount: hintCount,
                  isSpotlighted: isHintSpotlighted,
                  onTap: () {
                    if (hintCount > 0) {
                      controller.useHint();
                    } else {
                      BoosterUnlockDialog.show(
                        context,
                        boosterType: BoosterType.hint,
                        controller: controller,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }

        // Level 7+: Full Booster Suite (Extra Words, Hint, Rocket, Shop)
        final bool isAnySpotlighted = isHintSpotlighted || isExtraWordsSpotlighted;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Extra Words Button (Custom 3D Wordcraft Tile Stack)
              if (controller.isExtraWordsUnlocked)
                Opacity(
                  opacity: (isAnySpotlighted && !isExtraWordsSpotlighted) ? 0.35 : 1.0,
                  child: ExtraWordsButton(
                    key: extraWordsBtnKey,
                    extraCount: extraCount,
                    isSpotlighted: isExtraWordsSpotlighted,
                    onTap: onOpenExtraWords,
                  ),
                ),

              // 2. Hint Booster 💡
              Opacity(
                opacity: (isAnySpotlighted && !isHintSpotlighted) ? 0.35 : 1.0,
                child: _buildBoosterBtn(
                  emoji: '💡',
                  inventoryCount: hintCount,
                  isSpotlighted: isHintSpotlighted,
                  onTap: () {
                    if (hintCount > 0) {
                      controller.useHint();
                    } else {
                      BoosterUnlockDialog.show(
                        context,
                        boosterType: BoosterType.hint,
                        controller: controller,
                      );
                    }
                  },
                ),
              ),

              // 3. Rocket Booster 🚀
              if (controller.isRocketUnlocked)
                Opacity(
                  opacity: isAnySpotlighted ? 0.35 : 1.0,
                  child: _buildBoosterBtn(
                    emoji: '🚀',
                    inventoryCount: rocketCount,
                    onTap: () {
                      if (rocketCount > 0) {
                        controller.useRocket();
                      } else {
                        BoosterUnlockDialog.show(
                          context,
                          boosterType: BoosterType.rocket,
                          controller: controller,
                        );
                      }
                    },
                  ),
                ),

              // 4. Shop / Chest 🎁
              if (controller.isShopUnlocked)
                Opacity(
                  opacity: isAnySpotlighted ? 0.35 : 1.0,
                  child: _buildSpecialActionBtn(
                    emoji: '🎁',
                    label: 'SHOP',
                    onTap: onOpenShop,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoosterBtn({
    required String emoji,
    required int inventoryCount,
    required VoidCallback onTap,
    bool isSpotlighted = false,
  }) {
    final bool hasItems = inventoryCount > 0;

    return BouncyButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Circular Button with optional Spotlight Halo
          Container(
            decoration: isSpotlighted
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.75),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  )
                : null,
            child: Container(
              width: 58.r,
              height: 58.r,
              decoration: BoxDecoration(
                color: AppColors.btnRingBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpotlighted ? Colors.white : AppColors.btnRingBorder,
                  width: isSpotlighted ? 2.6 : 1.8,
                ),
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
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFE8DAC8),
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 25.sp),
                  ),
                ),
              ),
            ),
          ),

          // Attached 3D Badge: shows $inventoryCount if > 0, else 'FREE'
          Transform.translate(
            offset: Offset(0, -6.h),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hasItems ? 12.w : 10.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: hasItems ? AppColors.btnFaceBrown : const Color(0xFF1E8216),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: hasItems ? AppColors.btnBorderBrown : const Color(0xFF146C0B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasItems ? AppColors.btnShadowBrown : const Color(0xFF0E4B07),
                    offset: const Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: hasItems
                  ? Text(
                      '$inventoryCount',
                      style: GoogleFonts.fredoka(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    )
                  : Text(
                      'FREE',
                      style: GoogleFonts.fredoka(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialActionBtn({
    required String emoji,
    required String label,
    required VoidCallback? onTap,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58.r,
            height: 58.r,
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
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE8DAC8),
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.btnFaceBrown,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: badgeColor != null ? Colors.transparent : AppColors.btnBorderBrown,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor != null ? badgeColor.withValues(alpha: 0.5) : AppColors.btnShadowBrown,
                    offset: const Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: badgeTextColor ?? Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean, 100% Unified Circular Extra Words Action Button with Punch Bounce Animation
class ExtraWordsButton extends StatefulWidget {
  final int extraCount;
  final VoidCallback? onTap;
  final bool isSpotlighted;

  const ExtraWordsButton({
    super.key,
    required this.extraCount,
    required this.onTap,
    this.isSpotlighted = false,
  });

  @override
  State<ExtraWordsButton> createState() => ExtraWordsButtonState();
}

class ExtraWordsButtonState extends State<ExtraWordsButton> with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.32).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.32, end: 0.92).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void punchBounce() {
    _bounceController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadyToClaim = widget.extraCount >= 10;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: BouncyButton(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Circular Ring Button with optional Spotlight Halo
            Container(
              decoration: widget.isSpotlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.95),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.75),
                          blurRadius: 28,
                          spreadRadius: 8,
                        ),
                      ],
                    )
                  : null,
              child: Container(
                width: 58.r,
                height: 58.r,
                decoration: BoxDecoration(
                  color: AppColors.btnRingBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSpotlighted ? Colors.white : AppColors.btnRingBorder,
                    width: widget.isSpotlighted ? 2.6 : 1.8,
                  ),
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
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE8DAC8),
                        offset: Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '📖',
                      style: TextStyle(fontSize: 25.sp),
                    ),
                  ),
                ),
              ),
            ),

            // Attached 3D Status Pill (Shows $extraCount/10 or CLAIM!)
            Transform.translate(
              offset: Offset(0, -6.h),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isReadyToClaim ? 8.w : 10.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  gradient: isReadyToClaim
                      ? const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                        )
                      : null,
                  color: isReadyToClaim ? null : AppColors.btnFaceBrown,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isReadyToClaim ? const Color(0xFF047857) : AppColors.btnBorderBrown,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isReadyToClaim
                          ? const Color(0x88059669)
                          : AppColors.btnShadowBrown,
                      offset: const Offset(0, 1.5),
                      blurRadius: isReadyToClaim ? 4 : 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isReadyToClaim)
                      Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: const Text('🎁', style: TextStyle(fontSize: 10)),
                      ),
                    Text(
                      isReadyToClaim ? 'CLAIM!' : '${widget.extraCount}/10',
                      style: GoogleFonts.fredoka(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
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

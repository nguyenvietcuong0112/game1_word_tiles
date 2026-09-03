import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';

class BoosterBar extends StatelessWidget {
  final GameController controller;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenExtraWords;

  const BoosterBar({
    super.key,
    required this.controller,
    this.onOpenShop,
    this.onOpenExtraWords,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final extraCount = GameStorage.getExtraWordsChestCount();
        final hintCount = GameStorage.getHintCount();
        final rocketCount = GameStorage.getRocketCount();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Extra Words Button (Custom 3D Wordcraft Tile Stack)
              _buildExtraWordsBtn(
                extraCount: extraCount,
                onTap: onOpenExtraWords,
              ),

              // 2. Hint Booster 💡 (Shows count if > 0, else 80 🪙)
              _buildBoosterBtn(
                emoji: '💡',
                inventoryCount: hintCount,
                price: 80,
                onTap: () => controller.useHint(),
              ),

              // 3. Rocket Booster 🚀 (Shows count if > 0, else 240 🪙)
              _buildBoosterBtn(
                emoji: '🚀',
                inventoryCount: rocketCount,
                price: 240,
                onTap: () => controller.useRocket(),
              ),

              // 4. Shop / Chest 🎁
              _buildSpecialActionBtn(
                emoji: '🎁',
                label: 'SHOP',
                onTap: onOpenShop,
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
    required int price,
    required VoidCallback onTap,
  }) {
    final bool hasFreeItem = inventoryCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Circular Button (Matching Header Back / Setting 3D Round Buttons)
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
                  style: TextStyle(fontSize: 25.sp),
                ),
              ),
            ),
          ),

          // Attached 3D Badge (Shows free count if > 0, else coin price)
          Transform.translate(
            offset: Offset(0, -6.h),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hasFreeItem ? 12.w : 10.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.btnFaceBrown,
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
              child: hasFreeItem
                  ? Text(
                      '$inventoryCount',
                      style: GoogleFonts.fredoka(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🪙', style: TextStyle(fontSize: 10.sp)),
                        SizedBox(width: 3.w),
                        Text(
                          '$price',
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
    );
  }

  /// Clean, 100% Unified Circular Extra Words Action Button
  Widget _buildExtraWordsBtn({
    required int extraCount,
    required VoidCallback? onTap,
  }) {
    final bool isReadyToClaim = extraCount >= 10;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Circular Ring Button (Exact same size & shape as other 3 buttons)
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    'assets/images/extra_word_icon.jpg',
                    width: 33.r,
                    height: 33.r,
                    fit: BoxFit.contain,
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
                    isReadyToClaim ? 'CLAIM!' : '$extraCount/10',
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
    );
  }

  Widget _buildSpecialActionBtn({
    required String emoji,
    required String label,
    required VoidCallback? onTap,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32.r),
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

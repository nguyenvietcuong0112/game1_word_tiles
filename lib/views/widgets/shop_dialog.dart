import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import 'app_popup.dart';

class ShopDialog extends StatefulWidget {
  final VoidCallback onUpdated;

  const ShopDialog({super.key, required this.onUpdated});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _claimFreeReward() async {
    if (!GameStorage.canClaimDailyGift()) {
      final remaining = GameStorage.getRemainingDailyGiftCooldown();
      if (mounted) {
        AppPopup.show(
          context,
          title: 'Daily Gift Cooldown',
          message: 'Your next free reward is available in ${_formatDuration(remaining)}.',
          icon: '⏳',
        );
      }
      return;
    }

    await GameStorage.addCoins(100);
    await GameStorage.addHintCount(1);
    await GameStorage.addRocketCount(1);
    await GameStorage.setLastDailyGiftClaimTime(DateTime.now().millisecondsSinceEpoch);
    widget.onUpdated();
    setState(() {});
    if (mounted) {
      AppPopup.show(
        context,
        title: 'Daily Gift Claimed!',
        message: 'You received +100 🪙, +1 💡 Hint, and +1 🚀 Rocket!\nNext gift in 24 hours.',
        icon: '🎁',
      );
    }
  }

  void _buyBoosterPack(String name, int coinsCost, int hints, int rockets) async {
    final success = await GameStorage.spendCoins(coinsCost);
    if (success) {
      await GameStorage.addHintCount(hints);
      await GameStorage.addRocketCount(rockets);
      widget.onUpdated();
      setState(() {});
      if (mounted) {
        AppPopup.show(
          context,
          title: 'Pack Unlocked!',
          message: 'Successfully purchased $name! (+${hints}x 💡, +${rockets}x 🚀)',
          icon: '✨',
        );
      }
    } else {
      if (mounted) {
        AppPopup.show(
          context,
          title: 'Not Enough Coins!',
          message: 'You need $coinsCost 🪙 to purchase $name. Complete more levels or claim daily gifts!',
          icon: '❌',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = GameStorage.getCoins();
    final hints = GameStorage.getHintCount();
    final rockets = GameStorage.getRocketCount();
    final canClaimDaily = GameStorage.canClaimDailyGift();
    final remainingCooldown = GameStorage.getRemainingDailyGiftCooldown();

    return AlertDialog(
      backgroundColor: AppColors.cardPeach,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.r),
        side: const BorderSide(color: AppColors.borderSubtle, width: 2.0),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Coin Shop & Gifts',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 18.sp, color: AppColors.headerBrown),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.cardPeachLight,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.borderSubtle, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                SizedBox(width: 5.w),
                Text(
                  '$coins',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inventory preview
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(18.r),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.terracotta, size: 20),
                    SizedBox(width: 6.w),
                    Text(
                      '$hints Hints',
                      style: GoogleFonts.fredoka(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ]),
                  Container(width: 1.5, height: 20.h, color: AppColors.borderSubtle),
                  Row(children: [
                    const Icon(Icons.rocket_launch_outlined, color: AppColors.terracotta, size: 20),
                    SizedBox(width: 6.w),
                    Text(
                      '$rockets Rockets',
                      style: GoogleFonts.fredoka(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ]),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Daily Free Gift Card (24h Countdown Logic)
            Container(
              padding: EdgeInsets.all(14.r),
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
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Free Gift',
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 14.sp),
                        ),
                        Text(
                          canClaimDaily
                              ? '+100 🪙, +1 💡, +1 🚀'
                              : 'Next gift: ${_formatDuration(remainingCooldown)}',
                          style: GoogleFonts.fredoka(
                            fontSize: 11.sp,
                            color: canClaimDaily ? AppColors.textMuted : AppColors.terracotta,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  canClaimDaily
                      ? InkWell(
                          onTap: _claimFreeReward,
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
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
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            AppPopup.show(
                              context,
                              title: 'Daily Gift Cooldown',
                              message: 'Your next daily reward is ready in ${_formatDuration(remainingCooldown)}.',
                              icon: '⏳',
                            );
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.cardPeachLight,
                              borderRadius: BorderRadius.circular(14.r),
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
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatDuration(remainingCooldown),
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Booster Pack 1
            _buildShopItem(
              title: 'Explorer Pack',
              desc: '3x 💡 Hints + 1x 🚀 Rocket',
              icon: '🎒',
              cost: 300,
              onBuy: () => _buyBoosterPack('Explorer Pack', 300, 3, 1),
            ),
            SizedBox(height: 10.h),

            // Booster Pack 2
            _buildShopItem(
              title: 'Master Pack',
              desc: '8x 💡 Hints + 4x 🚀 Rockets',
              icon: '👑',
              cost: 800,
              onBuy: () => _buyBoosterPack('Master Pack', 800, 8, 4),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.cardPeachLight,
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
            child: Text(
              'Close',
              style: GoogleFonts.fredoka(
                color: AppColors.headerBrown,
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem({
    required String title,
    required String desc,
    required String icon,
    required int cost,
    required VoidCallback onBuy,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18.r),
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
          Text(icon, style: TextStyle(fontSize: 26.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13.sp, color: AppColors.textDark),
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  style: GoogleFonts.fredoka(fontSize: 11.sp, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onBuy,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4.w),
                  Text(
                    '$cost',
                    style: GoogleFonts.fredoka(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_typography.dart';
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

    AudioManager.playTileSelect(pitchIndex: 5);
    await GameStorage.addCoins(100);
    await GameStorage.addHintCount(1);
    await GameStorage.addRocketCount(1);
    await GameStorage.setLastDailyGiftClaimTime(DateTime.now().millisecondsSinceEpoch);
    widget.onUpdated();
    if (mounted) {
      setState(() {});
      AppPopup.show(
        context,
        title: 'Free Pack Claimed!',
        message: 'You received +1 💡 Hint, +1 🚀 Rocket, and +100 🪙 coins!\nNext free pack in 24 hours.',
        icon: '🎁',
      );
    }
  }

  void _buyBoosterPack(String name, int coinsCost, int hints, int rockets) async {
    final success = await GameStorage.spendCoins(coinsCost);
    if (success) {
      AudioManager.playTileSelect(pitchIndex: 5);
      await GameStorage.addHintCount(hints);
      await GameStorage.addRocketCount(rockets);
      widget.onUpdated();
      if (mounted) {
        setState(() {});
        AppPopup.show(
          context,
          title: 'Pack Unlocked!',
          message: 'Successfully purchased $name! (+${hints}x 💡, +${rockets}x 🚀)',
          icon: '✨',
        );
      }
    } else {
      AudioManager.playTileSelect(pitchIndex: 1);
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
    final canClaimDaily = GameStorage.canClaimDailyGift();
    final remainingCooldown = GameStorage.getRemainingDailyGiftCooldown();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Center(
        child: SizedBox(
          width: 338.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Outer Thick White Bezel Frame with Soft 3D Shadow
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(38.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38000000),
                      offset: Offset(0, 14),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0xFF7FA3BA),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8.r),
                // Inner Dialog Surface: Solid Slate-Blue background that makes cards POP OUT
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFA0C3D9),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  margin: EdgeInsets.only(top: 36.h,bottom: 4.h),
                  padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Free Pack (Raised 3D Card with 2-bottom-corner rounded bar)
                      _buildRaisedPackCard(
                        barBgAsset: 'assets/images/bar_free.png',
                        title: 'Free Pack',
                        titleOutlineColor: const Color(0xFF023E8A),
                        giftIcon: 'assets/icons/icon_gift_box.png',
                        rewardBgColor: const Color(0xFFB2D4EA),
                        rewardTopBorderColor: const Color(0xFF87A7BE),
                        hintCount: '1',
                        rocketCount: '1',
                        actionButton: _Green3DButton(
                          onTap: _claimFreeReward,
                          isPulsing: canClaimDaily,
                          bgAsset: canClaimDaily
                              ? 'assets/images/btn_green.png'
                              : 'assets/images/btn_grey.png',
                          child: canClaimDaily
                              ? const CartoonText(
                                  text: 'Free',
                                  fontSize: 18,
                                  textColor: Colors.white,
                                  outlineColor: Color(0xFF155484),
                                  strokeWidth: 3.0,
                                  shadowOffset: 1.2,
                                )
                              : CartoonText(
                                  text: _formatDuration(remainingCooldown),
                                  fontSize: 14,
                                  textColor: Colors.white,
                                  outlineColor: const Color(0xFF155484),
                                  strokeWidth: 2.8,
                                  shadowOffset: 1.0,
                                ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // 2. Explorer Pack (Raised 3D Card with 2-bottom-corner rounded bar)
                      _buildRaisedPackCard(
                        barBgAsset: 'assets/images/bar_explorer.png',
                        title: 'Explorer Pack',
                        titleOutlineColor: const Color(0xFF380662),
                        giftIcon: 'assets/icons/icon_gift_explore.png',
                        rewardBgColor: const Color(0xFFF0D0FF),
                        rewardTopBorderColor: const Color(0xFFD0A8E5),
                        hintCount: '3',
                        rocketCount: '1',
                        actionButton: _Green3DButton(
                          onTap: () => _buyBoosterPack('Explorer Pack', 300, 3, 1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/icon_coin.png',
                                width: 22.r,
                                height: 22.r,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 4.w),
                              const CartoonText(
                                text: '300',
                                fontSize: 18,
                                textColor: Colors.white,
                                outlineColor: Color(0xFF155484),
                                strokeWidth: 3.0,
                                shadowOffset: 1.2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // 3. Master Pack (Raised 3D Card with 2-bottom-corner rounded bar)
                      _buildRaisedPackCard(
                        barBgAsset: 'assets/images/bar_master.png',
                        title: 'Master Pack',
                        titleOutlineColor: const Color(0xFF660608),
                        giftIcon: 'assets/icons/icon_gift_master.png',
                        rewardBgColor: const Color(0xFFFBC4D7),
                        rewardTopBorderColor: const Color(0xFFDF9BAF),
                        hintCount: '8',
                        rocketCount: '4',
                        actionButton: _Green3DButton(
                          onTap: () => _buyBoosterPack('Master Pack', 800, 8, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/icon_coin.png',
                                width: 22.r,
                                height: 22.r,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 4.w),
                              const CartoonText(
                                text: '800',
                                fontSize: 18,
                                textColor: Colors.white,
                                outlineColor: Color(0xFF155484),
                                strokeWidth: 3.0,
                                shadowOffset: 1.2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Header Pill Banner: "Daily & Gift" using btn_gift.png
              Positioned(
                top: -20.h,
                child: Container(
                  width: 236.w,
                  height: 52.h,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/btn_gift.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: const CartoonText(
                    text: 'Daily & Gift',
                    fontSize: 23,
                    textColor: Colors.white,
                    outlineColor: Color(0xFF084E94),
                    strokeWidth: 3.6,
                    shadowOffset: 1.8,
                  ),
                ),
              ),

              // Floating 3D Red Circular Close "X" Button using icon_close.png (overflows corner as in mockup)
              Positioned(
                top: -10.h,
                right: -13.w,
                child: _CloseButton(
                  onTap: () => Navigator.of(context).pop(),
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

  /// Builds a prominent raised 3D Card that seamlessly joins the white body and bottom bar
  Widget _buildRaisedPackCard({
    required String barBgAsset,
    required String title,
    required Color titleOutlineColor,
    required String giftIcon,
    required Color rewardBgColor,
    required Color rewardTopBorderColor,
    required String hintCount,
    required String rocketCount,
    required Widget actionButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          // 3D Drop shadow making the card pop out from the slate-blue background
          BoxShadow(
            color: Color(0x32000000),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upper Box: Crisp Pure White Card Body with Gift Icon & Sunken Reward Capsule
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 12.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gift Box Icon with subtle floating shadow
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x18000000),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      giftIcon,
                      width: 64.r,
                      height: 64.r,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Sunken/Engraved Reward Capsule
                  Container(
                    width: 148.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: rewardBgColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: rewardTopBorderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildRewardItem(
                          iconAsset: 'assets/icons/icon_hint.png',
                          count: hintCount,
                        ),
                        _buildRewardItem(
                          iconAsset: 'assets/icons/icon_rocket.png',
                          count: rocketCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Bar: Seamlessly fits with the white container above it!
            Container(
              height: 54.h,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(barBgAsset),
                  fit: BoxFit.fill,
                ),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CartoonText(
                          text: title,
                          fontSize: 19,
                          textColor: Colors.white,
                          outlineColor: titleOutlineColor,
                          strokeWidth: 3.2,
                          shadowOffset: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  actionButton,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required String iconAsset,
    required String count,
  }) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2.h,
            child: Image.asset(
              iconAsset,
              width: 36.r,
              height: 36.r,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CartoonText(
              text: 'X$count',
              fontSize: 13,
              textColor: Colors.white,
              outlineColor: const Color(0xFF155484),
              strokeWidth: 2.8,
              shadowOffset: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile 3D Pack Button using btn_green.png / btn_grey.png asset
class _Green3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isPulsing;
  final String bgAsset;

  const _Green3DButton({
    required this.child,
    required this.onTap,
    this.isPulsing = false,
    this.bgAsset = 'assets/images/btn_green.png',
  });

  @override
  State<_Green3DButton> createState() => _Green3DButtonState();
}

class _Green3DButtonState extends State<_Green3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (GameStorage.isHapticEnabled()) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 88.w,
        height: 36.h,
        margin: EdgeInsets.only(
          top: _isPressed ? 2.h : 0,
          bottom: _isPressed ? 0 : 2.h,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.bgAsset),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: _isPressed ? 0 : 2.h),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.child,
        ),
      ),
    );

    if (widget.isPulsing) {
      button = button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 800.ms, curve: Curves.easeInOut);
    }

    return button;
  }
}

/// Tactile Close Button using user-provided icon_close.png asset
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (GameStorage.isHapticEnabled()) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        AudioManager.playTileSelect(pitchIndex: 1);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Image.asset(
          'assets/icons/icon_close.png',
          width: 44.r,
          height: 44.r,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

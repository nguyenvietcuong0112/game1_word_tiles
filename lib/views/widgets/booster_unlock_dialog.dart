import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/game_controller.dart';
import '../../services/ads_manager.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';
import '../shop_screen.dart';
import 'app_popup.dart';
import 'bouncy_button.dart';
import 'pressable_3d_button.dart';

enum BoosterType {
  hint,
  rocket,
}

class BoosterUnlockDialog extends StatefulWidget {
  final BoosterType boosterType;
  final GameController? controller;
  final VoidCallback? onPurchased;

  const BoosterUnlockDialog({
    super.key,
    required this.boosterType,
    this.controller,
    this.onPurchased,
  });

  /// Displays the BoosterUnlockDialog with spring scale transition
  static Future<void> show(
    BuildContext context, {
    required BoosterType boosterType,
    GameController? controller,
    VoidCallback? onPurchased,
  }) {
    return showGameDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BoosterUnlockDialog(
        boosterType: boosterType,
        controller: controller,
        onPurchased: onPurchased,
      ),
    );
  }

  @override
  State<BoosterUnlockDialog> createState() => _BoosterUnlockDialogState();
}

class _BoosterUnlockDialogState extends State<BoosterUnlockDialog> {
  String get _boosterName =>
      widget.boosterType == BoosterType.hint ? 'Hint' : 'Rocket';

  String get _description => widget.boosterType == BoosterType.hint
      ? 'Reveals a letter to help you find words!'
      : 'Blasts and clears a hidden word instantly!';

  int get _coinsCost => widget.boosterType == BoosterType.hint ? 180 : 450;
  int get _bundleCount => 3;

  void _onBuyWithCoins() async {
    final playerCoins = GameStorage.getCoins();
    if (playerCoins < _coinsCost) {
      AudioManager.playInvalid();
      if (!mounted) return;
      AppPopup.show(
        context,
        title: 'Not Enough Coins!',
        message: 'You need $_coinsCost 🪙 to unlock $_bundleCount $_boosterName.\nVisit the Shop to get more coins!',
        icon: '🪙',
        buttonText: 'Go to Shop',
        secondaryButtonText: 'Cancel',
        onAction: () {
          Navigator.of(context).push(
            GamePageRoute(
              child: const ShopScreen(),
            ),
          );
        },
      );
      return;
    }

    await GameStorage.spendCoins(_coinsCost);
    if (widget.boosterType == BoosterType.hint) {
      await GameStorage.addHintCount(_bundleCount);
    } else {
      await GameStorage.addRocketCount(_bundleCount);
    }

    AudioManager.playWordMatch();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onPurchased?.call();

    // If currently in an active game, execute 1 booster for instant satisfaction!
    if (widget.controller != null) {
      if (widget.boosterType == BoosterType.hint) {
        widget.controller!.useHint();
      } else {
        widget.controller!.useRocket();
      }
    }
  }

  bool _isLoadingAd = false;

  void _onClaimFreeAd() async {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    final boosterName = widget.boosterType == BoosterType.hint ? 'hint' : 'rocket';
    final currentLevel = widget.controller?.levelNumber ?? 1;

    AdsManager.showBoosterReward(
      boosterType: boosterName,
      levelNumber: currentLevel,
      onRewardResult: (success) async {
        if (!mounted) return;
        setState(() => _isLoadingAd = false);

        if (success) {
          if (widget.boosterType == BoosterType.hint) {
            await GameStorage.addHintCount(1);
          } else {
            await GameStorage.addRocketCount(1);
          }

          AudioManager.playWordMatch();
          if (!mounted) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          widget.onPurchased?.call();

          // Automatically trigger the rewarded booster in the level
          if (widget.controller != null) {
            if (widget.boosterType == BoosterType.hint) {
              widget.controller!.useHint();
            } else {
              widget.controller!.useRocket();
            }
          }
        } else {
          AppPopup.show(
            context,
            title: 'Ad Unavailable',
            message: 'Unable to load rewarded video right now. Please check your connection and try again!',
            icon: '❌',
            isError: true,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 326.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. Outer White Card with 3D Drop Shadow
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
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Coin Pill at top-right (Tap to open Shop)
                    Align(
                      alignment: Alignment.centerRight,
                      child: BouncyButton(
                        onTap: () {
                          Navigator.of(context).push(
                            GamePageRoute(child: const ShopScreen()),
                          );
                        },
                        child: Container(
                          height: 28.h,
                          padding: EdgeInsets.fromLTRB(10.w, 0, 4.w, 0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD5E7F3),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: const Color(0xFFBED7E8), width: 1.2),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: GameStorage.coinsNotifier,
                            builder: (context, coins, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/icons/icon_coin.webp',
                                    width: 18.r,
                                    height: 18.r,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '$coins',
                                    style: AppTypography.font(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Container(
                                    width: 18.r,
                                    height: 18.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFF5CEB38), Color(0xFF28A811)],
                                      ),
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Sunken Pastel Showcase Panel (Matching Settings style)
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
                      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
                      child: Column(
                        children: [
                          // Hero Booster Icon with subtle breathing animation
                          Image.asset(
                            widget.boosterType == BoosterType.hint
                                ? 'assets/icons/icon_hint.webp'
                                : 'assets/icons/icon_rocket.webp',
                            width: 76.r,
                            height: 76.r,
                            fit: BoxFit.contain,
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.96, 0.96),
                                end: const Offset(1.04, 1.04),
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              ),
                          SizedBox(height: 10.h),

                          // Description in white pill
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFFBED7E8), width: 1.0),
                            ),
                            child: Text(
                              _description,
                              textAlign: TextAlign.center,
                              style: AppTypography.font(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B4868),
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // In Inventory
                          ValueListenableBuilder<int>(
                            valueListenable: widget.boosterType == BoosterType.hint
                                ? GameStorage.hintCountNotifier
                                : GameStorage.rocketCountNotifier,
                            builder: (context, count, _) {
                              return Text(
                                'In Inventory: $count available',
                                style: AppTypography.font(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5A6E85),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 1. Option 1: Buy x3 with Coins (Vivid Green 3D Pressable Button)
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
                      onTap: _onBuyWithCoins,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  widget.boosterType == BoosterType.hint
                                      ? 'assets/icons/icon_hint.webp'
                                      : 'assets/icons/icon_rocket.webp',
                                  width: 26.r,
                                  height: 26.r,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 8.w),
                                CartoonText(
                                  text: 'x$_bundleCount',
                                  fontSize: 18.sp,
                                  strokeWidth: 2.8,
                                  outlineColor: const Color(0xFF179A09),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/icon_coin.webp',
                                  width: 24.r,
                                  height: 24.r,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 6.w),
                                CartoonText(
                                  text: '$_coinsCost',
                                  fontSize: 19.sp,
                                  strokeWidth: 2.8,
                                  outlineColor: const Color(0xFF0F5A06),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // 2. Option 2: Watch Ad / Free x1 (Golden Amber 3D Pressable Button)
                    Pressable3DButton(
                      width: double.infinity,
                      height: 52.h,
                      scaleDown: false,
                      borderRadius: 18,
                      bevelOffset: 4.5,
                      borderWidth: 1.2,
                      faceColor: const Color(0xFFFFB300),
                      bevelColor: const Color(0xFFE69500),
                      borderColor: const Color(0xFFD38109),
                      onTap: _isLoadingAd ? null : _onClaimFreeAd,
                      child: _isLoadingAd
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18.w),
                              child: Row(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        widget.boosterType == BoosterType.hint
                                            ? 'assets/icons/icon_hint.webp'
                                            : 'assets/icons/icon_rocket.webp',
                                        width: 26.r,
                                        height: 26.r,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 8.w),
                                      CartoonText(
                                        text: 'x1',
                                        fontSize: 18.sp,
                                        strokeWidth: 2.8,
                                        outlineColor: const Color(0xFF8B4513),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/icons/icon_ads.webp',
                                        width: 22.r,
                                        height: 22.r,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 6.w),
                                      CartoonText(
                                        text: 'FREE',
                                        fontSize: 18.sp,
                                        strokeWidth: 2.8,
                                        outlineColor: const Color(0xFF8B4513),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Header Banner: "Hint Booster" / "Rocket Booster" with bg_btn_setting.webp
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
                  child: Text(
                    '$_boosterName Booster',
                    style: AppTypography.font(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF380662),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Color(0xFF380662),
                          offset: Offset(0, 1.5),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating 3D Red Circular Close "X" Button using icon_close.webp
              Positioned(
                top: -15.h,
                right: -13.w,
                child: BouncyButton(
                  onTap: () {
                    AudioManager.playTileSelect(pitchIndex: 1);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
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


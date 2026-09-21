import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';

/// Modern 3D Casual Game Dialog for alerts, rewards, and confirmations.
/// Styled in complete harmony with SettingsDialog, ShopDialog, and ExitGameDialog:
/// - Beveled white card frame with 3D drop shadow (`#B0C9DA`)
/// - Overlapping cartoon header pill (`btn_gift.webp` / `bg_btn_setting.webp`)
/// - Sunken pastel alert panel (`#D5E7F3`)
/// - Smart 3D game asset icon resolution (`icon_coin.webp`, `icon_congrats.webp`, `icon_notice.webp`, etc.)
/// - Tactile 3D Action button (`#42D623` or `#FF3F3F`)
/// - Floating circular 3D close "X" button (`icon_close.webp`)
class AppPopup extends StatelessWidget {
  final String title;
  final String message;
  final String icon;
  final String? iconAsset;
  final String buttonText;
  final VoidCallback? onClose;
  final VoidCallback? onAction;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryAction;
  final bool isError;

  const AppPopup({
    super.key,
    required this.title,
    required this.message,
    this.icon = '✨',
    this.iconAsset,
    this.buttonText = 'OK',
    this.onClose,
    this.onAction,
    this.secondaryButtonText,
    this.onSecondaryAction,
    this.isError = false,
  });

  /// Displays the modernized 3D AppPopup with springy entrance animation.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String icon = '✨',
    String? iconAsset,
    String buttonText = 'OK',
    VoidCallback? onClose,
    VoidCallback? onAction,
    String? secondaryButtonText,
    VoidCallback? onSecondaryAction,
    bool isError = false,
  }) {
    return showGameDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppPopup(
        title: title,
        message: message,
        icon: icon,
        iconAsset: iconAsset,
        buttonText: buttonText,
        onClose: onClose,
        onAction: onAction,
        secondaryButtonText: secondaryButtonText,
        onSecondaryAction: onSecondaryAction,
        isError: isError,
      ),
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
                    // Sunken Pastel Alert Panel
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
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Graphic / Reward / Alert Icon
                          _buildVisualIcon(),
                          SizedBox(height: 14.h),

                          // Message Body
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: AppTypography.font(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A5F),
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Tactile 3D Action Button(s)
                    if (secondaryButtonText != null)
                      Row(
                        children: [
                          Expanded(
                            child: _Pressable3DButton(
                              label: secondaryButtonText!,
                              faceColor: const Color(0xFF8FAEC2),
                              bevelColor: const Color(0xFF6B8A9E),
                              borderColor: const Color(0xFF476273),
                              outlineColor: const Color(0xFF476273),
                              onTap: () {
                                AudioManager.playTileSelect(pitchIndex: 1);
                                Navigator.of(context).pop();
                                onSecondaryAction?.call();
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _Pressable3DButton(
                              label: buttonText,
                              faceColor: isError ? const Color(0xFFFF3F3F) : const Color(0xFF42D623),
                              bevelColor: isError ? const Color(0xFFD11F24) : const Color(0xFF229713),
                              borderColor: isError ? const Color(0xFF881014) : const Color(0xFF0F5A06),
                              outlineColor: isError ? const Color(0xFF881014) : const Color(0xFF0E5606),
                              onTap: () {
                                AudioManager.playTileSelect(pitchIndex: isError ? 1 : 3);
                                Navigator.of(context).pop();
                                if (onAction != null) {
                                  onAction!();
                                } else {
                                  onClose?.call();
                                }
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      _Pressable3DButton(
                        label: buttonText,
                        faceColor: isError ? const Color(0xFFFF3F3F) : const Color(0xFF42D623),
                        bevelColor: isError ? const Color(0xFFD11F24) : const Color(0xFF229713),
                        borderColor: isError ? const Color(0xFF881014) : const Color(0xFF0F5A06),
                        outlineColor: isError ? const Color(0xFF881014) : const Color(0xFF0E5606),
                        onTap: () {
                          AudioManager.playTileSelect(pitchIndex: isError ? 1 : 3);
                          Navigator.of(context).pop();
                          if (onAction != null) {
                            onAction!();
                          } else {
                            onClose?.call();
                          }
                        },
                      ),
                  ],
                ),
              ),

              // 2. Top Header Pill Banner
              Positioned(
                top: -20.h,
                child: Container(
                  width: 226.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        isError
                            ? 'assets/icons/bg_btn_setting.webp'
                            : 'assets/images/btn_gift.webp',
                      ),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CartoonText(
                      text: title,
                      fontSize: 20,
                      textColor: Colors.white,
                      outlineColor: isError
                          ? const Color(0xFF380662)
                          : const Color(0xFF084E94),
                      strokeWidth: 3.4,
                      shadowOffset: 1.6,
                    ),
                  ),
                ),
              ),

              // 3. Floating 3D Red Circular Close "X" Button
              Positioned(
                top: -10.h,
                right: -13.w,
                child: _CloseButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
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

  /// Intelligently resolves the optimal visual 3D asset based on icon string and context
  Widget _buildVisualIcon() {
    if (iconAsset != null && iconAsset!.isNotEmpty) {
      return _buildAssetImage(iconAsset!, size: 68);
    }

    if (icon.startsWith('assets/')) {
      return _buildAssetImage(icon, size: 68);
    }

    final lowerTitle = title.toLowerCase();

    // 1. Coins reward
    if (icon.contains('🪙') || lowerTitle.contains('coin')) {
      return _buildAssetImage('assets/icons/icon_coin.webp', size: 68);
    }

    // 2. Congratulations / celebration / unlocked
    if (icon.contains('✨') ||
        icon.contains('🎉') ||
        lowerTitle.contains('success') ||
        lowerTitle.contains('unlock')) {
      return _buildAssetImage('assets/icons/icon_congrats.webp', size: 68);
    }

    // 3. Error / Warning
    if (icon.contains('❌') || isError) {
      return _buildAssetImage('assets/icons/icon_notice.webp', size: 60);
    }

    // 4. Hint booster
    if (icon.contains('💡') || lowerTitle.contains('hint')) {
      return _buildAssetImage('assets/icons/icon_hint.webp', size: 62);
    }

    // 5. Rocket booster
    if (icon.contains('🚀') || lowerTitle.contains('rocket')) {
      return _buildAssetImage('assets/icons/icon_rocket.webp', size: 62);
    }

    // 6. Gift box / Daily cooldown
    if (icon.contains('⏳') ||
        icon.contains('🎁') ||
        lowerTitle.contains('cooldown') ||
        lowerTitle.contains('gift')) {
      return _buildAssetImage('assets/icons/icon_gift_box.webp', size: 64);
    }

    // 7. Star / Restored / Checked
    if (icon.contains('✅') || lowerTitle.contains('restor')) {
      return _buildAssetImage('assets/icons/icon_star.webp', size: 62);
    }

    // 8. Info / Notice / Question
    if (icon.contains('ℹ️') || icon.contains('❓')) {
      return _buildAssetImage('assets/icons/icon_notice.webp', size: 60);
    }

    // Fallback: Circular tactile badge with text emoji
    return Container(
      width: 62.r,
      height: 62.r,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBED7E8), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        icon,
        style: TextStyle(fontSize: 30.sp),
      ),
    );
  }

  Widget _buildAssetImage(String assetPath, {double size = 64}) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1E000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: size.r,
        height: size.r,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Tactile 3D Action Button matching the design system
class _Pressable3DButton extends StatefulWidget {
  final String label;
  final Color faceColor;
  final Color bevelColor;
  final Color borderColor;
  final Color outlineColor;
  final VoidCallback onTap;

  const _Pressable3DButton({
    required this.label,
    required this.faceColor,
    required this.bevelColor,
    required this.borderColor,
    required this.outlineColor,
    required this.onTap,
  });

  @override
  State<_Pressable3DButton> createState() => _Pressable3DButtonState();
}

class _Pressable3DButtonState extends State<_Pressable3DButton> {
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
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: double.infinity,
        height: 48.h,
        margin: EdgeInsets.only(
          top: _isPressed ? 3.h : 0,
          bottom: _isPressed ? 0 : 3.h,
        ),
        decoration: BoxDecoration(
          color: widget.faceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: widget.borderColor, width: 0.5),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.bevelColor,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            const BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: _isPressed ? 0 : 2.h),
        child: CartoonText(
          text: widget.label,
          fontSize: 18,
          textColor: Colors.white,
          outlineColor: widget.outlineColor,
          strokeWidth: 3.0,
          shadowOffset: 1.2,
        ),
      ),
    );
  }
}

/// Tactile Circular Close Button using icon_close.webp
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
          'assets/icons/icon_close.webp',
          width: 44.r,
          height: 44.r,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

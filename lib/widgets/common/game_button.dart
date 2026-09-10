import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';

enum GameButtonVariant {
  primary,
  success,
  gold,
  secondary,
  danger,
}

enum GameButtonSize {
  large,
  medium,
  small,
}

/// Unified 3D Tactile Action Button for Word Tiles.
/// Provides physical push-down depth, bouncy spring feedback, and semantic themes.
class GameButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String? text;
  final Widget? child;
  final Widget? icon;
  final Widget? trailingIcon;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final bool isFullWidth;
  final bool isLoading;

  const GameButton({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.variant = GameButtonVariant.primary,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  // Named factory constructors for common semantic patterns
  const GameButton.primary({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  }) : variant = GameButtonVariant.primary;

  const GameButton.success({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  }) : variant = GameButtonVariant.success;

  const GameButton.gold({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  }) : variant = GameButtonVariant.gold;

  const GameButton.secondary({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  }) : variant = GameButtonVariant.secondary;

  const GameButton.danger({
    super.key,
    required this.onTap,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    this.size = GameButtonSize.medium,
    this.isFullWidth = true,
    this.isLoading = false,
  }) : variant = GameButtonVariant.danger;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _animController.forward();
    if (GameStorage.isHapticEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _animController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dimensions
    final double height;
    final double fontSize;
    final double borderRadius;
    final double depth;

    switch (widget.size) {
      case GameButtonSize.large:
        height = 58.h;
        fontSize = 20.sp;
        borderRadius = 28.r;
        depth = 4.0;
        break;
      case GameButtonSize.medium:
        height = 48.h;
        fontSize = 15.sp;
        borderRadius = 20.r;
        depth = 3.0;
        break;
      case GameButtonSize.small:
        height = 36.h;
        fontSize = 12.sp;
        borderRadius = 14.r;
        depth = 2.0;
        break;
    }

    // 2. Styling Tokens
    final Gradient? gradient;
    final Color? solidColor;
    final Color borderColor;
    final Color shadowColor;
    final Color textColor;

    switch (widget.variant) {
      case GameButtonVariant.primary:
        gradient = const LinearGradient(
          colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        solidColor = null;
        borderColor = AppColors.btnBorderBrown;
        shadowColor = AppColors.btnShadowBrown;
        textColor = Colors.white;
        break;
      case GameButtonVariant.success:
        gradient = const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        solidColor = null;
        borderColor = const Color(0xFF166534);
        shadowColor = const Color(0xFF15803D);
        textColor = Colors.white;
        break;
      case GameButtonVariant.gold:
        gradient = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        solidColor = null;
        borderColor = const Color(0xFF92400E);
        shadowColor = const Color(0xFFB45309);
        textColor = Colors.white;
        break;
      case GameButtonVariant.danger:
        gradient = const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        solidColor = null;
        borderColor = AppColors.dangerBorder;
        shadowColor = AppColors.dangerShadow;
        textColor = Colors.white;
        break;
      case GameButtonVariant.secondary:
        gradient = null;
        solidColor = AppColors.cardPeachLight;
        borderColor = AppColors.borderSubtle;
        shadowColor = const Color(0xFFE8DAC8);
        textColor = AppColors.headerBrown;
        break;
    }

    final effectiveDepth = (widget.onTap != null && _isPressed) ? 0.0 : depth;
    final currentOffset = (widget.onTap != null && _isPressed) ? depth : 0.0;

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20.r,
        height: 20.r,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: textColor,
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.8,
                  shadows: widget.variant != GameButtonVariant.secondary
                      ? [
                          Shadow(
                            color: shadowColor,
                            offset: const Offset(0, 1.2),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          if (widget.trailingIcon != null) ...[
            SizedBox(width: 8.w),
            widget.trailingIcon!,
          ],
        ],
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          height: height + depth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom 3D Bevel / Shadow layer
              Positioned(
                top: depth,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: shadowColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              // Front Surface Layer
              Positioned(
                top: currentOffset,
                left: 0,
                right: 0,
                bottom: effectiveDepth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    color: solidColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        offset: const Offset(0, 1.2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  alignment: Alignment.center,
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

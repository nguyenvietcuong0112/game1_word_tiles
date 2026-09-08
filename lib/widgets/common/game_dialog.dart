import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';
import 'game_button.dart';
import 'game_icon_button.dart';

enum GameDialogHeaderStyle {
  banner, // 3D arched top banner strip with cartoon title
  badge,  // Circular icon badge at top
  inline, // Clean horizontal header row
  none,   // No header
}

/// Unified 3D Game Dialog Frame for Word Tiles.
/// Standardizes card surface, border, 3D drop shadow, header patterns, and floating close button.
class GameDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? bannerTitle;
  final Widget? badgeIcon;
  final GameDialogHeaderStyle headerStyle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final List<Widget>? actions;
  final Color backgroundColor;
  final double? maxWidth;

  const GameDialog({
    super.key,
    required this.child,
    this.title,
    this.bannerTitle,
    this.badgeIcon,
    this.headerStyle = GameDialogHeaderStyle.none,
    this.showCloseButton = true,
    this.onClose,
    this.actions,
    this.backgroundColor = AppColors.cardPeach,
    this.maxWidth,
  });

  /// Factory helper for standard Info/Alert popups (replaces legacy AppPopup)
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String icon = '✨',
    String buttonText = 'OK',
    VoidCallback? onClose,
    bool isError = false,
  }) {
    return showGameDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GameDialog(
        headerStyle: GameDialogHeaderStyle.badge,
        showCloseButton: false,
        badgeIcon: Container(
          width: 58.r,
          height: 58.r,
          decoration: BoxDecoration(
            color: isError ? Colors.redAccent.withValues(alpha: 0.12) : AppColors.cardWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: isError ? Colors.redAccent : AppColors.borderSubtle,
              width: 1.8,
            ),
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
              icon,
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        ),
        actions: [
          GameButton(
            variant: isError ? GameButtonVariant.danger : GameButtonVariant.primary,
            text: buttonText,
            onTap: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              onClose?.call();
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 19.sp,
                fontWeight: FontWeight.w900,
                color: isError ? Colors.red.shade800 : AppColors.headerBrown,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 13.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Factory helper for standard 2-button confirmations (Exit, Pause, Reset, etc.)
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String icon = '❓',
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    GameButtonVariant confirmVariant = GameButtonVariant.primary,
  }) {
    return showGameDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GameDialog(
        headerStyle: GameDialogHeaderStyle.badge,
        showCloseButton: false,
        backgroundColor: AppColors.cardWhite,
        badgeIcon: Container(
          width: 58.r,
          height: 58.r,
          decoration: BoxDecoration(
            color: AppColors.butterCream,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFDE68A), width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFFCD34D),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(icon, style: TextStyle(fontSize: 26.sp)),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton.secondary(
                  text: cancelText,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: GameButton(
                  variant: confirmVariant,
                  text: confirmText,
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 21.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Card Frame
          Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? 400.w,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: AppColors.borderSubtle, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 8.0),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Color(0xFFD4C2AE),
                  offset: Offset(0, 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header Area
                if (headerStyle == GameDialogHeaderStyle.banner) _buildBannerHeader(),
                if (headerStyle == GameDialogHeaderStyle.badge && badgeIcon != null) ...[
                  SizedBox(height: 20.h),
                  badgeIcon!,
                  SizedBox(height: 12.h),
                ],
                if (headerStyle == GameDialogHeaderStyle.inline) _buildInlineHeader(context),

                // 2. Child Body
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    headerStyle == GameDialogHeaderStyle.none ? 20.h : (headerStyle == GameDialogHeaderStyle.badge ? 0 : 14.h),
                    20.w,
                    actions != null ? 14.h : 20.h,
                  ),
                  child: child,
                ),

                // 3. Action Buttons Area
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),

          // Floating Glossy Red Circular Close "X" Button
          if (showCloseButton)
            Positioned(
              top: -12.h,
              right: -8.w,
              child: GameIconButton.close(
                context,
                onTap: onClose ?? () => Navigator.of(context).pop(),
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
        )
        .fadeIn(duration: 200.ms);
  }

  Widget _buildBannerHeader() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26.r),
          topRight: Radius.circular(26.r),
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF8F522C), width: 2.5),
        ),
      ),
      child: Center(
        child: CartoonText(
          text: bannerTitle ?? title ?? '',
          fontSize: 24.sp,
          outlineColor: const Color(0xFF5A2A0C),
          strokeWidth: 3.8,
        ),
      ),
    );
  }

  Widget _buildInlineHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title ?? '',
            style: GoogleFonts.fredoka(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.headerBrown,
              letterSpacing: 0.5,
            ),
          ),
          if (!showCloseButton)
            GameIconButton.close(
              context,
              size: GameIconButtonSize.mini,
              onTap: onClose ?? () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

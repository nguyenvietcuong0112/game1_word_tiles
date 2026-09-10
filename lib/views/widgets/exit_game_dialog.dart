import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';

/// Exit Game Confirmation Dialog styled identically to Settings & Shop popups.
/// Features:
/// - Purple 3D banner header (`bg_btn_setting.png`)
/// - Tactile close button overflowing the corner (`icon_close.png`)
/// - Sunken pastel alert panel (`#D5E7F3`) with `icon_notice.png`
/// - Tactile 3D Red "Exit" button and Green "Stay" button
class ExitGameDialog extends StatelessWidget {
  final VoidCallback? onExit;
  final VoidCallback? onStay;

  const ExitGameDialog({
    super.key,
    this.onExit,
    this.onStay,
  });

  /// Helper to open the ExitGameDialog with springy scale transition
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onExit,
    VoidCallback? onStay,
  }) {
    return showGameDialog(
      context: context,
      builder: (ctx) => ExitGameDialog(
        onExit: onExit ?? () => SystemNavigator.pop(),
        onStay: onStay,
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
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Alert/Notice Icon
                          Image.asset(
                            'assets/icons/icon_notice.png',
                            width: 58.r,
                            height: 58.r,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 12.h),

                          // Question Title
                          Text(
                            'Are you sure you want to exit?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A5F),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // Subtitle reassurance
                          Text(
                            'Your progress is always saved!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A7B9A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Side-by-side 3D Buttons (Exit vs Stay)
                    Row(
                      children: [
                        // Red 3D Exit Button
                        Expanded(
                          child: _Pressable3DButton(
                            label: 'Exit',
                            icon: Icons.exit_to_app_rounded,
                            faceColor: const Color(0xFFFF3F3F),
                            bevelColor: const Color(0xFFD11F24),
                            borderColor: const Color(0xFF881014),
                            outlineColor: const Color(0xFF881014),
                            onTap: () {
                              AudioManager.playTileSelect(pitchIndex: 2);
                              Navigator.of(context).pop();
                              if (onExit != null) {
                                onExit!();
                              } else {
                                SystemNavigator.pop();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Green 3D Stay Button
                        Expanded(
                          child: _Pressable3DButton(
                            label: 'Stay',
                            icon: Icons.play_arrow_rounded,
                            faceColor: const Color(0xFF42D623),
                            bevelColor: const Color(0xFF229713),
                            borderColor: const Color(0xFF0F5A06),
                            outlineColor: const Color(0xFF0E5606),
                            onTap: () {
                              AudioManager.playTileSelect(pitchIndex: 3);
                              Navigator.of(context).pop();
                              onStay?.call();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Header Pill: "Exit Game" with bg_btn_setting.png
              Positioned(
                top: -20.h,
                child: Container(
                  width: 200.w,
                  height: 48.h,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icons/bg_btn_setting.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: const CartoonText(
                    text: 'Exit Game',
                    fontSize: 21,
                    textColor: Colors.white,
                    outlineColor: Color(0xFF380662),
                    strokeWidth: 3.4,
                    shadowOffset: 1.6,
                  ),
                ),
              ),

              // Close Button using icon_close.png (overflows corner)
              Positioned(
                top: -10.h,
                right: -13.w,
                child: _CloseButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    onStay?.call();
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
}

/// Tactile 3D Button with face color, bevel, and outline
class _Pressable3DButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color faceColor;
  final Color bevelColor;
  final Color borderColor;
  final Color outlineColor;
  final VoidCallback onTap;

  const _Pressable3DButton({
    required this.label,
    required this.icon,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 20.r),
            SizedBox(width: 6.w),
            CartoonText(
              text: widget.label,
              fontSize: 16,
              textColor: Colors.white,
              outlineColor: widget.outlineColor,
              strokeWidth: 2.8,
              shadowOffset: 1.2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile Close Button using icon_close.png
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

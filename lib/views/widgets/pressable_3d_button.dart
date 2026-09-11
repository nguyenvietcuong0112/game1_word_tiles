import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/game_storage.dart';

/// Reusable 3D tactile pressable button matching the Settings popup Home button style.
/// Features a vivid face color, rich bottom bevel shadow, crisp border, and physical press sinking.
class Pressable3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Color faceColor;
  final Color bevelColor;
  final Color borderColor;
  final double borderRadius;
  final double bevelOffset;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const Pressable3DButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height = 48,
    this.faceColor = const Color(0xFF42D623),
    this.bevelColor = const Color(0xFF229713),
    this.borderColor = const Color(0xFF0F5A06),
    this.borderRadius = 16,
    this.bevelOffset = 4.0,
    this.borderWidth = 1.0,
    this.padding,
  });

  @override
  State<Pressable3DButton> createState() => _Pressable3DButtonState();
}

class _Pressable3DButtonState extends State<Pressable3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;
    final pressOffset = (widget.bevelOffset * 0.75).clamp(2.0, 5.0);

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              setState(() => _isPressed = true);
              try {
                if (GameStorage.isHapticEnabled()) {
                  HapticFeedback.lightImpact();
                }
              } catch (_) {}
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: isEnabled
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? pressOffset.h : 0,
          bottom: _isPressed ? 0 : pressOffset.h,
        ),
        decoration: BoxDecoration(
          color: widget.faceColor,
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          border: Border.all(color: widget.borderColor, width: widget.borderWidth),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.bevelColor,
                offset: Offset(0, widget.bevelOffset.h),
                blurRadius: 0,
              ),
            BoxShadow(
              color: const Color(0x28000000),
              offset: Offset(0, widget.bevelOffset.h),
              blurRadius: 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: widget.padding ?? EdgeInsets.only(bottom: _isPressed ? 0 : 2.h),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.child,
        ),
      ),
    );
  }
}

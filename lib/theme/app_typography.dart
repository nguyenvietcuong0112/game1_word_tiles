import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_theme.dart';

/// Centralized Typography tokens for Word Tiles.
/// All text styles use Mikado Bold with crisp scaling via ScreenUtil.
class AppTypography {
  static const String fontFamily = 'MikadoBold';
  static const List<String> fontFamilyFallback = ['Fredoka', 'Roboto', 'sans-serif'];

  /// Universal TextStyle generator using Mikado Bold.
  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    Paint? foreground,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      foreground: foreground,
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }

  static TextStyle titleHero({Color color = AppColors.headerBrown}) =>
      font(
        fontSize: 28.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: color,
      );

  static TextStyle titleLarge({Color color = AppColors.headerBrown}) =>
      font(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle titleMedium({Color color = AppColors.textDark}) =>
      font(
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle titleSmall({Color color = AppColors.textDark}) =>
      font(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle bodyLarge({Color color = AppColors.textMuted}) =>
      font(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyMedium({Color color = AppColors.textMuted}) =>
      font(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      font(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle buttonLarge({Color color = Colors.white}) =>
      font(
        fontSize: 20.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: color,
      );

  static TextStyle buttonMedium({Color color = Colors.white}) =>
      font(
        fontSize: 15.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle buttonSmall({Color color = Colors.white}) =>
      font(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: color,
      );
}

/// 3D Cartoon Outlined Text with solid drop shadow and crisp outline stroke
class CartoonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color outlineColor;
  final double strokeWidth;
  final double shadowOffset;
  final TextAlign textAlign;

  const CartoonText({
    super.key,
    required this.text,
    this.fontSize = 20,
    this.textColor = Colors.white,
    this.outlineColor = const Color(0xFF5A2A0C),
    this.strokeWidth = 3.0,
    this.shadowOffset = 1.8,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (strokeWidth / 2) + 2.w,
        vertical: (strokeWidth / 2) + shadowOffset + 1.h,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Drop shadow outline
          if (shadowOffset > 0)
            Transform.translate(
              offset: Offset(0, shadowOffset),
              child: Text(
                text,
                textAlign: textAlign,
                style: AppTypography.font(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth * 0.85
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round
                    ..color = outlineColor.withValues(alpha: 0.45),
                ),
              ),
            ),
          // Outer outline stroke
          Text(
            text,
            textAlign: textAlign,
            style: AppTypography.font(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.2,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = outlineColor,
            ),
          ),
          // Face text
          Text(
            text,
            textAlign: textAlign,
            style: AppTypography.font(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

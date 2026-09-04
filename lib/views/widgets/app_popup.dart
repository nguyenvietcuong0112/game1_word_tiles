import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/wood_widgets.dart';

class AppPopup extends StatelessWidget {
  final String title;
  final String message;
  final String icon;
  final String buttonText;
  final VoidCallback? onClose;
  final bool isError;

  const AppPopup({
    super.key,
    required this.title,
    required this.message,
    this.icon = '✨',
    this.buttonText = 'OK',
    this.onClose,
    this.isError = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String icon = '✨',
    String buttonText = 'OK',
    VoidCallback? onClose,
    bool isError = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppPopup(
        title: title,
        message: message,
        icon: icon,
        buttonText: buttonText,
        onClose: onClose,
        isError: isError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WoodSignboardDialog(
      title: title,
      onClose: () {
        Navigator.of(context, rootNavigator: true).pop();
        if (onClose != null) onClose!();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          // Top Circular Icon Badge
          Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EA),
              shape: BoxShape.circle,
              border: Border.all(
                color: isError ? const Color(0xFF9E1508) : WoodenStyle.woodBevel,
                width: 1.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: WoodenStyle.woodExtrusion,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(fontSize: 26.sp),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Message
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 14.sp,
                color: const Color(0xFFFFE8CC),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Wood CTA Button
          WoodCtaButton(
            text: buttonText,
            isGreen: !isError,
            height: 48.h,
            fontSize: 15.sp,
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              if (onClose != null) onClose!();
            },
          ),
        ],
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
  }
}

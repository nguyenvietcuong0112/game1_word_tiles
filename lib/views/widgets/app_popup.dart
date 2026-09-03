import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: AppColors.cardPeach,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderSubtle, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE8DAC8),
              offset: Offset(0, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Circular Icon Badge
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: isError
                    ? Colors.redAccent.withValues(alpha: 0.12)
                    : AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isError ? Colors.redAccent : AppColors.borderSubtle,
                  width: 1.5,
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
            SizedBox(height: 16.h),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: isError ? Colors.red.shade800 : AppColors.headerBrown,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),

            // Message
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
            SizedBox(height: 22.h),

            // Button
            InkWell(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                if (onClose != null) {
                  onClose!();
                }
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: isError
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFCA9370), AppColors.btnFaceBrown],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  color: isError ? Colors.redAccent.shade400 : null,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isError ? Colors.red.shade700 : AppColors.btnBorderBrown,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isError ? Colors.red.shade800 : AppColors.btnShadowBrown,
                      offset: const Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: GoogleFonts.fredoka(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
    );
  }
}

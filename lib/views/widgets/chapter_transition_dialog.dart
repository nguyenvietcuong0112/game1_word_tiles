import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/game_button.dart';

class ChapterTransitionDialog extends StatelessWidget {
  final VoidCallback onStartChapter;

  const ChapterTransitionDialog({
    super.key,
    required this.onStartChapter,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onStartChapter}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (_) => ChapterTransitionDialog(onStartChapter: onStartChapter),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: const Color(0xFF4A7DA5), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 10.0),
              blurRadius: 25,
            ),
            BoxShadow(
              color: Color(0xFF10233B),
              offset: Offset(0, 4.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Chapters" Title
            Text(
              'Chapters',
              style: GoogleFonts.fredoka(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 4.h, bottom: 20.h),
              width: 60.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // 2 Chapter Cards Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chapter 1 Card (Completed)
                _buildChapterCard(
                  chapterNum: 1,
                  title: 'Fuji Lake',
                  emoji: '🗻',
                  isCompleted: true,
                  isActive: false,
                ),
                SizedBox(width: 14.w),

                // Chapter 2 Card (Active / Unlocked)
                _buildChapterCard(
                  chapterNum: 2,
                  title: 'Mountain Trail',
                  emoji: '🌲',
                  isCompleted: false,
                  isActive: true,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Start Chapter 2 CTA Button
            SizedBox(
              width: 220.w,
              child: GameButton.success(
                size: GameButtonSize.large,
                text: 'PLAY CHAPTER 2',
                trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                onTap: () {
                  Navigator.of(context).pop();
                  onStartChapter();
                },
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 350.ms, curve: Curves.easeOutBack);
  }

  Widget _buildChapterCard({
    required int chapterNum,
    required String title,
    required String emoji,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Container(
      width: 130.w,
      height: 180.h,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2B527A) : const Color(0xFF182E4B),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF3B6188),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isActive)
            const BoxShadow(
              color: Color(0x66F59E0B),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: 48.sp)),
                SizedBox(height: 10.h),
                Text(
                  'Chapter $chapterNum',
                  style: GoogleFonts.fredoka(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 12.sp,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

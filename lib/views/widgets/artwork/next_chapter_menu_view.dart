import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/chapter_model.dart';
import '../../../services/audio_manager.dart';
import '../../../services/game_storage.dart';
import '../../../widgets/common/game_button.dart';
import 'particle_fireworks_overlay.dart';

/// NextChapterMenuView is the celebratory chapter-end screen showing the fully completed
/// landscape artwork, celebratory fireworks, reward claim (+50 coins), and the "NEXT CHAPTER" CTA button.
class NextChapterMenuView extends StatefulWidget {
  final int completedChapterNumber;
  final VoidCallback onNextChapter;

  const NextChapterMenuView({
    super.key,
    required this.completedChapterNumber,
    required this.onNextChapter,
  });

  static Future<void> show(
    BuildContext context, {
    required int completedChapterNumber,
    required VoidCallback onNextChapter,
  }) {
    AudioManager.playVictory();
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => NextChapterMenuView(
        completedChapterNumber: completedChapterNumber,
        onNextChapter: onNextChapter,
      ),
    );
  }

  @override
  State<NextChapterMenuView> createState() => _NextChapterMenuViewState();
}

class _NextChapterMenuViewState extends State<NextChapterMenuView> {
  @override
  void initState() {
    super.initState();
    // Award chapter completion coins
    final theme = ChapterTheme.forChapter(widget.completedChapterNumber);
    GameStorage.addCoins(theme.rewardCoins);
  }

  @override
  Widget build(BuildContext context) {
    final completedTheme = ChapterTheme.forChapter(widget.completedChapterNumber);
    final nextTheme = ChapterTheme.forChapter(widget.completedChapterNumber + 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Celebratory Particle Fireworks Layer
          const ParticleFireworksOverlay(isPlaying: true),

          // 2. Centered Celebration Card & Completed Artwork
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Deep Slate Navy
                  borderRadius: BorderRadius.circular(32.r),
                  border: Border.all(color: const Color(0xFFFBBF24), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 10.0),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Golden Trophy Badge
                    Container(
                      width: 58.r,
                      height: 58.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFE082), Color(0xFFF59E0B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66F59E0B),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text('🏆', style: TextStyle(fontSize: 28.sp)),
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 12.h),

                    // Celebration Title
                    Text(
                      'CHAPTER ${completedTheme.chapterNumber} COMPLETE!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${completedTheme.title} ${completedTheme.emoji} Mastered',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 14.sp,
                        color: const Color(0xFFFDE68A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Completed Full Landscape Painting (Framed in Gold)
                    Container(
                      width: 270.w,
                      height: 165.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 4.0),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.r),
                        child: CustomPaint(
                          painter: ChapterLandscapePainter(
                            theme: completedTheme,
                            progress: 1.0,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .scale(begin: const Offset(0.90, 0.90), end: const Offset(1.0, 1.0), duration: 400.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 16.h),

                    // Chapter Reward Badge Pill: 🎁 +50 Coins
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎁', style: TextStyle(fontSize: 18.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            '+${completedTheme.rewardCoins} COINS REWARD!',
                            style: GoogleFonts.fredoka(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 300.ms)
                        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 14.h),

                    // Next Chapter Teaser
                    Text(
                      'Next Up: ${nextTheme.title} ${nextTheme.emoji}',
                      style: GoogleFonts.fredoka(
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Next Chapter Action Button
                    SizedBox(
                      width: 250.w,
                      child: GameButton.success(
                        size: GameButtonSize.large,
                        text: 'NEXT CHAPTER',
                        trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onNextChapter();
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 300.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

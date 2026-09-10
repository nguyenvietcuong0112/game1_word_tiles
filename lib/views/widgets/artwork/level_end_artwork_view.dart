import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/chapter_model.dart';
import '../../../theme/app_theme.dart';
import 'particle_fireworks_overlay.dart';

/// LevelEndArtworkView displays the chapter's landscape puzzle artwork and
/// animates the chapter progress bar (IncrementLevelEndProgress) on level completion.
class LevelEndArtworkView extends StatefulWidget {
  final ChapterInfo chapterInfo;
  final ChapterTheme theme;
  final double cardWidth;
  final double cardHeight;

  const LevelEndArtworkView({
    super.key,
    required this.chapterInfo,
    required this.theme,
    this.cardWidth = 260,
    this.cardHeight = 160,
  });

  @override
  State<LevelEndArtworkView> createState() => _LevelEndArtworkViewState();
}

class _LevelEndArtworkViewState extends State<LevelEndArtworkView> with SingleTickerProviderStateMixin {
  late final AnimationController _progressAnimController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    final total = widget.chapterInfo.totalLevelsInChapter;
    final current = widget.chapterInfo.levelInChapter;
    final previousProg = ((current - 1) / total).clamp(0.0, 1.0);
    final targetProg = (current / total).clamp(0.0, 1.0);

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _progressAnimation = Tween<double>(
      begin: previousProg,
      end: targetProg,
    ).animate(CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.easeOutCubic,
    ));

    // Delay progress bar animation slightly for anticipation
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _progressAnimController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.chapterInfo;
    final total = info.totalLevelsInChapter;
    final current = info.levelInChapter;
    final isComplete = info.isChapterCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Framed 3D Landscape Artwork Card with Puzzle Grid Overlay
        Container(
          width: widget.cardWidth.w,
          height: widget.cardHeight.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isComplete ? const Color(0xFFFBBF24) : AppColors.borderSubtle,
              width: isComplete ? 3.0 : 2.0,
            ),
            boxShadow: [
              if (isComplete)
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.60),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              const BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 4.0),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer A: Full Landscape Painting
                CustomPaint(
                  painter: ChapterLandscapePainter(
                    theme: widget.theme,
                    progress: 1.0,
                  ),
                ),

                // Layer B: Puzzle Tile Grid Overlay (Hides locked pieces, reveals unlocked)
                if (!isComplete)
                  _buildPuzzleGrid(
                    totalPieces: total,
                    unlockedCount: current,
                  ),

                // Layer C: Chapter Badge Watermark at Top Left
                Positioned(
                  top: 8.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.theme.emoji, style: TextStyle(fontSize: 12.sp)),
                        SizedBox(width: 4.w),
                        Text(
                          widget.theme.title,
                          style: GoogleFonts.fredoka(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Layer D: Celebratory Fireworks Sparkles on Complete
                if (isComplete)
                  const Positioned.fill(
                    child: ParticleFireworksOverlay(isPlaying: true),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // 2. IncrementLevelEndProgress: Chapter Progress Bar
        IncrementLevelEndProgress(
          progressAnimation: _progressAnimation,
          current: current,
          total: total,
          chapterNumber: widget.chapterInfo.chapterNumber,
          width: widget.cardWidth,
        ),
      ],
    );
  }

  /// Builds the puzzle pieces overlay:
  /// For Chapter 1 (5 pieces): 1 row of 5 columns.
  /// For Chapter 2+ (10 pieces): 2 rows of 5 columns.
  Widget _buildPuzzleGrid({
    required int totalPieces,
    required int unlockedCount,
  }) {
    final int rows = totalPieces > 5 ? 2 : 1;
    final int cols = totalPieces > 5 ? 5 : 5;

    return Column(
      children: List.generate(rows, (r) {
        return Expanded(
          child: Row(
            children: List.generate(cols, (c) {
              final pieceIndex = r * cols + c;
              final isUnlocked = pieceIndex < unlockedCount;
              final isNewlyUnlocked = pieceIndex == (unlockedCount - 1);

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isNewlyUnlocked
                          ? const Color(0xFFFBBF24)
                          : Colors.black.withValues(alpha: 0.20),
                      width: isNewlyUnlocked ? 2.0 : 0.75,
                    ),
                    color: isUnlocked
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.65),
                  ),
                  child: isUnlocked
                      ? (isNewlyUnlocked
                          ? Center(
                              child: Container(
                                width: 24.r,
                                height: 24.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.85),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66FBBF24),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text('✨', style: TextStyle(fontSize: 13.sp)),
                                ),
                              )
                                  .animate()
                                  .scale(duration: 400.ms, curve: Curves.easeOutBack)
                                  .fadeOut(delay: 500.ms, duration: 300.ms),
                            )
                          : null)
                      : Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 14.r,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// IncrementLevelEndProgress displays and animates the chapter progress bar
/// when a level is completed.
class IncrementLevelEndProgress extends StatelessWidget {
  final Animation<double> progressAnimation;
  final int current;
  final int total;
  final int chapterNumber;
  final double width;

  const IncrementLevelEndProgress({
    super.key,
    required this.progressAnimation,
    required this.current,
    required this.total,
    required this.chapterNumber,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chapter $chapterNumber Progress',
                  style: GoogleFonts.fredoka(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerBrown,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$current / $total',
                style: GoogleFonts.fredoka(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, _) {
              return Container(
                height: 14.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9.r),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progressAnimation.value,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF34D399), // Emerald
                                Color(0xFF059669), // Jade
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Subtle diagonal gloss shimmer
                      FractionallySizedBox(
                        widthFactor: progressAnimation.value,
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/game_button.dart';

/// 3D Animated Hand Guide moving over the tiles inside the board with active trail & tile illumination
class TutorialHandGuide extends StatefulWidget {
  final List<Point<int>> path;
  final double tileSize;

  const TutorialHandGuide({
    super.key,
    required this.path,
    required this.tileSize,
  });

  @override
  State<TutorialHandGuide> createState() => _TutorialHandGuideState();
}

class _TutorialHandGuideState extends State<TutorialHandGuide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: max(1600, widget.path.length * 700)),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant TutorialHandGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _controller.duration = Duration(milliseconds: max(1600, widget.path.length * 700));
      _controller.reset();
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final segmentCount = widget.path.length - 1;
          Offset currentOffset;
          int activeIndex = 0;

          if (segmentCount <= 0) {
            final pt = widget.path[0];
            currentOffset = Offset(
              (pt.x + 0.5) * widget.tileSize,
              (pt.y + 0.5) * widget.tileSize,
            );
          } else {
            // 0.0 -> 0.85 (moving across path), 0.85 -> 1.0 (pause at end)
            final activeT = (t / 0.85).clamp(0.0, 1.0);
            final totalLength = segmentCount.toDouble();
            final currentProg = activeT * totalLength;
            final segIndex = currentProg.floor().clamp(0, segmentCount - 1);
            final segT = (currentProg - segIndex).clamp(0.0, 1.0);
            activeIndex = segIndex;

            final ptA = widget.path[segIndex];
            final ptB = widget.path[min(segIndex + 1, widget.path.length - 1)];

            final xA = (ptA.x + 0.5) * widget.tileSize;
            final yA = (ptA.y + 0.5) * widget.tileSize;
            final xB = (ptB.x + 0.5) * widget.tileSize;
            final yB = (ptB.y + 0.5) * widget.tileSize;

            currentOffset = Offset(
              xA + (xB - xA) * segT,
              yA + (yB - yA) * segT,
            );
          }

          final handOpacity = t > 0.88 ? (1.0 - ((t - 0.88) / 0.12)) : (t < 0.08 ? (t / 0.08) : 1.0);
          final visitedSubpath = widget.path.sublist(0, min(activeIndex + 1, widget.path.length));

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Highlight visited tiles with warm glowing face
              ...visitedSubpath.map((pt) {
                return Positioned(
                  left: pt.x * widget.tileSize + 3,
                  top: pt.y * widget.tileSize + 3,
                  width: widget.tileSize - 6,
                  height: widget.tileSize - 6,
                  child: Opacity(
                    opacity: handOpacity * 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.btnFaceBrown,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66BA805D),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // 2. Animated Swipe Trail line connecting visited points to current hand fingertip
              CustomPaint(
                painter: _TutorialTrailPainter(
                  path: widget.path,
                  visitedCount: activeIndex + 1,
                  currentTip: currentOffset,
                  tileSize: widget.tileSize,
                  opacity: handOpacity,
                ),
              ),

              // 3. Glowing Touch Point under fingertip
              Positioned(
                left: currentOffset.dx - 18.r,
                top: currentOffset.dy - 18.r,
                child: Opacity(
                  opacity: handOpacity * 0.85,
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: AppColors.btnFaceBrown.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66BA805D),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Hand Cursor Icon (👆)
              Positioned(
                left: currentOffset.dx - 12.r,
                top: currentOffset.dy - 6.r,
                child: Opacity(
                  opacity: handOpacity,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(2, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '👆',
                        style: TextStyle(fontSize: 42.sp),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TutorialTrailPainter extends CustomPainter {
  final List<Point<int>> path;
  final int visitedCount;
  final Offset currentTip;
  final double tileSize;
  final double opacity;

  _TutorialTrailPainter({
    required this.path,
    required this.visitedCount,
    required this.currentTip,
    required this.tileSize,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty || opacity <= 0) return;

    final paintGlow = Paint()
      ..color = const Color(0x88BA805D).withValues(alpha: 0.5 * opacity)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintCore = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * opacity)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trail = Path();
    final p0 = Offset((path[0].x + 0.5) * tileSize, (path[0].y + 0.5) * tileSize);
    trail.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < visitedCount && i < path.length; i++) {
      final pi = Offset((path[i].x + 0.5) * tileSize, (path[i].y + 0.5) * tileSize);
      trail.lineTo(pi.dx, pi.dy);
    }
    trail.lineTo(currentTip.dx, currentTip.dy);

    canvas.drawPath(trail, paintGlow);
    canvas.drawPath(trail, paintCore);
  }

  @override
  bool shouldRepaint(covariant _TutorialTrailPainter oldDelegate) => true;
}

/// Centered Floating Tooltip Card for Swipe Guidance (Level 1, Level 4, Fail-Safe)
class SwipeTutorialCard extends StatelessWidget {
  final List<InlineSpan> spans;

  const SwipeTutorialCard({
    super.key,
    required this.spans,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.05),
      child: IgnorePointer(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.borderSubtle, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 6.0),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Color(0xFFD4C2AE),
                offset: Offset(0, 3.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fredoka(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.35,
              ),
              children: spans,
            ),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
      ),
    );
  }
}

/// Modal Dialog explaining letter usage count with spotlight emphasis on the real board tile
class TileCountTutorialModal extends StatelessWidget {
  final String? sampleLetter;
  final int? count;
  final VoidCallback onDismiss;

  const TileCountTutorialModal({
    super.key,
    this.sampleLetter,
    this.count,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.05),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 32.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 22.h),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
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
            // Explanation Text with Highlighted "number"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.fredoka(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: 'This '),
                  TextSpan(
                    text: 'number',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(text: ' shows\neach letter\'s usage count.'),
                ],
              ),
            ),
            if (sampleLetter != null && count != null) ...[
              SizedBox(height: 14.h),
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD4C2AE),
                      offset: Offset(0, 3.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        sampleLetter!,
                        style: GoogleFonts.fredoka(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4.w,
                      bottom: 4.h,
                      child: Container(
                        width: 20.r,
                        height: 20.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: GoogleFonts.fredoka(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 18.h),

            // "Got it!" 3D Green CTA Button
            SizedBox(
              width: 140.w,
              child: GameButton.success(
                text: 'Got it!',
                size: GameButtonSize.medium,
                onTap: () async {
                  await GameStorage.setCountTutorialShown(true);
                  onDismiss();
                },
              ),
            ),
          ],
        ),
      )
          .animate()
          .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 350.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 250.ms),
    );
  }
}

/// 3D Animated White Arrow bouncing vertically
class TutorialArrowPointer extends StatefulWidget {
  final double size;
  const TutorialArrowPointer({super.key, this.size = 36});

  @override
  State<TutorialArrowPointer> createState() => _TutorialArrowPointerState();
}

class _TutorialArrowPointerState extends State<TutorialArrowPointer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size * 1.1),
        painter: _TutorialArrowCustomPainter(),
      ),
    );
  }
}

class _TutorialArrowCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.30, 0)
      ..lineTo(w * 0.70, 0)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.95, h * 0.52)
      ..lineTo(w * 0.50, h)
      ..lineTo(w * 0.05, h * 0.52)
      ..lineTo(w * 0.30, h * 0.52)
      ..close();

    // Soft drop shadow
    canvas.drawPath(
      path.shift(const Offset(0, 3.5)),
      Paint()
        ..color = const Color(0xFFC7B198)
        ..style = PaintingStyle.fill,
    );

    // White surface face
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFDF9)
        ..style = PaintingStyle.fill,
    );

    // Subtle edge border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE5D5C5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Unified In-Game Speech Bubble Card
class TutorialSpeechBubble extends StatelessWidget {
  final List<InlineSpan> spans;
  final Widget? actionButton;
  final double maxWidth;

  const TutorialSpeechBubble({
    super.key,
    required this.spans,
    this.actionButton,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth.w),
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(26.r),
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
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fredoka(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.4,
              ),
              children: spans,
            ),
          ),
          if (actionButton != null) ...[
            SizedBox(height: 14.h),
            actionButton!,
          ],
        ],
      ),
    )
        .animate()
        .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 350.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 250.ms);
  }
}

/// Level 5 Hint Booster Tutorial Overlay
class HintBoosterTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const HintBoosterTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorialSpeechBubble(
            spans: const [
              TextSpan(text: 'If you get stuck\ntry tapping '),
              TextSpan(
                text: '"Hint Button"',
                style: TextStyle(
                  color: Color(0xFFE11D48),
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(text: '.'),
            ],
            actionButton: SizedBox(
              width: 140.w,
              child: GameButton.success(
                text: 'Got it!',
                size: GameButtonSize.medium,
                onTap: () async {
                  await GameStorage.setHintTutorialShown(true);
                  onDismiss();
                },
              ),
            ),
          ),
          SizedBox(height: 20.h),
          const TutorialArrowPointer(size: 38),
        ],
      ),
    );
  }
}

/// Level 7 Extra Words Tutorial Overlay
class ExtraWordsTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const ExtraWordsTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorialSpeechBubble(
            spans: const [
              TextSpan(
                text: '"Extra Words"',
                style: TextStyle(
                  color: Color(0xFF9333EA),
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(text: ' found are\nlisted in this section.'),
            ],
            actionButton: SizedBox(
              width: 140.w,
              child: GameButton.success(
                text: 'Got it!',
                size: GameButtonSize.medium,
                onTap: () async {
                  await GameStorage.setExtraWordsTutorialShown(true);
                  onDismiss();
                },
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Transform.rotate(
            angle: 0.35,
            child: const TutorialArrowPointer(size: 38),
          ),
        ],
      ),
    );
  }
}

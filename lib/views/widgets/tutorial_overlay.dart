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

/// Modal Dialog explaining letter usage count with spotlight emphasis
/// Modal Dialog explaining letter usage count with spotlight emphasis on 1 single letter tile
class TileCountTutorialModal extends StatelessWidget {
  final String sampleLetter;
  final int count;
  final VoidCallback onDismiss;

  const TileCountTutorialModal({
    super.key,
    this.sampleLetter = 'A',
    this.count = 2,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.38),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 28.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
                // 3D Single Letter Tile Preview with Count Badge
                Container(
                  width: 72.r,
                  height: 72.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFE11D48), width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55E11D48),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Color(0xFFBE123C),
                        offset: Offset(0, 3.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          sampleLetter,
                          style: GoogleFonts.fredoka(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.headerBrown,
                            height: 1.0,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          width: 26.r,
                          height: 26.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFBE123C),
                                offset: Offset(0, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: GoogleFonts.fredoka(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Explanation Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.fredoka(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'This '),
                      const TextSpan(
                        text: 'number',
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' shows\neach letter\'s usage count.'),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),

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

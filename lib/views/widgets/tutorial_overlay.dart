import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/game_storage.dart';
import '../common/wood_widgets.dart';

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

class _TutorialHandGuideState extends State<TutorialHandGuide>
    with SingleTickerProviderStateMixin {
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
      _controller.duration = Duration(
        milliseconds: max(1600, widget.path.length * 700),
      );
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

          final handOpacity = t > 0.88
              ? (1.0 - ((t - 0.88) / 0.12))
              : (t < 0.08 ? (t / 0.08) : 1.0);
          final visitedSubpath = widget.path.sublist(
            0,
            min(activeIndex + 1, widget.path.length),
          );

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
                        color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99F58A07),
                            blurRadius: 10,
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
                      color: const Color(0xFFF58A07).withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xAAF58A07),
                          blurRadius: 12,
                          spreadRadius: 3,
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
                      child: Text('👆', style: TextStyle(fontSize: 42.sp)),
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
      ..color = const Color(0xFFF58A07).withValues(alpha: 0.65 * opacity)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintCore = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * opacity)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trail = Path();
    final p0 = Offset(
      (path[0].x + 0.5) * tileSize,
      (path[0].y + 0.5) * tileSize,
    );
    trail.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < visitedCount && i < path.length; i++) {
      final pi = Offset(
        (path[i].x + 0.5) * tileSize,
        (path[i].y + 0.5) * tileSize,
      );
      trail.lineTo(pi.dx, pi.dy);
    }
    trail.lineTo(currentTip.dx, currentTip.dy);

    canvas.drawPath(trail, paintGlow);
    canvas.drawPath(trail, paintCore);
  }

  @override
  bool shouldRepaint(covariant _TutorialTrailPainter oldDelegate) => true;
}

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
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0.0, -0.2), // Positioned at 2/5 of screen height, centered horizontally
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: GoldenWoodColors.woodBevel,
                width: 2.2, 
              ),
              boxShadow: const [
                BoxShadow(
                  color: GoldenWoodColors.woodExtrusion,
                  offset: Offset(0, 5.0),
                ),
                BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 10),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19.r),
              child: Stack(
                children: [
                  // Bright Golden Honey Wood Face Background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GoldenWoodColors.woodHighlight,
                            GoldenWoodColors.woodTop,
                            GoldenWoodColors.woodMid,
                            GoldenWoodColors.woodDark,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Wood Grain on Inset
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.38,
                      child: Image.asset(
                        'assets/images/golden_wood_texture.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Content Column 
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Title Badge (Carved dark wood badge on bright wood)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: GoldenWoodColors.woodExtrusion,
                            borderRadius: BorderRadius.circular(
                              12.r,
                            ),
                            border: Border.all(
                              color: GoldenWoodColors.woodHighlight,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                offset: Offset(0, 2.0),
                              ),
                            ],
                          ),
                          child: Text(
                            'HOW TO PLAY',
                            style: GoogleFonts.fredoka(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFE8CC),
                              letterSpacing: 1.5,
                              shadows: const [
                                Shadow(
                                  color: Color(0xFF1F0900),
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Authentic 3D Wooden Tile Preview with Count Badge
                        WoodenTile(
                          letter: sampleLetter,
                          count: count,
                          state: WoodenTileState.normal,
                          size: 68.r,
                        ),
                        SizedBox(height: 16.h),

                        // Explanation Text
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.fredoka(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.35,
                              shadows: const [
                                Shadow(
                                  color: Color(0xFF381401),
                                  offset: Offset(0, 1.5),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            children: [
                              const TextSpan(text: 'This '),
                              const TextSpan(
                                text: 'number',
                                style: TextStyle(
                                  color: Color(0xFFFFDF00),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(
                                text: ' shows how many times\nthis letter can be used!',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // "Got it!" Wooden Plank Action Button
                        WoodenButton(
                          text: 'GOT IT!',
                          variant: WoodenButtonVariant.action,
                          textColor: Colors.white,
                          width: 190.w,
                          height: 52.h,
                          fontSize: 20.sp,
                          onTap: () async {
                            await GameStorage.setCountTutorialShown(
                              true,
                            );
                            onDismiss();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().scale(
              duration: 250.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
            ),
          ),
        ),
      ),
    );
  }
}

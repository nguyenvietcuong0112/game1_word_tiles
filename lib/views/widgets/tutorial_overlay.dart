import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import 'bouncy_button.dart';

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
              // 1. Highlight visited tiles with lavender glowing face (matching screenshot 1)
              ...visitedSubpath.map((pt) {
                return Positioned(
                  left: pt.x * widget.tileSize + 3,
                  top: pt.y * widget.tileSize + 3,
                  width: widget.tileSize - 6,
                  height: widget.tileSize - 6,
                  child: Opacity(
                    opacity: handOpacity * 0.55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCA7CFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66CA7CFB),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // 2. Animated Lavender Swipe Trail line connecting visited points to hand tip
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
                      color: const Color(0xFFCA7CFB).withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66CA7CFB),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Stylized Cartoon Glove Hand Cursor
              Positioned(
                left: currentOffset.dx - 14.r,
                top: currentOffset.dy - 12.r,
                child: Opacity(
                  opacity: handOpacity,
                  child: CustomPaint(
                    size: Size(46.r, 46.r),
                    painter: const _CartoonGlovePainter(),
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

class _CartoonGlovePainter extends CustomPainter {
  const _CartoonGlovePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x44000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final cuffPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.68, h * 0.74),
        width: w * 0.40,
        height: h * 0.28,
      ));

    final glovePath = Path()
      ..moveTo(w * 0.16, h * 0.14) // Fingertip pointing up-left
      ..cubicTo(w * 0.10, h * 0.08, w * 0.24, h * 0.02, w * 0.32, h * 0.10)
      ..lineTo(w * 0.48, h * 0.30) // Index finger base
      ..cubicTo(w * 0.64, h * 0.24, w * 0.76, h * 0.34, w * 0.73, h * 0.46) // Middle
      ..cubicTo(w * 0.82, h * 0.48, w * 0.82, h * 0.62, w * 0.70, h * 0.70) // Ring & pinky
      ..lineTo(w * 0.58, h * 0.76) // Wrist outer
      ..lineTo(w * 0.42, h * 0.66) // Wrist inner
      ..cubicTo(w * 0.30, h * 0.60, w * 0.22, h * 0.48, w * 0.26, h * 0.38) // Thumb
      ..cubicTo(w * 0.28, h * 0.32, w * 0.38, h * 0.34, w * 0.38, h * 0.42)
      ..lineTo(w * 0.28, h * 0.26)
      ..close();

    canvas.drawPath(glovePath.shift(const Offset(2.0, 3.5)), shadowPaint);
    canvas.drawPath(cuffPath.shift(const Offset(2.0, 3.5)), shadowPaint);

    // 2. Glove white body
    final gloveFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(glovePath, gloveFill);

    // 3. Crisp outline
    final strokePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(glovePath, strokePaint);

    // 4. Finger creases
    final creasePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.48, h * 0.38), Offset(w * 0.60, h * 0.40), creasePaint);
    canvas.drawLine(Offset(w * 0.52, h * 0.50), Offset(w * 0.64, h * 0.52), creasePaint);

    // 5. Light cyan-blue 3D rolled cuff
    final cuffFill = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cuffPath, cuffFill);

    final cuffBorder = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(cuffPath, cuffBorder);

    final cuffInner = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.68, h * 0.74),
        width: w * 0.24,
        height: h * 0.16,
      ));
    canvas.drawPath(cuffInner, Paint()..color = const Color(0xFFBAE6FD));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      ..color = const Color(0xFFCA7CFB).withValues(alpha: 0.55 * opacity)
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

/// Unified In-Game Speech Bubble Card using btn_tutorial asset
class TutorialSpeechBubble extends StatelessWidget {
  final List<InlineSpan> spans;
  final Widget? actionButton;
  final double maxWidth;

  const TutorialSpeechBubble({
    super.key,
    required this.spans,
    this.actionButton,
    this.maxWidth = 310,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech Bubble Pill (using btn_tutorial.png)
        Container(
          constraints: BoxConstraints(
            minWidth: 260.w,
            maxWidth: maxWidth.w,
            minHeight: 68.h,
          ),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/btn_tutorial.png'),
              fit: BoxFit.fill,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 14.h),
          alignment: Alignment.center,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fredoka(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF342820),
                height: 1.35,
              ),
              children: spans,
            ),
          ),
        ),
        if (actionButton != null) ...[
          SizedBox(height: 10.h),
          actionButton!,
        ],
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 220.ms);
  }
}

/// "Got it!" 3D Green CTA Button using btn_green asset
class TutorialGotItButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const TutorialGotItButton({
    super.key,
    required this.onTap,
    this.text = 'Got it!',
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: 120.w,
        height: 44.h,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/btn_green.png'),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: Text(
            text,
            style: GoogleFonts.fredoka(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Color(0xFF136B10),
                  offset: Offset(0, 1.8),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      alignment: const Alignment(0, -0.22),
      child: IgnorePointer(
        child: TutorialSpeechBubble(spans: spans),
      ),
    );
  }
}

/// Modal Dialog explaining letter usage count with spotlight emphasis on the real board tile (Level 2)
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
      alignment: const Alignment(0, -0.22),
      child: TutorialSpeechBubble(
        spans: const [
          TextSpan(text: 'This '),
          TextSpan(
            text: 'number',
            style: TextStyle(
              color: Color(0xFFDD4C8E),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' shows\neach letter\'s usage count.'),
        ],
        actionButton: TutorialGotItButton(
          onTap: () async {
            await GameStorage.setCountTutorialShown(true);
            onDismiss();
          },
        ),
      ),
    );
  }
}

/// 3D Animated White/Cyan Arrow bouncing vertically (Level 5 & Level 7)
class TutorialArrowPointer extends StatefulWidget {
  final double size;
  final bool pointingUp;

  const TutorialArrowPointer({
    super.key,
    this.size = 38,
    this.pointingUp = false,
  });

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
          offset: Offset(0, widget.pointingUp ? -_animation.value : _animation.value),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size * 1.1),
        painter: _TutorialArrowCustomPainter(pointingUp: widget.pointingUp),
      ),
    );
  }
}

class _TutorialArrowCustomPainter extends CustomPainter {
  final bool pointingUp;

  const _TutorialArrowCustomPainter({this.pointingUp = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    if (pointingUp) {
      path
        ..moveTo(w * 0.30, h)
        ..lineTo(w * 0.70, h)
        ..lineTo(w * 0.70, h * 0.48)
        ..lineTo(w * 0.95, h * 0.48)
        ..lineTo(w * 0.50, 0)
        ..lineTo(w * 0.05, h * 0.48)
        ..lineTo(w * 0.30, h * 0.48)
        ..close();
    } else {
      path
        ..moveTo(w * 0.30, 0)
        ..lineTo(w * 0.70, 0)
        ..lineTo(w * 0.70, h * 0.52)
        ..lineTo(w * 0.95, h * 0.52)
        ..lineTo(w * 0.50, h)
        ..lineTo(w * 0.05, h * 0.52)
        ..lineTo(w * 0.30, h * 0.52)
        ..close();
    }

    // Soft drop shadow
    canvas.drawPath(
      path.shift(const Offset(0, 3.5)),
      Paint()
        ..color = const Color(0xFF8DBCC7)
        ..style = PaintingStyle.fill,
    );

    // Cyan-white surface face (matching reference design)
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1FCFE)
        ..style = PaintingStyle.fill,
    );

    // 3D edge border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFBBE5EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialArrowCustomPainter oldDelegate) =>
      oldDelegate.pointingUp != pointingUp;
}

/// Level 5 Hint Booster Tutorial Overlay (matching screenshot 2)
class HintBoosterTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const HintBoosterTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.18),
      child: TutorialSpeechBubble(
        spans: const [
          TextSpan(text: 'If you get stuck\ntry tapping '),
          TextSpan(
            text: '“Hint Button”',
            style: TextStyle(
              color: Color(0xFF8F34D0),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: '.'),
        ],
        actionButton: TutorialGotItButton(
          onTap: () async {
            await GameStorage.setHintTutorialShown(true);
            onDismiss();
          },
        ),
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
      alignment: const Alignment(0, -0.18),
      child: TutorialSpeechBubble(
        spans: const [
          TextSpan(
            text: '“Extra Words”',
            style: TextStyle(
              color: Color(0xFF8F34D0),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' found are\nlisted in this section.'),
        ],
        actionButton: TutorialGotItButton(
          onTap: () async {
            await GameStorage.setExtraWordsTutorialShown(true);
            onDismiss();
          },
        ),
      ),
    );
  }
}

/// Level 7 Rocket Booster Tutorial Overlay
class RocketBoosterTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const RocketBoosterTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.18),
      child: TutorialSpeechBubble(
        spans: const [
          TextSpan(text: 'Blast words away\nby tapping '),
          TextSpan(
            text: '“Rocket”',
            style: TextStyle(
              color: Color(0xFF8F34D0),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: '!'),
        ],
        actionButton: TutorialGotItButton(
          onTap: () async {
            await GameStorage.setRocketTutorialShown(true);
            onDismiss();
          },
        ),
      ),
    );
  }
}

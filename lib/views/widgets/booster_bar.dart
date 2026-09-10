import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import 'booster_unlock_dialog.dart';
import 'bouncy_button.dart';
import 'tutorial_overlay.dart';

class BoosterBar extends StatefulWidget {
  final GameController controller;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenExtraWords;
  final VoidCallback? onHintTap;
  final VoidCallback? onRocketTap;
  final bool isHintSpotlighted;
  final bool isRocketSpotlighted;
  final GlobalKey<ExtraWordsButtonState>? extraWordsBtnKey;

  const BoosterBar({
    super.key,
    required this.controller,
    this.onOpenShop,
    this.onOpenExtraWords,
    this.onHintTap,
    this.onRocketTap,
    this.isHintSpotlighted = false,
    this.isRocketSpotlighted = false,
    this.extraWordsBtnKey,
  });

  @override
  State<BoosterBar> createState() => _BoosterBarState();
}

class _BoosterBarState extends State<BoosterBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    GameStorage.hintCountNotifier.addListener(_rebuild);
    GameStorage.rocketCountNotifier.addListener(_rebuild);
    GameStorage.coinsNotifier.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant BoosterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    GameStorage.hintCountNotifier.removeListener(_rebuild);
    GameStorage.rocketCountNotifier.removeListener(_rebuild);
    GameStorage.coinsNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Dimensions matching mockup media_1789032593898.png:
    // Menu bar sits at bottom with height 54.h + bottomInset
    // Booster cards are 58.r tall. Exactly 50% (29.r) sits above menu_bar on the background,
    // and 50% (29.r) sits below the top edge of menu_bar.
    final cardHeight = 58.r;
    final halfOverlap = cardHeight / 2; // 29.r
    final menuBarHeight = 54.h + bottomInset;
    final totalHeight = halfOverlap + menuBarHeight;

    // Levels 1-4: No boosters unlocked yet. Do NOT show booster bar or menu_bar
    if (!controller.isBoosterBarVisible) {
      return const SizedBox.shrink();
    }

    final hintCount = GameStorage.getHintCount();
    final rocketCount = GameStorage.getRocketCount();

    // Levels 5 & 6: Only Hint is unlocked (Rocket unlocks at Level 7).
    // Display Hint button alone, centered at the bottom, without Rocket and without menu_bar.
    if (!controller.isRocketUnlocked) {
      return SizedBox(
        width: double.infinity,
        height: totalHeight,
        child: Align(
          alignment: Alignment.topCenter,
          child: _buildHintBooster(hintCount: hintCount),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Menu bar asset at the bottom (NO custom code/container color)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: menuBarHeight,
            child: Image.asset(
              'assets/images/menu_bar.png',
              width: double.infinity,
              height: menuBarHeight,
              fit: BoxFit.fill,
            ),
          ),

          // 2. Booster buttons row - aligned so cards are 50% on background, 50% on menu bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hint Booster 💡
                _buildHintBooster(hintCount: hintCount),
                SizedBox(width: 18.w),
                // 2. Rocket Booster 🚀
                _buildRocketBooster(rocketCount: rocketCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBooster({required int hintCount}) {
    final controller = widget.controller;
    final isSpotlighted = widget.isHintSpotlighted;

    return BouncyButton(
      onTap: () async {
        widget.onHintTap?.call();
        if (hintCount > 0) {
          controller.useHint();
        } else {
          await BoosterUnlockDialog.show(
            context,
            boosterType: BoosterType.hint,
            controller: controller,
          );
        }
      },
      child: SizedBox(
        width: 66.r,
        height: 70.r,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // White Rounded Square Card (58.r x 58.r)
            Container(
              width: 58.r,
              height: 58.r,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  if (isSpotlighted)
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.8),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  const BoxShadow(
                    color: Color(0xFFCBD5E1),
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/icon_hint.png',
                  width: 38.r,
                  height: 38.r,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Attached badge in bottom-right corner:
            Positioned(
              bottom: 2.h,
              right: 0,
              child: hintCount > 0
                  ? OrangeCountBadge(count: hintCount)
                  : GreenPillBadge.coinPrice(coins: 80),
            ),

            // Downward arrow pointer positioned directly above the Hint icon
            if (isSpotlighted)
              Positioned(
                top: -60.h,
                child: const IgnorePointer(
                  child: TutorialArrowPointer(size: 38),
                ),
              ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildRocketBooster({required int rocketCount}) {
    final controller = widget.controller;
    final isSpotlighted = widget.isRocketSpotlighted;

    return BouncyButton(
      onTap: () async {
        widget.onRocketTap?.call();
        if (rocketCount > 0) {
          controller.useRocket();
        } else {
          await BoosterUnlockDialog.show(
            context,
            boosterType: BoosterType.rocket,
            controller: controller,
          );
        }
      },
      child: SizedBox(
        width: 66.r,
        height: 70.r,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // White Rounded Square Card (58.r x 58.r)
            Container(
              width: 58.r,
              height: 58.r,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSpotlighted ? const Color(0xFFFFD700) : Colors.white,
                  width: isSpotlighted ? 2.5 : 1.5,
                ),
                boxShadow: [
                  if (isSpotlighted) ...[
                    BoxShadow(
                      color: const Color(0xFFFF9900).withValues(alpha: 0.9),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                  const BoxShadow(
                    color: Color(0xFFCBD5E1),
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/icon_rocket.png',
                  width: 38.r,
                  height: 38.r,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Attached badge in bottom-right corner:
            Positioned(
              bottom: 2.h,
              right: 0,
              child: rocketCount > 0
                  ? OrangeCountBadge(count: rocketCount)
                  : GreenPillBadge.coinPrice(coins: 240),
            ),

            // Downward arrow pointer positioned directly above the Rocket icon
            if (isSpotlighted)
              Positioned(
                top: -60.h,
                child: const IgnorePointer(
                  child: TutorialArrowPointer(size: 38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Star Progress / Extra Words circular button matching mockup exactly
class ExtraWordsButton extends StatefulWidget {
  final int extraCount;
  final VoidCallback? onTap;
  final bool isSpotlighted;

  const ExtraWordsButton({
    super.key,
    required this.extraCount,
    required this.onTap,
    this.isSpotlighted = false,
  });

  @override
  State<ExtraWordsButton> createState() => ExtraWordsButtonState();
}

class ExtraWordsButtonState extends State<ExtraWordsButton> with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.90).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void punchBounce() {
    _bounceController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((widget.extraCount % 10) / 10.0).clamp(0.0, 1.0);
    final displayValue = widget.extraCount;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: BouncyButton(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2A66),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSpotlighted ? const Color(0xFFFFD700) : Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  if (widget.isSpotlighted) ...[
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.95),
                      blurRadius: 22,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.85),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inside green progress arc hugging inner rim of white border
                  if (progress > 0)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(0.8),
                        child: CustomPaint(
                          painter: _StarProgressArcPainter(
                            progress: progress,
                            color: const Color(0xFF4ADE80),
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                    ),

                  // Centered Yellow Star
                  Image.asset(
                    'assets/icons/icon_star.png',
                    width: 28.r,
                    height: 28.r,
                    fit: BoxFit.contain,
                  ),

                  // Number with dark navy cartoon outline matching reference exactly
                  Text(
                    '$displayValue',
                    style: GoogleFonts.fredoka(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(offset: Offset(-1.2, -1.2), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(1.2, -1.2), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(-1.2, 1.2), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(1.2, 1.2), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(0, -1.5), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(0, 1.5), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(-1.5, 0), color: Color(0xFF0F2A66)),
                        Shadow(offset: Offset(1.5, 0), color: Color(0xFF0F2A66)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Upward arrow pointer positioned directly below the Extra Words star icon
            if (widget.isSpotlighted)
              Positioned(
                bottom: -52.h,
                child: const IgnorePointer(
                  child: TutorialArrowPointer(size: 38, pointingUp: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the green progress arc inside the star button rim
class _StarProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _StarProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Start at -pi / 2 (top / 12 o'clock), sweep clockwise
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StarProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 3D Vector-rendered Orange Circular Badge for remaining booster counts.
class OrangeCountBadge extends StatelessWidget {
  final int count;
  final double size;

  const OrangeCountBadge({
    super.key,
    required this.count,
    this.size = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCB63D), // top sunny amber
            Color(0xFFE58826), // bottom warm orange
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8B3612), // cartoon warm russet outline
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF9E4216), // 3D bottom bevel
            offset: Offset(0, 1.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 2.5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: GoogleFonts.fredoka(
            fontSize: (size * 0.54).sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            shadows: const [
              Shadow(offset: Offset(-0.8, -0.8), color: Color(0xFF1E3A6E)),
              Shadow(offset: Offset(0.8, -0.8), color: Color(0xFF1E3A6E)),
              Shadow(offset: Offset(-0.8, 0.8), color: Color(0xFF1E3A6E)),
              Shadow(offset: Offset(0.8, 0.8), color: Color(0xFF1E3A6E)),
              Shadow(offset: Offset(0, 1.2), color: Color(0xFF1E3A6E)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3D Vector-rendered Green Pill Badge for booster prices and action buttons.
class GreenPillBadge extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GreenPillBadge({
    super.key,
    required this.child,
    this.padding,
  });

  /// Factory constructor for displaying a coin price (e.g. [coin] 80 or [coin] 240)
  factory GreenPillBadge.coinPrice({
    Key? key,
    required int coins,
    double? coinSize,
    double? fontSize,
  }) {
    return GreenPillBadge(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/icon_coin.png',
            width: coinSize ?? 13.5.r,
            height: coinSize ?? 13.5.r,
          ),
          SizedBox(width: 2.5.w),
          Text(
            '$coins',
            style: GoogleFonts.fredoka(
              fontSize: fontSize ?? 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              shadows: const [
                Shadow(
                  color: Color(0xFF238E13),
                  offset: Offset(0, 1.0),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Factory constructor for displaying text (e.g. 'GIFT')
  factory GreenPillBadge.text({
    Key? key,
    required String text,
    double? fontSize,
    EdgeInsetsGeometry? padding,
  }) {
    return GreenPillBadge(
      key: key,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          fontSize: fontSize ?? 10.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
          height: 1.0,
          shadows: const [
            Shadow(
              color: Color(0xFF238E13),
              offset: Offset(0, 1.0),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  /// Factory constructor for displaying a count number (e.g. 1, 2, 3...)
  factory GreenPillBadge.count({
    Key? key,
    required int count,
    double? fontSize,
  }) {
    return GreenPillBadge(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      child: Text(
        '$count',
        style: GoogleFonts.fredoka(
          fontSize: fontSize ?? 12.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          shadows: const [
            Shadow(
              color: Color(0xFF238E13),
              offset: Offset(0, 1.0),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6DE853), // bright fresh lime-green
            Color(0xFF45D028), // warm vibrant grass-green
          ],
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF3AB81E), // natural soft green border, NOT dark forest green
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF238E13), // 3D bottom bevel
            offset: Offset(0, 1.6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x2A000000),
            offset: Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}


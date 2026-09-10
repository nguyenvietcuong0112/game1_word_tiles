import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/ads_manager.dart';
import '../../services/audio_manager.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/game_transitions.dart';
import '../../widgets/common/game_button.dart';
import '../../widgets/common/game_dialog.dart';

enum BoosterType {
  hint,
  rocket,
}

class BoosterUnlockDialog extends StatefulWidget {
  final BoosterType boosterType;
  final GameController? controller;
  final VoidCallback? onPurchased;

  const BoosterUnlockDialog({
    super.key,
    required this.boosterType,
    this.controller,
    this.onPurchased,
  });

  static Future<void> show(
    BuildContext context, {
    required BoosterType boosterType,
    GameController? controller,
    VoidCallback? onPurchased,
  }) {
    return showGameDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BoosterUnlockDialog(
        boosterType: boosterType,
        controller: controller,
        onPurchased: onPurchased,
      ),
    );
  }

  @override
  State<BoosterUnlockDialog> createState() => _BoosterUnlockDialogState();
}

class _BoosterUnlockDialogState extends State<BoosterUnlockDialog> {
  String get _boosterName =>
      widget.boosterType == BoosterType.hint ? 'Hint' : 'Rocket';

  String get _description => widget.boosterType == BoosterType.hint
      ? 'Reveals a letter to help you find words!'
      : 'Blasts and clears a hidden word instantly!';

  int get _coinsCost => widget.boosterType == BoosterType.hint ? 180 : 450;
  int get _bundleCount => 3;

  void _onBuyWithCoins() async {
    final playerCoins = GameStorage.getCoins();
    if (playerCoins < _coinsCost) {
      AudioManager.playInvalid();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins! Need $_coinsCost 🪙',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await GameStorage.spendCoins(_coinsCost);
    if (widget.boosterType == BoosterType.hint) {
      await GameStorage.addHintCount(_bundleCount);
    } else {
      await GameStorage.addRocketCount(_bundleCount);
    }

    AudioManager.playWordMatch();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onPurchased?.call();

    // If currently in an active game, execute 1 booster for instant satisfaction!
    if (widget.controller != null) {
      if (widget.boosterType == BoosterType.hint) {
        widget.controller!.useHint();
      } else {
        widget.controller!.useRocket();
      }
    }
  }

  bool _isLoadingAd = false;

  void _onClaimFreeAd() async {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    final boosterName = widget.boosterType == BoosterType.hint ? 'hint' : 'rocket';
    final currentLevel = widget.controller?.levelNumber ?? 1;

    AdsManager.showBoosterReward(
      boosterType: boosterName,
      levelNumber: currentLevel,
      onRewardResult: (success) async {
        if (!mounted) return;
        setState(() => _isLoadingAd = false);

        if (success) {
          if (widget.boosterType == BoosterType.hint) {
            await GameStorage.addHintCount(1);
          } else {
            await GameStorage.addRocketCount(1);
          }

          if (!mounted) return;
          AudioManager.playWordMatch();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          widget.onPurchased?.call();

          // If currently in an active game, execute 1 booster for instant satisfaction!
          if (widget.controller != null) {
            if (widget.boosterType == BoosterType.hint) {
              widget.controller!.useHint();
            } else {
              widget.controller!.useRocket();
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ad not completed. Could not claim free booster.',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildHeroArtwork() {
    return Container(
      width: 110.r,
      height: 110.r,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(110.r, 110.r),
        painter: widget.boosterType == BoosterType.hint
            ? _HintBulbPainter()
            : _RocketPainter(),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.05, 1.05),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildMiniBoosterIcon() {
    return SizedBox(
      width: 28.r,
      height: 28.r,
      child: CustomPaint(
        size: Size(28.r, 28.r),
        painter: widget.boosterType == BoosterType.hint
            ? _HintBulbPainter(isMini: true)
            : _RocketPainter(isMini: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = GameStorage.getCoins();
    final currentInventory = widget.boosterType == BoosterType.hint
        ? GameStorage.getHintCount()
        : GameStorage.getRocketCount();

    return GameDialog(
      showCloseButton: true,
      backgroundColor: AppColors.cardPeach,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Row: Emoji + Title (Left) & Coins Pill (Right)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.boosterType == BoosterType.hint ? '💡' : '🚀',
                      style: TextStyle(fontSize: 22.sp),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        '$_boosterName Booster',
                        style: GoogleFonts.fredoka(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.headerBrown,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                decoration: BoxDecoration(
                  color: AppColors.cardPeachLight,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4.w),
                    Text(
                      '$coins',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 2. Central Showcase Card (Pedestal for Hero Artwork & Description)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.borderSubtle, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFE8DAC8),
                  offset: Offset(0, 1.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeroArtwork(),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardPeachLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headerBrown,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'In Inventory: $currentInventory available',
                  style: GoogleFonts.fredoka(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 3. Option 1: Buy x3 with Coins (Standard 3D Success Green GameButton)
          GameButton.success(
            size: GameButtonSize.large,
            onTap: _onBuyWithCoins,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniBoosterIcon(),
                    SizedBox(width: 8.w),
                    CartoonText(
                      text: 'x$_bundleCount',
                      fontSize: 18.sp,
                      strokeWidth: 2.8,
                      outlineColor: const Color(0xFF14532D),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _GoldCoin3d(size: 24),
                    SizedBox(width: 6.w),
                    CartoonText(
                      text: '$_coinsCost',
                      fontSize: 19.sp,
                      strokeWidth: 2.8,
                      outlineColor: const Color(0xFF14532D),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // 4. Option 2: Watch Ad / Free x1 (Standard 3D Gold Amber GameButton)
          GameButton.gold(
            size: GameButtonSize.large,
            isLoading: _isLoadingAd,
            onTap: _isLoadingAd ? null : _onClaimFreeAd,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniBoosterIcon(),
                    SizedBox(width: 8.w),
                    CartoonText(
                      text: 'x1',
                      fontSize: 18.sp,
                      strokeWidth: 2.8,
                      outlineColor: const Color(0xFF78350F),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B3A1C),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                    ),
                    SizedBox(width: 6.w),
                    CartoonText(
                      text: 'FREE',
                      fontSize: 18.sp,
                      strokeWidth: 2.8,
                      outlineColor: const Color(0xFF78350F),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Gold Coin with metallic rim and center star
class _GoldCoin3d extends StatelessWidget {
  final double size;
  const _GoldCoin3d({this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFE65100)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container( 
          width: size * 0.74,
          height: size * 0.74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
            ),
            border: Border.all(color: const Color(0xFFFFF9C4), width: 1.0),
          ),
          child: Center(
            child: Icon(
              Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.95),
              size: size * 0.50,
            ),
          ),
        ),
      ),
    );
  }
}


/// Rich 3D Glowing Lightbulb Painter for Hint Booster
class _HintBulbPainter extends CustomPainter {
  final bool isMini;
  _HintBulbPainter({this.isMini = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * (isMini ? 0.46 : 0.43));

    // 1. Warm Golden Radial Aura
    if (!isMini) {
      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.60),
            const Color(0xFFFFA000).withValues(alpha: 0.20),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.48));
      canvas.drawCircle(center, w * 0.48, auraPaint);

      // Sunburst Rays
      final rayPaint = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.45)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4.0;
        final start = center + Offset(cos(angle) * 38, sin(angle) * 38);
        final end = center + Offset(cos(angle) * 46, sin(angle) * 46);
        canvas.drawLine(start, end, rayPaint);
      }
    }

    // 2. Drop Shadow of the bulb
    final r = isMini ? w * 0.32 : 26.0;
    final shadowPath = Path();
    shadowPath.addOval(Rect.fromCircle(center: center + Offset(0, isMini ? 1.5 : 4.0), radius: r));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMini ? 1.5 : 4.0),
    );

    // 3. Bulb Glass Body (Circle + Tapered Neck)
    final bulbPath = Path();
    bulbPath.addArc(
      Rect.fromCircle(center: center, radius: r),
      pi * 0.72,
      pi * 1.56,
    );
    final neckBottomY = h * (isMini ? 0.78 : 0.74);
    final neckWidth = isMini ? 7.0 : 13.0;
    bulbPath.lineTo(center.dx + neckWidth, neckBottomY);
    bulbPath.lineTo(center.dx - neckWidth, neckBottomY);
    bulbPath.close();

    // Glass Body Shader (Glossy Radial Glow)
    final bulbShader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 0.95,
      colors: const [
        Color(0xFFFFFDE7),
        Color(0xFFFFF176),
        Color(0xFFFFB300),
        Color(0xFFF57C00),
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: r * 1.3));

    canvas.drawPath(bulbPath, Paint()..shader = bulbShader);

    // Outer crisp white rim
    canvas.drawPath(
      bulbPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMini ? 1.2 : 2.2,
    );

    // 4. Curved Specular Gloss Highlight (Top-left glass reflection)
    final highlightPath = Path();
    highlightPath.addArc(
      Rect.fromCircle(center: center, radius: r - (isMini ? 2.0 : 4.0)),
      pi * 0.92,
      pi * 0.58,
    );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMini ? 2.0 : 3.8
        ..strokeCap = StrokeCap.round,
    );

    // 5. Glowing Tungsten Filament Loop
    if (!isMini) {
      final filamentPath = Path();
      filamentPath.moveTo(center.dx - 6, neckBottomY - 4);
      filamentPath.lineTo(center.dx - 5, center.dy + 3);
      filamentPath.cubicTo(
        center.dx - 9, center.dy - 12,
        center.dx + 9, center.dy - 12,
        center.dx + 5, center.dy + 3,
      );
      filamentPath.lineTo(center.dx + 6, neckBottomY - 4);

      canvas.drawPath(
        filamentPath,
        Paint()
          ..color = const Color(0xFFFF6F00).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        filamentPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }

    // 6. Metallic Brass Screw Base
    final baseY = neckBottomY;
    final numRings = isMini ? 2 : 3;
    for (int i = 0; i < numRings; i++) {
      final rw = (isMini ? 14.0 : 23.0) - i * (isMini ? 1.0 : 1.5);
      final rh = isMini ? 2.8 : 4.8;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, baseY + (isMini ? 2.0 : 4.0) + i * (isMini ? 3.2 : 5.8)),
          width: rw,
          height: rh,
        ),
        Radius.circular(isMini ? 1.0 : 2.0),
      );
      final baseShader = const LinearGradient(
        colors: [
          Color(0xFF8D6E63),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFF5D4037),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect.outerRect);
      canvas.drawRRect(rect, Paint()..shader = baseShader);
    }

    // 7. Sparkle Stars
    if (!isMini) {
      _drawSparkle(canvas, Offset(center.dx + 32, center.dy - 18), 5.5, Colors.white);
      _drawSparkle(canvas, Offset(center.dx - 30, center.dy + 12), 4.2, const Color(0xFFFFF9C4));
    }
  }

  void _drawSparkle(Canvas canvas, Offset pos, double size, Color color) {
    final p = Path();
    p.moveTo(pos.dx, pos.dy - size);
    p.lineTo(pos.dx + size * 0.25, pos.dy - size * 0.25);
    p.lineTo(pos.dx + size, pos.dy);
    p.lineTo(pos.dx + size * 0.25, pos.dy + size * 0.25);
    p.lineTo(pos.dx, pos.dy + size);
    p.lineTo(pos.dx - size * 0.25, pos.dy + size * 0.25);
    p.lineTo(pos.dx - size, pos.dy);
    p.lineTo(pos.dx - size * 0.25, pos.dy - size * 0.25);
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rich 3D Retro Rocket Painter for Rocket Booster
class _RocketPainter extends CustomPainter {
  final bool isMini;
  _RocketPainter({this.isMini = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 4.0); // Flying dynamically up-right!

    final scale = isMini ? 0.35 : 1.0;
    canvas.scale(scale, scale);

    // 1. Fiery Jet Exhaust Flame
    final flamePath = Path();
    flamePath.moveTo(-10, 24);
    flamePath.lineTo(0, 50); // Flame tip
    flamePath.lineTo(10, 24);
    flamePath.close();

    final flameShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF9C4),
        Color(0xFFFFB300),
        Color(0xFFFF3D00),
      ],
    ).createShader(const Rect.fromLTWH(-10, 24, 20, 26));
    canvas.drawPath(flamePath, Paint()..shader = flameShader);

    // Inner Core Flame
    final innerFlame = Path();
    innerFlame.moveTo(-4.5, 24);
    innerFlame.lineTo(0, 36);
    innerFlame.lineTo(4.5, 24);
    innerFlame.close();
    canvas.drawPath(innerFlame, Paint()..color = Colors.white.withValues(alpha: 0.92));

    // 2. Cobalt Blue Stabilizer Wings
    final leftFin = Path()
      ..moveTo(-13, 10)
      ..lineTo(-26, 25)
      ..lineTo(-13, 21)
      ..close();
    final rightFin = Path()
      ..moveTo(13, 10)
      ..lineTo(26, 25)
      ..lineTo(13, 21)
      ..close();

    final finShader = const LinearGradient(
      colors: [Color(0xFF38BDF8), Color(0xFF0288D1), Color(0xFF01579B)],
    ).createShader(const Rect.fromLTWH(-26, 10, 52, 15));
    canvas.drawPath(leftFin, Paint()..shader = finShader);
    canvas.drawPath(rightFin, Paint()..shader = finShader);

    // 3. Ruby Red Fuselage
    final bodyPath = Path();
    bodyPath.moveTo(0, -34); // Nose tip
    bodyPath.cubicTo(20, -18, 17, 12, 13, 25);
    bodyPath.lineTo(-13, 25);
    bodyPath.cubicTo(-17, 12, -20, -18, 0, -34);
    bodyPath.close();

    final bodyShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFFF8A80),
        Color(0xFFFF5252),
        Color(0xFFD32F2F),
        Color(0xFF991B1B),
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
    ).createShader(const Rect.fromLTWH(-20, -34, 40, 59));
    canvas.drawPath(bodyPath, Paint()..shader = bodyShader);

    // 4. White Center Nose Stripe
    final stripePath = Path();
    stripePath.moveTo(0, -34);
    stripePath.lineTo(4.5, -12);
    stripePath.lineTo(-4.5, -12);
    stripePath.close();
    canvas.drawPath(stripePath, Paint()..color = Colors.white.withValues(alpha: 0.95));

    // Specular Highlight Arc
    final shinePath = Path();
    shinePath.moveTo(-6, -26);
    shinePath.cubicTo(-13, -12, -11, 10, -9, 19);
    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // 5. Circular Chrome Porthole Window
    // Chrome Ring
    canvas.drawCircle(
      const Offset(0, 0),
      9.5,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFECEFF1), Color(0xFF90A4AE), Color(0xFFCFD8DC)],
        ).createShader(const Rect.fromLTWH(-9.5, -9.5, 19, 19)),
    );
    // Glass
    canvas.drawCircle(
      const Offset(0, 0),
      7.0,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
        ).createShader(const Rect.fromLTWH(-7, -7, 14, 14)),
    );
    // Glint
    canvas.drawCircle(
      const Offset(-2.4, -2.4),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';

/// A single particle shard: either a glossy gem/ceramic fragment or a juicy candy pop bead.
class TileShard {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double vRot;
  final double size;
  final double aspectRatio;
  final Color faceColor;
  final bool isBubble;
  final List<Offset> normalizedVertices;
  double life;
  final double maxLife;

  TileShard({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
    required this.size,
    required this.aspectRatio,
    required this.faceColor,
    required this.isBubble,
    required this.normalizedVertices,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    // Apply gravity & air drag
    vy += 920.0 * dt;
    x += vx * dt;
    y += vy * dt;
    rotation += vRot * dt;

    vx *= 0.982;

    return true;
  }
}

/// Expanding glowing energy ring at the burst origin.
class ShatterShockwave {
  final double x;
  final double y;
  final double maxRadius;
  final Color color;
  double life;
  final double maxLife;

  ShatterShockwave({
    required this.x,
    required this.y,
    required this.maxRadius,
    required this.color,
    this.maxLife = 0.28,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    return life > 0;
  }
}

/// 4-pointed golden sparkle star glint.
class Sparkle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double vRot;
  final double size;
  final Color color;
  double life;
  final double maxLife;

  Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
    required this.size,
    required this.color,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    x += vx * dt;
    y += vy * dt;
    vy -= 40.0 * dt; // Upward drift
    vx *= 0.96;
    rotation += vRot * dt;

    return true;
  }
}

class TileShatterController extends ChangeNotifier {
  final List<TileShard> shards = [];
  final List<ShatterShockwave> shockwaves = [];
  final List<Sparkle> sparkles = [];
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();

  void init(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  void shatterTile({
    required Offset center,
    required double tileSize,
    TileColorTheme? theme,
  }) {
    // 1. Expanding Golden Energy Shockwave (Amber Gold)
    shockwaves.add(
      ShatterShockwave(
        x: center.dx,
        y: center.dy,
        maxRadius: tileSize * 0.85,
        color: const Color(0xFFE5A638), // Warm Amber Honey Gold (AppColors.honeyGold)
        maxLife: 0.26,
      ),
    );

    // 2. Button-Brown Cocoa & Caramel Palette (Dominant 75%+)
    // Directly matching the rich 3D brown buttons (Play, Header, Boosters)
    final List<Color> buttonBrownPalette = [
      AppColors.btnFaceBrown, // 0xFFA66640 - Rich Roasted Cocoa Button Face
      const Color(0xFFCA9370), // Warm Caramel Highlight (Play button gradient top)
      AppColors.terracottaLight, // 0xFFBD7C54 - Caramel Terra
      AppColors.btnBorderBrown, // 0xFF8F522C - Roasted Cocoa
      const Color(0xFF9E5C35), // Warm Roasted Chestnut
      const Color(0xFFB57048), // Amber Cocoa
      AppColors.btnShadowBrown, // 0xFF7B411D - Deep Chocolate Brown
    ];

    // Warm Gold & Cream Accents (25%) for high-contrast popping glints
    final List<Color> accentPalette = [
      const Color(0xFFF59E0B), // Warm Amber Gold
      AppColors.honeyGold, // 0xFFE5A638 - Honey Gold
      const Color(0xFFFFF7ED), // Warm Ivory Sheen
      AppColors.butterCream, // 0xFFFEF3C7 - Butter Cream
    ];

    // 3. Spawn 18 to 22 Casual Particles (Brown Dominant: 75% button brown, 25% amber/cream)
    final numParticles = 18 + _random.nextInt(5);
    for (int i = 0; i < numParticles; i++) {
      final offsetX = (_random.nextDouble() - 0.5) * (tileSize * 0.75);
      final offsetY = (_random.nextDouble() - 0.5) * (tileSize * 0.75);

      final angle = _random.nextDouble() * 2 * pi;
      final speed = 130.0 + _random.nextDouble() * 230.0;
      final vx = cos(angle) * speed;
      final vy = -150.0 - _random.nextDouble() * 240.0 + sin(angle) * (speed * 0.35);

      final isBubble = i % 3 == 0; // 1/3 are round juicy glossy beads
      final double size;
      if (isBubble) {
        size = tileSize * (0.10 + _random.nextDouble() * 0.08);
      } else if (i < 8) {
        size = tileSize * (0.18 + _random.nextDouble() * 0.07);
      } else {
        size = tileSize * (0.11 + _random.nextDouble() * 0.06);
      }

      final maxLife = 0.50 + _random.nextDouble() * 0.30;
      // Dominant 75% button brown, 25% warm gold & cream accent
      final Color color = (_random.nextDouble() < 0.75)
          ? buttonBrownPalette[_random.nextInt(buttonBrownPalette.length)]
          : accentPalette[_random.nextInt(accentPalette.length)];

      shards.add(
        TileShard(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: vx,
          vy: vy,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 12.0,
          size: size,
          aspectRatio: isBubble ? 1.0 : (0.75 + _random.nextDouble() * 0.50),
          faceColor: color,
          isBubble: isBubble,
          normalizedVertices: isBubble ? const [] : _generatePolygonVertices(),
          maxLife: maxLife,
        ),
      );
    }

    // 4. Spawn 6 to 9 Golden Star Glints & Diamond Sparkles
    final numSparkles = 6 + _random.nextInt(4);
    for (int i = 0; i < numSparkles; i++) {
      final offsetX = (_random.nextDouble() - 0.5) * tileSize;
      final offsetY = (_random.nextDouble() - 0.5) * tileSize;
      final speed = 45.0 + _random.nextDouble() * 100.0;
      final angle = _random.nextDouble() * 2 * pi;

      sparkles.add(
        Sparkle(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 65.0,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 8.0,
          size: 5.0 + _random.nextDouble() * 6.0,
          color: i % 2 == 0 ? const Color(0xFFFFD166) : const Color(0xFFFFFFFF),
          maxLife: 0.45 + _random.nextDouble() * 0.30,
        ),
      );
    }

    if (_ticker != null && !_ticker!.isActive) {
      _lastElapsed = Duration.zero;
      _ticker!.start();
    }
    notifyListeners();
  }

  List<Offset> _generatePolygonVertices() {
    const numPoints = 4;
    final List<Offset> pts = [];
    for (int i = 0; i < numPoints; i++) {
      final baseAngle = (i * 2 * pi / numPoints);
      final angle = baseAngle + (_random.nextDouble() - 0.5) * 0.6;
      final r = 0.65 + _random.nextDouble() * 0.35;
      pts.add(Offset(cos(angle) * r, sin(angle) * r));
    }
    return pts;
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    final clampedDt = dt.clamp(0.0, 0.05);

    shards.removeWhere((shard) => !shard.update(clampedDt));
    shockwaves.removeWhere((sw) => !sw.update(clampedDt));
    sparkles.removeWhere((sparkle) => !sparkle.update(clampedDt));

    if (shards.isEmpty && shockwaves.isEmpty && sparkles.isEmpty) {
      _ticker?.stop();
      _lastElapsed = Duration.zero;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

class TileShatterPainter extends CustomPainter {
  final List<TileShard> shards;
  final List<ShatterShockwave> shockwaves;
  final List<Sparkle> sparkles;

  TileShatterPainter({
    required this.shards,
    required this.shockwaves,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shards.isEmpty && shockwaves.isEmpty && sparkles.isEmpty) return;

    // 1. Draw Expanding Shockwave Burst Rings
    for (final sw in shockwaves) {
      final t = (1.0 - (sw.life / sw.maxLife)).clamp(0.0, 1.0);
      final currentRadius = sw.maxRadius * Curves.easeOutCubic.transform(t);
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      // Expanding golden ring
      final ringPaint = Paint()
        ..color = sw.color.withValues(alpha: opacity * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - t) * 3.5 + 0.5;
      canvas.drawCircle(Offset(sw.x, sw.y), currentRadius, ringPaint);

      // Warm radial center flash
      final flashPaint = Paint()
        ..color = sw.color.withValues(alpha: opacity * 0.20)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sw.x, sw.y), currentRadius * 0.60, flashPaint);
    }

    // 2. Draw Shards & Pop Beads
    for (final shard in shards) {
      final progress = shard.life / shard.maxLife; // 1.0 -> 0.0
      // Stay fully solid for the first 65% of flight, then smoothly fade
      final opacity = (progress / 0.35).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(shard.x, shard.y);
      canvas.rotate(shard.rotation);

      if (shard.isBubble) {
        // --- Juicy Round Candy Pop Bubble ---
        final r = shard.size * 0.5;

        // Soft drop shadow
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: opacity * 0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(0, 1.8), r, shadowPaint);

        // Main Bubble Face
        final bubblePaint = Paint()
          ..color = shard.faceColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, r, bubblePaint);

        // Specular Gloss Highlight Dot
        final glossPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.90)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(-r * 0.32, -r * 0.32), r * 0.30, glossPaint);

        // Crisp White Rim
        final rimPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset.zero, r, rimPaint);
      } else {
        // --- Glossy Gem / Ceramic Fragment ---
        canvas.scale(shard.size * shard.aspectRatio, shard.size);

        final path = Path();
        if (shard.normalizedVertices.isNotEmpty) {
          path.moveTo(shard.normalizedVertices[0].dx, shard.normalizedVertices[0].dy);
          for (int i = 1; i < shard.normalizedVertices.length; i++) {
            path.lineTo(shard.normalizedVertices[i].dx, shard.normalizedVertices[i].dy);
          }
          path.close();
        }

        // Soft clean drop shadow (NO dirty brown bevel!)
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: opacity * 0.16)
          ..style = PaintingStyle.fill;
        canvas.save();
        canvas.translate(0, 0.18);
        canvas.drawPath(path, shadowPaint);
        canvas.restore();

        // Main Gem Face
        final facePaint = Paint()
          ..color = shard.faceColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, facePaint);

        // Specular Gloss Highlight along top
        if (shard.normalizedVertices.length >= 2) {
          final highlightPath = Path()
            ..moveTo(shard.normalizedVertices[0].dx, shard.normalizedVertices[0].dy)
            ..lineTo(shard.normalizedVertices[1].dx, shard.normalizedVertices[1].dy);
          final highlightPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.90)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.18
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(highlightPath, highlightPaint);
        }

        // Crisp White Crystal Edge Rim (Clean, bright, non-woody)
        final rimPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.10
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, rimPaint);
      }

      canvas.restore();
    }

    // 3. Draw 4-Pointed Star Sparkles with Glowing Core
    for (final sparkle in sparkles) {
      final progress = sparkle.life / sparkle.maxLife;
      final opacity = (sin(progress * pi)).clamp(0.0, 1.0);
      final currentSize = sparkle.size * (0.6 + 0.4 * progress);

      canvas.save();
      canvas.translate(sparkle.x, sparkle.y);
      canvas.rotate(sparkle.rotation);

      // 4-pointed Star Sparkle Path
      final starPath = Path();
      final r = currentSize;
      final innerR = currentSize * 0.28;

      for (int i = 0; i < 4; i++) {
        final outerAngle = i * pi / 2;
        final innerAngle = outerAngle + pi / 4;

        if (i == 0) {
          starPath.moveTo(cos(outerAngle) * r, sin(outerAngle) * r);
        } else {
          starPath.lineTo(cos(outerAngle) * r, sin(outerAngle) * r);
        }
        starPath.lineTo(cos(innerAngle) * innerR, sin(innerAngle) * innerR);
      }
      starPath.close();

      // Outer glow aura
      final glowPaint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset.zero, currentSize * 0.85, glowPaint);

      // Star body
      final starPaint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(starPath, starPaint);

      // Diamond core highlight
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, currentSize * 0.22, corePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TileShatterPainter oldDelegate) => true;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';

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
  final Color bevelColor;
  final List<Offset> normalizedVertices;
  double life; // 1.0 -> 0.0
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
    required this.bevelColor,
    required this.normalizedVertices,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    // Apply gravity
    vy += 950.0 * dt;
    x += vx * dt;
    y += vy * dt;
    rotation += vRot * dt;

    // Air drag
    vx *= 0.985;

    return true;
  }
}

class Sparkle {
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final Color color;
  double life;
  final double maxLife;

  Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    x += vx * dt;
    y += vy * dt;
    vy -= 40.0 * dt; // Slight upward buoyancy
    vx *= 0.96;

    return true;
  }
}

class TileShatterController extends ChangeNotifier {
  final List<TileShard> shards = [];
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
    required TileColorTheme theme,
  }) {
    // 1. Spawn 14 to 18 3D Shards
    final numShards = 14 + _random.nextInt(5);
    for (int i = 0; i < numShards; i++) {
      // Offset from tile center inside [-tileSize/2, tileSize/2]
      final offsetX = (_random.nextDouble() - 0.5) * (tileSize * 0.75);
      final offsetY = (_random.nextDouble() - 0.5) * (tileSize * 0.75);

      // Initial burst velocity in radial outward direction + strong upward lift
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120.0 + _random.nextDouble() * 220.0;
      final vx = cos(angle) * speed;
      final vy = -180.0 - _random.nextDouble() * 240.0 + sin(angle) * (speed * 0.4);

      // Random polygon vertices for irregular shards
      final vertices = _generatePolygonVertices();
      final size = (tileSize * 0.14) + _random.nextDouble() * (tileSize * 0.18);
      final maxLife = 0.55 + _random.nextDouble() * 0.35;

      shards.add(
        TileShard(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: vx,
          vy: vy,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 12.0,
          size: size,
          aspectRatio: 0.7 + _random.nextDouble() * 0.6,
          faceColor: theme.face,
          bevelColor: theme.bevel,
          normalizedVertices: vertices,
          maxLife: maxLife,
        ),
      );
    }

    // 2. Spawn 5 to 7 Glow Sparkles
    final numSparkles = 5 + _random.nextInt(3);
    for (int i = 0; i < numSparkles; i++) {
      final offsetX = (_random.nextDouble() - 0.5) * tileSize;
      final offsetY = (_random.nextDouble() - 0.5) * tileSize;
      final speed = 40.0 + _random.nextDouble() * 90.0;
      final angle = _random.nextDouble() * 2 * pi;

      sparkles.add(
        Sparkle(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 60.0,
          size: 4.0 + _random.nextDouble() * 6.0,
          color: i % 2 == 0 ? const Color(0xFFFEF08A) : const Color(0xFFFFFFFF),
          maxLife: 0.45 + _random.nextDouble() * 0.35,
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
      final r = 0.6 + _random.nextDouble() * 0.4;
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

    // Clamp dt to avoid huge jumps
    final clampedDt = dt.clamp(0.0, 0.05);

    shards.removeWhere((shard) => !shard.update(clampedDt));
    sparkles.removeWhere((sparkle) => !sparkle.update(clampedDt));

    if (shards.isEmpty && sparkles.isEmpty) {
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
  final List<Sparkle> sparkles;

  TileShatterPainter({
    required this.shards,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shards.isEmpty && sparkles.isEmpty) return;

    // 1. Draw 3D Shards
    for (final shard in shards) {
      final progress = shard.life / shard.maxLife; // 1.0 -> 0.0
      final opacity = (progress * 1.5).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(shard.x, shard.y);
      canvas.rotate(shard.rotation);
      canvas.scale(shard.size * shard.aspectRatio, shard.size);

      // Create polygon path
      final path = Path();
      if (shard.normalizedVertices.isNotEmpty) {
        path.moveTo(shard.normalizedVertices[0].dx, shard.normalizedVertices[0].dy);
        for (int i = 1; i < shard.normalizedVertices.length; i++) {
          path.lineTo(shard.normalizedVertices[i].dx, shard.normalizedVertices[i].dy);
        }
        path.close();
      }

      // Draw 3D Bevel/Shadow underneath each shard
      final shadowPaint = Paint()
        ..color = shard.bevelColor.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, 0.28);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      // Draw Shard Face
      final facePaint = Paint()
        ..color = shard.faceColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, facePaint);

      // Draw subtle highlight rim
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12;
      canvas.drawPath(path, strokePaint);

      canvas.restore();
    }

    // 2. Draw Sparkles
    for (final sparkle in sparkles) {
      final progress = sparkle.life / sparkle.maxLife;
      final opacity = (sin(progress * pi)).clamp(0.0, 1.0);
      final currentSize = sparkle.size * (0.6 + 0.4 * progress);

      canvas.save();
      canvas.translate(sparkle.x, sparkle.y);

      // 4-pointed Star Sparkle
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

      // Outer glow
      final glowPaint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset.zero, currentSize * 0.8, glowPaint);

      // Star shape
      final starPaint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(starPath, starPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TileShatterPainter oldDelegate) => true;
}

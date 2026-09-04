import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';

enum ShardKind { block, splinter, chip }

class TileShard {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double vRot;
  final double size;
  final double aspectRatio;
  final ShardKind kind;
  final List<Offset> normalizedVertices;
  final double grainAngle;
  final List<double> grainOffsets;
  final Color woodLight;
  final Color woodMid;
  final Color woodDark;
  final Color woodBevel;
  final Color grainColor;
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
    required this.kind,
    required this.normalizedVertices,
    required this.grainAngle,
    required this.grainOffsets,
    required this.woodLight,
    required this.woodMid,
    required this.woodDark,
    required this.woodBevel,
    required this.grainColor,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    // Gravity & Air Resistance
    vy += (kind == ShardKind.splinter ? 1050.0 : 920.0) * dt;
    x += vx * dt;
    y += vy * dt;
    rotation += vRot * dt;

    vx *= 0.982;
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
  final bool isDustFleck;
  double life;
  final double maxLife;

  Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.isDustFleck = false,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    x += vx * dt;
    y += vy * dt;
    if (isDustFleck) {
      vy += 220.0 * dt; // Fluttering wood dust falls gently
      vx *= 0.94;
    } else {
      vy -= 40.0 * dt; // Upward spark buoyancy
      vx *= 0.96;
    }

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
    // Master Warm Honey Wood Palette for realistic wood splinters
    const Color defaultWoodLight = Color(0xFFFFC966); // Golden Amber Top Highlight
    const Color defaultWoodMid = Color(0xFFE0821E);   // Honey Oak Midtone
    const Color defaultWoodDark = Color(0xFFA04E0C);  // Deep Wood Grain Core
    const Color defaultWoodBevel = Color(0xFF4E1B00); // 3D Carved Bottom Bevel
    const Color defaultGrain = Color(0xFF6B2B04);     // Dark Wood Fiber Streak

    // 1. Spawn 16 to 22 Realistic Wood Shards (Blocks + Splinters + Chips)
    final numShards = 16 + _random.nextInt(7);
    for (int i = 0; i < numShards; i++) {
      final offsetX = (_random.nextDouble() - 0.5) * (tileSize * 0.80);
      final offsetY = (_random.nextDouble() - 0.5) * (tileSize * 0.80);

      // Radial blast direction with upward pop
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 110.0 + _random.nextDouble() * 240.0;
      final vx = cos(angle) * speed;
      final vy = -190.0 - _random.nextDouble() * 260.0 + sin(angle) * (speed * 0.45);

      final ShardKind kind;
      final double aspectRatio;
      final double size;
      final List<Offset> vertices;

      if (i % 3 == 0) {
        // Wood Splinter (Long thin sharp wood sliver)
        kind = ShardKind.splinter;
        aspectRatio = 2.2 + _random.nextDouble() * 1.5;
        size = (tileSize * 0.12) + _random.nextDouble() * (tileSize * 0.14);
        vertices = _generateSplinterVertices();
      } else if (i % 3 == 1) {
        // Chunky Wood Block (Polygonal chunk)
        kind = ShardKind.block;
        aspectRatio = 0.8 + _random.nextDouble() * 0.5;
        size = (tileSize * 0.15) + _random.nextDouble() * (tileSize * 0.16);
        vertices = _generatePolygonVertices(numPoints: 4 + _random.nextInt(2));
      } else {
        // Small Wood Chip / Flake
        kind = ShardKind.chip;
        aspectRatio = 0.9 + _random.nextDouble() * 0.4;
        size = (tileSize * 0.08) + _random.nextDouble() * (tileSize * 0.09);
        vertices = _generatePolygonVertices(numPoints: 3);
      }

      // Generate realistic longitudinal wood grain offsets
      final grainOffsets = [
        -0.45 + _random.nextDouble() * 0.25,
        -0.05 + _random.nextDouble() * 0.20,
        0.30 + _random.nextDouble() * 0.25,
      ];

      final maxLife = 0.58 + _random.nextDouble() * 0.38;

      shards.add(
        TileShard(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: vx,
          vy: vy,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 14.0,
          size: size,
          aspectRatio: aspectRatio,
          kind: kind,
          normalizedVertices: vertices,
          grainAngle: (_random.nextDouble() - 0.5) * 0.4, // Fiber runs along length
          grainOffsets: grainOffsets,
          woodLight: defaultWoodLight,
          woodMid: defaultWoodMid,
          woodDark: defaultWoodDark,
          woodBevel: defaultWoodBevel,
          grainColor: defaultGrain,
          maxLife: maxLife,
        ),
      );
    }

    // 2. Spawn 6 to 10 Golden Sawdust Flecks & Amber Glow Sparks
    final numSparkles = 7 + _random.nextInt(4);
    for (int i = 0; i < numSparkles; i++) {
      final offsetX = (_random.nextDouble() - 0.5) * tileSize;
      final offsetY = (_random.nextDouble() - 0.5) * tileSize;
      final speed = 35.0 + _random.nextDouble() * 110.0;
      final angle = _random.nextDouble() * 2 * pi;
      final isDust = i % 2 == 0;

      sparkles.add(
        Sparkle(
          x: center.dx + offsetX,
          y: center.dy + offsetY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - (isDust ? 30.0 : 80.0),
          size: isDust ? (3.0 + _random.nextDouble() * 4.0) : (4.5 + _random.nextDouble() * 5.5),
          color: isDust
              ? const Color(0xFFFFD479) // Warm golden sawdust
              : (i % 4 == 0 ? const Color(0xFFFFFFFF) : const Color(0xFFFFAE19)), // Amber sparkle
          isDustFleck: isDust,
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

  List<Offset> _generateSplinterVertices() {
    // Sharp tapered wood splinter diamond/needle shape
    final pts = <Offset>[
      const Offset(0.0, -0.9),  // Sharp top point
      Offset(0.28 + _random.nextDouble() * 0.15, -0.2), // Right side barb
      Offset(0.22 + _random.nextDouble() * 0.12, 0.4),
      const Offset(0.0, 0.9),   // Sharp bottom point
      Offset(-0.25 - _random.nextDouble() * 0.12, 0.3),
      Offset(-0.28 - _random.nextDouble() * 0.15, -0.2),
    ];
    return pts;
  }

  List<Offset> _generatePolygonVertices({int numPoints = 4}) {
    final List<Offset> pts = [];
    for (int i = 0; i < numPoints; i++) {
      final baseAngle = (i * 2 * pi / numPoints);
      final angle = baseAngle + (_random.nextDouble() - 0.5) * 0.55;
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

    // 1. Draw 3D Textured Wood Shards
    for (final shard in shards) {
      final progress = shard.life / shard.maxLife; // 1.0 -> 0.0
      final opacity = (progress * 1.6).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(shard.x, shard.y);
      canvas.rotate(shard.rotation);
      canvas.scale(
        shard.size * (shard.kind == ShardKind.splinter ? 0.65 : shard.aspectRatio),
        shard.size * (shard.kind == ShardKind.splinter ? shard.aspectRatio : 1.0),
      );

      // Build polygon path
      final path = Path();
      if (shard.normalizedVertices.isNotEmpty) {
        path.moveTo(shard.normalizedVertices[0].dx, shard.normalizedVertices[0].dy);
        for (int i = 1; i < shard.normalizedVertices.length; i++) {
          path.lineTo(shard.normalizedVertices[i].dx, shard.normalizedVertices[i].dy);
        }
        path.close();
      }

      // 1.1 Draw 3D Bottom Wood Extrusion / Bevel
      final shadowPaint = Paint()
        ..color = shard.woodBevel.withValues(alpha: opacity * 0.95)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, 0.32);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      // 1.2 Draw Wood Face with Natural Golden Wood Gradient
      final rect = path.getBounds();
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            shard.woodLight.withValues(alpha: opacity),
            shard.woodMid.withValues(alpha: opacity),
            shard.woodDark.withValues(alpha: opacity),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, gradientPaint);

      // 1.3 Draw Authentic Wood Grain Fibers (clipped within the shard)
      canvas.save();
      canvas.clipPath(path);

      final grainDarkPaint = Paint()
        ..color = shard.grainColor.withValues(alpha: opacity * 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12;

      final grainLightPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.08;

      for (final offsetRatio in shard.grainOffsets) {
        final xPos = offsetRatio * (rect.width > 0 ? rect.width : 1.0);
        // Wood grain fiber lines running through the wood slice
        canvas.drawLine(
          Offset(xPos - 0.1, -1.2),
          Offset(xPos + 0.1, 1.2),
          grainDarkPaint,
        );
        // Subtle highlight fiber next to dark grain
        canvas.drawLine(
          Offset(xPos - 0.04, -1.2),
          Offset(xPos + 0.16, 1.2),
          grainLightPaint,
        );
      }
      canvas.restore();

      // 1.4 Crisp Wood Edge Bevel Highlight
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.10;
      canvas.drawPath(path, strokePaint);

      canvas.restore();
    }

    // 2. Draw Sawdust Flecks & Amber Star Sparks
    for (final sparkle in sparkles) {
      final progress = sparkle.life / sparkle.maxLife;
      final opacity = (sin(progress * pi)).clamp(0.0, 1.0);
      final currentSize = sparkle.size * (0.5 + 0.5 * progress);

      canvas.save();
      canvas.translate(sparkle.x, sparkle.y);

      if (sparkle.isDustFleck) {
        // Floating wood dust flake
        final dustPaint = Paint()
          ..color = sparkle.color.withValues(alpha: opacity * 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, currentSize * 0.4, dustPaint);
      } else {
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
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TileShatterPainter oldDelegate) => true;
}

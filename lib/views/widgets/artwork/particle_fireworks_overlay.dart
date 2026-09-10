import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Celebratory particle fireworks overlay that erupts with radiant starbursts,
/// expanding energy rings, and shimmering sparkles upon chapter completion.
class ParticleFireworksOverlay extends StatefulWidget {
  final bool isPlaying;

  const ParticleFireworksOverlay({
    super.key,
    this.isPlaying = true,
  });

  @override
  State<ParticleFireworksOverlay> createState() => _ParticleFireworksOverlayState();
}

class _ParticleFireworksOverlayState extends State<ParticleFireworksOverlay>
    with SingleTickerProviderStateMixin {
  final List<_FireworkParticle> _particles = [];
  final List<_FireworkRing> _rings = [];
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();
  double _spawnTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.isPlaying) {
      _ticker.start();
      // Initial celebratory salvos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        _launchSalvo(Offset(size.width * 0.30, size.height * 0.28));
        _launchSalvo(Offset(size.width * 0.70, size.height * 0.22));
      });
    }
  }

  @override
  void didUpdateWidget(covariant ParticleFireworksOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ticker.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!widget.isPlaying && _ticker.isTicking && _particles.isEmpty && _rings.isEmpty) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _particles.clear();
    _rings.clear();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    // Periodic new fireworks burst while playing
    if (widget.isPlaying) {
      _spawnTimer += dt;
      if (_spawnTimer >= 0.55) {
        _spawnTimer = 0.0;
        final size = MediaQuery.of(context).size;
        final burstX = size.width * (0.20 + _random.nextDouble() * 0.60);
        final burstY = size.height * (0.16 + _random.nextDouble() * 0.32);
        _launchSalvo(Offset(burstX, burstY));
      }
    }

    // Update particles physics
    _particles.removeWhere((p) => !p.update(dt));
    _rings.removeWhere((r) => !r.update(dt));

    if (_particles.isEmpty && _rings.isEmpty && !widget.isPlaying) {
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }

    setState(() {});
  }

  void _launchSalvo(Offset center) {
    final palettes = [
      [const Color(0xFFFFD54F), const Color(0xFFFFA000), const Color(0xFFFFF7ED)], // Golden Amber
      [const Color(0xFFF472B6), const Color(0xFFEC4899), const Color(0xFFFFF1F2)], // Radiant Rose
      [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFFE0F2FE)], // Electric Cyan
      [const Color(0xFFA78BFA), const Color(0xFF7C3AED), const Color(0xFFEDE9FE)], // Royal Violet
      [const Color(0xFF34D399), const Color(0xFF059669), const Color(0xFFECFDF5)], // Emerald Jade
    ];

    final palette = palettes[_random.nextInt(palettes.length)];

    // 1. Expanding shockwave ring
    _rings.add(
      _FireworkRing(
        center: center,
        color: palette.first,
        maxRadius: 55.0 + _random.nextDouble() * 25.0,
      ),
    );

    // 2. Radial explosion sparks
    final sparkCount = 24 + _random.nextInt(10);
    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * pi + (_random.nextDouble() - 0.5) * 0.25;
      final speed = 80.0 + _random.nextDouble() * 140.0;
      final color = palette[_random.nextInt(palette.length)];
      final size = 7.0 + _random.nextDouble() * 6.0;

      _particles.add(
        _FireworkParticle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 15.0,
          color: color,
          size: size,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 8.0,
          maxLife: 0.65 + _random.nextDouble() * 0.35,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty && _rings.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FireworksPainter(particles: _particles, rings: _rings),
      ),
    );
  }
}

class _FireworkParticle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double rotation;
  final double vRot;
  double life;
  final double maxLife;

  _FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.vRot,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    // Gravity & air drag
    vy += 120.0 * dt;
    x += vx * dt;
    y += vy * dt;
    vx *= 0.97;
    vy *= 0.97;
    rotation += vRot * dt;

    return true;
  }
}

class _FireworkRing {
  final Offset center;
  final Color color;
  final double maxRadius;
  double life;
  final double maxLife;

  _FireworkRing({
    required this.center,
    required this.color,
    required this.maxRadius,
    this.maxLife = 0.32,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    return life > 0;
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_FireworkParticle> particles;
  final List<_FireworkRing> rings;

  _FireworksPainter({required this.particles, required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Shockwave Rings
    for (final ring in rings) {
      final t = 1.0 - (ring.life / ring.maxLife); // 0.0 -> 1.0
      final radius = ring.maxRadius * Curves.easeOutCubic.transform(t);
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = ring.color.withValues(alpha: opacity * 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - t) * 3.5 + 0.5;

      canvas.drawCircle(ring.center, radius, paint);
    }

    // 2. Draw 4-Pointed Star Sparkles
    for (final p in particles) {
      final progress = p.life / p.maxLife;
      final opacity = (sin(progress * pi)).clamp(0.0, 1.0);
      final curSize = p.size * (0.4 + 0.6 * progress);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final starPath = Path();
      final r = curSize;
      final innerR = curSize * 0.28;

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

      // Outer Glow
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset.zero, curSize * 0.80, glowPaint);

      // Star Face
      final starPaint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(starPath, starPaint);

      // Core Highlight
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, curSize * 0.20, corePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => true;
}

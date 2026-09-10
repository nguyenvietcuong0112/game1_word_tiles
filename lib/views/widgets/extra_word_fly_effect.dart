import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../services/audio_manager.dart';
import 'board_widget.dart';
import 'booster_bar.dart';

/// Non-blocking visual FX overlay that animates found extra words jumping from the
/// board tiles along a curved parabolic Bézier trajectory into the Extra Words feature icon.
class ExtraWordFlyOverlay extends StatefulWidget {
  final GameController controller;
  final GlobalKey<BoardWidgetState> boardKey;
  final GlobalKey<ExtraWordsButtonState> extraWordsBtnKey;

  const ExtraWordFlyOverlay({
    super.key,
    required this.controller,
    required this.boardKey,
    required this.extraWordsBtnKey,
  });

  @override
  State<ExtraWordFlyOverlay> createState() => _ExtraWordFlyOverlayState();
}

class _ExtraWordFlyOverlayState extends State<ExtraWordFlyOverlay> with TickerProviderStateMixin {
  final List<_ActiveFlight> _flights = [];
  final List<_Particle> _particles = [];
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.extraWordFlyNotifier.addListener(_onExtraWordEvent);
  }

  @override
  void didUpdateWidget(covariant ExtraWordFlyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.extraWordFlyNotifier.removeListener(_onExtraWordEvent);
      widget.controller.extraWordFlyNotifier.addListener(_onExtraWordEvent);
    }
  }

  @override
  void dispose() {
    widget.controller.extraWordFlyNotifier.removeListener(_onExtraWordEvent);
    _ticker?.dispose();
    for (final f in _flights) {
      f.controller.dispose();
    }
    _flights.clear();
    _particles.clear();
    super.dispose();
  }

  void _onExtraWordEvent() {
    final event = widget.controller.extraWordFlyNotifier.value;
    if (event == null || !mounted) return;

    // 1. Calculate Start Position (Centroid of swiped tiles on board)
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final globalStart = widget.boardKey.currentState?.getGlobalCenterForPath(event.path) ??
        overlayBox.localToGlobal(Offset(overlayBox.size.width / 2, overlayBox.size.height / 2));
    final startPos = overlayBox.globalToLocal(globalStart);

    // 2. Calculate Target Position (Center of Extra Words button)
    final targetBox = widget.extraWordsBtnKey.currentContext?.findRenderObject() as RenderBox?;
    Offset targetPos;
    if (targetBox != null && targetBox.hasSize) {
      final globalTarget = targetBox.localToGlobal(Offset(targetBox.size.width / 2, targetBox.size.height / 2));
      targetPos = overlayBox.globalToLocal(globalTarget);
    } else {
      // Fallback coordinate: bottom-left area where BoosterBar sits
      targetPos = Offset(48.w, overlayBox.size.height - 68.h);
    }

    // 3. Compute Parabolic Jump Control Point (Arches upward and outward)
    final midX = (startPos.dx + targetPos.dx) / 2;
    // Lateral curve bias: curve slightly outwards toward center or edge
    final lateralBias = (startPos.dx > targetPos.dx) ? 35.0 : -35.0;
    final peakY = min(startPos.dy, targetPos.dy) - 110.0;
    final controlPoint = Offset(midX + lateralBias, peakY);

    // 4. Initial burst of sparkles at origin
    _spawnBurst(startPos, 6, const Color(0xFFFFD54F));

    // 5. Create flight controller & state
    final flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    final flight = _ActiveFlight(
      word: event.word,
      bankCount: event.bankCount,
      startPos: startPos,
      controlPoint: controlPoint,
      targetPos: targetPos,
      controller: flightController,
    );

    flightController.addListener(() {
      if (!mounted) return;
      final t = flightController.value;

      // Spawn trail particles during the flight phase (t: 0.18 -> 0.95)
      if (t >= 0.18 && t < 0.95) {
        final pos = flight.getCurrentPosition(t);
        _spawnTrailParticle(pos);
      }
      setState(() {});
    });

    flightController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onFlightCompleted(flight);
      }
    });

    setState(() {
      _flights.add(flight);
    });

    flightController.forward();
  }

  void _onFlightCompleted(_ActiveFlight flight) {
    if (!mounted) return;

    // 1. Trigger punch bounce on the Extra Words button
    widget.extraWordsBtnKey.currentState?.punchBounce();

    // 2. Starburst particle explosion at the Extra Words icon
    _spawnImpactStarburst(flight.targetPos);

    // 3. Impact Audio & Haptic
    if (flight.bankCount >= 10) {
      AudioManager.playVictory();
    } else {
      AudioManager.playExtraWord();
    }
    HapticFeedback.mediumImpact();

    // 4. Clean up flight instance
    setState(() {
      _flights.remove(flight);
    });
    flight.controller.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (_particles.isEmpty && _flights.isEmpty) {
      _ticker?.stop();
      _lastElapsed = Duration.zero;
      return;
    }

    // Update particles physics
    final survivingParticles = <_Particle>[];
    for (final p in _particles) {
      if (p.update(dt)) {
        survivingParticles.add(p);
      }
    }

    if (survivingParticles.length != _particles.length || _particles.isNotEmpty) {
      setState(() {
        _particles.clear();
        _particles.addAll(survivingParticles);
      });
    }

    if (_particles.isEmpty && _flights.isEmpty) {
      _ticker?.stop();
      _lastElapsed = Duration.zero;
    }
  }

  void _ensureTickerRunning() {
    if (_ticker != null && !_ticker!.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker!.start();
    }
  }

  void _spawnTrailParticle(Offset pos) {
    _ensureTickerRunning();
    final colors = [
      const Color(0xFFFFD54F), // Amber gold
      const Color(0xFFFFA000), // Honey gold
      const Color(0xFFFFF7ED), // Warm Ivory
      const Color(0xFFA855F7), // Gentle purple accent
    ];
    final color = colors[_random.nextInt(colors.length)];
    final angle = _random.nextDouble() * 2 * pi;
    final speed = 15.0 + _random.nextDouble() * 35.0;

    _particles.add(
      _Particle(
        x: pos.dx + (_random.nextDouble() - 0.5) * 16.0,
        y: pos.dy + (_random.nextDouble() - 0.5) * 16.0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed + 10.0,
        size: 7.0 + _random.nextDouble() * 6.0,
        color: color,
        rotation: _random.nextDouble() * 2 * pi,
        vRot: (_random.nextDouble() - 0.5) * 6.0,
        maxLife: 0.35 + _random.nextDouble() * 0.15,
      ),
    );
  }

  void _spawnBurst(Offset center, int count, Color color) {
    _ensureTickerRunning();
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + (_random.nextDouble() * 0.4);
      final speed = 40.0 + _random.nextDouble() * 60.0;
      _particles.add(
        _Particle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 9.0 + _random.nextDouble() * 5.0,
          color: color,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 8.0,
          maxLife: 0.40,
        ),
      );
    }
  }

  void _spawnImpactStarburst(Offset center) {
    _ensureTickerRunning();
    final colors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFFC107),
      const Color(0xFFFFF7ED),
      const Color(0xFFA855F7),
      const Color(0xFF34D399),
    ];
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 70.0 + _random.nextDouble() * 120.0;
      _particles.add(
        _Particle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 20.0,
          size: 10.0 + _random.nextDouble() * 7.0,
          color: colors[i % colors.length],
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 10.0,
          maxLife: 0.45 + _random.nextDouble() * 0.20,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flights.isEmpty && _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Particle Sparkle Trail & Starburst Layer
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _FlyParticlePainter(particles: _particles),
              ),
            ),

          // 2. Flying 3D Word Pill Badges
          ..._flights.map((flight) {
            final t = flight.controller.value;
            final pos = flight.getCurrentPosition(t);
            final scale = flight.getCurrentScale(t);
            final rotation = flight.getCurrentRotation(t);
            final opacity = flight.getCurrentOpacity(t);

            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: _FlyingWordBadge(word: flight.word),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Represents an active in-flight word entity
class _ActiveFlight {
  final String word;
  final int bankCount;
  final Offset startPos;
  final Offset controlPoint;
  final Offset targetPos;
  final AnimationController controller;

  _ActiveFlight({
    required this.word,
    required this.bankCount,
    required this.startPos,
    required this.controlPoint,
    required this.targetPos,
    required this.controller,
  });

  /// Compute current position along Quadratic Bézier Curve
  Offset getCurrentPosition(double t) {
    // 0.0 -> 0.18: Pop-up & float at start position (anticipation)
    if (t < 0.18) {
      final subT = t / 0.18;
      // Slight upward float during pop
      return Offset(startPos.dx, startPos.dy - 22.0 * sin(subT * pi * 0.5));
    }

    // 0.18 -> 1.0: Parabolic Bézier flight to target
    final u = Curves.easeInOutCubic.transform(((t - 0.18) / 0.82).clamp(0.0, 1.0));
    final oneMinusU = 1.0 - u;
    final x = oneMinusU * oneMinusU * startPos.dx +
        2 * oneMinusU * u * controlPoint.dx +
        u * u * targetPos.dx;
    final y = oneMinusU * oneMinusU * (startPos.dy - 22.0) +
        2 * oneMinusU * u * controlPoint.dy +
        u * u * targetPos.dy;

    return Offset(x, y);
  }

  double getCurrentScale(double t) {
    // 0.0 -> 0.18: Pop from 0.0 to 1.25 with bouncy overshoot
    if (t < 0.18) {
      final subT = t / 0.18;
      return Curves.easeOutBack.transform(subT) * 1.22;
    }
    // 0.18 -> 1.0: Gently scale from 1.22 down to 0.72 so it plunges neatly into icon
    final u = ((t - 0.18) / 0.82).clamp(0.0, 1.0);
    return 1.22 - (u * 0.50);
  }

  double getCurrentRotation(double t) {
    if (t < 0.18) return 0.0;
    final u = ((t - 0.18) / 0.82).clamp(0.0, 1.0);
    // Subtle tilt dynamic (-0.18 to +0.18 rad) based on flight trajectory
    final dir = (targetPos.dx < startPos.dx) ? -1.0 : 1.0;
    return sin(u * pi) * 0.22 * dir;
  }

  double getCurrentOpacity(double t) {
    // Fade out smoothly right at destination entrance
    if (t > 0.94) {
      return (1.0 - ((t - 0.94) / 0.06)).clamp(0.0, 1.0);
    }
    return 1.0;
  }
}

/// 3D Glowing Golden Word Pill Badge
class _FlyingWordBadge extends StatelessWidget {
  final String word;

  const _FlyingWordBadge({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFEE58), // Bright Radiant Lemon Gold
            Color(0xFFFFA000), // Rich Warm Amber Gold
          ],
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          // Radiant glowing outer halo
          BoxShadow(
            color: const Color(0xFFFFA000).withValues(alpha: 0.70),
            blurRadius: 18,
            spreadRadius: 3,
          ),
          // 3D Drop shadow
          const BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 3.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 5.w),
          Text(
            word,
            style: GoogleFonts.fredoka(
              fontSize: 17.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: const [
                Shadow(
                  color: Color(0xFFBF360C),
                  offset: Offset(0, 1.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Particle shard for trail and impact starbursts
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final Color color;
  double rotation;
  final double vRot;
  double life;
  final double maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.vRot,
    required this.maxLife,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;

    x += vx * dt;
    y += vy * dt;
    vx *= 0.96;
    vy *= 0.96;
    rotation += vRot * dt;

    return true;
  }
}

/// Custom painter that renders 4-pointed golden sparkle stars with glowing cores
class _FlyParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _FlyParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = p.life / p.maxLife;
      final opacity = (sin(progress * pi)).clamp(0.0, 1.0);
      final currentSize = p.size * (0.5 + 0.5 * progress);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

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
        ..color = p.color.withValues(alpha: opacity * 0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset.zero, currentSize * 0.85, glowPaint);

      // Star body
      final starPaint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(starPath, starPaint);

      // Bright white diamond core glint
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, currentSize * 0.22, corePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlyParticlePainter oldDelegate) => true;
}

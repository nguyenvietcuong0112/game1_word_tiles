import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum GameBackgroundVariant {
  standard,
  gameplay,
  clean,
  mountainRoad,
}

/// Unified Ambient Game Background for Word Tiles.
/// Features a warm sandalwood linen canvas with subtle 3D birch wood ambient tiles,
/// and lush mountain road atmosphere for Chapter 2.
class GameBackground extends StatelessWidget {
  final Widget? child;
  final GameBackgroundVariant variant;

  const GameBackground({
    super.key,
    this.child,
    this.variant = GameBackgroundVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isMountain = variant == GameBackgroundVariant.mountainRoad;

    final gradient = isMountain
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D5542), // Alpine Forest Mist
              Color(0xFF3F6F57), // Verdant Canopy
              Color(0xFF264736), // Deep Pine Shadow
            ],
            stops: [0.0, 0.50, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgSkyGradientStart,
              AppColors.bgCanvas,
              AppColors.bgCanvasSecondary,
            ],
            stops: [0.0, 0.45, 1.0],
          );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (variant != GameBackgroundVariant.clean)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AmbientWoodTilesPainter(
                    isGameplay: variant == GameBackgroundVariant.gameplay || isMountain,
                    isMountain: isMountain,
                  ),
                ),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _AmbientWoodTilesPainter extends CustomPainter {
  final bool isGameplay;
  final bool isMountain;

  const _AmbientWoodTilesPainter({
    required this.isGameplay,
    this.isMountain = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> positions;
    if (isGameplay) {
      // Sparsely placed at extreme edges so it never interferes with target words or board
      positions = [
        Offset(size.width * 0.08, size.height * 0.10),
        Offset(size.width * 0.92, size.height * 0.12),
        Offset(size.width * 0.06, size.height * 0.90),
        Offset(size.width * 0.94, size.height * 0.88),
      ];
    } else {
      // Standard balanced ambient composition
      positions = [
        Offset(size.width * 0.10, size.height * 0.14),
        Offset(size.width * 0.88, size.height * 0.16),
        Offset(size.width * 0.08, size.height * 0.52),
        Offset(size.width * 0.92, size.height * 0.58),
        Offset(size.width * 0.18, size.height * 0.88),
        Offset(size.width * 0.82, size.height * 0.91),
      ];
    }

    final tileColor = isMountain ? const Color(0xFF6DA584) : const Color(0xFFDEC5AE);

    final fillPaint = Paint()
      ..color = tileColor.withValues(alpha: isGameplay ? 0.10 : 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = tileColor.withValues(alpha: isGameplay ? 0.16 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final pos in positions) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pos,
          width: 44,
          height: 44,
        ),
        const Radius.circular(14),
      );

      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientWoodTilesPainter oldDelegate) =>
      oldDelegate.isGameplay != isGameplay || oldDelegate.isMountain != isMountain;
}

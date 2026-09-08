import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum GameBackgroundVariant {
  standard,
  gameplay,
  clean,
}

/// Unified Ambient Game Background for Word Tiles.
/// Features a warm sandalwood linen canvas with subtle 3D birch wood ambient tiles.
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgSkyGradientStart,
            AppColors.bgCanvas,
            AppColors.bgCanvasSecondary,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (variant != GameBackgroundVariant.clean)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AmbientWoodTilesPainter(
                    isGameplay: variant == GameBackgroundVariant.gameplay,
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

  const _AmbientWoodTilesPainter({required this.isGameplay});

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

    final fillPaint = Paint()
      ..color = const Color(0xFFDEC5AE).withValues(alpha: isGameplay ? 0.12 : 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFDEC5AE).withValues(alpha: isGameplay ? 0.18 : 0.28)
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
      oldDelegate.isGameplay != isGameplay;
}

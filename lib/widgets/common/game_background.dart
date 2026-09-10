import 'package:flutter/material.dart';
import '../../models/chapter_model.dart';
import '../../theme/app_theme.dart';

enum GameBackgroundVariant {
  standard,
  gameplay,
  clean,
  mountainRoad,
}

/// Unified Ambient Game Background for Word Tiles.
/// Features a warm sandalwood linen canvas with subtle 3D birch wood ambient tiles,
/// and rich thematic visual atmosphere matching the current chapter.
class GameBackground extends StatelessWidget {
  final Widget? child;
  final GameBackgroundVariant variant;
  final ChapterTheme? chapterTheme;

  const GameBackground({
    super.key,
    this.child,
    this.variant = GameBackgroundVariant.standard,
    this.chapterTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = chapterTheme;
    final isMountain = variant == GameBackgroundVariant.mountainRoad || theme?.chapterNumber == 2;

    final Gradient gradient;
    if (theme != null && theme.chapterNumber != 1) {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.skyGradient.first.withValues(alpha: 0.85),
          theme.skyGradient[1].withValues(alpha: 0.90),
          theme.skyGradient.last,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    } else if (isMountain) {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2D5542), // Alpine Forest Mist
          Color(0xFF3F6F57), // Verdant Canopy
          Color(0xFF264736), // Deep Pine Shadow
        ],
        stops: [0.0, 0.50, 1.0],
      );
    } else {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.bgSkyGradientStart,
          AppColors.bgCanvas,
          AppColors.bgCanvasSecondary,
        ],
        stops: [0.0, 0.45, 1.0],
      );
    }

    return RepaintBoundary(
      child: Container(
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
                      isGameplay: variant == GameBackgroundVariant.gameplay || isMountain || theme != null,
                      isMountain: isMountain,
                      ambientColor: theme?.ambientColor,
                    ),
                  ),
                ),
              ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _AmbientWoodTilesPainter extends CustomPainter {
  final bool isGameplay;
  final bool isMountain;
  final Color? ambientColor;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  const _AmbientWoodTilesPainter({
    required this.isGameplay,
    this.isMountain = false,
    this.ambientColor,
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

    final tileColor = ambientColor ?? (isMountain ? const Color(0xFF6DA584) : const Color(0xFFDEC5AE));

    _fillPaint.color = tileColor.withValues(alpha: isGameplay ? 0.10 : 0.18);
    _borderPaint.color = tileColor.withValues(alpha: isGameplay ? 0.16 : 0.28);

    for (final pos in positions) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pos,
          width: 44,
          height: 44,
        ),
        const Radius.circular(14),
      );

      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientWoodTilesPainter oldDelegate) =>
      oldDelegate.isGameplay != isGameplay ||
      oldDelegate.isMountain != isMountain ||
      oldDelegate.ambientColor != ambientColor;
}


import 'dart:math';
import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../theme/app_theme.dart';
import 'tile_widget.dart';

class BoardWidget extends StatefulWidget {
  final GameController controller;

  const BoardWidget({super.key, required this.controller});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<Offset?> _touchPosNotifier = ValueNotifier<Offset?>(null);

  double _tileSize = 64.0;

  void _handleTouch(Offset globalPos, bool isStart) {
    final RenderBox? renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPos);
    final width = widget.controller.level.width;
    final height = widget.controller.level.height;

    if (width == 0 || height == 0) return;

    _touchPosNotifier.value = localPos;

    final col = (localPos.dx / _tileSize).floor();
    final row = (localPos.dy / _tileSize).floor();

    if (row >= 0 && row < height && col >= 0 && col < width) {
      if (isStart) {
        widget.controller.startSwipe(row, col);
      } else {
        widget.controller.updateSwipe(row, col);
      }
    }
  }

  void _handleTouchEnd() {
    _touchPosNotifier.value = null;
    widget.controller.endSwipe();
  }

  @override
  void dispose() {
    _touchPosNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.controller.level.height;
    final width = widget.controller.level.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth - 40;
        final maxH = constraints.maxHeight - 40;

        final sizeByWidth = width > 0 ? maxW / width : 64.0;
        final sizeByHeight = height > 0 ? maxH / height : 64.0;
        _tileSize = min(sizeByWidth, sizeByHeight).clamp(48.0, 80.0);

        final boardWidth = width * _tileSize;
        final boardHeight = height * _tileSize;

        return Center(
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardPeach, // Warm peach sand card matching reference image
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderDark, // Crisp 2px dark border
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderDark.withOpacity(0.12),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: GestureDetector(
                  onPanStart: (details) => _handleTouch(details.globalPosition, true),
                  onPanUpdate: (details) => _handleTouch(details.globalPosition, false),
                  onPanEnd: (_) => _handleTouchEnd(),
                  onPanCancel: () => _handleTouchEnd(),
                  child: Stack(
                    key: _gridKey,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Underlying Terracotta Connecting Ribbon (120 FPS)
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          if (widget.controller.currentPath.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<Offset?>(
                                  valueListenable: _touchPosNotifier,
                                  builder: (context, touchPos, _) {
                                    return CustomPaint(
                                      painter: SwipeLinePainter(
                                        path: widget.controller.currentPath,
                                        livePos: touchPos,
                                        tileSize: _tileSize,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 2. Grid of tiles
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          return RepaintBoundary(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(height, (r) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(width, (c) {
                                    final tile = widget.controller.grid[r][c];
                                    final isSelected = widget.controller.currentPath.contains(Point(c, r));
                                    final isHinted = widget.controller.highlightedHintPath?.contains(Point(c, r)) ?? false;

                                    return TileWidget(
                                      tile: tile,
                                      isSelected: isSelected,
                                      isHinted: isHinted,
                                      size: _tileSize,
                                    );
                                  }),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SwipeLinePainter extends CustomPainter {
  final List<Point<int>> path;
  final Offset? livePos;
  final double tileSize;

  SwipeLinePainter({
    required this.path,
    this.livePos,
    required this.tileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final trackPaint = Paint()
      ..color = AppColors.terracotta
      ..strokeWidth = tileSize * 0.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final drawPath = Path();
    for (int i = 0; i < path.length; i++) {
      final pt = path[i];
      final center = Offset((pt.x + 0.5) * tileSize, (pt.y + 0.5) * tileSize);
      if (i == 0) {
        drawPath.moveTo(center.dx, center.dy);
      } else {
        drawPath.lineTo(center.dx, center.dy);
      }
    }

    if (livePos != null) {
      drawPath.lineTo(livePos!.dx, livePos!.dy);
    }

    canvas.drawPath(drawPath, trackPaint);
  }

  @override
  bool shouldRepaint(covariant SwipeLinePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.livePos != livePos ||
        oldDelegate.tileSize != tileSize;
  }
}

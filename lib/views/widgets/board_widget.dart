import 'dart:math';
import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import '../common/wood_widgets.dart';
import 'shatter_particle_overlay.dart';
import 'tile_widget.dart';
import 'tutorial_overlay.dart';

class BoardWidget extends StatefulWidget {
  final GameController controller;

  const BoardWidget({super.key, required this.controller});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with SingleTickerProviderStateMixin {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<Offset?> _touchPosNotifier = ValueNotifier<Offset?>(null);
  late final TileShatterController _shatterController;
  final Set<String> _previouslyClearedTileKeys = {};

  double _tileSize = 64.0;

  @override
  void initState() {
    super.initState();
    _shatterController = TileShatterController();
    _shatterController.init(this);
    _syncClearedTiles(triggerParticles: false);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _previouslyClearedTileKeys.clear();
      _syncClearedTiles(triggerParticles: false);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    _syncClearedTiles(triggerParticles: true);
  }

  void _syncClearedTiles({required bool triggerParticles}) {
    final height = widget.controller.grid.length;
    for (int r = 0; r < height; r++) {
      final width = widget.controller.grid[r].length;
      for (int c = 0; c < width; c++) {
        final tile = widget.controller.grid[r][c];
        final key = '$r-$c';
        if (tile.isCleared) {
          if (!_previouslyClearedTileKeys.contains(key)) {
            _previouslyClearedTileKeys.add(key);
            if (triggerParticles) {
              final center = Offset((c + 0.5) * _tileSize, (r + 0.5) * _tileSize);
              final theme = AppColors.getTileThemeForPosition(r, c);
              _shatterController.shatterTile(
                center: center,
                tileSize: _tileSize,
                theme: theme,
              );
            }
          }
        } else {
          _previouslyClearedTileKeys.remove(key);
        }
      }
    }
  }

  void _handleTouch(Offset globalPos, bool isStart) {
    if (!GameStorage.isCountTutorialShown() &&
        widget.controller.getFirstTileWithCountGreaterThanOne() != null) {
      return;
    }

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
    widget.controller.removeListener(_onControllerChanged);
    _shatterController.dispose();
    _touchPosNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.controller.level.height;
    final width = widget.controller.level.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double trayPadding = 18.0;
        const double outerSafety = 6.0;

        final availableW = max(0.0, constraints.maxWidth - trayPadding - outerSafety);
        final availableH = max(0.0, constraints.maxHeight - trayPadding - outerSafety);

        final sizeByWidth = width > 0 ? availableW / width : 58.0;
        final sizeByHeight = height > 0 ? availableH / height : 58.0;
        _tileSize = min(sizeByWidth, sizeByHeight).clamp(24.0, 64.0);

        final boardWidth = width * _tileSize;
        final boardHeight = height * _tileSize;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              child: WoodBoardTray(
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
                      // 1. Glowing Laser Swipe Trail (120 FPS)
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

                      // 2. Grid of 3D Pastel Tiles
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          final firstCountPt = (!GameStorage.isCountTutorialShown() && !widget.controller.isWon)
                              ? widget.controller.getFirstTileWithCountGreaterThanOne()
                              : null;

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
                                    final isCountSpotlight = firstCountPt != null &&
                                        firstCountPt.x == c &&
                                        firstCountPt.y == r;
                                    final tileWidget = TileWidget(
                                      tile: tile,
                                      isSelected: isSelected,
                                      isHinted: isHinted,
                                      isCountSpotlight: isCountSpotlight,
                                      size: _tileSize,
                                    );

                                    // Dim other tiles when count tutorial spotlight is active
                                    if (firstCountPt != null && !isCountSpotlight) {
                                      return Opacity(
                                        opacity: 0.30,
                                        child: tileWidget,
                                      );
                                    }
                                    return tileWidget;
                                  }),
                                );
                              }),
                            ),
                          );
                        },
                      ),

                      // 3. 3D Tile Shatter Particles & Sparkles Layer (60-120 FPS GPU Canvas)
                      ListenableBuilder(
                        listenable: _shatterController,
                        builder: (context, _) {
                          if (_shatterController.shards.isEmpty && _shatterController.sparkles.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: TileShatterPainter(
                                    shards: _shatterController.shards,
                                    sparkles: _shatterController.sparkles,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 4. In-Game Tutorial Animated Hand Guide (Level 1 only, hides during active swipe)
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          if (widget.controller.isWon ||
                              widget.controller.isWinning ||
                              GameStorage.isTutorialCompleted() ||
                              !GameStorage.isCountTutorialShown() ||
                              widget.controller.levelNumber != 1 ||
                              widget.controller.currentPath.isNotEmpty) {
                            return const SizedBox.shrink();
                          }

                          final nextWord = widget.controller.getNextUnsolvedTargetWord();
                          if (nextWord == null) return const SizedBox.shrink();

                          final path = widget.controller.getTutorialPathForWord(nextWord);
                          if (path == null || path.isEmpty) return const SizedBox.shrink();

                          return Positioned.fill(
                            child: TutorialHandGuide(
                              path: path,
                              tileSize: _tileSize,
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

    // 1. Wide Honey Gold Radiant Glow
    final glowPaint = Paint()
      ..color = AppColors.honeyGold.withValues(alpha: 0.45)
      ..strokeWidth = tileSize * 0.50
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(drawPath, glowPaint);

    // 2. Main Vibrant Terracotta Peach Ribbon
    final trackPaint = Paint()
      ..color = AppColors.terracotta
      ..strokeWidth = tileSize * 0.32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(drawPath, trackPaint);

    // 3. Inner Gloss Laser Beam Highlight
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = tileSize * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(drawPath, shinePaint);

    // 4. Sparkle Golden Node Beads at each connected tile center
    final nodePaint = Paint()
      ..color = AppColors.butterCream
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = AppColors.terracottaDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final pt in path) {
      final center = Offset((pt.x + 0.5) * tileSize, (pt.y + 0.5) * tileSize);
      canvas.drawCircle(center, tileSize * 0.16, nodePaint);
      canvas.drawCircle(center, tileSize * 0.16, nodeBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SwipeLinePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.livePos != livePos ||
        oldDelegate.tileSize != tileSize;
  }
}


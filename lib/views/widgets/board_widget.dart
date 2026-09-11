import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/game_controller.dart';
import '../../services/game_storage.dart';
import '../../theme/app_theme.dart';
import 'shatter_particle_overlay.dart';
import 'tile_widget.dart';
import 'tutorial_overlay.dart';

class BoardWidget extends StatefulWidget {
  final GameController controller;

  const BoardWidget({super.key, required this.controller});

  @override
  State<BoardWidget> createState() => BoardWidgetState();
}

class BoardWidgetState extends State<BoardWidget> with SingleTickerProviderStateMixin {
  final GlobalKey _gridKey = GlobalKey();
  final ValueNotifier<Offset?> _touchPosNotifier = ValueNotifier<Offset?>(null);
  late final TileShatterController _shatterController;
  final Set<String> _previouslyClearedTileKeys = {};

  double _tileSize = 64.0;

  /// Get the global screen coordinates for the centroid of a path of tiles.
  /// If the path is empty, returns the global center of the board grid.
  Offset? getGlobalCenterForPath(List<Point<int>> path) {
    final RenderBox? renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    if (path.isEmpty) {
      final size = renderBox.size;
      return renderBox.localToGlobal(Offset(size.width / 2, size.height / 2));
    }

    double sumX = 0;
    double sumY = 0;
    for (final pt in path) {
      sumX += (pt.x + 0.5) * _tileSize;
      sumY += (pt.y + 0.5) * _tileSize;
    }
    return renderBox.localToGlobal(Offset(sumX / path.length, sumY / path.length));
  }

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
                primaryColor: widget.controller.chapterTheme.primaryColor,
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
        const double containerPadding = 20.0;
        const double borderAndMargin = 12.0;

        final availableW = max(0.0, constraints.maxWidth - containerPadding - borderAndMargin);
        final availableH = max(0.0, constraints.maxHeight - containerPadding - borderAndMargin);

        final sizeByWidth = width > 0 ? availableW / width : 58.0;
        final sizeByHeight = height > 0 ? availableH / height : 58.0;
        _tileSize = min(sizeByWidth, sizeByHeight).clamp(24.0, 64.0);

        final boardWidth = width * _tileSize;
        final boardHeight = height * _tileSize;

        return Center(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              // Check active tutorial guidance
              List<Point<int>>? tutorialHighlightPath;
              Point<int>? countSpotlightPt;
              bool isBoardDimmed = false;

              // 1. Fail-Safe Dynamic Hint (Levels 1-10 after 5 failed swipes)
              if (widget.controller.levelNumber <= 10 &&
                  widget.controller.failSafeHintPath != null &&
                  widget.controller.failSafeHintPath!.isNotEmpty) {
                tutorialHighlightPath = widget.controller.failSafeHintPath;
                isBoardDimmed = false;
              }
              // 2. Level 1 Tutorial (Steps 1 & 2 only)
              else if (!GameStorage.isTutorialCompleted() &&
                  widget.controller.levelNumber == 1 &&
                  widget.controller.solvedTargetWords.length < 2) {
                final nextWord = widget.controller.getNextUnsolvedTargetWord();
                if (nextWord != null) {
                  tutorialHighlightPath = widget.controller.getTutorialPathForWord(nextWord);
                  isBoardDimmed = true;
                }
              }
              // 3. Level 2 Count Tutorial
              else if (!GameStorage.isCountTutorialShown() &&
                  !widget.controller.isWon &&
                  widget.controller.levelNumber == 2) {
                countSpotlightPt = widget.controller.getFirstTileWithCountGreaterThanOne();
                if (countSpotlightPt != null) {
                  isBoardDimmed = true;
                }
              }
              // 4. Level 4 Reverse Swipe Tutorial
              else if (!GameStorage.isReverseTutorialShown() &&
                  widget.controller.levelNumber == 4 &&
                  widget.controller.solvedTargetWords.isEmpty) {
                final firstWord = widget.controller.level.targetWords.isNotEmpty
                    ? widget.controller.level.targetWords.first.word
                    : 'CAR';
                tutorialHighlightPath = widget.controller.getTutorialPathForWord(firstWord);
                isBoardDimmed = true;
              }
              // 5. Level 5 Hint Booster Tutorial
              else if (!GameStorage.isHintTutorialShown() &&
                  !widget.controller.isWon &&
                  widget.controller.levelNumber == 5) {
                isBoardDimmed = true;
              }
              // 6. Level 7 Extra Words & Rocket Tutorials
              else if ((!GameStorage.isExtraWordsTutorialShown() ||
                        !GameStorage.isRocketTutorialShown()) &&
                  !widget.controller.isWon &&
                  widget.controller.levelNumber == 7) {
                isBoardDimmed = true;
              }

              return RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/images/bg_card_board.png'),
                      fit: BoxFit.fill,
                      opacity: isBoardDimmed ? 0.6 : 1.0,
                    ),
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
                          // 1. Glowing Laser Swipe Trail (120 FPS)
                          if (widget.controller.currentPath.isNotEmpty)
                            Positioned.fill(
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
                                          lineColor: widget.controller.chapterTheme.primaryColor,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                          // 2. Grid of 3D Pastel Tiles
                          RepaintBoundary(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(height, (r) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(width, (c) {
                                    final pt = Point(c, r);
                                    final tile = widget.controller.grid[r][c];
                                    final isSelected = widget.controller.currentPath.contains(pt);
                                    final isHinted = (widget.controller.highlightedHintPath?.contains(pt) ?? false) ||
                                        (widget.controller.failSafeHintPath?.contains(pt) ?? false);
                                    final isTutorialHighlighted = tutorialHighlightPath != null &&
                                        tutorialHighlightPath.contains(pt);
                                    final isCountSpotlight = countSpotlightPt != null &&
                                        countSpotlightPt.x == c &&
                                        countSpotlightPt.y == r;
                                    final isDimmed = isBoardDimmed &&
                                        !isTutorialHighlighted &&
                                        !isCountSpotlight &&
                                        !isSelected;

                                    return TileWidget(
                                      tile: tile,
                                      isSelected: isSelected,
                                      isHinted: isHinted,
                                      isCountSpotlight: isCountSpotlight,
                                      isTutorialHighlighted: isTutorialHighlighted,
                                      isDimmed: isDimmed,
                                      size: _tileSize,
                                      chapterTheme: widget.controller.chapterTheme,
                                    );
                                  }),
                                );
                              }),
                            )
                                .animate(
                                  key: ValueKey('board-grid-${widget.controller.levelNumber}'),
                                )
                                .fadeIn(duration: 200.ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  end: const Offset(1.0, 1.0),
                                  duration: 260.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),

                      // 3. 3D Tile Shatter Particles & Sparkles Layer (60-120 FPS GPU Canvas)
                      ListenableBuilder(
                        listenable: _shatterController,
                        builder: (context, _) {
                          if (_shatterController.shards.isEmpty &&
                              _shatterController.shockwaves.isEmpty &&
                              _shatterController.sparkles.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: TileShatterPainter(
                                    shards: _shatterController.shards,
                                    shockwaves: _shatterController.shockwaves,
                                    sparkles: _shatterController.sparkles,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 4. In-Game Tutorial & Fail-Safe Animated Hand Guide
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          if (widget.controller.isWon ||
                              widget.controller.isWinning ||
                              widget.controller.currentPath.isNotEmpty) {
                            return const SizedBox.shrink();
                          }

                          List<Point<int>>? guidePath;

                          // Priority 1: Fail-Safe Dynamic Hint (Levels 1-10 after 5 failed swipes)
                          if (widget.controller.levelNumber <= 10 &&
                              widget.controller.failSafeHintPath != null &&
                              widget.controller.failSafeHintPath!.isNotEmpty) {
                            guidePath = widget.controller.failSafeHintPath;
                          }
                          // Priority 2: Level 1 Tutorial (Steps 1 & 2 only: SUN and ICE, Step 3 JOB is free play)
                          else if (!GameStorage.isTutorialCompleted() &&
                              widget.controller.levelNumber == 1 &&
                              widget.controller.solvedTargetWords.length < 2) {
                            final nextWord = widget.controller.getNextUnsolvedTargetWord();
                            if (nextWord != null) {
                              guidePath = widget.controller.getTutorialPathForWord(nextWord);
                            }
                          }
                          // Priority 3: Level 4 Reverse Swipe Tutorial
                          else if (!GameStorage.isReverseTutorialShown() &&
                              widget.controller.levelNumber == 4 &&
                              widget.controller.solvedTargetWords.isEmpty) {
                            final firstWord = widget.controller.level.targetWords.isNotEmpty
                                ? widget.controller.level.targetWords.first.word
                                : 'CAR';
                            guidePath = widget.controller.getTutorialPathForWord(firstWord);
                          }

                          if (guidePath == null || guidePath.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Positioned.fill(
                            child: TutorialHandGuide(
                              path: guidePath,
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
          );
        },
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
  final Color? lineColor;

  SwipeLinePainter({
    required this.path,
    this.livePos,
    required this.tileSize,
    this.lineColor,
  });

  static final Paint _glowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _trackPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _shinePaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _nodePaint = Paint()
    ..color = AppColors.butterCream
    ..style = PaintingStyle.fill;

  static final Paint _nodeBorderPaint = Paint()
    ..color = AppColors.terracottaDark
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Path _drawPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    _drawPath.reset();
    for (int i = 0; i < path.length; i++) {
      final pt = path[i];
      final center = Offset((pt.x + 0.5) * tileSize, (pt.y + 0.5) * tileSize);
      if (i == 0) {
        _drawPath.moveTo(center.dx, center.dy);
      } else {
        _drawPath.lineTo(center.dx, center.dy);
      }
    }

    if (livePos != null) {
      _drawPath.lineTo(livePos!.dx, livePos!.dy);
    }

    // 1. Wide Radiant Glow
    _glowPaint
      ..color = (lineColor ?? AppColors.honeyGold).withValues(alpha: 0.45)
      ..strokeWidth = tileSize * 0.50;
    canvas.drawPath(_drawPath, _glowPaint);

    // 2. Main Vibrant Chapter Colored Ribbon
    _trackPaint
      ..color = lineColor ?? AppColors.terracotta
      ..strokeWidth = tileSize * 0.32;
    canvas.drawPath(_drawPath, _trackPaint);

    // 3. Inner Gloss Laser Beam Highlight
    _shinePaint
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = tileSize * 0.12;
    canvas.drawPath(_drawPath, _shinePaint);

    // 4. Sparkle Golden Node Beads at each connected tile center
    for (final pt in path) {
      final center = Offset((pt.x + 0.5) * tileSize, (pt.y + 0.5) * tileSize);
      canvas.drawCircle(center, tileSize * 0.16, _nodePaint);
      canvas.drawCircle(center, tileSize * 0.16, _nodeBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SwipeLinePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.livePos != livePos ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.lineColor != lineColor;
  }
}


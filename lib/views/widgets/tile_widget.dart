import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/level_model.dart';
import '../common/wood_widgets.dart';

class TileWidget extends StatelessWidget {
  final LetterTile tile;
  final bool isSelected;
  final bool isHinted;
  final bool isCountSpotlight;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.isHinted,
    this.isCountSpotlight = false,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.isCleared || tile.count <= 0) {
      return SizedBox(
        width: size,
        height: size,
      );
    }

    final WoodenTileState tileState;
    if (isSelected) {
      tileState = WoodenTileState.selected;
    } else if (isHinted) {
      tileState = WoodenTileState.correct;
    } else {
      tileState = WoodenTileState.normal;
    }

    final Widget woodTile = WoodenTile(
      letter: tile.letter,
      state: tileState,
      count: tile.count,
      isObstacleLocked: tile.isObstacleLocked,
      obstacleRequiredWords: tile.obstacleRequiredWords ?? 0,
      size: size,
    );

    if (isCountSpotlight) {
      return woodTile
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.10, 1.10),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return woodTile;
  }
}



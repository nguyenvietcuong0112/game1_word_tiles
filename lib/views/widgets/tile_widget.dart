import 'package:flutter/material.dart';
import '../../models/level_model.dart';
import '../../theme/app_theme.dart';

class TileWidget extends StatelessWidget {
  final LetterTile tile;
  final bool isSelected;
  final bool isHinted;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.isHinted,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.isCleared) {
      return SizedBox(
        width: size,
        height: size,
      );
    }

    // Locked obstacle tile (Frosted paper look)
    if (tile.isObstacleLocked) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.90,
            height: size * 0.90,
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5FE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.borderDark.withOpacity(0.12),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 20, color: Color(0xFF0288D1)),
                      const SizedBox(height: 2),
                      Text(
                        '${tile.obstacleRequiredWords}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 4,
                  child: Text(
                    tile.letter,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.borderDark.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Styling matching the user's reference image:
    // Solid warm cream/peach with crisp 2px dark border
    final faceColor = isSelected
        ? AppColors.terracotta // Bold terracotta fill on selection
        : (isHinted ? AppColors.cardPeach : AppColors.tileFace);

    final borderColor = isSelected
        ? AppColors.borderDark
        : (isHinted ? AppColors.borderSelected : AppColors.borderDark);

    final textColor = isSelected
        ? Colors.white
        : AppColors.textDark;

    final subscriptColor = isSelected
        ? Colors.white.withOpacity(0.9)
        : AppColors.textDark.withOpacity(0.75);

    final tileContent = Container(
      width: size * 0.92,
      height: size * 0.92,
      decoration: BoxDecoration(
        color: faceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderDark.withOpacity(isSelected ? 0.25 : 0.15),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Centered Main Letter
          Center(
            child: Text(
              tile.letter,
              style: TextStyle(
                fontSize: size * 0.46,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),

          // Subscript Usage Number at Bottom-Right
          if (tile.count > 0)
            Positioned(
              bottom: 3,
              right: 6,
              child: Text(
                '${tile.count}',
                style: TextStyle(
                  fontSize: size * 0.20,
                  fontWeight: FontWeight.w900,
                  color: subscriptColor,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.05 : (isHinted ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutBack,
          child: tileContent,
        ),
      ),
    );
  }
}

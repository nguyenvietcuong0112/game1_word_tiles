import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/level_model.dart';
import '../../theme/app_theme.dart';

class TileWidget extends StatelessWidget {
  final LetterTile tile;
  final bool isSelected;
  final bool isHinted;
  final bool isCountSpotlight;
  final bool isTutorialHighlighted;
  final bool isDimmed;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.isHinted,
    this.isCountSpotlight = false,
    this.isTutorialHighlighted = false,
    this.isDimmed = false,
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

    final double tileSize = size * 0.94;
    final theme = AppColors.getTileThemeForPosition(tile.row, tile.col);

    // 1. Locked Obstacle Tile (3D Frosted Crystal Ice & Lock)
    if (tile.isObstacleLocked) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F9FF),
                  Color(0xFFBAE6FD),
                  Color(0xFF7DD3FC),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF0284C7), width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0369A1),
                  offset: Offset(0, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Lock Icon & Required Count
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 24, color: Color(0xFF0369A1)),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                        ),
                        child: Text(
                          '${tile.obstacleRequiredWords}',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0369A1),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtle Preview of letter underneath
                Positioned(
                  top: 4,
                  right: 6,
                  child: Text(
                    tile.letter,
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Playable 3D Natural Wood Letter Tile
    final bool isHighlighted = isTutorialHighlighted;
    final bool isDimmedTile = isDimmed && !isHighlighted && !isCountSpotlight;

    final Color faceColor = isSelected
        ? AppColors.btnFaceBrown
        : (isHinted
            ? AppColors.honeyGold
            : (isDimmedTile ? const Color(0xFF2D2E38) : theme.face));

    final Color bevelColor = isSelected
        ? AppColors.btnShadowBrown
        : (isHinted
            ? AppColors.goldAccent
            : (isDimmedTile ? const Color(0xFF1F2028) : theme.bevel));

    final Color textColor = isSelected
        ? Colors.white
        : (isHinted
            ? Colors.white
            : (isDimmedTile ? const Color(0xFF64748B) : AppColors.textDark));

    final Color borderColor = isCountSpotlight
        ? const Color(0xFFE11D48)
        : (isSelected
            ? AppColors.btnBorderBrown
            : (isDimmedTile ? const Color(0xFF333544) : theme.bevel));

    Widget tileBox = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmedTile ? 0.30 : 1.0,
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: (isSelected || isCountSpotlight) ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isCountSpotlight)
              const BoxShadow(
                color: Color(0x66E11D48),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            // 3D Extrusion Bevel Shadow
            BoxShadow(
              color: isCountSpotlight ? const Color(0xFFBE123C) : bevelColor,
              offset: Offset(0, isSelected ? 3.0 : 2.0),
              blurRadius: 0,
            ),
            if (isSelected)
              BoxShadow(
                color: AppColors.btnShadowBrown.withValues(alpha: 0.35),
                offset: const Offset(0, 4.0),
                blurRadius: 4,
              ),
          ],
        ),
            child: Stack(
              children: [
                // Center Bold Letter with 3D Drop
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      tile.letter,
                      style: GoogleFonts.fredoka(
                        fontSize: size * 0.60,
                        fontWeight: FontWeight.w900,
                        color: isCountSpotlight ? AppColors.headerBrown : textColor,
                        letterSpacing: -0.5,
                        height: 1.0,
                        shadows: isSelected
                            ? [
                                const Shadow(
                                  color: Color(0xFF6B3818),
                                  offset: Offset(0, 1.5),
                                  blurRadius: 0,
                                ),
                              ]
                            : [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  offset: const Offset(0, 1.0),
                                  blurRadius: 0,
                                ),
                              ],
                      ),
                    ),
                  ),
                ),

                // Subscript Tile Usage Badge (If > 0)
                if (tile.count > 0)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: isCountSpotlight
                        ? Container(
                            width: size * 0.36,
                            height: size * 0.36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFBE123C),
                                  offset: Offset(0, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${tile.count}',
                                style: GoogleFonts.fredoka(
                                  fontSize: size * 0.22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.20)
                                  : const Color(0xFFEADBC8).withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppColors.borderDark.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '${tile.count}',
                              style: GoogleFonts.fredoka(
                                fontSize: size * 0.21,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark.withValues(alpha: 0.85),
                                height: 1.0,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        );

    if (isCountSpotlight) {
      tileBox = tileBox
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.15, 1.15),
            duration: 650.ms,
            curve: Curves.easeInOut,
          );
    } else {
      tileBox = AnimatedScale(
        scale: isSelected ? 1.16 : (isHinted ? 1.08 : 1.0),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: tileBox,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: tileBox,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chapter_model.dart';
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
  final ChapterTheme? chapterTheme;

  const TileWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.isHinted,
    this.isCountSpotlight = false,
    this.isTutorialHighlighted = false,
    this.isDimmed = false,
    this.size = 64,
    this.chapterTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.isCleared || tile.count <= 0) {
      return SizedBox(
        width: size,
        height: size,
      );
    }

    // Fixed uniform gap between tiles across all rows & columns
    final double tileGap = size < 40 ? 3.0 : 4.0;
    final double bevelDepth = isSelected ? 3.5 : 3.0;
    final double tileWidth = size - tileGap;
    final double tileHeight = size - tileGap - bevelDepth;

    // 1. Locked Obstacle Tile (3D Frosted Crystal Ice & Lock)
    if (tile.isObstacleLocked) {
      return SizedBox(
        width: size,
        height: size,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: tileGap / 2),
            child: Container(
              width: tileWidth,
              height: tileHeight,
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0284C7), width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF0369A1),
                    offset: Offset(0, 3.0),
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
      ),
    );
  }

    // 2. Playable 3D Natural Wood Letter Tile
    final bool isHighlighted = isTutorialHighlighted;
    final bool isDimmedTile = isDimmed && !isHighlighted && !isCountSpotlight;

    final selectedFace = chapterTheme?.primaryColor ?? AppColors.btnFaceBrown;
    final selectedBevel = chapterTheme?.bevelColor ?? AppColors.btnShadowBrown;
    final selectedBorder = chapterTheme?.borderColor ?? AppColors.btnBorderBrown;
    final selectedText = chapterTheme?.textColor ?? Colors.white;

    final Color faceColor = isSelected
        ? selectedFace
        : (isHinted
            ? AppColors.honeyGold
            : (isHighlighted
                ? const Color(0xFFCA7CFB)
                : (isDimmedTile ? const Color(0xFF2D2E38) : const Color(0xFFFBF1E6))));

    final Color bevelColor = isSelected
        ? selectedBevel
        : (isHinted
            ? AppColors.goldAccent
            : (isHighlighted
                ? const Color(0xFFA855F7)
                : (isDimmedTile ? const Color(0xFF1F2028) : const Color(0xFFEEB596))));

    final Color textColor = isSelected
        ? selectedText
        : (isHinted
            ? Colors.white
            : (isHighlighted
                ? Colors.white
                : (isDimmedTile ? const Color(0xFF64748B) : const Color(0xFF2C2523))));

    final Color borderColor = isCountSpotlight
        ? const Color(0xFFE11D48)
        : (isSelected
            ? selectedBorder
            : (isHighlighted
                ? const Color(0xFFF3E8FF)
                : (isDimmedTile ? const Color(0xFF333544) : Colors.white.withValues(alpha: 0.65))));

    Widget tileBox = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmedTile ? 0.30 : 1.0,
      child: Container(
        width: tileWidth,
        height: tileHeight,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: (isSelected || isCountSpotlight || isHighlighted) ? 2.2 : 1.0,
          ),
          boxShadow: [
            if (isCountSpotlight)
              const BoxShadow(
                color: Color(0x66E11D48),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            if (isHighlighted)
              const BoxShadow(
                color: Color(0x66CA7CFB),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            // 1. Solid 3D Extrusion Bevel Shadow (Độ dày gạch)
            BoxShadow(
              color: isCountSpotlight ? const Color(0xFFBE123C) : bevelColor,
              offset: Offset(0, bevelDepth),
              blurRadius: 0,
            ),
            // 2. Soft Ambient Drop Shadow (Bóng đổ mềm nổi lên nền)
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.20),
              offset: Offset(0, bevelDepth + 1.5),
              blurRadius: 3.5,
              spreadRadius: 0.2,
            ),
          ],
        ),
            child: Stack(
              children: [
                // Center Bold Letter
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
                            : (isHighlighted
                                ? [
                                    const Shadow(
                                      color: Color(0xFF7E22CE),
                                      offset: Offset(0, 1.5),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null),
                      ),
                    ),
                  ),
                ),

                // Subscript Tile Usage Badge (If > 0)
                if (tile.count > 0)
                  Positioned(
                    bottom: isCountSpotlight ? 2 : 4,
                    right: isCountSpotlight ? 2 : 6,
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
                        : Text(
                            '${tile.count}',
                            style: GoogleFonts.fredoka(
                              fontSize: size * 0.22,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2C2523),
                              height: 1.0,
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
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: tileGap / 2),
          child: tileBox,
        ),
      ),
    );
  }
}


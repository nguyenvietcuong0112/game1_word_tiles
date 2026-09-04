import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_manager.dart';

/// Master Central Reusable Wooden Design System Palette & Typography
class WoodenStyle {
  // Wood Plank Gradients (Golden Honey Oak)
  static const Color woodHighlight = Color(0xFFFFBA52);
  static const Color woodTop = Color(0xFFF3942B);
  static const Color woodMid = Color(0xFFD97213);
  static const Color woodDark = Color(0xFFB55208);
  static const Color woodBevel = Color(0xFF7A2F02);
  static const Color woodExtrusion = Color(0xFF4E1B00);

  // Inset Grooves & Recessed Panels
  static const Color grooveDark = Color(0xFF381401);
  static const Color grooveMid = Color(0xFF522105);
  static const Color grooveBorder = Color(0xFF280C00);

  // Carved Symbols & Text
  static const Color carvedDark = Color(0xFF381401);
  static const Color carvedShadowLight = Color(0xFFFFD48F);

  // Glowing Lime Green Crystal / Gem Fill
  static const Color greenGlowTop = Color(0xFFAEF82C);
  static const Color greenMid = Color(0xFF6DCB0C);
  static const Color greenDark = Color(0xFF3C8503);
  static const Color greenBorder = Color(0xFF225200);

  // Ruby / Warm Terracotta CTA
  static const Color rubyTop = Color(0xFFFF6247);
  static const Color rubyMid = Color(0xFFE03020);
  static const Color rubyDark = Color(0xFF9E1508);
  static const Color rubyBorder = Color(0xFF5E0B05);

  // Amber / Golden Highlight (Selected State)
  static const Color amberHighlightTop = Color(0xFFFFE066);
  static const Color amberHighlightMid = Color(0xFFFFB020);
  static const Color amberHighlightDark = Color(0xFFD96E06);

  // Star Colors
  static const Color starGoldTop = Color(0xFFFFDF00);
  static const Color starGoldMid = Color(0xFFF59E0B);
  static const Color starGoldDark = Color(0xFFD97706);
}

/// Central Asset Icon references and helper widgets
class WoodGameIcons {
  static const String iconCoin = 'assets/icons/icon_coin.webp';
  static const String iconHint = 'assets/icons/icon_hint.webp';
  static const String iconRocket = 'assets/icons/icon_rocket.webp';
  static const String iconExtraWords = 'assets/icons/icon_extra_words.webp';
  static const String iconShop = 'assets/icons/icon_shop.webp';
  static const String iconStar = 'assets/icons/icon_star.webp';
  static const String iconStarOff = 'assets/icons/icon_star_off.webp';
  static const String iconTrophy = 'assets/icons/icon_trophy.webp';

  // Carved wooden buttons (100% matched to reference)
  static const String btnSettings = 'assets/icons/wood_btn_settings.webp';
  static const String btnRestart = 'assets/icons/wood_btn_restart.webp';
  static const String btnClose = 'assets/icons/wood_btn_close.webp';
  static const String btnBack = 'assets/icons/wood_btn_back.webp';
  static const String btnSound = 'assets/icons/wood_btn_sound.webp';
  static const String btnMusic = 'assets/icons/wood_btn_music.webp';
  static const String btnHome = 'assets/icons/wood_btn_home.webp';
  static const String btnPlay = 'assets/icons/wood_btn_play.webp';
  static const String btnCheck = 'assets/icons/wood_btn_check.webp';
  static const String btnStar = 'assets/icons/wood_btn_star.webp';
  static const String btnHelp = 'assets/icons/wood_btn_help.webp';
  static const String btnLock = 'assets/icons/wood_btn_lock.webp';
  static const String btnInfo = 'assets/icons/wood_btn_info.webp';
  static const String btnVibrate = 'assets/icons/wood_btn_vibrate.webp';

  static Widget buttonImage(String assetPath, {double size = 48}) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  static Widget coin({double size = 20, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconCoin,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('🪙', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget hint({double size = 28, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconHint,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('💡', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget rocket({double size = 28, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconRocket,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('🚀', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget extraWords({double size = 28, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconExtraWords,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('📚', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget shop({double size = 28, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconShop,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('🎁', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget star({double size = 24, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconStar,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('⭐', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget starOff({double size = 24, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconStarOff,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('☆', style: TextStyle(fontSize: size * 0.8)),
    );
  }

  static Widget trophy({double size = 28, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      iconTrophy,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (c, e, s) => Text('🏆', style: TextStyle(fontSize: size * 0.8)),
    );
  }
}

typedef GoldenWoodColors = WoodenStyle;

/// Visual states for Word Tiles
enum WoodenTileState {
  normal,
  selected,
  pressed,
  correct,
  incorrect,
  disabled,
  completed,
}

/// 0. WOODEN TILE (Physical Wooden Puzzle Piece)
class WoodenTile extends StatelessWidget {
  final String letter;
  final WoodenTileState state;
  final int count;
  final bool isObstacleLocked;
  final int obstacleRequiredWords;
  final double size;
  final VoidCallback? onTap;

  const WoodenTile({
    super.key,
    required this.letter,
    this.state = WoodenTileState.normal,
    this.count = 0,
    this.isObstacleLocked = false,
    this.obstacleRequiredWords = 0,
    this.size = 64.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state == WoodenTileState.completed) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.88,
            height: size * 0.88,
            decoration: BoxDecoration(
              color: WoodenStyle.grooveDark.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(
                color: WoodenStyle.grooveBorder.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
          ),
        ),
      );
    }

    final double tileSize = size * 0.94;
    final double radius = tileSize * 0.26;

    // Obstacle Ice/Lock Tile
    if (isObstacleLocked) {
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
                colors: [Color(0xFFF0F9FF), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
              ),
              borderRadius: BorderRadius.circular(radius),
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
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 22, color: Color(0xFF0369A1)),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                        ),
                        child: Text(
                          '$obstacleRequiredWords',
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
                Positioned(
                  top: 3,
                  right: 5,
                  child: Text(
                    letter,
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

    // State styling
    final bool isSelected = state == WoodenTileState.selected;
    final bool isCorrect = state == WoodenTileState.correct;
    final bool isIncorrect = state == WoodenTileState.incorrect;
    final bool isDisabled = state == WoodenTileState.disabled;
    final bool isPressed = state == WoodenTileState.pressed;

    final double bevelOffset = isPressed ? 1.0 : (isSelected ? 3.8 : 2.8);
    final double scale = isSelected ? 1.15 : (isCorrect ? 1.08 : 1.0);

    final List<Color> gradientColors;
    final Color borderColor;
    final Color bevelColor;
    final Color textColor;
    final List<Shadow> letterShadows;

    if (isSelected) {
      gradientColors = const [
        Color(0xFFFFFAEE),
        Color(0xFFFFD043),
        Color(0xFFF58A07),
        Color(0xFFC75500),
      ];
      borderColor = const Color(0xFF5C2000);
      bevelColor = const Color(0xFF421500);
      textColor = Colors.white;
      letterShadows = const [
        Shadow(color: Color(0xFF4A1A00), offset: Offset(0, 1.8), blurRadius: 0),
        Shadow(color: Color(0x66000000), offset: Offset(0, 3.0), blurRadius: 2),
      ];
    } else if (isCorrect) {
      gradientColors = const [
        WoodenStyle.greenGlowTop,
        WoodenStyle.greenMid,
        WoodenStyle.greenDark,
      ];
      borderColor = WoodenStyle.greenBorder;
      bevelColor = const Color(0xFF1B3D00);
      textColor = Colors.white;
      letterShadows = const [
        Shadow(color: Color(0xFF143000), offset: Offset(0, 1.8)),
      ];
    } else if (isIncorrect) {
      gradientColors = const [
        Color(0xFFFFB2A6),
        Color(0xFFE56A54),
        Color(0xFFBD3822),
      ];
      borderColor = const Color(0xFF5E0B05);
      bevelColor = const Color(0xFF380703);
      textColor = Colors.white;
      letterShadows = const [
        Shadow(color: Color(0xFF380703), offset: Offset(0, 1.5)),
      ];
    } else if (isDisabled) {
      gradientColors = const [
        Color(0xFFE5D5C4),
        Color(0xFFCDB9A5),
        Color(0xFFB59D88),
      ];
      borderColor = const Color(0xFF7A6856);
      bevelColor = const Color(0xFF544638);
      textColor = const Color(0xFF6B5846);
      letterShadows = [
        Shadow(color: Colors.white.withValues(alpha: 0.6), offset: const Offset(0, 1.0)),
      ];
    } else {
      gradientColors = const [
        WoodenStyle.woodHighlight,
        WoodenStyle.woodTop,
        WoodenStyle.woodMid,
        WoodenStyle.woodDark,
      ];
      borderColor = WoodenStyle.woodBevel;
      bevelColor = WoodenStyle.woodExtrusion;
      textColor = WoodenStyle.carvedDark;
      letterShadows = const [
        Shadow(color: WoodenStyle.carvedShadowLight, offset: Offset(0, 1.2)),
        Shadow(color: Color(0xFF1F0900), offset: Offset(0, -1.0)),
      ];
    }

    Widget tileContent = Center(
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.8),
            boxShadow: [
              BoxShadow(
                color: bevelColor,
                offset: Offset(0, bevelOffset),
                blurRadius: 0,
              ),
              if (isSelected)
                const BoxShadow(
                  color: Color(0x66F58A07),
                  offset: Offset(0, 5),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: const Color(0x28000000),
                  offset: Offset(0, bevelOffset + 1.2),
                  blurRadius: 3,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                        stops: gradientColors.length == 4 ? const [0.0, 0.25, 0.70, 1.0] : null,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: (isSelected || isCorrect || isIncorrect) ? 0.22 : 0.36,
                    child: Image.asset(
                      'assets/images/golden_wood_texture.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: tileSize * 0.42,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: isSelected ? 0.55 : 0.42),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius * 0.75),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isSelected ? 0.45 : 0.25),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      letter,
                      style: GoogleFonts.fredoka(
                        fontSize: tileSize * 0.62,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.0,
                        letterSpacing: -0.5,
                        shadows: letterShadows,
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    bottom: 2.5,
                    right: 2.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5C2000) : WoodenStyle.grooveDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFD043) : WoodenStyle.woodHighlight,
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 1.2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.fredoka(
                          fontSize: tileSize * 0.22,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : WoodenStyle.woodHighlight,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: tileContent,
      ),
    );
  }
}

/// 1. Authentic Square Wooden Icon Button (Matching the 4x7 grid in reference image)
class WoodSquareButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget? icon;
  final IconData? iconData;
  final double size;
  final String? badgeText;
  final Color? badgeColor;
  final Color? iconColor;
  final String? label;
  final bool isSecondary;

  const WoodSquareButton({
    super.key,
    this.onTap,
    this.icon,
    this.iconData,
    this.size = 52,
    this.badgeText,
    this.badgeColor,
    this.iconColor,
    this.label,
    this.isSecondary = false,
  });

  @override
  State<WoodSquareButton> createState() => _WoodSquareButtonState();
}

class _WoodSquareButtonState extends State<WoodSquareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double radius = widget.size * 0.28;
    final double bevelOffset = _isPressed ? 1.0 : 3.8;

    Widget button = GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          AudioManager.playTileSelect(pitchIndex: 4);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 3D Wooden Block Frame with Bevel
          AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: GoldenWoodColors.woodBevel,
                width: 2.0,
              ),
              boxShadow: [
                // Deep Extrusion Shadow
                BoxShadow(
                  color: GoldenWoodColors.woodExtrusion,
                  offset: Offset(0, bevelOffset),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0x33000000),
                  offset: Offset(0, _isPressed ? 2.0 : 5.0),
                  blurRadius: _isPressed ? 2 : 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 2),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Base Golden Honey Oak Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          GoldenWoodColors.woodHighlight,
                          GoldenWoodColors.woodTop,
                          GoldenWoodColors.woodMid,
                          GoldenWoodColors.woodDark,
                        ],
                        stops: [0.0, 0.25, 0.70, 1.0],
                      ),
                    ),
                  ),

                  // Real Golden Wood Grain Texture
                  Opacity(
                    opacity: 0.38,
                    child: Image.asset(
                      'assets/images/golden_wood_texture.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),

                  // Inset Carved Inner Frame Rim
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius * 0.75),
                          border: Border.all(
                            color: GoldenWoodColors.woodHighlight.withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Specular Gloss Highlight
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.size * 0.40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.42),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Carved Icon with Deep Inset Shadow + Bottom Highlight
                  Center(
                    child: widget.icon ??
                        (widget.iconData != null
                            ? Icon(
                                widget.iconData,
                                color: widget.iconColor ?? GoldenWoodColors.carvedDark,
                                size: widget.size * 0.52,
                                shadows: const [
                                  // Bottom Light Edge (gives deeply engraved 3D look)
                                  Shadow(
                                    color: GoldenWoodColors.carvedShadowLight,
                                    offset: Offset(0, 1.2),
                                    blurRadius: 0,
                                  ),
                                  // Top Inset Dark Drop
                                  Shadow(
                                    color: Color(0xFF1F0900),
                                    offset: Offset(0, -1.0),
                                    blurRadius: 0,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          ),

          // Attached Subscript Badge Pill (e.g. 80 Coins, Claim)
          if (widget.badgeText != null)
            Positioned(
              bottom: -5,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: widget.badgeColor == null
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [GoldenWoodColors.rubyTop, GoldenWoodColors.rubyMid],
                        )
                      : null,
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: GoldenWoodColors.woodExtrusion, width: 1.4),
                  boxShadow: const [
                    BoxShadow(
                      color: GoldenWoodColors.woodExtrusion,
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  widget.badgeText!,
                  style: GoogleFonts.fredoka(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF4A0E13),
                        offset: Offset(0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          SizedBox(height: 4.h),
          Text(
            widget.label!,
            style: GoogleFonts.fredoka(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: GoldenWoodColors.carvedDark,
              shadows: const [
                Shadow(
                  color: GoldenWoodColors.carvedShadowLight,
                  offset: Offset(0, 1.0),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return button;
  }
}

/// Circular Wooden Action Button alias using WoodSquareButton with round shape
class WoodCircularButton extends WoodSquareButton {
  const WoodCircularButton({
    super.key,
    super.onTap,
    super.icon,
    super.iconData,
    super.size = 52,
    super.badgeText,
    super.badgeColor,
    super.iconColor,
    super.label,
    super.isSecondary = false,
  });
}

/// Carved Wooden Button using authentic high-fidelity reference assets
class WoodCarvedIconButton extends StatefulWidget {
  final String assetPath;
  final VoidCallback? onTap;
  final double size;
  final String? badgeText;
  final Color? badgeColor;

  const WoodCarvedIconButton({
    super.key,
    required this.assetPath,
    this.onTap,
    this.size = 48,
    this.badgeText,
    this.badgeColor,
  });

  @override
  State<WoodCarvedIconButton> createState() => _WoodCarvedIconButtonState();
}

class _WoodCarvedIconButtonState extends State<WoodCarvedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          AudioManager.playTileSelect(pitchIndex: 3);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset(
                widget.assetPath,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (widget.badgeText != null)
            Positioned(
              bottom: -4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: widget.badgeColor == null
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [GoldenWoodColors.rubyTop, GoldenWoodColors.rubyMid],
                        )
                      : null,
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: GoldenWoodColors.woodExtrusion, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: GoldenWoodColors.woodExtrusion,
                      offset: Offset(0, 1.2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  widget.badgeText!,
                  style: GoogleFonts.fredoka(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 2. Authentic Wooden Plank CTA Button (Matching RESTART, OPTION, EXIT, PLAY from reference)
class WoodPlankButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final bool isGreen;
  final bool isRuby;
  final Color? textColor;

  const WoodPlankButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.fontSize,
    this.isGreen = false,
    this.isRuby = false,
    this.textColor,
  });

  @override
  State<WoodPlankButton> createState() => _WoodPlankButtonState();
}

class _WoodPlankButtonState extends State<WoodPlankButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double defaultH = widget.height ?? 54.h;
    final double bevelOffset = _isPressed ? 1.0 : 4.0;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          AudioManager.playTileSelect(pitchIndex: 4);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: defaultH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: widget.isGreen
                ? GoldenWoodColors.greenBorder
                : (widget.isRuby
                    ? GoldenWoodColors.rubyBorder
                    : GoldenWoodColors.woodBevel),
            width: 2.2,
          ),
          boxShadow: [
            // 3D Bottom Wood Plank Extrusion
            BoxShadow(
              color: widget.isGreen
                  ? const Color(0xFF1B4000)
                  : (widget.isRuby
                      ? const Color(0xFF5E0B05)
                      : GoldenWoodColors.woodExtrusion),
              offset: Offset(0, bevelOffset),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0x33000000),
              offset: Offset(0, _isPressed ? 2.0 : 5.0),
              blurRadius: _isPressed ? 2 : 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19.r),
          child: Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: [
              // 1. Base Gradient (Golden Oak / Glowing Green / Ruby)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isGreen
                          ? const [
                              GoldenWoodColors.greenGlowTop,
                              GoldenWoodColors.greenMid,
                              GoldenWoodColors.greenDark,
                            ]
                          : (widget.isRuby
                              ? const [
                                  GoldenWoodColors.rubyTop,
                                  GoldenWoodColors.rubyMid,
                                  GoldenWoodColors.rubyDark,
                                ]
                              : const [
                                  GoldenWoodColors.woodHighlight,
                                  GoldenWoodColors.woodTop,
                                  GoldenWoodColors.woodMid,
                                  GoldenWoodColors.woodDark,
                                ]),
                    ),
                  ),
                ),
              ),

              // 2. Real Golden Wood Grain Texture Overlay
              Positioned.fill(
                child: Opacity(
                  opacity: (widget.isGreen || widget.isRuby) ? 0.20 : 0.38,
                  child: Image.asset(
                    'assets/images/golden_wood_texture.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 3. Top Specular Gloss Highlight Strip
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: defaultH * 0.42,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.48),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Inset Light Rim at Top
              Positioned(
                top: 0.5,
                left: 8,
                right: 8,
                height: 1.2,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),

              // 5. Carved Bold Typography
              Padding(
                padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final Color effectiveTextColor = widget.textColor ??
                          ((widget.isGreen || widget.isRuby)
                              ? Colors.white
                              : GoldenWoodColors.carvedDark);
                      final bool isWhiteText = effectiveTextColor == Colors.white;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: effectiveTextColor,
                              size: widget.fontSize ?? 22.sp,
                              shadows: [
                                Shadow(
                                  color: (widget.isGreen || widget.isRuby)
                                      ? const Color(0xFF1E5001)
                                      : (isWhiteText
                                          ? const Color(0xFF260C00)
                                          : GoldenWoodColors.carvedShadowLight),
                                  offset: const Offset(0, 1.5),
                                ),
                                if (isWhiteText && !widget.isGreen && !widget.isRuby)
                                  const Shadow(
                                    color: Color(0x66000000),
                                    offset: Offset(0, 2.5),
                                    blurRadius: 2,
                                  ),
                              ],
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            widget.text,
                            style: GoogleFonts.fredoka(
                              fontSize: widget.fontSize ?? 19.sp,
                              fontWeight: FontWeight.w900,
                              color: effectiveTextColor,
                              letterSpacing: 1.5,
                              shadows: isWhiteText && !widget.isGreen && !widget.isRuby
                                  ? const [
                                      Shadow(
                                        color: Color(0xFF1F0900),
                                        offset: Offset(0, 2.0),
                                        blurRadius: 1,
                                      ),
                                      Shadow(
                                        color: Color(0x66000000),
                                        offset: Offset(0, 3.5),
                                        blurRadius: 3,
                                      ),
                                    ]
                                  : [
                                      Shadow(
                                        color: (widget.isGreen || widget.isRuby)
                                            ? const Color(0xFF1E5001)
                                            : GoldenWoodColors.carvedShadowLight,
                                        offset: const Offset(0, 1.5),
                                      ),
                                      if (!(widget.isGreen || widget.isRuby))
                                        const Shadow(
                                          color: Color(0xFF1F0900),
                                          offset: Offset(0, -1.0),
                                        ),
                                    ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias for WoodPlankButton to support existing WoodCtaButton calls
class WoodCtaButton extends WoodPlankButton {
  const WoodCtaButton({
    super.key,
    required super.text,
    super.onTap,
    super.icon,
    super.width,
    super.height,
    super.padding,
    super.fontSize,
    super.isGreen = false,
    bool isAmber = false,
  }) : super(isRuby: !isGreen && !isAmber);
}

/// 3. Authentic Slotted Wooden Progress Bar with Lime Green Juice (Top left in reference)
class WoodProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? text;
  final double height;
  final double? width;

  const WoodProgressBar({
    super.key,
    required this.progress,
    this.text,
    this.height = 24,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.5),
        border: Border.all(
          color: GoldenWoodColors.woodBevel,
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: GoldenWoodColors.woodExtrusion,
            offset: Offset(0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height * 0.5 - 2),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Outer Frame Golden Wood Texture
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GoldenWoodColors.woodTop,
                      GoldenWoodColors.woodMid,
                      GoldenWoodColors.woodDark,
                    ],
                  ),
                ),
              ),
            ),

            // Inner Recessed Dark Groove Slot
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: GoldenWoodColors.grooveDark,
                    borderRadius: BorderRadius.circular(height * 0.4),
                    border: Border.all(color: GoldenWoodColors.grooveBorder, width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 1.5),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Glowing Juicy Lime Green Capsule Fill
            Padding(
              padding: const EdgeInsets.all(2.5),
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height * 0.4),
                    border: Border.all(color: GoldenWoodColors.greenBorder, width: 1.0),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        GoldenWoodColors.greenGlowTop,
                        GoldenWoodColors.greenMid,
                        GoldenWoodColors.greenDark,
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x886DCB0C),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Top Gloss highlight on green bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: height * 0.40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.6),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Optional Progress Text
            if (text != null)
              Positioned.fill(
                child: Center(
                  child: Text(
                    text!,
                    style: GoogleFonts.fredoka(
                      fontSize: (height * 0.55).sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF1E5001),
                          offset: Offset(0, 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 4. Authentic Golden Wood Signboard / Board Dialog (Matching the MENU board in reference)
class WoodSignboardDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const WoodSignboardDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Main Golden Wood Board Body
          Container(
            width: width ?? double.infinity,
            margin: EdgeInsets.only(top: 24.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: GoldenWoodColors.woodBevel,
                width: 2.8,
              ),
              boxShadow: const [
                // 3D Bottom Wood Extrusion
                BoxShadow(
                  color: GoldenWoodColors.woodExtrusion,
                  offset: Offset(0, 6.0),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x55000000),
                  offset: Offset(0, 10),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21.r),
              child: Stack(
                children: [
                  // Outer Board Honey Oak Wood
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GoldenWoodColors.woodHighlight,
                            GoldenWoodColors.woodTop,
                            GoldenWoodColors.woodMid,
                            GoldenWoodColors.woodDark,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Real Golden Wood Grain
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.38,
                      child: Image.asset(
                        'assets/images/golden_wood_texture.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Inner Recessed Dark Wood Inset Panel
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 28.h, 10.w, 10.h),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: GoldenWoodColors.grooveBorder,
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 2.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          children: [
                            // Dark Roasted Inset Face
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      GoldenWoodColors.grooveMid,
                                      GoldenWoodColors.grooveDark,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Real Wood Grain on Inset
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.40,
                                child: Image.asset(
                                  'assets/images/golden_wood_texture.webp',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                            ),

                            // Dialog Content
                            Padding(
                              padding: padding ?? EdgeInsets.all(16.r),
                              child: child,
                            ),
                          ],
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

          // 2. Top Curved Title Plank ("MENU" / Title from reference)
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: GoldenWoodColors.woodBevel,
                  width: 2.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: GoldenWoodColors.woodExtrusion,
                    offset: Offset(0, 3.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base Wood Gradient
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              GoldenWoodColors.woodHighlight,
                              GoldenWoodColors.woodTop,
                              GoldenWoodColors.woodMid,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Wood Grain on Header
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.40,
                        child: Image.asset(
                          'assets/images/golden_wood_texture.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // Title Text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 7.h),
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: GoldenWoodColors.carvedDark,
                          letterSpacing: 1.8,
                          shadows: const [
                            Shadow(
                              color: GoldenWoodColors.carvedShadowLight,
                              offset: Offset(0, 1.5),
                            ),
                            Shadow(
                              color: Color(0xFF1F0900),
                              offset: Offset(0, -1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top-Right Wood Carved Close Button (Reference Style)
          if (onClose != null)
            Positioned(
              top: 14.h,
              right: 0,
              child: WoodCarvedIconButton(
                size: 40.r,
                assetPath: WoodGameIcons.btnClose,
                onTap: onClose,
              ),
            ),
        ],
      ),
    );
  }
}

/// 5. Handcrafted Sleek Golden Wood Board Tray
class WoodBoardTray extends StatelessWidget {
  final Widget child;

  const WoodBoardTray({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: GoldenWoodColors.woodBevel,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: GoldenWoodColors.woodExtrusion,
            offset: Offset(0, 3.0),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x28000000),
            offset: Offset(0, 5),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Stack(
          children: [
            // Inner Warm Wood Plank Canvas Face
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFDF5E6),
                      Color(0xFFF8E7CE),
                      Color(0xFFEED3B0),
                    ],
                  ),
                ),
              ),
            ),

            // Wood Grain on Board Canvas
            Positioned.fill(
              child: Opacity(
                opacity: 0.20,
                child: Image.asset(
                  'assets/images/golden_wood_texture.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Inner Grid Content with uniform balanced padding
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. Wood Plank Card Container
class WoodPlankContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const WoodPlankContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(20.r);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(
          color: GoldenWoodColors.woodBevel,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: GoldenWoodColors.woodExtrusion,
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // Base Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GoldenWoodColors.woodHighlight,
                      GoldenWoodColors.woodTop,
                      GoldenWoodColors.woodMid,
                      GoldenWoodColors.woodDark,
                    ],
                  ),
                ),
              ),
            ),

            // Real Wood Grain
            Positioned.fill(
              child: Opacity(
                opacity: 0.38,
                child: Image.asset(
                  'assets/images/golden_wood_texture.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Top Specular Highlight Rim
            Positioned(
              top: 0.5,
              left: 10,
              right: 10,
              height: 1.2,
              child: Container(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            // Content
            Padding(
              padding: padding ?? EdgeInsets.all(16.r),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// REUSABLE SYSTEM EXTENSIONS & ALIASES
/// ---------------------------------------------------------------------------

typedef WoodenBoard = WoodBoardTray;
typedef WoodenProgressBar = WoodProgressBar;
typedef WoodenDialog = WoodSignboardDialog;
typedef WoodenPanel = WoodPlankContainer;

enum WoodenButtonVariant {
  primary,
  action,
  alert,
}

class WoodenButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final WoodenButtonVariant variant;
  final bool isEnabled;
  final Color? textColor;

  const WoodenButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.fontSize,
    this.variant = WoodenButtonVariant.primary,
    this.isEnabled = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return WoodPlankButton(
      text: text,
      onTap: isEnabled ? onTap : null,
      icon: icon,
      width: width,
      height: height,
      padding: padding,
      fontSize: fontSize,
      isGreen: variant == WoodenButtonVariant.action,
      isRuby: variant == WoodenButtonVariant.alert,
      textColor: textColor,
    );
  }
}

class WoodenIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? icon;
  final IconData? iconData;
  final double size;
  final String? badgeText;
  final Color? badgeColor;
  final Color? iconColor;
  final String? label;
  final bool isCircular;

  const WoodenIconButton({
    super.key,
    this.onTap,
    this.icon,
    this.iconData,
    this.size = 52,
    this.badgeText,
    this.badgeColor,
    this.iconColor,
    this.label,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircular) {
      return WoodCircularButton(
        onTap: onTap,
        icon: icon,
        iconData: iconData,
        size: size,
        badgeText: badgeText,
        badgeColor: badgeColor,
        iconColor: iconColor,
        label: label,
      );
    }
    return WoodSquareButton(
      onTap: onTap,
      icon: icon,
      iconData: iconData,
      size: size,
      badgeText: badgeText,
      badgeColor: badgeColor,
      iconColor: iconColor,
      label: label,
    );
  }
}

/// 3D Wooden Star with Golden Face, Deep Extrusion, and Glowing Gem Center
class WoodenStar extends StatelessWidget {
  final bool isEarned;
  final double size;

  const WoodenStar({
    super.key,
    required this.isEarned,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        isEarned ? WoodGameIcons.iconStar : WoodGameIcons.iconStarOff,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Reusable Wooden Level/Indicator Badge
class WoodenBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? textColor;
  final VoidCallback? onTap;

  const WoodenBadge({
    super.key,
    required this.text,
    this.icon,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: WoodenStyle.woodBevel, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: WoodenStyle.woodExtrusion,
              offset: Offset(0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        WoodenStyle.woodHighlight,
                        WoodenStyle.woodTop,
                        WoodenStyle.woodMid,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/images/golden_wood_texture.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16.sp, color: textColor ?? WoodenStyle.carvedDark),
                      SizedBox(width: 5.w),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.fredoka(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor ?? WoodenStyle.carvedDark,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: textColor == null
                                ? WoodenStyle.carvedShadowLight
                                : WoodenStyle.woodExtrusion,
                            offset: const Offset(0, 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Wooden Coin Currency Counter
class WoodenCurrency extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const WoodenCurrency({
    super.key,
    required this.coins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: WoodenStyle.woodBevel, width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: WoodenStyle.woodExtrusion,
              offset: Offset(0, 2.2),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF4A2007),
                        Color(0xFF381401),
                        Color(0xFF260C00),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: Image.asset(
                    'assets/images/golden_wood_texture.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WoodGameIcons.coin(size: 18.sp),
                    SizedBox(width: 5.w),
                    Text(
                      '$coins',
                      style: GoogleFonts.fredoka(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF1F0900),
                            offset: Offset(0, 1.2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // 1. Backgrounds (Warm Sandalwood & Rich Linen Canvas with High Contrast)
  static const Color bgCanvas = Color(0xFFEADBCE);
  static const Color bgCanvasSecondary = Color(0xFFDECBB8);
  static const Color bgSkyGradientStart = Color(0xFFEDE0D1);
  static const Color bgSkyGradientEnd = Color(0xFFDAC7B2);
  static const Color cardPeach = Color(0xFFF5EBE1);
  static const Color cardPeachLight = Color(0xFFFCF7F0);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // 2. Outlines & Borders (Warm Wood Grain & Cocoa Borders)
  static const Color borderDark = Color(0xFFB89B7E);
  static const Color borderSubtle = Color(0xFFD9C6B0);
  static const Color borderSelected = Color(0xFF854B26);

  // 3. Primary Accents - Rich Roasted Cocoa Caramel (Punchy, High Contrast Action Color)
  static const Color terracotta = Color(0xFFA66640); // Rich Roasted Cocoa Face
  static const Color terracottaLight = Color(0xFFBD7C54); // Caramel Highlight
  static const Color terracottaDark = Color(0xFF854B26); // Deep Roasted Shadow

  // 3.1. 3D Woodcraft Header Round Buttons (Rich Cocoa & Birch Ring)
  static const Color btnRingBg = Color(0xFFF0DEC9);
  static const Color btnRingBorder = Color(0xFFDFC4AA);
  static const Color btnRingShadow = Color(0xFFC7A588);
  static const Color btnFaceBrown = Color(0xFFA66640);
  static const Color btnBorderBrown = Color(0xFF8F522C);
  static const Color btnShadowBrown = Color(0xFF7B411D);

  // 4. Success Green & Rewards
  static const Color sageGreen = Color(0xFF5B8E67); // Earthy Forest Moss Green
  static const Color sageGreenLight = Color(0xFF81B28D);
  static const Color sageGreenDark = Color(0xFF3F6949);
  static const Color successGreen = sageGreen;
  static const Color successGreenDark = sageGreenDark;

  // 4.1. Gold & Coins (Warm Amber Honey)
  static const Color goldAccent = Color(0xFFD9822B);
  static const Color honeyGold = Color(0xFFE5A638);
  static const Color butterCream = Color(0xFFFEF3C7);
  static const Color gold = goldAccent;

  // 5. Typography (Rich Deep Carved Walnut on Wood Canvas)
  static const Color headerBrown = Color(0xFF5C2E14); // Deep Walnut Header
  static const Color subHeaderBrown = Color(0xFF8C5838); // Warm Teak Subheader
  static const Color textDark = Color(0xFF381E0F); // Deep Carved Coffee Text
  static const Color textMuted = Color(0xFF8A6E59); // Muted Wood Brown
  static const Color textLight = Color(0xFFFFFFFF);

  // 6. Board & Word Tiles (Natural Birch Woodcraft 3D Tiles)
  static const Color tileFace = Color(0xFFFFFDF9); // Natural Birch Top
  static const Color tileBevel = Color(0xFFDFCBB7); // Natural Birch 3D Bevel
  static const Color tileText = Color(0xFF4A2610); // Carved Walnut Letter

  // Selected Tile (Rich Roasted Cocoa 3D)
  static const Color tileSelectedFace = Color(0xFFA66640);
  static const Color tileSelectedBevel = Color(0xFF7B411D);
  static const Color tileSelectedText = Colors.white;

  // Swipe Path (Rich Warm Amber Honey Wood Beam)
  static const Color swipePathGlow = Color(0xFFC97C3E);

  // Ice Obstacle Colors (Frosted Crystal Wood)
  static const Color iceTileFace = Color(0xFFEDF5F9);
  static const Color iceTileBevel = Color(0xFFB8D8E8);
  static const Color iceGlow = Color(0xFF7CB9D8);

  // Crate Obstacle Colors
  static const Color crateFace = Color(0xFFD4A373);
  static const Color crateBevel = Color(0xFFA97142);
  static const Color crateDark = Color(0xFF7A4B23);

  // Legacy mappings for full compatibility
  static const Color primaryGreen = terracotta;
  static const Color primaryGreenLight = terracottaLight;
  static const Color primaryGreenDark = terracottaDark;
  static const Color bgTop = bgCanvas;
  static const Color bgBottom = bgCanvasSecondary;
  static const Color cardBg = cardPeach;
  static const Color cardBgLight = cardPeachLight;
  static const Color mintGreen = sageGreen;
  static const Color pastelPink = Color(0xFFD48B70);
  static const Color pastelPinkBevel = Color(0xFFB56A50);
  static const Color pastelLavender = Color(0xFFAB8476);
  static const Color pastelLavenderLight = Color(0xFFD6BCB2);
  static const Color pastelLavenderDark = Color(0xFF805A4D);
  static const Color pastelSky = Color(0xFF9EB5C2);
  static const Color pastelSkyLight = Color(0xFFD3E0E8);
  static const Color pastelSkyDark = Color(0xFF6B8B9E);

  /// Natural Warm Wood Palette for Word Tiles (Clean, Minimalist, Uniform)
  static const List<TileColorTheme> woodTileThemes = [
    TileColorTheme(
      face: Color(0xFFFFFDF9), // Natural Birch Wood
      bevel: Color(0xFFE6D6C4),
      textColor: Color(0xFF4A2610),
    ),
    TileColorTheme(
      face: Color(0xFFFAF3EB), // Warm Maple Wood
      bevel: Color(0xFFE2D0BC),
      textColor: Color(0xFF4A2610),
    ),
    TileColorTheme(
      face: Color(0xFFFDF7F0), // Soft Oak Wood
      bevel: Color(0xFFE4D3BF),
      textColor: Color(0xFF4A2610),
    ),
  ];

  static TileColorTheme getTileThemeForPosition(int row, int col) {
    final index = (row + col) % woodTileThemes.length;
    return woodTileThemes[index];
  }
}

class TileColorTheme {
  final Color face;
  final Color bevel;
  final Color textColor;

  const TileColorTheme({
    required this.face,
    required this.bevel,
    required this.textColor,
  });
}

class AppThemes {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      primaryColor: AppColors.terracotta,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        secondary: AppColors.goldAccent,
        surface: AppColors.cardPeach,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(base.textTheme),
    );
  }
}

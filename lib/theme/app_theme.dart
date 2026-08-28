import 'package:flutter/material.dart';

class AppColors {
  // 1. Backgrounds (Warm Cream / Paper Canvas)
  static const Color bgCanvas = Color(0xFFFFF9F0);
  static const Color bgCanvasSecondary = Color(0xFFFAF2E6);
  static const Color cardPeach = Color(0xFFF8E7D5);
  static const Color cardPeachLight = Color(0xFFFDF4EA);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // 2. Outlines & Strokes (Clean Crisp Dark 2px Borders)
  static const Color borderDark = Color(0xFF2B2824);
  static const Color borderSubtle = Color(0xFFD6C8B8);
  static const Color borderSelected = Color(0xFFC85332);

  // 3. Brand Accents
  static const Color terracotta = Color(0xFFC85332);
  static const Color terracottaDark = Color(0xFF9E3A20);
  static const Color terracottaLight = Color(0xFFE27150);

  // 4. Success Green & Rewards
  static const Color successGreen = Color(0xFF43A047);
  static const Color successGreenDark = Color(0xFF2E7D32);
  static const Color goldAccent = Color(0xFFE67E22);

  // 5. Typography
  static const Color textDark = Color(0xFF241F1A);
  static const Color textMuted = Color(0xFF7A7065);
  static const Color textLight = Color(0xFFFFFFFF);

  // 6. Tiles
  static const Color tileFace = Color(0xFFFFFDF9);
  static const Color tileBevel = Color(0xFFEADCCF);
  static const Color tileText = Color(0xFF241F1A);

  // Selected Tile
  static const Color tileSelectedFace = Color(0xFFC85332);
  static const Color tileSelectedBevel = Color(0xFF9E3A20);
  static const Color tileSelectedText = Colors.white;

  // Legacy mappings for compatibility
  static const Color primaryGreen = terracotta;
  static const Color primaryGreenLight = terracottaLight;
  static const Color primaryGreenDark = terracottaDark;
  static const Color bgTop = bgCanvas;
  static const Color bgBottom = bgCanvasSecondary;
  static const Color cardBg = cardPeach;
  static const Color cardBgLight = cardPeachLight;
  static const Color gold = goldAccent;
}

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      primaryColor: AppColors.terracotta,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        secondary: AppColors.goldAccent,
        surface: AppColors.cardPeach,
      ),
      fontFamily: 'Roboto',
    );
  }
}

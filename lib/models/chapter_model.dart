import 'dart:math';
import 'package:flutter/material.dart';
import '../services/chapter_loader.dart';

/// Information about a chapter and the level's position within it.
class ChapterInfo {
  final int chapterNumber;
  final int levelInChapter;
  final int totalLevelsInChapter;
  final bool isChapterCompleted;
  final int startLevel;
  final int endLevel;

  const ChapterInfo({
    required this.chapterNumber,
    required this.levelInChapter,
    required this.totalLevelsInChapter,
    required this.isChapterCompleted,
    required this.startLevel,
    required this.endLevel,
  });

  String get chapterImage => ChapterTheme.getImagePath(chapterNumber);

  /// Map levelNumber to ChapterInfo:
  /// - Chapter 1: Levels 1 - 5 (5 levels)
  /// - Chapter 2+: 10 levels each (Chapter 2: 6 - 15, Chapter 3: 16 - 25, etc.)
  static ChapterInfo forLevel(int levelNumber) {
    if (levelNumber <= 5) {
      return ChapterInfo(
        chapterNumber: 1,
        levelInChapter: levelNumber,
        totalLevelsInChapter: 5,
        isChapterCompleted: levelNumber == 5,
        startLevel: 1,
        endLevel: 5,
      );
    }

    final offset = levelNumber - 5;
    final chIdx = (offset - 1) ~/ 10;
    final chNum = chIdx + 2;
    final lvlInCh = ((offset - 1) % 10) + 1;
    final start = 5 + chIdx * 10 + 1;
    final end = 5 + (chIdx + 1) * 10;

    return ChapterInfo(
      chapterNumber: chNum,
      levelInChapter: lvlInCh,
      totalLevelsInChapter: 10,
      isChapterCompleted: lvlInCh == 10,
      startLevel: start,
      endLevel: end,
    );
  }

  /// Whether the specified level is the last level of its chapter.
  static bool isLastLevelOfChapter(int levelNumber) {
    if (levelNumber <= 0) return false;
    if (levelNumber == 5) return true;
    if (levelNumber > 5) {
      return (levelNumber - 5) % 10 == 0;
    }
    return false;
  }
}

/// Thematic visual metadata for a chapter's artwork and landscape background.
class ChapterTheme {
  final int chapterNumber;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> skyGradient;
  final List<Color> mountainGradient;
  final List<Color> foregroundGradient;
  final Color sunColor;
  final Color ambientColor;
  final Color primaryColor;
  final int rewardCoins;
  static const int totalChapterImages = 18;

  const ChapterTheme({
    required this.chapterNumber,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.skyGradient,
    required this.mountainGradient,
    required this.foregroundGradient,
    required this.sunColor,
    required this.ambientColor,
    this.primaryColor = const Color(0xFF3D6BFF),
    this.rewardCoins = 50,
  });

  /// Light highlight tint (e.g. for gradients on buttons & solved target word boxes)
  Color get lightColor {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  /// Dark 3D bevel bottom lip and shadow
  Color get bevelColor {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  /// Crisp outline border
  Color get borderColor {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
  }

  /// High-contrast text color: deep walnut for bright Yellow (#FEDD39), crisp white for vibrant colors
  Color get textColor =>
      primaryColor.computeLuminance() > 0.55 ? const Color(0xFF381E0F) : Colors.white;

  /// Path to chapter artwork image (1..18 with automatic looping from chapters.json)
  String get imageAsset => getImagePath(chapterNumber);

  /// Get chapter image asset path for any chapter number (loops over chapters in chapters.json)
  static String getImagePath(int chapterNumber) {
    return ChapterLoader.getImagePath(chapterNumber);
  }

  static const List<ChapterTheme> _allThemes = [
    // Chapter 1: Fuji Lake 🗻
    ChapterTheme(
      chapterNumber: 1,
      title: 'Fuji Lake',
      subtitle: 'Sunrise Reflection',
      emoji: '🗻',
      skyGradient: [Color(0xFFFFD1A9), Color(0xFFF9A88F), Color(0xFF8E9AAF)],
      mountainGradient: [Color(0xFF4A5568), Color(0xFF2D3748)],
      foregroundGradient: [Color(0xFF2C4A52), Color(0xFF1E3A42)],
      sunColor: Color(0xFFFF6B6B),
      ambientColor: Color(0xFFF4A261),
      rewardCoins: 50,
    ),
    // Chapter 2: Alpine Forest 🌲
    ChapterTheme(
      chapterNumber: 2,
      title: 'Alpine Forest',
      subtitle: 'Mountain Trail',
      emoji: '🌲',
      skyGradient: [Color(0xFFB5EAD7), Color(0xFF70A9A1), Color(0xFF40798C)],
      mountainGradient: [Color(0xFF2D5542), Color(0xFF1F3B2E)],
      foregroundGradient: [Color(0xFF1B3B2B), Color(0xFF132A1F)],
      sunColor: Color(0xFFFDE68A),
      ambientColor: Color(0xFF34D399),
      rewardCoins: 50,
    ),
    // Chapter 3: Golden Valley 🍁
    ChapterTheme(
      chapterNumber: 3,
      title: 'Golden Valley',
      subtitle: 'Autumn Mist',
      emoji: '🍁',
      skyGradient: [Color(0xFFFEE180), Color(0xFFFA8B60), Color(0xFFD35400)],
      mountainGradient: [Color(0xFF8B4513), Color(0xFF5C2C16)],
      foregroundGradient: [Color(0xFF4A2511), Color(0xFF32170A)],
      sunColor: Color(0xFFFFD54F),
      ambientColor: Color(0xFFF59E0B),
      rewardCoins: 50,
    ),
    // Chapter 4: Azure Coast 🌊
    ChapterTheme(
      chapterNumber: 4,
      title: 'Azure Coast',
      subtitle: 'Coral Shores',
      emoji: '🌊',
      skyGradient: [Color(0xFF90E0EF), Color(0xFF00B4D8), Color(0xFF0077B6)],
      mountainGradient: [Color(0xFF023E8A), Color(0xFF03045E)],
      foregroundGradient: [Color(0xFF002855), Color(0xFF001845)],
      sunColor: Color(0xFFFFF3B0),
      ambientColor: Color(0xFF38BDF8),
      rewardCoins: 50,
    ),
    // Chapter 5: Celestial Peak 🌌
    ChapterTheme(
      chapterNumber: 5,
      title: 'Celestial Peak',
      subtitle: 'Aurora Borealis',
      emoji: '🌌',
      skyGradient: [Color(0xFF0B092B), Color(0xFF1D1A44), Color(0xFF3B1E54)],
      mountainGradient: [Color(0xFF1A153A), Color(0xFF0D0A22)],
      foregroundGradient: [Color(0xFF080616), Color(0xFF03020A)],
      sunColor: Color(0xFFA7F3D0),
      ambientColor: Color(0xFFA855F7),
      rewardCoins: 50,
    ),
    // Chapter 6: Sakura Garden 🌸
    ChapterTheme(
      chapterNumber: 6,
      title: 'Sakura Garden',
      subtitle: 'Spring Petals',
      emoji: '🌸',
      skyGradient: [Color(0xFFFFDFD3), Color(0xFFFFB7B2), Color(0xFFE0BBE4)],
      mountainGradient: [Color(0xFF5D4E6D), Color(0xFF392F47)],
      foregroundGradient: [Color(0xFF2C2236), Color(0xFF1B1424)],
      sunColor: Color(0xFFFEC8D8),
      ambientColor: Color(0xFFF472B6),
      rewardCoins: 50,
    ),
  ];

  static ChapterTheme forChapter(int chapterNumber) {
    final effectiveNum = chapterNumber <= 0 ? 1 : chapterNumber;
    final jsonChapter = ChapterLoader.getChapter(effectiveNum);
    final themeIndex = (effectiveNum - 1) % _allThemes.length;
    final baseTheme = _allThemes[themeIndex];

    final isJsonLoaded = ChapterLoader.chapters.isNotEmpty;
    final title = isJsonLoaded ? jsonChapter.title : baseTheme.title;
    final subtitle = isJsonLoaded ? jsonChapter.subtitle : baseTheme.subtitle;

    return ChapterTheme(
      chapterNumber: effectiveNum,
      title: title,
      subtitle: subtitle,
      emoji: baseTheme.emoji,
      skyGradient: baseTheme.skyGradient,
      mountainGradient: baseTheme.mountainGradient,
      foregroundGradient: baseTheme.foregroundGradient,
      sunColor: baseTheme.sunColor,
      ambientColor: baseTheme.ambientColor,
      primaryColor: jsonChapter.primaryColor,
      rewardCoins: jsonChapter.rewardCoins,
    );
  }
}

/// Custom painter that renders a beautiful stylized landscape painting
/// for a chapter's artwork.
class ChapterLandscapePainter extends CustomPainter {
  final ChapterTheme theme;
  final double progress; // 0.0 -> 1.0 (for partial reveal if needed)
  final bool showSunGlow;

  const ChapterLandscapePainter({
    required this.theme,
    this.progress = 1.0,
    this.showSunGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.skyGradient,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Celestial Body (Sun/Moon/Glow)
    if (showSunGlow) {
      final sunCenter = Offset(w * 0.72, h * 0.28);
      final sunRadius = min(w, h) * 0.16;

      // Outer diffuse corona
      final coronaPaint = Paint()
        ..color = theme.sunColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(sunCenter, sunRadius * 1.8, coronaPaint);

      // Mid aura
      final auraPaint = Paint()
        ..color = theme.sunColor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(sunCenter, sunRadius * 1.2, auraPaint);

      // Core sun disc
      final sunDiscPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sunCenter, sunRadius * 0.75, sunDiscPaint);
    }

    // 3. Distant Mountains (Layer 1)
    final distantPath = Path();
    distantPath.moveTo(0, h * 0.58);
    distantPath.lineTo(w * 0.22, h * 0.44);
    distantPath.lineTo(w * 0.48, h * 0.52);
    distantPath.lineTo(w * 0.75, h * 0.38);
    distantPath.lineTo(w, h * 0.50);
    distantPath.lineTo(w, h);
    distantPath.lineTo(0, h);
    distantPath.close();

    final distantPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.mountainGradient.first.withValues(alpha: 0.65),
          theme.mountainGradient.last.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.38, w, h * 0.62));
    canvas.drawPath(distantPath, distantPaint);

    // 4. Midground Peaks / Hills (Layer 2)
    final midPath = Path();
    midPath.moveTo(0, h * 0.68);
    midPath.lineTo(w * 0.32, h * 0.54);
    midPath.lineTo(w * 0.58, h * 0.62);
    midPath.lineTo(w * 0.88, h * 0.50);
    midPath.lineTo(w, h * 0.58);
    midPath.lineTo(w, h);
    midPath.lineTo(0, h);
    midPath.close();

    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.mountainGradient,
      ).createShader(Rect.fromLTWH(0, h * 0.50, w, h * 0.50));
    canvas.drawPath(midPath, midPaint);

    // 5. Water / Meadow Reflection Basin (Layer 3)
    final waterRect = Rect.fromLTWH(0, h * 0.72, w, h * 0.28);
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.foregroundGradient.first.withValues(alpha: 0.80),
          theme.foregroundGradient.last,
        ],
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    // Water Shimmer Horizontal Lines
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      final y = h * (0.74 + i * 0.05);
      canvas.drawLine(
        Offset(w * (0.15 + i * 0.05), y),
        Offset(w * (0.85 - i * 0.04), y),
        shimmerPaint,
      );
    }

    // 6. Foreground Silhouette Trees & Foliage (Layer 4)
    final forePath = Path();
    forePath.moveTo(0, h * 0.82);
    forePath.lineTo(w * 0.18, h * 0.78);
    forePath.lineTo(w * 0.40, h * 0.86);
    forePath.lineTo(w * 0.70, h * 0.80);
    forePath.lineTo(w, h * 0.76);
    forePath.lineTo(w, h);
    forePath.lineTo(0, h);
    forePath.close();

    final forePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.foregroundGradient,
      ).createShader(Rect.fromLTWH(0, h * 0.76, w, h * 0.24));
    canvas.drawPath(forePath, forePaint);

    // Stylized Pine Trees on Left and Right Edges
    _drawPineTree(canvas, Offset(w * 0.08, h * 0.80), h * 0.16, theme.foregroundGradient.last);
    _drawPineTree(canvas, Offset(w * 0.16, h * 0.84), h * 0.12, theme.foregroundGradient.last);
    _drawPineTree(canvas, Offset(w * 0.90, h * 0.78), h * 0.18, theme.foregroundGradient.last);
    _drawPineTree(canvas, Offset(w * 0.82, h * 0.82), h * 0.13, theme.foregroundGradient.last);
  }

  void _drawPineTree(Canvas canvas, Offset base, double height, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = height * 0.45;
    final top = base.dy - height;

    final path = Path();
    // 3 layered pine tiers
    final tierH = height * 0.38;

    // Top tier
    path.moveTo(base.dx, top);
    path.lineTo(base.dx - width * 0.40, top + tierH);
    path.lineTo(base.dx + width * 0.40, top + tierH);
    path.close();

    // Mid tier
    final midTop = top + tierH * 0.65;
    path.moveTo(base.dx, midTop);
    path.lineTo(base.dx - width * 0.70, midTop + tierH);
    path.lineTo(base.dx + width * 0.70, midTop + tierH);
    path.close();

    // Bottom tier
    final botTop = top + tierH * 1.30;
    path.moveTo(base.dx, botTop);
    path.lineTo(base.dx - width, base.dy);
    path.lineTo(base.dx + width, base.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChapterLandscapePainter oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.progress != progress ||
        oldDelegate.showSunGlow != showSunGlow;
  }
}

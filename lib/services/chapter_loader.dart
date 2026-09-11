import 'dart:convert';
import 'package:flutter/services.dart';

/// Data class representing a chapter's metadata defined in chapters.json
class ChapterData {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final String color;
  final int rewardCoins;

  const ChapterData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.color = '#3D6BFF',
    this.rewardCoins = 50,
  });

  String get imagePath => 'assets/chapter/$image';

  Color get primaryColor {
    final clean = color.replaceFirst('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('0xFF$clean'));
    } else if (clean.length == 8) {
      return Color(int.parse('0x$clean'));
    }
    return const Color(0xFF3D6BFF);
  }

  factory ChapterData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 1;
    return ChapterData(
      id: id,
      title: json['title'] as String? ?? 'Chapter $id',
      subtitle: json['subtitle'] as String? ?? '',
      image: json['image'] as String? ?? 'chapter_$id.webp',
      color: json['color'] as String? ??
          json['primary_color'] as String? ??
          ChapterLoader.defaultColorForChapter(id),
      rewardCoins: json['reward_coins'] as int? ?? 50,
    );
  }
}

/// Service that loads and provides chapter configurations from assets/chapter/chapters.json
class ChapterLoader {
  static List<ChapterData> _chapters = [];
  static bool _isInitialized = false;

  static List<ChapterData> get chapters => _chapters;
  static int get totalChapters => _chapters.isNotEmpty ? _chapters.length : 18;

  /// Loads chapters from assets/chapter/chapters.json
  static Future<void> init([String? jsonContent]) async {
    if (_isInitialized && _chapters.isNotEmpty && jsonContent == null) return;
    try {
      final jsonString = jsonContent ?? await rootBundle.loadString('assets/chapter/chapters.json');
      loadFromJsonString(jsonString);
    } catch (_) {
      // If error loading JSON, fallback logic will handle it gracefully
    }
  }

  static void loadFromJsonString(String jsonString) {
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    _chapters = list.map((item) => ChapterData.fromJson(item as Map<String, dynamic>)).toList();
    _isInitialized = true;
  }

  /// Default color mapping for chapters 1..18 adhering strictly to:
  /// - Yellow (#FEDD39) ONLY for Chapter 7 & Chapter 17 (chapter_7.webp & chapter_17.webp)
  /// - The other 7 colors repeat in sequence: Blue, Brown, Green, Orange, Pink, Purple, Red
  static String defaultColorForChapter(int chapterNumber) {
    final idx = chapterNumber <= 0 ? 1 : ((chapterNumber - 1) % 18) + 1;
    if (idx == 7 || idx == 17) {
      return '#FEDD39';
    }
    const mapping = {
      1: '#3D6BFF', // Blue
      2: '#D77B48', // Brown
      3: '#1DB205', // Green
      4: '#FF602F', // Orange
      5: '#FC368B', // Pink
      6: '#B33DFF', // Purple
      8: '#FF4F4F', // Red
      9: '#3D6BFF', // Blue
      10: '#D77B48', // Brown
      11: '#1DB205', // Green
      12: '#FF602F', // Orange
      13: '#FC368B', // Pink
      14: '#B33DFF', // Purple
      15: '#FF4F4F', // Red
      16: '#3D6BFF', // Blue
      18: '#D77B48', // Brown
    };
    return mapping[idx] ?? '#3D6BFF';
  }

  /// Get chapter data for a given chapterNumber (1-based, loops when exceeding total)
  static ChapterData getChapter(int chapterNumber) {
    if (_chapters.isEmpty) {
      final idx = chapterNumber <= 0 ? 1 : ((chapterNumber - 1) % 18) + 1;
      return ChapterData(
        id: chapterNumber,
        title: 'Chapter $chapterNumber',
        subtitle: 'Adventure $idx',
        image: 'chapter_$idx.webp',
        color: defaultColorForChapter(idx),
        rewardCoins: 50,
      );
    }

    final effectiveNumber = chapterNumber <= 0 ? 1 : chapterNumber;
    final index = (effectiveNumber - 1) % _chapters.length;
    final base = _chapters[index];

    // If chapterNumber exceeds base count, keep image, color, and subtitle while displaying chapter number
    if (chapterNumber > _chapters.length) {
      return ChapterData(
        id: chapterNumber,
        title: '${base.title} $chapterNumber',
        subtitle: base.subtitle,
        image: base.image,
        color: base.color,
        rewardCoins: base.rewardCoins,
      );
    }
    return base;
  }

  /// Get image asset path for any chapter number (with looping)
  static String getImagePath(int chapterNumber) {
    return getChapter(chapterNumber).imagePath;
  }
}

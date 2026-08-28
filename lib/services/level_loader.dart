import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/level_model.dart';

class LevelLoader {
  static const List<String> supportedLanguages = [
    'english',
    'turkish',
    'russian',
    'spanish',
    'portuguese',
  ];

  static final Map<String, String> languageDisplayNames = {
    'english': 'English 🇺🇸',
    'turkish': 'Türkçe 🇹🇷',
    'russian': 'Русский 🇷🇺',
    'spanish': 'Español 🇪🇸',
    'portuguese': 'Português 🇵🇹',
  };

  static const Map<String, int> totalLevelsPerLanguage = {
    'english': 2461,
    'turkish': 2448,
    'russian': 1927,
    'spanish': 1361,
    'portuguese': 1353,
  };

  /// Load progression level numbers (1 to totalLevels)
  static Future<List<int>> loadLevelList(String language, {String? listName}) async {
    final count = totalLevelsPerLanguage[language] ?? 1000;
    return List.generate(count, (i) => i + 1);
  }

  /// Load a specific level by language and level Number (e.g. level1.json, level2.json, ...)
  static Future<LevelModel?> loadLevel(String language, int levelNumber) async {
    // 1. Try level{levelNumber}.json (e.g. assets/levels/english/level1.json)
    try {
      final jsonPath = 'assets/levels/$language/level$levelNumber.json';
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return LevelModel.fromJson(jsonMap);
    } catch (_) {}

    // 2. Try {levelNumber}.json
    try {
      final jsonPath = 'assets/levels/$language/$levelNumber.json';
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return LevelModel.fromJson(jsonMap);
    } catch (_) {}

    return null;
  }

  /// Compute the initial tile counts and obstacle states for the board
  static List<List<LetterTile>> createInitialGridTiles(LevelModel level) {
    final grid = <List<LetterTile>>[];
    final height = level.letterGrid.length;
    final width = height > 0 ? level.letterGrid[0].length : 0;

    // 1. Calculate how many times each cell is needed
    final cellUsageCounts = _calculateCellUsageCounts(level);

    // 2. Map obstacles to cells
    final obstacleMap = <String, int>{};
    for (final obs in level.obstacles) {
      for (final cell in obs.cells) {
        // cell.x is column, cell.y is row (or vice-versa in grid)
        final key = '${cell.y},${cell.x}';
        obstacleMap[key] = obs.requiredWords;
      }
    }

    for (int r = 0; r < height; r++) {
      final rowList = <LetterTile>[];
      for (int c = 0; c < width; c++) {
        final letter = r < level.letterGrid.length && c < level.letterGrid[r].length
            ? level.letterGrid[r][c]
            : '';
        final count = cellUsageCounts[Point(c, r)] ?? 1;
        final obsReq = obstacleMap['$r,$c'] ?? obstacleMap['$c,$r'];
        final isLocked = obsReq != null && obsReq > 0;

        rowList.add(LetterTile(
          row: r,
          col: c,
          letter: letter,
          count: count,
          initialCount: count,
          isObstacleLocked: isLocked,
          obstacleRequiredWords: obsReq,
          isCleared: letter.isEmpty,
        ));
      }
      grid.add(rowList);
    }

    return grid;
  }

  /// Calculates how many times each tile on the board is used in the target words
  static Map<Point<int>, int> _calculateCellUsageCounts(LevelModel level) {
    final height = level.letterGrid.length;
    final width = height > 0 ? level.letterGrid[0].length : 0;
    final cellCounts = <Point<int>, int>{};

    // Initialize all cells with 0
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        cellCounts[Point(c, r)] = 0;
      }
    }

    // Collect all tile positions for each letter
    final letterToCells = <String, List<Point<int>>>{};
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final ch = level.letterGrid[r][c];
        if (ch.isNotEmpty) {
          letterToCells.putIfAbsent(ch, () => []).add(Point(c, r));
        }
      }
    }

    // For each target word, find the best matching adjacent path in the grid
    for (final target in level.targetWords) {
      final word = target.word;
      final path = _findWordPath(word, level.letterGrid, width, height);

      if (path != null && path.isNotEmpty) {
        for (final pt in path) {
          cellCounts[pt] = (cellCounts[pt] ?? 0) + 1;
        }
      } else {
        // Fallback: distribute count to cells matching the letters
        for (int i = 0; i < word.length; i++) {
          final ch = word[i];
          final cells = letterToCells[ch];
          if (cells != null && cells.isNotEmpty) {
            // Pick cell with lowest count so far to balance
            cells.sort((a, b) => (cellCounts[a] ?? 0).compareTo(cellCounts[b] ?? 0));
            final best = cells.first;
            cellCounts[best] = (cellCounts[best] ?? 0) + 1;
          }
        }
      }
    }

    // Ensure every non-empty tile has at least count 1
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final pt = Point(c, r);
        if (level.letterGrid[r][c].isNotEmpty && (cellCounts[pt] ?? 0) == 0) {
          cellCounts[pt] = 1;
        }
      }
    }

    return cellCounts;
  }

  /// Search for a valid adjacent path for a given word on the board
  static List<Point<int>>? _findWordPath(
    String word,
    List<List<String>> grid,
    int width,
    int height,
  ) {
    if (word.isEmpty || height == 0 || width == 0) return null;

    final firstChar = word[0];
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (grid[r][c] == firstChar) {
          final visited = <Point<int>>{Point(c, r)};
          final path = <Point<int>>[Point(c, r)];
          if (_dfsWord(word, 1, Point(c, r), grid, width, height, visited, path)) {
            return path;
          }
        }
      }
    }
    return null;
  }

  static bool _dfsWord(
    String word,
    int index,
    Point<int> current,
    List<List<String>> grid,
    int width,
    int height,
    Set<Point<int>> visited,
    List<Point<int>> path,
  ) {
    if (index >= word.length) return true;

    final targetChar = word[index];
    // 4 adjacent directions (Horizontal & Vertical only)
    const dr = [-1, 1, 0, 0];
    const dc = [0, 0, -1, 1];
    for (int i = 0; i < 4; i++) {
      final nx = current.x + dc[i];
      final ny = current.y + dr[i];

      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        final nextPt = Point(nx, ny);
        if (!visited.contains(nextPt) && grid[ny][nx] == targetChar) {
          visited.add(nextPt);
          path.add(nextPt);
          if (_dfsWord(word, index + 1, nextPt, grid, width, height, visited, path)) {
            return true;
          }
          path.removeLast();
          visited.remove(nextPt);
        }
      }
    }
    return false;
  }
}

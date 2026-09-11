import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/level_model.dart';

class LevelLoader {
  static const List<String> supportedLanguages = [
    'english',
    'german',
    'french',
    'italian',
    'spanish',
    'portuguese',
    'russian',
    'turkish',
  ];

  static final Map<String, String> languageDisplayNames = {
    'english': 'English 🇺🇸',
    'german': 'Deutsch 🇩🇪',
    'french': 'Français 🇫🇷',
    'italian': 'Italiano 🇮🇹',
    'spanish': 'Español 🇪🇸',
    'portuguese': 'Português 🇵🇹',
    'russian': 'Русский 🇷🇺',
    'turkish': 'Türkçe 🇹🇷',
  };

  static const Map<String, int> totalLevelsPerLanguage = {
    'english': 2471,
    'german': 1500,
    'french': 1500,
    'italian': 1500,
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
  /// Load a specific level by language and level Number (e.g. level1.json, level2.json, ...)
  static Future<LevelModel?> loadLevel(String language, int levelNumber) async {
    // 1. Try level{levelNumber}.json (e.g. assets/levels/english/level1.json)
    try {
      final jsonPath = 'assets/levels/$language/level$levelNumber.json';
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final raw = LevelModel.fromJson(jsonMap);
      return harmonizeLevel(raw);
    } catch (_) {}

    // 2. Try {levelNumber}.json
    try {
      final jsonPath = 'assets/levels/$language/$levelNumber.json';
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final raw = LevelModel.fromJson(jsonMap);
      return harmonizeLevel(raw);
    } catch (_) {}

    return null;
  }

  /// Automatically harmonizes level so that all tiles on the board belong to target words
  static LevelModel harmonizeLevel(LevelModel level) {
    final height = level.letterGrid.length;
    final width = height > 0 ? level.letterGrid[0].length : 0;
    final grid = level.letterGrid;
    if (height == 0 || width == 0) return level;

    // 1. Validate existing target words and calculate covered cells
    final validTargetWords = <TargetWord>[];
    final coveredCells = <Point<int>>{};

    for (final tw in level.targetWords) {
      final paths = _findAllWordPaths(tw.word, grid, width, height);
      if (paths.isNotEmpty) {
        validTargetWords.add(tw);
        coveredCells.addAll(paths.first);
      }
    }

    // 2. Collect all cells present on the board
    final allCells = <Point<int>>{};
    for (int r = 0; r < height; r++) {
      if (r >= grid.length) continue;
      for (int c = 0; c < width; c++) {
        if (c < grid[r].length && grid[r][c].isNotEmpty) {
          allCells.add(Point(c, r));
        }
      }
    }

    final uncovered = allCells.difference(coveredCells);
    if (uncovered.isEmpty && validTargetWords.length == level.targetWords.length) {
      return level; // Already 100% covered!
    }

    // 3. Promote extra words that cover uncovered cells into targetWords
    final newTargetWords = List<TargetWord>.from(validTargetWords);
    final remainingExtra = <TargetWord>[];

    for (final ew in level.extraWords) {
      final paths = _findAllWordPaths(ew.word, grid, width, height);
      if (paths.isNotEmpty) {
        final coversNewCell = paths.any((p) => p.any((pt) => uncovered.contains(pt)));
        if (coversNewCell && !newTargetWords.any((t) => t.word == ew.word)) {
          newTargetWords.add(ew);
          for (final p in paths) {
            uncovered.removeAll(p);
          }
          continue;
        }
      }
      remainingExtra.add(ew);
    }

    return LevelModel(
      id: level.id,
      width: level.width,
      height: level.height,
      targetWords: newTargetWords.isNotEmpty ? newTargetWords : level.targetWords,
      extraWords: remainingExtra,
      letterGrid: level.letterGrid,
      obstacles: level.obstacles,
    );
  }

  /// Compute the initial tile counts and obstacle states for the board
  static List<List<LetterTile>> createInitialGridTiles(LevelModel level) {
    final grid = <List<LetterTile>>[];
    final height = level.letterGrid.length;
    final width = height > 0 ? level.letterGrid[0].length : 0;

    // 1. Calculate how many times each cell is needed
    final Map<Point<int>, int> cellUsageCounts;
    if (level.countsGrid != null) {
      cellUsageCounts = {};
      for (int r = 0; r < level.countsGrid!.length; r++) {
        for (int c = 0; c < level.countsGrid![r].length; c++) {
          cellUsageCounts[Point(c, r)] = level.countsGrid![r][c];
        }
      }
    } else {
      cellUsageCounts = _calculateCellUsageCounts(level);
    }

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
        final count = cellUsageCounts[Point(c, r)] ?? 0;
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
          isCleared: letter.isEmpty || count == 0,
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
    final grid = level.letterGrid;

    // Find locked cells
    final lockedCells = <Point<int>>{};
    for (final obs in level.obstacles) {
      if (obs.requiredWords > 0) {
        for (final c in obs.cells) {
          lockedCells.add(Point(c.x, c.y));
        }
      }
    }

    final wordAllPaths = <String, List<List<Point<int>>>>{};
    for (int i = 0; i < level.targetWords.length; i++) {
      final tw = level.targetWords[i];
      final all = _findAllWordPaths(tw.word, grid, width, height);
      // Prefer paths not using locked cells
      all.sort((a, b) {
        final lockA = a.where((p) => lockedCells.contains(p)).length;
        final lockB = b.where((p) => lockedCells.contains(p)).length;
        return lockA.compareTo(lockB);
      });
      wordAllPaths[tw.word] = all;
    }

    // Joint backtrack to find simultaneous path assignments
    final assignedCounts = <Point<int>, int>{};
    _backtrackCounts(0, level.targetWords, wordAllPaths, <Point<int>, int>{}, assignedCounts);

    return assignedCounts;
  }

  static bool _backtrackCounts(
    int wordIdx,
    List<TargetWord> targetWords,
    Map<String, List<List<Point<int>>>> wordAllPaths,
    Map<Point<int>, int> currentUsage,
    Map<Point<int>, int> bestUsage,
  ) {
    if (wordIdx >= targetWords.length) {
      bestUsage.clear();
      bestUsage.addAll(currentUsage);
      return true;
    }

    final word = targetWords[wordIdx].word;
    final paths = wordAllPaths[word] ?? [];
    if (paths.isEmpty) {
      return _backtrackCounts(wordIdx + 1, targetWords, wordAllPaths, currentUsage, bestUsage);
    }

    for (final path in paths) {
      // Temporarily add path usage
      for (final pt in path) {
        currentUsage[pt] = (currentUsage[pt] ?? 0) + 1;
      }

      if (_backtrackCounts(wordIdx + 1, targetWords, wordAllPaths, currentUsage, bestUsage)) {
        return true;
      }

      // Rollback
      for (final pt in path) {
        final count = currentUsage[pt] ?? 1;
        if (count <= 1) {
          currentUsage.remove(pt);
        } else {
          currentUsage[pt] = count - 1;
        }
      }
    }

    return false;
  }

  /// Finds all 4-way orthogonal paths spelling a word on the letter grid
  static List<List<Point<int>>> _findAllWordPaths(
    String word,
    List<List<String>> grid,
    int width,
    int height,
  ) {
    final actualHeight = grid.length;
    final actualWidth = actualHeight > 0 ? grid[0].length : 0;
    if (word.isEmpty || actualHeight == 0 || actualWidth == 0) return [];

    final allPaths = <List<Point<int>>>[];
    final firstChar = word[0];
    for (int r = 0; r < actualHeight; r++) {
      if (r >= grid.length) continue;
      for (int c = 0; c < actualWidth; c++) {
        if (c < grid[r].length && grid[r][c] == firstChar) {
          final visited = <Point<int>>{Point(c, r)};
          final path = <Point<int>>[Point(c, r)];
          _dfsAllWordPaths(word, 1, Point(c, r), grid, actualWidth, actualHeight, visited, path, allPaths);
        }
      }
    }

    return allPaths;
  }

  static void _dfsAllWordPaths(
    String word,
    int index,
    Point<int> current,
    List<List<String>> grid,
    int width,
    int height,
    Set<Point<int>> visited,
    List<Point<int>> path,
    List<List<Point<int>>> allPaths,
  ) {
    if (index >= word.length) {
      allPaths.add(List.from(path));
      return;
    }

    final targetChar = word[index];
    // 4 adjacent directions (Horizontal & Vertical only)
    const dr = [-1, 1, 0, 0];
    const dc = [0, 0, -1, 1];
    for (int i = 0; i < 4; i++) {
      final nx = current.x + dc[i];
      final ny = current.y + dr[i];

      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        if (ny < grid.length && nx < grid[ny].length) {
          final nextPt = Point(nx, ny);
          if (!visited.contains(nextPt) && grid[ny][nx] == targetChar) {
            visited.add(nextPt);
            path.add(nextPt);
            _dfsAllWordPaths(word, index + 1, nextPt, grid, width, height, visited, path, allPaths);
            path.removeLast();
            visited.remove(nextPt);
          }
        }
      }
    }
  }
}

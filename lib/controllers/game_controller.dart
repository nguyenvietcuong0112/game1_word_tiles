import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';

class GameController extends ChangeNotifier {
  final String language;
  final int levelId;
  final int levelNumber;
  final LevelModel level;

  late List<List<LetterTile>> grid;
  final Set<String> solvedTargetWords = {};
  final Set<String> foundExtraWords = {};

  final List<Point<int>> currentPath = [];
  String currentWord = '';

  bool isWon = false;
  int starsEarned = 0;
  int coinsReward = 10;
  String victoryCelebrationText = 'LEVEL COMPLETE!';

  List<Point<int>>? highlightedHintPath;
  Timer? _hintTimer;

  String? feedbackMessage;
  Color? feedbackColor;
  Timer? _feedbackTimer;

  static const List<String> celebrationPhrases = [
    'WORD MASTER!',
    'SMOOTH SOLVE!',
    'CRUSHED IT!',
    'WORDPLAY MAGIC!',
    'FLAWLESS!',
    'ZERO MISTAKES!',
    'MASTERFUL!',
    'ON FIRE!',
    'UNSTOPPABLE!',
    'WORDSTORM!',
  ];

  GameController({
    required this.language,
    required this.levelId,
    required this.levelNumber,
    required this.level,
  }) {
    _initGrid();
  }

  void _initGrid() {
    grid = LevelLoader.createInitialGridTiles(level);
    _checkObstacleUnlocks();
  }

  int get wordsSolvedCount => solvedTargetWords.length;
  int get totalTargetWords => level.targetWords.length;
  double get progress => totalTargetWords > 0 ? wordsSolvedCount / totalTargetWords : 0.0;

  /// Start dragging from a tile at (row, col)
  void startSwipe(int row, int col) {
    if (isWon) return;
    if (row < 0 || row >= grid.length || col < 0 || col >= grid[0].length) return;

    final tile = grid[row][col];
    if (tile.isCleared) return;

    if (tile.isObstacleLocked) {
      _showFeedback(
        'Locked! Solve ${tile.obstacleRequiredWords} words to unlock.',
        Colors.orangeAccent,
      );
      AudioManager.playInvalid();
      return;
    }

    currentPath.clear();
    currentPath.add(Point(col, row));
    currentWord = tile.letter;
    highlightedHintPath = null;
    AudioManager.playTileSelect();
    notifyListeners();
  }

  /// Update swipe dragging to a tile at (row, col)
  void updateSwipe(int row, int col) {
    if (isWon || currentPath.isEmpty) return;
    if (row < 0 || row >= grid.length || col < 0 || col >= grid[0].length) return;

    final pt = Point(col, row);
    final tile = grid[row][col];

    if (tile.isCleared) return;

    // Backtracking to previous tile
    if (currentPath.length > 1 && currentPath[currentPath.length - 2] == pt) {
      currentPath.removeLast();
      _recalculateCurrentWord();
      AudioManager.playTileSelect();
      notifyListeners();
      return;
    }

    if (currentPath.contains(pt)) return;

    if (tile.isObstacleLocked) {
      _showFeedback(
        'Locked! Needs ${tile.obstacleRequiredWords} solved words.',
        Colors.orangeAccent,
      );
      return;
    }

    // 4 directions (Horizontal & Vertical only)
    final last = currentPath.last;
    final dx = (last.x - pt.x).abs();
    final dy = (last.y - pt.y).abs();
    if (dx + dy == 1) {
      currentPath.add(pt);
      currentWord += tile.letter;
      AudioManager.playTileSelect();
      notifyListeners();
    }
  }

  /// End swipe and evaluate word
  void endSwipe() {
    if (isWon || currentPath.isEmpty) {
      currentPath.clear();
      currentWord = '';
      notifyListeners();
      return;
    }

    final word = currentWord.trim();
    if (word.length >= 2) {
      _evaluateWord(word);
    }

    currentPath.clear();
    currentWord = '';
    notifyListeners();
  }

  void _recalculateCurrentWord() {
    final sb = StringBuffer();
    for (final pt in currentPath) {
      sb.write(grid[pt.y][pt.x].letter);
    }
    currentWord = sb.toString();
  }

  void _evaluateWord(String word) {
    // 1. Target word
    final isTarget = level.targetWords.any((tw) => tw.word == word);
    if (isTarget) {
      if (solvedTargetWords.contains(word)) {
        _showFeedback('Already found "$word"!', Colors.amber);
        AudioManager.playInvalid();
        return;
      }

      // Solved new target word!
      solvedTargetWords.add(word);
      AudioManager.playWordMatch();
      _showFeedback('Awesome! "$word"', const Color(0xFF69F0AE));

      // Decrement tile badge counts
      for (final pt in currentPath) {
        final tile = grid[pt.y][pt.x];
        tile.count--;
        if (tile.count <= 0) {
          tile.isCleared = true;
        }
      }

      // Check obstacle unlocks
      _checkObstacleUnlocks();

      // Check win condition
      if (solvedTargetWords.length >= level.targetWords.length) {
        _handleVictory();
      }
      return;
    }

    // 2. Extra / Bonus word
    final isExtra = level.extraWords.any((ew) => ew.word == word);
    if (isExtra) {
      if (foundExtraWords.contains(word)) {
        _showFeedback('Extra word "$word" already found!', Colors.amber);
        AudioManager.playInvalid();
      } else {
        foundExtraWords.add(word);
        var chestCount = GameStorage.getExtraWordsChestCount() + 1;

        if (chestCount >= 5) {
          // Chest opened!
          GameStorage.setExtraWordsChestCount(0);
          GameStorage.addCoins(25);
          AudioManager.playVictory();
          _showFeedback('🎁 Star Chest Opened! +25 🪙', Colors.amberAccent);
        } else {
          GameStorage.setExtraWordsChestCount(chestCount);
          GameStorage.addCoins(2);
          AudioManager.playExtraWord();
          _showFeedback('Bonus Word! "$word" ($chestCount/5 🎁 +2 🪙)', const Color(0xFFFFD54F));
        }
      }
      return;
    }

    // 3. Invalid word
    AudioManager.playInvalid();
    _showFeedback('"$word" is not on the board', Colors.redAccent.shade100);
  }

  void _checkObstacleUnlocks() {
    final solved = wordsSolvedCount;
    bool unlockedAny = false;

    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        final tile = grid[r][c];
        if (tile.isObstacleLocked) {
          final req = tile.obstacleRequiredWords ?? 0;
          if (solved >= req) {
            tile.isObstacleLocked = false;
            unlockedAny = true;
          }
        }
      }
    }

    if (unlockedAny) {
      AudioManager.playObstacleUnlock();
      _showFeedback('Obstacle Unlocked! 🔓', Colors.lightBlueAccent);
    }
  }

  void _handleVictory() {
    isWon = true;
    starsEarned = 3;
    // Milestone level check (e.g. every 5th or 10th level gives 25 coins, regular gives 10 coins)
    coinsReward = (levelNumber % 5 == 0) ? 25 : 10;
    GameStorage.addCoins(coinsReward);

    // Random celebration text
    final random = Random();
    victoryCelebrationText = celebrationPhrases[random.nextInt(celebrationPhrases.length)];

    // Save progress
    GameStorage.saveLevelStars(language, levelId, starsEarned);
    GameStorage.setMaxUnlockedLevelIndex(language, levelNumber);

    AudioManager.playVictory();
    _showFeedback('🎉 $victoryCelebrationText +$coinsReward 🪙', Colors.amberAccent);
  }

  /// Use 💡 Lightbulb Hint booster (Costs 80 Coins)
  Future<bool> useHint() async {
    if (isWon) return false;

    // Try using inventory item first
    final hasItem = await GameStorage.useHintItem();
    if (!hasItem) {
      const hintCost = 80;
      final hasCoins = await GameStorage.spendCoins(hintCost);
      if (!hasCoins) {
        _showFeedback('Not enough coins! Need $hintCost 🪙 for Hint', Colors.redAccent);
        AudioManager.playInvalid();
        return false;
      }
    }

    for (final target in level.targetWords) {
      if (!solvedTargetWords.contains(target.word)) {
        final path = _findValidActivePath(target.word);
        if (path != null && path.isNotEmpty) {
          highlightedHintPath = path;
          _hintTimer?.cancel();
          _hintTimer = Timer(const Duration(seconds: 5), () {
            highlightedHintPath = null;
            notifyListeners();
          });
          _showFeedback('💡 Hint: "${target.word}" (-80 🪙)', Colors.yellowAccent);
          AudioManager.playWordMatch();
          notifyListeners();
          return true;
        }
      }
    }

    _showFeedback('No available hint path found.', Colors.white70);
    return false;
  }

  /// Use 🚀 Rocket / Firework booster (Costs 240 Coins - Instantly Solves a Word!)
  Future<bool> useRocket() async {
    if (isWon) return false;

    // Try using inventory item first
    final hasItem = await GameStorage.useRocketItem();
    if (!hasItem) {
      const rocketCost = 240;
      final hasCoins = await GameStorage.spendCoins(rocketCost);
      if (!hasCoins) {
        _showFeedback('Not enough coins! Need $rocketCost 🪙 for Rocket', Colors.redAccent);
        AudioManager.playInvalid();
        return false;
      }
    }

    // Find the longest unsolved target word
    TargetWord? targetToSolve;
    int maxLen = 0;
    for (final target in level.targetWords) {
      if (!solvedTargetWords.contains(target.word)) {
        if (target.word.length > maxLen) {
          maxLen = target.word.length;
          targetToSolve = target;
        }
      }
    }

    if (targetToSolve != null) {
      final word = targetToSolve.word;
      solvedTargetWords.add(word);

      // Decrement tile counts on board
      final path = _findValidActivePath(word);
      if (path != null) {
        for (final pt in path) {
          final tile = grid[pt.y][pt.x];
          tile.count--;
          if (tile.count <= 0) {
            tile.isCleared = true;
          }
        }
      }

      AudioManager.playVictory();
      _showFeedback('🚀 Rocket Cleared: "$word"! (-240 🪙)', const Color(0xFF69F0AE));

      _checkObstacleUnlocks();

      if (solvedTargetWords.length >= level.targetWords.length) {
        _handleVictory();
      }

      notifyListeners();
      return true;
    }

    _showFeedback('All target words are already solved!', Colors.white70);
    return false;
  }

  /// Search for a path for a word using 4 directions
  List<Point<int>>? _findValidActivePath(String word) {
    final height = grid.length;
    final width = height > 0 ? grid[0].length : 0;
    if (word.isEmpty || height == 0 || width == 0) return null;

    final firstChar = word[0];
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final tile = grid[r][c];
        if (!tile.isCleared && !tile.isObstacleLocked && tile.letter == firstChar) {
          final visited = <Point<int>>{Point(c, r)};
          final path = <Point<int>>[Point(c, r)];
          if (_dfsActive(word, 1, Point(c, r), visited, path, width, height)) {
            return path;
          }
        }
      }
    }
    return null;
  }

  bool _dfsActive(
    String word,
    int index,
    Point<int> current,
    Set<Point<int>> visited,
    List<Point<int>> path,
    int width,
    int height,
  ) {
    if (index >= word.length) return true;

    final targetChar = word[index];
    const dr = [-1, 1, 0, 0];
    const dc = [0, 0, -1, 1];
    for (int i = 0; i < 4; i++) {
      final nx = current.x + dc[i];
      final ny = current.y + dr[i];

      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        final nextPt = Point(nx, ny);
        final tile = grid[ny][nx];
        if (!visited.contains(nextPt) &&
            !tile.isCleared &&
            !tile.isObstacleLocked &&
            tile.letter == targetChar) {
          visited.add(nextPt);
          path.add(nextPt);
          if (_dfsActive(word, index + 1, nextPt, visited, path, width, height)) {
            return true;
          }
          path.removeLast();
          visited.remove(nextPt);
        }
      }
    }
    return false;
  }

  void _showFeedback(String message, Color color) {
    feedbackMessage = message;
    feedbackColor = color;
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      feedbackMessage = null;
      feedbackColor = null;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
}

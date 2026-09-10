import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../services/analytics_service.dart';
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
  bool isWinning = false;
  int starsEarned = 0;
  int coinsReward = 10;
  String victoryCelebrationText = 'LEVEL COMPLETE!';

  int invalidAttemptsCount = 0;
  int consecutiveFailedSwipes = 0;
  List<Point<int>>? failSafeHintPath;
  int boostersUsedCount = 0;
  final DateTime levelStartTime = DateTime.now();

  // Chapter & Level progression
  int get chapterNumber => ((levelNumber - 1) ~/ 5) + 1;
  int get levelInChapter => ((levelNumber - 1) % 5) + 1;

  // Progressive Feature & Booster Unlocks
  bool get isBoosterBarVisible => levelNumber >= 5;
  bool get isHintUnlocked => levelNumber >= 5;
  bool get isRocketUnlocked => levelNumber >= 7;
  bool get isExtraWordsUnlocked => levelNumber >= 7;
  bool get isShopUnlocked => levelNumber >= 7;

  List<Point<int>>? highlightedHintPath;
  Timer? _hintTimer;
  Timer? _victoryTimer;

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

  static const List<String> matchFeedbackPhrases = [
    'NICE!',
    'AWESOME!',
    'GOOD!',
    'GREAT!',
    'SUPER!',
    'BRILLIANT!',
    'FANTASTIC!',
    'WONDERFUL!',
    'PERFECT!',
    'AMAZING!',
    'EXCELLENT!',
    'WELL DONE!',
    'SPLENDID!',
    'SWEET!',
    'WOW!',
    'BINGO!',
  ];

  static const List<Color> matchFeedbackColors = [
    Color(0xFF10B981), // Emerald Mint
    Color(0xFF3B82F6), // Ocean Blue
    Color(0xFFF59E0B), // Golden Amber
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFEC4899), // Hot Pink / Rose
    Color(0xFF06B6D4), // Cyan Turquoise
    Color(0xFFF97316), // Vivid Orange
    Color(0xFF84CC16), // Lime Green
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
  ];

  final Random _feedbackRandom = Random();

  String _getRandomMatchPhrase() {
    return matchFeedbackPhrases[_feedbackRandom.nextInt(matchFeedbackPhrases.length)];
  }

  Color _getRandomMatchColor() {
    return matchFeedbackColors[_feedbackRandom.nextInt(matchFeedbackColors.length)];
  }

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
    if (isWon || isWinning) return;
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
    AudioManager.playTileSelect(pitchIndex: 1);
    notifyListeners();
  }

  /// Update swipe dragging to a tile at (row, col)
  void updateSwipe(int row, int col) {
    if (isWon || isWinning || currentPath.isEmpty) return;
    if (row < 0 || row >= grid.length || col < 0 || col >= grid[0].length) return;

    final pt = Point(col, row);
    final tile = grid[row][col];

    if (tile.isCleared) return;

    // Backtracking to previous tile
    if (currentPath.length > 1 && currentPath[currentPath.length - 2] == pt) {
      currentPath.removeLast();
      _recalculateCurrentWord();
      AudioManager.playTileSelect(pitchIndex: currentPath.length);
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
      AudioManager.playTileSelect(pitchIndex: currentPath.length);
      notifyListeners();
    }
  }

  /// End swipe and evaluate word
  void endSwipe() {
    if (isWon || isWinning || currentPath.isEmpty) {
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

  void _evaluateWord(String rawWord) {
    final word = rawWord.trim().toUpperCase();

    // 1. Target word
    TargetWord? matchedTarget;
    for (final tw in level.targetWords) {
      if (tw.word.trim().toUpperCase() == word) {
        matchedTarget = tw;
        break;
      }
    }

    if (matchedTarget != null) {
      final targetKey = matchedTarget.word;
      if (solvedTargetWords.contains(targetKey)) {
        _showFeedback('Already found!', Colors.amber);
        AudioManager.playInvalid();
        return;
      }

      // Solved new target word!
      solvedTargetWords.add(targetKey);
      consecutiveFailedSwipes = 0;
      failSafeHintPath = null;
      AudioManager.playWordMatch();
      _showFeedback(_getRandomMatchPhrase(), _getRandomMatchColor());

      // Decrement optimal tile badge counts with 0-leftover guarantee
      _decrementWordTiles(targetKey, currentPath);

      // Unlock any obstacles requiring this word count
      _checkObstacleUnlocks();

      // Check win condition (500ms delay for last tile shatter animation to complete)
      if (solvedTargetWords.length >= level.targetWords.length) {
        for (final row in grid) {
          for (final tile in row) {
            tile.count = 0;
            tile.isCleared = true;
          }
        }
        _victoryTimer?.cancel();
        _victoryTimer = Timer(const Duration(milliseconds: 500), () {
          _handleVictory();
          notifyListeners();
        });
      }
      return;
    }

    // 2. Extra / Bonus word
    TargetWord? matchedExtra;
    for (final ew in level.extraWords) {
      if (ew.word.trim().toUpperCase() == word) {
        matchedExtra = ew;
        break;
      }
    }

    // 2b. Dynamic Safeguard for Plural/Singular:
    // If player swiped 'W' and 'W+S' is a target/extra word on this level,
    // or player swiped 'W' ending with 'S' and singular 'W' is a target/extra word on this level:
    if (matchedExtra == null) {
      final hasPluralOnBoard = level.targetWords.any((tw) => tw.word == '${word}S') ||
          level.extraWords.any((ew) => ew.word == '${word}S');
      final hasSingularOnBoard = word.endsWith('S') && word.length >= 4 &&
          (level.targetWords.any((tw) => tw.word == word.substring(0, word.length - 1)) ||
              level.extraWords.any((ew) => ew.word == word.substring(0, word.length - 1)));

      if (hasPluralOnBoard || hasSingularOnBoard) {
        matchedExtra = TargetWord(word: word, type: 0);
      }
    }

    if (matchedExtra != null) {
      final extraKey = matchedExtra.word;
      if (foundExtraWords.contains(extraKey)) {
        _showFeedback('Already found!', Colors.amber);
        AudioManager.playInvalid();
      } else {
        foundExtraWords.add(extraKey);
        final bankCount = GameStorage.addExtraWordToBank();

        if (bankCount >= 10) {
          AudioManager.playVictory();
          _showFeedback('🎁 Extra Words Bank Full! (10/10)', const Color(0xFFFFD54F));
        } else {
          AudioManager.playExtraWord();
          _showFeedback('✨ EXTRA WORD! ($bankCount/10)', const Color(0xFFFFD54F));
        }
      }
      return;
    }

    // 3. Invalid word
    invalidAttemptsCount++;
    consecutiveFailedSwipes++;
    if (levelNumber <= 10 && consecutiveFailedSwipes >= 5) {
      final nextWord = getNextUnsolvedTargetWord();
      if (nextWord != null) {
        failSafeHintPath = getTutorialPathForWord(nextWord);
      }
    }
    AudioManager.playInvalid();
    _showFeedback('Not on the board', Colors.redAccent.shade100);
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
    isWinning = false;
    isWon = true;

    // Dynamic Star Rating Calculation:
    // Flawless (<= 1 error/hint) -> 3 Stars ⭐⭐⭐
    // Great (2-3 errors/hints) -> 2 Stars ⭐⭐
    // Cleared (4+ errors/hints) -> 1 Star ⭐
    final penalty = invalidAttemptsCount + (boostersUsedCount * 1.5) - (foundExtraWords.length * 0.5);
    final isMilestone = (levelNumber % 5 == 0);

    if (penalty <= 1.0) {
      starsEarned = 3;
      coinsReward = isMilestone ? 35 : 15;
      victoryCelebrationText = const [
        'PERFECT SOLVE!',
        'MASTERFUL!',
        'GENIUS!',
        'FLAWLESS!',
        'WORD MASTER!',
      ][Random().nextInt(5)];
    } else if (penalty <= 3.0) {
      starsEarned = 2;
      coinsReward = isMilestone ? 25 : 10;
      victoryCelebrationText = const [
        'GREAT JOB!',
        'SMOOTH SOLVE!',
        'WELL PLAYED!',
        'NICE FINISH!',
      ][Random().nextInt(4)];
    } else {
      starsEarned = 1;
      coinsReward = isMilestone ? 15 : 6;
      victoryCelebrationText = const [
        'LEVEL COMPLETED!',
        'GOOD EFFORT!',
        'STAGE CLEARED!',
      ][Random().nextInt(3)];
    }

    GameStorage.addCoins(coinsReward);
    AnalyticsService.logEarnResource(
      level: levelNumber,
      itemType: 'currency',
      itemName: 'coin',
      amount: coinsReward.toDouble(),
      earnPlacement: 'level_win',
      balance: GameStorage.getCoins().toDouble(),
    );

    // Save progress
    GameStorage.saveLevelStars(language, levelId, starsEarned);
    GameStorage.setMaxUnlockedLevelIndex(language, levelNumber);
    if (levelNumber == 1) {
      GameStorage.setTutorialCompleted(true);
    }

    AudioManager.playVictory();
    _showFeedback('🎉 $victoryCelebrationText +$coinsReward 🪙', Colors.amberAccent);

    // Log Firebase Analytics Event
    AnalyticsService.logLevelComplete(
      level: levelNumber,
      language: language,
      stars: starsEarned,
    );
  }

  /// Get next unsolved target word for tutorial
  String? getNextUnsolvedTargetWord() {
    for (final target in level.targetWords) {
      if (!solvedTargetWords.contains(target.word)) {
        return target.word;
      }
    }
    return null;
  }

  /// Get valid path for tutorial word
  List<Point<int>>? getTutorialPathForWord(String word) {
    return _findValidActivePath(word);
  }

  /// Check if board contains any active tile with count > 1
  Point<int>? getFirstTileWithCountGreaterThanOne() {
    final height = grid.length;
    final width = height > 0 ? grid[0].length : 0;
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final tile = grid[r][c];
        if (!tile.isCleared && !tile.isObstacleLocked && tile.count > 1) {
          return Point(c, r);
        }
      }
    }
    return null;
  }

  /// Use 💡 Lightbulb Hint booster (Costs 80 Coins)
  Future<bool> useHint() async {
    if (isWon || isWinning) return false;

    boostersUsedCount++;

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
      AnalyticsService.logSpendResource(
        level: levelNumber,
        itemType: 'currency',
        itemName: 'coin',
        amount: hintCost.toDouble(),
        spendPlacement: 'ingame_booster',
        spendReason: 'hint',
        balance: GameStorage.getCoins().toDouble(),
      );
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
          final costStr = hasItem ? ' (Free Item)' : ' (-80 🪙)';
          _showFeedback('💡 Hint: "${target.word}"$costStr', const Color(0xFF69F0AE));
          AudioManager.playWordMatch();
          AnalyticsService.logBoosterUsed(boosterType: 'hint', level: levelNumber);
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
    if (isWon || isWinning) return false;

    boostersUsedCount++;

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
      AnalyticsService.logSpendResource(
        level: levelNumber,
        itemType: 'currency',
        itemName: 'coin',
        amount: rocketCost.toDouble(),
        spendPlacement: 'ingame_booster',
        spendReason: 'rocket',
        balance: GameStorage.getCoins().toDouble(),
      );
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

      // Decrement tile counts on board with 0-leftover guarantee
      final path = _findValidActivePath(word) ?? [];
      _decrementWordTiles(word, path);

      AudioManager.playBooster();
      AnalyticsService.logBoosterUsed(boosterType: 'rocket', level: levelNumber);
      final costStr = hasItem ? ' (Free Item)' : ' (-240 🪙)';
      _showFeedback('🚀 Rocket Cleared: "$word"!$costStr', const Color(0xFF69F0AE));

      _checkObstacleUnlocks();

      if (solvedTargetWords.length >= level.targetWords.length) {
        _victoryTimer?.cancel();
        _victoryTimer = Timer(const Duration(milliseconds: 500), () {
          _handleVictory();
          notifyListeners();
        });
        return true;
      }

      notifyListeners();
      return true;
    }

    _showFeedback('All target words are already solved!', Colors.white70);
    return false;
  }

  /// Checks if all remaining unsolved target words have at least one valid path on the board
  bool _areAllRemainingWordsSolvable(Set<String> solvedWords) {
    for (final tw in level.targetWords) {
      if (!solvedWords.contains(tw.word)) {
        if (_findValidActivePath(tw.word) == null) {
          return false;
        }
      }
    }
    return true;
  }

  /// Decrements tile counts with Solvability Protection, ensuring remaining words stay connected
  void _decrementWordTiles(String word, List<Point<int>> swipedPath) {
    final futureSolved = Set<String>.from(solvedTargetWords);

    for (int i = 0; i < word.length; i++) {
      final ch = word[i];
      final swipedPt = (i < swipedPath.length) ? swipedPath[i] : null;

      // Find all tiles on the board with this letter and count > 0
      final candidateTiles = <LetterTile>[];
      for (final row in grid) {
        for (final tile in row) {
          if (!tile.isCleared && tile.letter == ch && tile.count > 0) {
            candidateTiles.add(tile);
          }
        }
      }

      if (candidateTiles.isEmpty) continue;

      // Prefer the tile on the swiped path if available
      LetterTile chosenTile = candidateTiles.first;
      if (swipedPt != null) {
        final onPathTile = grid[swipedPt.y][swipedPt.x];
        if (candidateTiles.contains(onPathTile)) {
          chosenTile = onPathTile;
        }
      }

      // Decrement chosenTile
      chosenTile.count--;
      final wasCleared = chosenTile.count <= 0;
      if (wasCleared) chosenTile.isCleared = true;

      // If clearing chosenTile breaks any remaining word, search for a safer alternative tile
      if (!_areAllRemainingWordsSolvable(futureSolved) && candidateTiles.length > 1) {
        // Revert chosenTile
        if (wasCleared) chosenTile.isCleared = false;
        chosenTile.count++;

        LetterTile? safeTile;
        for (final altTile in candidateTiles) {
          if (altTile == chosenTile) continue;
          altTile.count--;
          final altCleared = altTile.count <= 0;
          if (altCleared) altTile.isCleared = true;

          if (_areAllRemainingWordsSolvable(futureSolved)) {
            safeTile = altTile;
            break;
          }

          // Revert altTile
          if (altCleared) altTile.isCleared = false;
          altTile.count++;
        }

        // If no safe tile was found, re-apply decrement on chosenTile
        if (safeTile == null) {
          chosenTile.count--;
          if (chosenTile.count <= 0) chosenTile.isCleared = true;
        }
      }
    }

    // Mark all tiles with count <= 0 as cleared immediately
    for (final row in grid) {
      for (final tile in row) {
        if (tile.count <= 0) {
          tile.count = 0;
          tile.isCleared = true;
        }
      }
    }
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
    _victoryTimer?.cancel();
    super.dispose();
  }
}

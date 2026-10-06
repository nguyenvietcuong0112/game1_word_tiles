import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/level_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.init();
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
  });

  test('Verify Level 1 Target Words (CAT, DOG, PEN) Solvability', () async {
    final file = File('assets/levels/english/level1.json');
    expect(file.existsSync(), isTrue);
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final level = LevelLoader.harmonizeLevel(LevelModel.fromJson(jsonMap));

    final targetStrings = level.targetWords.map((t) => t.word).toSet();
    expect(targetStrings.contains('CAT'), isTrue);
    expect(targetStrings.contains('DOG'), isTrue);
    expect(targetStrings.contains('PEN'), isTrue);

    final controller = GameController(
      language: 'english',
      levelId: 1,
      levelNumber: 1,
      level: level,
    );

    // Swipe targets: CAT, DOG, PEN
    for (final word in ['CAT', 'DOG', 'PEN']) {
      final path = controller.getTutorialPathForWord(word);
      expect(path, isNotNull, reason: 'Target $word must be traceable');
      controller.startSwipe(path!.first.y, path.first.x);
      for (int i = 1; i < path.length; i++) {
        controller.updateSwipe(path[i].y, path[i].x);
      }
      controller.endSwipe();
    }

    expect(controller.solvedTargetWords.length, equals(3));
    for (final r in controller.grid) {
      for (final t in r) {
        expect(t.isCleared, isTrue, reason: 'Tile at (${t.col}, ${t.row}) count=${t.count} not cleared');
      }
    }

    controller.dispose();
  });

  test('Verify Singular Target Words (ART, RAT) and Plural Extra Safeguard (ARTS, RATS)', () async {
    final level = LevelModel(
      id: 99,
      width: 4,
      height: 2,
      targetWords: const [
        TargetWord(word: 'ART', type: 0),
        TargetWord(word: 'RAT', type: 0),
      ],
      extraWords: const [
        TargetWord(word: 'ARTS', type: 0),
        TargetWord(word: 'RATS', type: 0),
      ],
      letterGrid: const [
        ['A', 'R', 'T', 'S'],
        ['R', 'A', 'T', 'S'],
      ],
      countsGrid: const [
        [1, 1, 1, 1],
        [1, 1, 1, 1],
      ],
      obstacles: const [],
    );

    final controller = GameController(
      language: 'english',
      levelId: 99,
      levelNumber: 99,
      level: level,
    );

    // 1. Swipe plural ARTS -> Should be recognized as extra word, no error
    final artsPath = controller.getTutorialPathForWord('ARTS');
    expect(artsPath, isNotNull);
    controller.startSwipe(artsPath!.first.y, artsPath.first.x);
    for (int i = 1; i < artsPath.length; i++) {
      controller.updateSwipe(artsPath[i].y, artsPath[i].x);
    }
    controller.endSwipe();
    expect(controller.foundExtraWords.contains('ARTS'), isTrue);
    expect(controller.invalidAttemptsCount, equals(0));

    // 2. Solve target words in order: ART, RAT
    for (final word in ['ART', 'RAT']) {
      final path = controller.getTutorialPathForWord(word);
      expect(path, isNotNull, reason: 'Must find path for target "$word"');
      controller.startSwipe(path!.first.y, path.first.x);
      for (int i = 1; i < path.length; i++) {
        controller.updateSwipe(path[i].y, path[i].x);
      }
      controller.endSwipe();
    }

    expect(controller.solvedTargetWords.length, equals(2));
    controller.dispose();
  });

  test('Verify Singular Target (TOP) and Plural Extra (TOPS)', () async {
    final level = LevelModel(
      id: 98,
      width: 4,
      height: 2,
      targetWords: const [
        TargetWord(word: 'TOP', type: 0),
      ],
      extraWords: const [
        TargetWord(word: 'TOPS', type: 0),
      ],
      letterGrid: const [
        ['T', 'O', 'P', 'S'],
        ['S', 'P', 'O', 'T'],
      ],
      countsGrid: const [
        [1, 1, 1, 1],
        [1, 1, 1, 1],
      ],
      obstacles: const [],
    );

    final controller = GameController(
      language: 'english',
      levelId: 98,
      levelNumber: 98,
      level: level,
    );

    // Swipe TOPS -> Recognized as extra word
    final topsPath = controller.getTutorialPathForWord('TOPS');
    expect(topsPath, isNotNull);
    controller.startSwipe(topsPath!.first.y, topsPath.first.x);
    for (int i = 1; i < topsPath.length; i++) {
      controller.updateSwipe(topsPath[i].y, topsPath[i].x);
    }
    controller.endSwipe();
    expect(controller.foundExtraWords.contains('TOPS'), isTrue);
    expect(controller.invalidAttemptsCount, equals(0));

    controller.dispose();
  });

  test('Verify Levels 1 to 20 are 100% solvable with noun targets', () async {
    for (int lvl = 1; lvl <= 20; lvl++) {
      final file = File('assets/levels/english/level$lvl.json');
      expect(file.existsSync(), isTrue, reason: 'Level $lvl file must exist');
      final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final level = LevelLoader.harmonizeLevel(LevelModel.fromJson(jsonMap));

      final controller = GameController(
        language: 'english',
        levelId: lvl,
        levelNumber: lvl,
        level: level,
      );

      for (final target in level.targetWords) {
        final path = controller.getTutorialPathForWord(target.word);
        expect(path, isNotNull, reason: 'Target word "${target.word}" in level $lvl must have path');
        controller.startSwipe(path!.first.y, path.first.x);
        for (int i = 1; i < path.length; i++) {
          controller.updateSwipe(path[i].y, path[i].x);
        }
        controller.endSwipe();
      }

      expect(controller.solvedTargetWords.length, equals(level.targetWords.length),
          reason: 'All targets in level $lvl must be solved');
      for (final r in controller.grid) {
        for (final t in r) {
          expect(t.isCleared, isTrue,
              reason: 'Tile (${t.col}, ${t.row}) in level $lvl must be cleared');
        }
      }

      controller.dispose();
    }
  });
}

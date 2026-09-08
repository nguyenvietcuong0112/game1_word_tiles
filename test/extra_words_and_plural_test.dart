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

  test('Verify Level 1 Extra Words (COP, TOP) and Target Words (CAT, CUP, POT)', () async {
    final file = File('assets/levels/english/level1.json');
    expect(file.existsSync(), isTrue);
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final level = LevelLoader.harmonizeLevel(LevelModel.fromJson(jsonMap));

    final targetStrings = level.targetWords.map((t) => t.word).toSet();
    expect(targetStrings.contains('CAT'), isTrue);
    expect(targetStrings.contains('CUP'), isTrue);
    expect(targetStrings.contains('POT'), isTrue);

    final extraWordStrings = level.extraWords.map((e) => e.word).toSet();
    expect(extraWordStrings.contains('COP'), isTrue, reason: 'Level 1 must contain COP in extra_words');
    expect(extraWordStrings.contains('TOP'), isTrue, reason: 'Level 1 must contain TOP in extra_words');

    final controller = GameController(
      language: 'english',
      levelId: 1,
      levelNumber: 1,
      level: level,
    );

    // Swipe COP -> Should be recognized as extra word
    final copPath = controller.getTutorialPathForWord('COP');
    expect(copPath, isNotNull, reason: 'COP must be traceable on grid');
    controller.startSwipe(copPath!.first.y, copPath.first.x);
    for (int i = 1; i < copPath.length; i++) {
      controller.updateSwipe(copPath[i].y, copPath[i].x);
    }
    controller.endSwipe();

    expect(controller.foundExtraWords.contains('COP'), isTrue);
    expect(controller.invalidAttemptsCount, equals(0));

    // Swipe targets: CAT, CUP, POT
    for (final word in ['CAT', 'CUP', 'POT']) {
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

  test('Verify Level 13 Singular Target Words (ART, RAT) and Plural Extra (ARTS, RATS)', () async {
    final file = File('assets/levels/english/level13.json');
    expect(file.existsSync(), isTrue);
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final level = LevelLoader.harmonizeLevel(LevelModel.fromJson(jsonMap));

    final targetStrings = level.targetWords.map((t) => t.word).toSet();
    expect(targetStrings.contains('ART'), isTrue, reason: 'Level 13 target must include ART');
    expect(targetStrings.contains('RAT'), isTrue, reason: 'Level 13 target must include RAT');
    expect(targetStrings.contains('STAR'), isTrue, reason: 'Level 13 target must include STAR');
    expect(targetStrings.contains('TAR'), isTrue, reason: 'Level 13 target must include TAR');

    final extraStrings = level.extraWords.map((e) => e.word).toSet();
    expect(extraStrings.contains('ARTS'), isTrue, reason: 'Level 13 extra must include ARTS');
    expect(extraStrings.contains('RATS'), isTrue, reason: 'Level 13 extra must include RATS');
    expect(extraStrings.contains('SAT'), isTrue, reason: 'Level 13 extra must include SAT');

    final controller = GameController(
      language: 'english',
      levelId: 13,
      levelNumber: 13,
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

    // 2. Solve target words in order: ART, RAT, TAR, STAR
    for (final word in ['ART', 'RAT', 'TAR', 'STAR']) {
      final path = controller.getTutorialPathForWord(word);
      expect(path, isNotNull, reason: 'Must find path for target "$word"');
      controller.startSwipe(path!.first.y, path.first.x);
      for (int i = 1; i < path.length; i++) {
        controller.updateSwipe(path[i].y, path[i].x);
      }
      controller.endSwipe();
    }

    expect(controller.solvedTargetWords.length, equals(4));
    // Verify all tiles cleared
    for (final r in controller.grid) {
      for (final t in r) {
        expect(t.isCleared, isTrue, reason: 'Tile at (${t.col}, ${t.row}) count=${t.count} not cleared');
      }
    }

    controller.dispose();
  });

  test('Verify Level 14 Singular Target (TOP) and Plural Extra (TOPS)', () async {
    final file = File('assets/levels/english/level14.json');
    expect(file.existsSync(), isTrue);
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final level = LevelLoader.harmonizeLevel(LevelModel.fromJson(jsonMap));

    final targetStrings = level.targetWords.map((t) => t.word).toSet();
    expect(targetStrings.contains('TOP'), isTrue, reason: 'Level 14 target must include TOP');

    final extraStrings = level.extraWords.map((e) => e.word).toSet();
    expect(extraStrings.contains('TOPS'), isTrue, reason: 'Level 14 extra must include TOPS');

    final controller = GameController(
      language: 'english',
      levelId: 14,
      levelNumber: 14,
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

    // Solve all targets: POST, SPOT, STOP, TOP
    for (final word in ['POST', 'SPOT', 'STOP', 'TOP']) {
      final path = controller.getTutorialPathForWord(word);
      expect(path, isNotNull, reason: 'Must find path for target "$word"');
      controller.startSwipe(path!.first.y, path.first.x);
      for (int i = 1; i < path.length; i++) {
        controller.updateSwipe(path[i].y, path[i].x);
      }
      controller.endSwipe();
    }

    expect(controller.solvedTargetWords.length, equals(4));
    for (final r in controller.grid) {
      for (final t in r) {
        expect(t.isCleared, isTrue, reason: 'Tile at (${t.col}, ${t.row}) count=${t.count} not cleared');
      }
    }

    controller.dispose();
  });

  test('Verify Levels 1 to 12 are 100% solvable with noun targets', () async {
    for (int lvl = 1; lvl <= 12; lvl++) {
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

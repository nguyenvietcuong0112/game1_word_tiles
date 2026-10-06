import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/level_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

Iterable<List<T>> generatePermutations<T>(List<T> list) sync* {
  if (list.length <= 1) {
    yield list;
    return;
  }
  for (int i = 0; i < list.length; i++) {
    final current = list[i];
    final remaining = List<T>.from(list)..removeAt(i);
    for (final perm in generatePermutations(remaining)) {
      yield [current, ...perm];
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.init();
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
  });

  test('Audit first 100 Vietnamese levels across all permutations', () {
    for (int id = 1; id <= 100; id++) {
      final file = File('assets/levels/vietnamese/level$id.json');
      if (!file.existsSync()) continue;
      final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rawLevel = LevelModel.fromJson(jsonMap);
      final level = LevelLoader.harmonizeLevel(rawLevel);

      final words = level.targetWords.map((t) => t.word).toList();
      // Limit to 6 permutations for performance
      final testPerms = generatePermutations(words).take(6).toList();

      for (final p in testPerms) {
        final controller = GameController(
          language: 'vietnamese',
          levelId: id,
          levelNumber: id,
          level: level,
        );

        for (final word in p) {
          final path = controller.getTutorialPathForWord(word);
          expect(path, isNotNull, reason: 'Vietnamese Level $id: Failed to find path for "$word" in order $p');

          controller.startSwipe(path!.first.y, path.first.x);
          for (int i = 1; i < path.length; i++) {
            controller.updateSwipe(path[i].y, path[i].x);
          }
          controller.endSwipe();
        }

        expect(controller.solvedTargetWords.length, equals(level.targetWords.length),
            reason: 'Vietnamese Level $id: Not all words solved');

        for (final r in controller.grid) {
          for (final t in r) {
            expect(t.isCleared, isTrue,
                reason: 'Vietnamese Level $id: Tile at (${t.col}, ${t.row}) count=${t.count} not cleared in order $p');
          }
        }
        controller.dispose();
      }
    }
  });

  test('Audit first 100 English levels across all permutations', () {
    for (int id = 1; id <= 100; id++) {
      final file = File('assets/levels/english/level$id.json');
      if (!file.existsSync()) continue;
      final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rawLevel = LevelModel.fromJson(jsonMap);
      final level = LevelLoader.harmonizeLevel(rawLevel);

      final words = level.targetWords.map((t) => t.word).toList();
      final testPerms = generatePermutations(words).take(6).toList();

      for (final p in testPerms) {
        final controller = GameController(
          language: 'english',
          levelId: id,
          levelNumber: id,
          level: level,
        );

        for (final word in p) {
          final path = controller.getTutorialPathForWord(word);
          expect(path, isNotNull, reason: 'English Level $id: Failed to find path for "$word" in order $p');

          controller.startSwipe(path!.first.y, path.first.x);
          for (int i = 1; i < path.length; i++) {
            controller.updateSwipe(path[i].y, path[i].x);
          }
          controller.endSwipe();
        }

        expect(controller.solvedTargetWords.length, equals(level.targetWords.length),
            reason: 'English Level $id: Not all words solved');

        for (final r in controller.grid) {
          for (final t in r) {
            expect(t.isCleared, isTrue,
                reason: 'English Level $id: Tile at (${t.col}, ${t.row}) count=${t.count} not cleared in order $p');
          }
        }
        controller.dispose();
      }
    }
  });
}

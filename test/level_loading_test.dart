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

  test('Test LevelLoader and GameController for early levels', () async {
    final rawLevel = LevelModel(
      id: 1,
      width: 3,
      height: 2,
      targetWords: [
        TargetWord(word: 'BÉ', type: 0),
        TargetWord(word: 'MẸ', type: 0),
        TargetWord(word: 'BÀ', type: 0),
      ],
      extraWords: [],
      letterGrid: [
        ['B', 'É', 'M'],
        ['B', 'À', 'Ẹ'],
      ],
      obstacles: [],
    );

    final harmonized = LevelLoader.harmonizeLevel(rawLevel);
    expect(harmonized.targetWords.length, equals(3));

    final controller = GameController(
      language: 'vietnamese',
      levelId: 1,
      levelNumber: 1,
      level: harmonized,
    );

    expect(controller.grid.length, equals(2));
    expect(controller.grid[0].length, equals(3));

    // Verify words are selectable and swipable
    final bePath = controller.getTutorialPathForWord('BÉ');
    expect(bePath, isNotNull);
    expect(bePath!.length, equals(2));

    controller.dispose();
  });
}

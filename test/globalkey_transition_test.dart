import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/views/widgets/board_widget.dart';
import 'package:word_tiles_flutter/views/widgets/booster_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.init();
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
  });

  LevelModel createMockLevel() {
    return const LevelModel(
      id: 1,
      width: 2,
      height: 1,
      targetWords: [TargetWord(word: 'HI', type: 0)],
      extraWords: [],
      letterGrid: [
        ['H', 'I'],
      ],
      obstacles: [],
    );
  }

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  Widget buildTransitionTree({
    required int levelIndex,
    required GlobalKey<BoardWidgetState> boardKey,
    required GlobalKey<ExtraWordsButtonState> extraWordsBtnKey,
    required GameController controller,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: KeyedSubtree(
        key: ValueKey('level-$levelIndex'),
        child: Column(
          children: [
            ExtraWordsButton(
              key: extraWordsBtnKey,
              extraCount: 0,
              onTap: () {},
            ),
            Expanded(
              child: BoardWidget(
                key: boardKey,
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Old behavior with static GlobalKeys reproduces duplicate GlobalKey assertion during AnimatedSwitcher transition', (tester) async {
    final controller = GameController(
      language: 'english',
      levelId: 1,
      levelNumber: 1,
      level: createMockLevel(),
    );

    // Old behavior: Fixed GlobalKeys reused across level transitions
    final staticBoardKey = GlobalKey<BoardWidgetState>();
    final staticExtraWordsKey = GlobalKey<ExtraWordsButtonState>();

    int currentLevel = 0;

    await tester.pumpWidget(
      wrapWithScreenUtil(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLevel++; // Switches child in AnimatedSwitcher WITHOUT regenerating keys
                    });
                  },
                  child: const Text('Next'),
                ),
                Expanded(
                  child: buildTransitionTree(
                    levelIndex: currentLevel,
                    boardKey: staticBoardKey,
                    extraWordsBtnKey: staticExtraWordsKey,
                    controller: controller,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    // Tap next level to trigger AnimatedSwitcher transition
    await tester.tap(find.text('Next'));
    
    // Pump mid-transition frame where both old and new subtrees exist simultaneously
    await tester.pump(const Duration(milliseconds: 50));

    // Flutter should catch duplicate GlobalKeys exception
    final dynamic error = tester.takeException();
    expect(error, isNotNull);
    expect(error.toString(), contains('Duplicate GlobalKeys detected'));

    controller.dispose();
  });

  testWidgets('New behavior: Regenerating GlobalKeys on level transition resolves duplicate GlobalKey assertion', (tester) async {
    final controller = GameController(
      language: 'english',
      levelId: 1,
      levelNumber: 1,
      level: createMockLevel(),
    );

    // New behavior: Keys regenerated upon level change
    GlobalKey<BoardWidgetState> boardKey = GlobalKey<BoardWidgetState>();
    GlobalKey<ExtraWordsButtonState> extraWordsKey = GlobalKey<ExtraWordsButtonState>();

    int currentLevel = 0;

    await tester.pumpWidget(
      wrapWithScreenUtil(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLevel++;
                      boardKey = GlobalKey<BoardWidgetState>();
                      extraWordsKey = GlobalKey<ExtraWordsButtonState>();
                    });
                  },
                  child: const Text('Next'),
                ),
                Expanded(
                  child: buildTransitionTree(
                    levelIndex: currentLevel,
                    boardKey: boardKey,
                    extraWordsBtnKey: extraWordsKey,
                    controller: controller,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    // Tap next level
    await tester.tap(find.text('Next'));

    // Pump mid-transition frame (50ms into 260ms animation)
    await tester.pump(const Duration(milliseconds: 50));

    // No exception should be thrown!
    expect(tester.takeException(), isNull);

    // Complete the animation
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    controller.dispose();
  });
}

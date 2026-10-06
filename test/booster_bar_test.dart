import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/views/widgets/booster_bar.dart';
import 'package:word_tiles_flutter/views/widgets/tutorial_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'player_coins': 500,
      'inventory_hint_count': 2,
      'inventory_rocket_count': 2,
    });
    await GameStorage.init();
  });

  LevelModel createMockLevel(int levelNumber) {
    return LevelModel(
      id: levelNumber,
      width: 3,
      height: 1,
      targetWords: [const TargetWord(word: 'CAT', type: 0)],
      extraWords: [],
      letterGrid: [
        ['C', 'A', 'T'],
      ],
      obstacles: [],
    );
  }

  GameController createController(int levelNumber) {
    return GameController(
      language: 'english',
      levelId: levelNumber,
      levelNumber: levelNumber,
      level: createMockLevel(levelNumber),
    );
  }

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  Finder findAssetImage(String assetName) {
    return find.byWidgetPredicate(
      (w) => w is Image && (w.image as AssetImage).assetName == assetName,
    );
  }

  testWidgets('Level 1-4: BoosterBar is hidden (no Hint, no Rocket, no menu_bar)', (tester) async {
    final controller = createController(1);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(findAssetImage('assets/icons/icon_hint.webp'), findsNothing);
    expect(findAssetImage('assets/icons/icon_rocket.webp'), findsNothing);
    expect(findAssetImage('assets/images/menu_bar.webp'), findsNothing);
  });

  testWidgets('Level 5: Only Hint button is visible (no Rocket, no menu_bar)', (tester) async {
    final controller = createController(5);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    // Hint is visible
    expect(findAssetImage('assets/icons/icon_hint.webp'), findsOneWidget);

    // Rocket and menu_bar are NOT visible
    expect(findAssetImage('assets/icons/icon_rocket.webp'), findsNothing);
    expect(findAssetImage('assets/images/menu_bar.webp'), findsNothing);
  });

  testWidgets('Level 6: Only Hint button is visible (no Rocket, no menu_bar)', (tester) async {
    final controller = createController(6);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(findAssetImage('assets/icons/icon_hint.webp'), findsOneWidget);
    expect(findAssetImage('assets/icons/icon_rocket.webp'), findsNothing);
    expect(findAssetImage('assets/images/menu_bar.webp'), findsNothing);
  });

  testWidgets('Level 7+: Both Hint and Rocket buttons and menu_bar are visible', (tester) async {
    final controller = createController(7);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    // Both boosters and menu_bar are now visible
    expect(findAssetImage('assets/icons/icon_hint.webp'), findsOneWidget);
    expect(findAssetImage('assets/icons/icon_rocket.webp'), findsOneWidget);
    expect(findAssetImage('assets/images/menu_bar.webp'), findsOneWidget);
  });

  testWidgets('isHintSpotlighted renders TutorialArrowPointer directly above Hint', (tester) async {
    final controller = createController(5);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(
          controller: controller,
          isHintSpotlighted: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TutorialArrowPointer), findsOneWidget);
  });

  testWidgets('Tapping Hint triggers onHintTap callback', (tester) async {
    final controller = createController(5);
    bool hintTapped = false;

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(
          controller: controller,
          isHintSpotlighted: true,
          onHintTap: () {
            hintTapped = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(findAssetImage('assets/icons/icon_hint.webp'));
    await tester.pump();
    expect(hintTapped, isTrue);

    // Let the hint timer complete
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('isRocketSpotlighted renders TutorialArrowPointer directly above Rocket', (tester) async {
    final controller = createController(7);

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(
          controller: controller,
          isRocketSpotlighted: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TutorialArrowPointer), findsOneWidget);
  });

  testWidgets('Tapping Rocket triggers onRocketTap callback', (tester) async {
    final controller = createController(7);
    bool rocketTapped = false;

    await tester.pumpWidget(
      buildTestWidget(
        BoosterBar(
          controller: controller,
          isRocketSpotlighted: true,
          onRocketTap: () {
            rocketTapped = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(findAssetImage('assets/icons/icon_rocket.webp'));
    await tester.pump();
    expect(rocketTapped, isTrue);

    // Drain rocket booster timer
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('ExtraWordsButton: isSpotlighted renders upward TutorialArrowPointer', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        ExtraWordsButton(
          extraCount: 5,
          onTap: () {},
          isSpotlighted: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final arrowFinder = find.byType(TutorialArrowPointer);
    expect(arrowFinder, findsOneWidget);

    final arrowWidget = tester.widget<TutorialArrowPointer>(arrowFinder);
    expect(arrowWidget.pointingUp, isTrue);
  });

  testWidgets('RocketBoosterTutorialOverlay: tapping Got It marks tutorial shown', (tester) async {
    await GameStorage.setRocketTutorialShown(false);
    expect(GameStorage.isRocketTutorialShown(), isFalse);

    bool dismissed = false;
    await tester.pumpWidget(
      buildTestWidget(
        RocketBoosterTutorialOverlay(
          onDismiss: () {
            dismissed = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Rocket')),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it!'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
    expect(GameStorage.isRocketTutorialShown(), isTrue);
  });
}

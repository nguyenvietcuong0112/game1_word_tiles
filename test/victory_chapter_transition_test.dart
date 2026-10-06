import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/ads_manager.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/widgets/bouncy_button.dart';
import 'package:word_tiles_flutter/views/widgets/victory_dialog.dart';

Finder findCartoon(String text) =>
    find.byWidgetPredicate((w) => w is CartoonText && w.text == text);

Finder findCongratsImage() => find.byWidgetPredicate((w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName.contains('icon_congrats'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'player_coins': 200,
    });
    await GameStorage.init();
    AdsManager.enableAds = false;
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
          body: Stack(
            children: [
              child,
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Normal victory level (Level 4) displays progress bar and next level button', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = createController(4);
    var nextLevelCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () => nextLevelCalled = true,
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Normal victory elements
    expect(findCongratsImage(), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(findCartoon('Level 5'), findsOneWidget);

    // Chapter milestone view should NOT be visible
    expect(find.text('CHAPTER COMPLETE!'), findsNothing);
    expect(find.text('Auto-advancing to next level...'), findsNothing);

    // Tapping Next Level button triggers onNextLevel
    final nextBtn = find.ancestor(
      of: findCartoon('Level 5'),
      matching: find.byType(BouncyButton),
    );
    await tester.tap(nextBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(nextLevelCalled, isTrue);
  });

  testWidgets('Chapter milestone level (Level 5) triggers slide animation and awards chapter bonus coins upon Next Chapter tap', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = createController(5);
    expect(controller.isLastLevelOfChapter, isTrue);
    expect(controller.chapterNumber, equals(1));

    // Initial coins = 200, Chapter 1 completion awards 50 coins -> 250
    final initialCoins = GameStorage.getCoins();
    expect(initialCoins, equals(200));

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () {},
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Step 1: Normal victory card with Next Chapter CTA
    expect(findCongratsImage(), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(findCartoon('Next Chapter'), findsOneWidget);

    // Tap Next Chapter to transition into chapter preview
    await tester.tap(findCartoon('Next Chapter'));
    await tester.pump();

    // Chapter bonus coins added upon entering preview
    expect(GameStorage.getCoins(), equals(250));

    // Chapter Milestone Header
    expect(find.text('CHAPTER COMPLETE!'), findsOneWidget);
    expect(find.text('Next chapter unlocked!'), findsOneWidget);

    // Both old chapter card and new chapter card exist in the widget tree for sliding transition
    expect(find.text('Fuji Lake'), findsOneWidget);
    expect(find.text('CHAPTER 1 COMPLETED'), findsOneWidget);
    expect(find.text('Alpine Forest'), findsOneWidget);
    expect(find.text('NEW CHAPTER UNLOCKED!'), findsOneWidget);
    expect(find.text('+50 Chapter Bonus!'), findsOneWidget);
    expect(find.text('Auto-advancing to next level...'), findsOneWidget);

    // Pump past the slide animation
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 750));

    // View is still stable
    expect(find.text('Alpine Forest'), findsOneWidget);
  });

  testWidgets('Chapter milestone level (Level 5) auto-advances to next level after ~2.2 seconds', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = createController(5);
    var nextLevelCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () => nextLevelCalled = true,
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Next Chapter
    await tester.tap(findCartoon('Next Chapter'));
    await tester.pump();

    expect(nextLevelCalled, isFalse);

    // At 1.5 seconds, has not auto-advanced yet
    await tester.pump(const Duration(milliseconds: 1500));
    expect(nextLevelCalled, isFalse);

    // At 2.2+ seconds, auto-advance fires
    await tester.pump(const Duration(milliseconds: 1000));
    expect(nextLevelCalled, isTrue);
  });

  testWidgets('Manual tap on Level button advances immediately without double-calling upon timer expiry', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = createController(5);
    var callCount = 0;

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () => callCount++,
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Next Chapter to enter preview
    await tester.tap(findCartoon('Next Chapter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tap Level 6 button manually at 400ms
    final nextBtn = find.ancestor(
      of: findCartoon('Level 6'),
      matching: find.byType(BouncyButton),
    );
    await tester.tap(nextBtn, warnIfMissed: false);
    await tester.pump();

    expect(callCount, equals(1));

    // Fast forward past the auto advance timer
    await tester.pump(const Duration(seconds: 5));

    // Must still be 1 (never double called)
    expect(callCount, equals(1));
  });

  testWidgets('Watching Rewarded Ad on normal level (Level 10) auto-advances to next level directly and skips Interstitial Ad', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AdsManager.enableAds = true;
    AdsManager.mockRewardResult = true;

    final controller = createController(10);
    var nextLevelCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () => nextLevelCalled = true,
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Rewarded Video button (which displays coins reward)
    final rewardBtn = find.ancestor(
      of: findCartoon('${controller.coinsReward}'),
      matching: find.byType(BouncyButton),
    );
    await tester.tap(rewardBtn);
    await tester.pump();

    // After 600ms delay, auto-advances directly to next level (not milestone)
    expect(nextLevelCalled, isFalse);
    await tester.pump(const Duration(milliseconds: 700));
    expect(nextLevelCalled, isTrue);

    AdsManager.enableAds = false;
    AdsManager.mockRewardResult = null;
  });

  testWidgets('Watching Rewarded Ad on chapter milestone (Level 15) auto-advances to chapter preview and skips Interstitial Ad', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AdsManager.enableAds = true;
    AdsManager.mockRewardResult = true;

    final controller = createController(15);
    expect(controller.isLastLevelOfChapter, isTrue);
    var nextLevelCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        VictoryOverlay(
          controller: controller,
          onNextLevel: () => nextLevelCalled = true,
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Rewarded Video button (which displays coins reward)
    final rewardBtn = find.ancestor(
      of: findCartoon('${controller.coinsReward}'),
      matching: find.byType(BouncyButton),
    );
    await tester.tap(rewardBtn);
    await tester.pump();

    // After 600ms delay, auto-advances to Chapter Preview
    await tester.pump(const Duration(milliseconds: 700));

    // Chapter Preview is now showing
    expect(find.text('CHAPTER COMPLETE!'), findsOneWidget);
    expect(find.text('Next chapter unlocked!'), findsOneWidget);

    // Auto-advances to next level after ~2.2s
    await tester.pump(const Duration(milliseconds: 2400));
    expect(nextLevelCalled, isTrue);

    AdsManager.enableAds = false;
    AdsManager.mockRewardResult = null;
  });
}


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/controllers/game_controller.dart';
import 'package:word_tiles_flutter/models/level_model.dart';
import 'package:word_tiles_flutter/services/ads_manager.dart';
import 'package:word_tiles_flutter/services/analytics_service.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/game_screen.dart';

Finder findCartoon(String text) =>
    find.byWidgetPredicate((w) => w is CartoonText && w.text == text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Map<String, dynamic>> capturedCalls = [];

  setUp(() async {
    capturedCalls.clear();

    SharedPreferences.setMockInitialValues({
      'player_coins': 500,
      'selected_language': 'english',
      'level_play_count_english_1': 0,
      'level_lose_count_english_1': 0,
      'level_play_count_english_2': 0,
      'level_lose_count_english_2': 0,
      'tutorial_completed': true,
      'count_tutorial_shown': true,
      'reverse_tutorial_shown': true,
      'hint_tutorial_shown': true,
      'extra_words_tutorial_shown': true,
      'rocket_tutorial_shown': true,
    });
    await GameStorage.init();
    AdsManager.enableAds = false;

    // Intercept FGSDK method calls via MethodChannel 'fgsdk'
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('fgsdk'), (MethodCall call) async {
      if (call.method == 'send') {
        final rawJson = call.arguments as String;
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        capturedCalls.add(decoded);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('fgsdk'), null);
  });

  Widget buildGameScreenWidget(int levelIndex, {required Key key}) {
    return ScreenUtilInit(
      key: key,
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: GameScreen(
          key: ValueKey('game_${levelIndex}_$key'),
          language: 'english',
          levelIndex: levelIndex,
        ),
      ),
    );
  }

  group('AnalyticsService Unit Tests', () {
    test('logLevelStart passes all required parameters to FGSDK', () {
      AnalyticsService.logLevelStart(
        level: 1,
        playCount: 2,
        loseCount: 1,
        playMode: 'default',
      );

      final call = capturedCalls.firstWhere((c) => c['m'] == 'logLevelStart');
      expect(call, isNotNull);
      final args = call['args'] as Map<String, dynamic>;
      expect(args['level'], equals(1));
      expect(args['playCount'], equals(2));
      expect(args['loseCount'], equals(1));
      expect(args['playMode'], equals('default'));

      final extra = args['extra'] as Map<String, dynamic>;
      expect(extra['level'], equals(1));
      expect(extra['play_count'], equals(2));
      expect(extra['lose_count'], equals(1));
      expect(extra['play_mode'], equals('default'));
    });

    test('logLevelEnd passes all required parameters on win', () {
      AnalyticsService.logLevelEnd(
        level: 5,
        playCount: 3,
        loseCount: 2,
        playDuration: 45.6,
        totalItems: 4,
        clearedItems: 4,
        success: true,
        reason: 'win',
        adDuration: 5.0,
      );

      final call = capturedCalls.firstWhere((c) => c['m'] == 'logLevelEnd');
      expect(call, isNotNull);
      final args = call['args'] as Map<String, dynamic>;
      expect(args['level'], equals(5));
      expect(args['playCount'], equals(3));
      expect(args['loseCount'], equals(2));
      expect(args['playMode'], equals('default'));
      expect(args['playDuration'], closeTo(45.6, 0.01));
      expect(args['success'], isTrue);
      expect(args['reason'], equals('win'));

      final extra = args['extra'] as Map<String, dynamic>;
      expect(extra['level'], equals(5));
      expect(extra['play_mode'], equals('default'));
      expect(extra['play_count'], equals(3));
      expect(extra['lose_count'], equals(2));
      expect(extra['play_duration'], equals(45));
      expect(extra['total_items'], equals(4));
      expect(extra['cleared_items'], equals(4));
      expect(extra['success'], isTrue);
      expect(extra['reason'], equals('win'));
      expect(extra['ad_duration'], equals(5));
    });

    test('logLevelEnd passes all required parameters on restart/quit (failed)', () {
      AnalyticsService.logLevelEnd(
        level: 3,
        playCount: 1,
        loseCount: 1,
        playDuration: 20.0,
        totalItems: 5,
        clearedItems: 2,
        success: false,
        reason: 'restart',
        adDuration: 0.0,
      );

      final call = capturedCalls.firstWhere((c) => c['m'] == 'logLevelEnd');
      expect(call, isNotNull);
      final args = call['args'] as Map<String, dynamic>;
      expect(args['level'], equals(3));
      expect(args['success'], isFalse);
      expect(args['reason'], equals('restart'));

      final extra = args['extra'] as Map<String, dynamic>;
      expect(extra['success'], isFalse);
      expect(extra['reason'], equals('restart'));
      expect(extra['total_items'], equals(5));
      expect(extra['cleared_items'], equals(2));
    });
  });

  group('GameScreen Level Start & End Integration Tests', () {
    testWidgets('GameScreen initial load triggers logLevelStart and updates play_count', (tester) async {
      await tester.pumpWidget(buildGameScreenWidget(0, key: const ValueKey('test1')));

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('LEVEL 1').evaluate().isNotEmpty) break;
      }
      expect(find.text('LEVEL 1'), findsOneWidget);

      final startCalls = capturedCalls.where((c) => c['m'] == 'logLevelStart').toList();
      expect(startCalls.length, equals(1));
      final startArgs = startCalls.first['args'] as Map<String, dynamic>;
      expect(startArgs['level'], equals(1));
      expect(startArgs['playCount'], equals(1));
      expect(startArgs['loseCount'], equals(0));

      expect(GameStorage.getLevelPlayCount('english', 1), equals(1));

      // Advance timers so no pending timers remain
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('GameScreen going Home from SettingsDialog triggers logLevelEnd with reason quit and increments lose_count', (tester) async {
      await tester.pumpWidget(buildGameScreenWidget(1, key: const ValueKey('test2'))); // Level 2

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('LEVEL 2').evaluate().isNotEmpty) break;
      }
      
      for (final el in find.byType(Text).evaluate()) { final t = el.widget as Text; print('test_bg Text: ' + (t.data ?? '')); }
      expect(find.text('LEVEL 2'), findsOneWidget);


      // Open settings dialog by long pressing the level header
      final levelHeader = find.text('LEVEL 2');
      expect(levelHeader, findsOneWidget);
      await tester.longPress(levelHeader);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Home button in SettingsDialog
      final homeBtn = findCartoon('Home');
      expect(homeBtn, findsOneWidget);
      await tester.tap(homeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

       final endCalls = capturedCalls.where((c) => c['m'] == 'logLevelEnd').toList();
      expect(endCalls.length, equals(1));
      final endArgs = endCalls.first['args'] as Map<String, dynamic>;
      expect(endArgs['level'], equals(2));
      expect(endArgs['success'], isFalse);
      expect(endArgs['reason'], equals('quit'));

      // Verify that level_exit is NOT triggered when ending a level via quit
      final exitCalls = capturedCalls.where((c) => c['m'] == 'logEvent' && (c['args'] as Map)['name'] == 'level_exit').toList();
      expect(exitCalls, isEmpty);

      await tester.idle();
      expect(GameStorage.getLevelLoseCount('english', 2), equals(1));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('GameScreen restarting level triggers logLevelEnd with reason restart and then logLevelStart', (tester) async {
      await tester.pumpWidget(buildGameScreenWidget(2, key: const ValueKey('test3'))); // Level 3

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.idle();
        if (find.text('LEVEL 3').evaluate().isNotEmpty) break;
      }
      expect(find.text('LEVEL 3'), findsOneWidget);

      // Initial level_start for Level 3
      final startCalls = capturedCalls.where((c) => c['m'] == 'logLevelStart').toList();
      expect(startCalls.length, equals(1));
      expect(startCalls.first['args']['level'], equals(3));
      expect(startCalls.first['args']['playCount'], equals(1));

      // Open settings dialog by long pressing the level header
      final levelHeader = find.text('LEVEL 3');
      expect(levelHeader, findsOneWidget);
      await tester.longPress(levelHeader);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Restart button in SettingsDialog
      final restartBtn = findCartoon('Restart');
      expect(restartBtn, findsOneWidget);
      await tester.tap(restartBtn);
      await tester.pump();
      // Wait for reloaded level
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('LEVEL 3').evaluate().isNotEmpty) break;
      }

      // Verify level_end was fired with reason restart and success false
      final endCalls = capturedCalls.where((c) => c['m'] == 'logLevelEnd').toList();
      expect(endCalls.length, equals(1));
      final endArgs = endCalls.first['args'] as Map<String, dynamic>;
      expect(endArgs['level'], equals(3));
      expect(endArgs['success'], isFalse);
      expect(endArgs['reason'], equals('restart'));

      // Verify that level_exit is NOT triggered when ending a level via restart
      final exitCalls = capturedCalls.where((c) => c['m'] == 'logEvent' && (c['args'] as Map)['name'] == 'level_exit').toList();
      expect(exitCalls, isEmpty);

      // Verify new level_start was fired for the restart attempt with play_count = 2
      final allStartCalls = capturedCalls.where((c) => c['m'] == 'logLevelStart').toList();
      expect(allStartCalls.length, equals(2));
      final secondStartArgs = allStartCalls[1]['args'] as Map<String, dynamic>;
      expect(secondStartArgs['level'], equals(3));
      expect(secondStartArgs['playCount'], equals(2));
      expect(secondStartArgs['loseCount'], equals(1));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('App lifecycle paused triggers level_exit with reason background', (tester) async {
      await tester.pumpWidget(buildGameScreenWidget(4, key: const ValueKey('test_bg'))); // Level 5
      await tester.idle();

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.idle();
        if (find.text('LEVEL 5').evaluate().isNotEmpty) break;
      }
      expect(find.text('LEVEL 5'), findsOneWidget);

      // Simulate app going to background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      final exitCalls = capturedCalls.where((c) => c['m'] == 'logEvent' && (c['args'] as Map)['name'] == 'level_exit').toList();
      expect(exitCalls.length, equals(1));
      final exitParams = (exitCalls.first['args'] as Map)['params'] as Map<String, dynamic>;
      expect(exitParams['reason'], equals('background'));
      expect(exitParams['level'], equals(5));

      // Simulate app resuming
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      final reopenCalls = capturedCalls.where((c) => c['m'] == 'logEvent' && (c['args'] as Map)['name'] == 'level_reopen').toList();
      expect(reopenCalls.length, equals(1));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('GameController victory triggers logLevelEnd with reason win without duplicate on exit', (tester) async {
      final mockLevel = LevelModel(
        id: 1,
        width: 3,
        height: 1,
        targetWords: [const TargetWord(word: 'CAT', type: 0)],
        extraWords: [],
        letterGrid: [
          ['C', 'A', 'T'],
        ],
        obstacles: [],
      );

      final controller = GameController(
        language: 'english',
        levelId: 1,
        levelNumber: 1,
        level: mockLevel,
      );

      // Solve the word to trigger victory
      controller.startSwipe(0, 0); // 'C'
      controller.updateSwipe(0, 1); // 'A'
      controller.updateSwipe(0, 2); // 'T'
      controller.endSwipe();

      // Allow async victory delay (500ms in GameController)
      await tester.pump(const Duration(milliseconds: 600));

      expect(controller.isWon, isTrue);

      final endCalls = capturedCalls.where((c) => c['m'] == 'logLevelEnd').toList();
      expect(endCalls.length, equals(1));
      final endArgs = endCalls.first['args'] as Map<String, dynamic>;
      expect(endArgs['level'], equals(1));
      expect(endArgs['success'], isTrue);
      expect(endArgs['reason'], equals('win'));

      // If controller is disposed, no duplicate logLevelEnd should be sent
      controller.dispose();
      final endCallsAfterDispose = capturedCalls.where((c) => c['m'] == 'logLevelEnd').toList();
      expect(endCallsAfterDispose.length, equals(1));
    });

    testWidgets('Header layout has no overlap between coin capsule and level title with 18480 coins on Level 15', (tester) async {
      await GameStorage.addCoins(18480 - GameStorage.getCoins());
      expect(GameStorage.getCoins(), equals(18480));

      await tester.pumpWidget(buildGameScreenWidget(14, key: const ValueKey('level15'))); // Level 15

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('LEVEL 15').evaluate().isNotEmpty) break;
      }

      expect(find.text('LEVEL 15'), findsOneWidget);
      expect(find.text('18480'), findsOneWidget);

      final levelRect = tester.getRect(find.text('LEVEL 15'));
      final coinsRect = tester.getRect(find.text('18480'));

      // Verify that the right edge of coins text is strictly to the left of the level text
      expect(coinsRect.right < levelRect.left, isTrue,
          reason: 'Coin text (${coinsRect.right}) must not reach Level text (${levelRect.left})');

      // Also verify plus badge rect does not overlap levelRect
      final plusBadge = find.byIcon(Icons.add_rounded);
      expect(plusBadge, findsOneWidget);
      final plusRect = tester.getRect(plusBadge);
      expect(plusRect.right < levelRect.left, isTrue,
          reason: 'Plus badge (${plusRect.right}) must not reach Level text (${levelRect.left})');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}

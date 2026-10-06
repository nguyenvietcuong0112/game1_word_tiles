import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/remote_config_service.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'music_enabled': true,
      'sound_enabled': true,
      'haptic_enabled': true,
      'selected_language': 'english',
    });
    await GameStorage.init();
    await GameStorage.setMusicEnabled(true);
    await GameStorage.setSoundEnabled(true);
    await GameStorage.setHapticEnabled(true);
  });

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

  Finder findCartoon(String text) =>
      find.byWidgetPredicate((w) => w is CartoonText && w.text == text);

  testWidgets('SettingsDialog renders in-game mode with Home and Restart buttons', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        const SettingsDialog(isHomeScreen: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(findCartoon('Setting'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(findCartoon('Home'), findsOneWidget);
    expect(findCartoon('Restart'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SettingsDialog renders home-screen mode with Language action', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        const SettingsDialog(isHomeScreen: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(findCartoon('Setting'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    // Home & Restart not present in home screen mode
    expect(findCartoon('Home'), findsNothing);
    expect(findCartoon('Restart'), findsNothing);
    // Language action is present
    expect(findCartoon('English'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Toggling switches updates GameStorage values', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        const SettingsDialog(isHomeScreen: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(GameStorage.isMusicEnabled(), isTrue);
    expect(GameStorage.isSoundEnabled(), isTrue);
    expect(GameStorage.isHapticEnabled(), isTrue);

    // Switch row: Music
    await tester.tap(find.text('Music'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Sound toggle
    await tester.tap(find.text('Sound'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Vibration toggle
    await tester.tap(find.text('Vibration'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify storage was toggled
    expect(GameStorage.isMusicEnabled(), isFalse);
    expect(GameStorage.isSoundEnabled(), isFalse);
    expect(GameStorage.isHapticEnabled(), isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Restart calls onRestartLevel callback', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool restartCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        SettingsDialog(
          isHomeScreen: false,
          onRestartLevel: () {
            restartCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(findCartoon('Restart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restartCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Home calls onGoHome callback', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool homeCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        SettingsDialog(
          isHomeScreen: false,
          onGoHome: () {
            homeCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(findCartoon('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(homeCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Home directly pops to first route without confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('HomeScreenWidget')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Push gameplay dummy route
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (gameContext) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              showDialog(
                context: gameContext,
                builder: (dialogContext) => SettingsDialog(
                  isHomeScreen: false,
                  onGoHome: () {
                    Navigator.of(gameContext).popUntil((route) => route.isFirst);
                  },
                ),
              );
            },
            child: const Text('OpenSettings'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OpenSettings'), findsOneWidget);

    // Open settings
    await tester.tap(find.text('OpenSettings'));
    await tester.pumpAndSettle();

    expect(findCartoon('Home'), findsOneWidget);

    // Tap Home
    await tester.tap(findCartoon('Home'));
    await tester.pumpAndSettle();

    // Both SettingsDialog and GameScreen are popped, returning directly to HomeScreenWidget
    expect(find.text('HomeScreenWidget'), findsOneWidget);
    expect(find.text('OpenSettings'), findsNothing);
    expect(findCartoon('Home'), findsNothing);
    expect(find.text('Pause Game'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('When cheatEnabled is true, DEV badge is rendered in SettingsDialog', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    RemoteConfigService.setMockValues(cheatEnabled: true);

    await tester.pumpWidget(
      buildTestWidget(
        const SettingsDialog(isHomeScreen: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DEV'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('When cheatEnabled is false, DEV badge is NOT rendered in SettingsDialog', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    RemoteConfigService.setMockValues(cheatEnabled: false);

    await tester.pumpWidget(
      buildTestWidget(
        const SettingsDialog(isHomeScreen: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DEV'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}

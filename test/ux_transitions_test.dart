import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/utils/game_transitions.dart';
import 'package:word_tiles_flutter/views/home_screen.dart';
import 'package:word_tiles_flutter/views/shop_screen.dart';
import 'package:word_tiles_flutter/views/widgets/bouncy_button.dart';
import 'package:word_tiles_flutter/views/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.init();
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
  });

  group('UX Transitions & BouncyButton Tests', () {
    testWidgets('BouncyButton scales down on tapDown and restores on tapUp', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncyButton(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 50,
                  child: Text('Click Me'),
                ),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(BouncyButton);
      expect(buttonFinder, findsOneWidget);

      // Verify initial scale is 1.0
      Transform transform = tester.widget(find.descendant(
        of: buttonFinder,
        matching: find.byType(Transform),
      ));
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.001));

      // Press down using tester.press
      final gesture = await tester.press(buttonFinder);
      await tester.pump(); // Initialize ticker
      await tester.pump(const Duration(milliseconds: 100)); // Advance animation

      final state = tester.state<BouncyButtonState>(buttonFinder);
      expect(state.currentScale, lessThan(0.96));

      // Release finger
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);

      // Verify scale restored to 1.0
      transform = tester.widget(find.descendant(
        of: buttonFinder,
        matching: find.byType(Transform),
      ));
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.001));
    });

    testWidgets('GamePageRoute executes Zoom-Fade transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    GamePageRoute(
                      child: const Scaffold(
                        body: Text('Page 2 Content'),
                      ),
                    ),
                  );
                },
                child: const Text('Go to Page 2'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Page 2'));
      await tester.pump(); // Start transition

      // Halfway through 260ms transition
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.text('Page 2 Content'), findsOneWidget);

      // Settle transition
      await tester.pumpAndSettle();
      expect(find.text('Page 2 Content'), findsOneWidget);
    });

    testWidgets('showGameDialog presents dialog with spring scale transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showGameDialog(
                    context: context,
                    builder: (ctx) => const AlertDialog(
                      title: Text('Spring Dialog Title'),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(); // Start dialog transition

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Spring Dialog Title'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Spring Dialog Title'), findsOneWidget);

      // Dismiss dialog
      await tester.tapAt(const Offset(10, 10)); // Tap barrier
      await tester.pumpAndSettle();
      expect(find.text('Spring Dialog Title'), findsNothing);
    });

    testWidgets('Tapping outside SettingsDialog dismisses it via barrier tap', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showGameDialog(
                      context: context,
                      builder: (ctx) => const SettingsDialog(isHomeScreen: true),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsDialog), findsOneWidget);

      // Tap outside the card on the dark scrim
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verified: SettingsDialog dismissed!
      expect(find.byType(SettingsDialog), findsNothing);
    });

    testWidgets('HomeScreen coin capsule renders 3D plus badge and taps to open ShopScreen', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Plus icon should be rendered inside the coin capsule
      expect(find.byIcon(Icons.add_rounded), findsWidgets);

      // Tap the plus icon or coin capsule
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();

      // ShopScreen should now be opened
      expect(find.byType(ShopScreen), findsOneWidget);
    });
  });
}


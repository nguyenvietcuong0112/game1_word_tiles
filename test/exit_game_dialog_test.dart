import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/widgets/exit_game_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'music_enabled': true,
      'sound_enabled': true,
      'haptic_enabled': true,
    });
    await GameStorage.init();
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

  testWidgets('ExitGameDialog renders header, notice icon, message, and buttons', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        const ExitGameDialog(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Header CartoonText
    expect(findCartoon('Exit Game'), findsOneWidget);

    // Question and reassurance
    expect(find.text('Are you sure you want to exit?'), findsOneWidget);
    expect(find.text('Your progress is always saved!'), findsOneWidget);

    // Action buttons
    expect(findCartoon('Exit'), findsOneWidget);
    expect(findCartoon('Stay'), findsOneWidget);

    // Notice icon image
    expect(
      find.byWidgetPredicate(
        (w) => w is Image && (w.image as AssetImage).assetName == 'assets/icons/icon_notice.webp',
      ),
      findsOneWidget,
    );

    // Close button image
    expect(
      find.byWidgetPredicate(
        (w) => w is Image && (w.image as AssetImage).assetName == 'assets/icons/icon_close.webp',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Exit calls onExit callback', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool exitCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        ExitGameDialog(
          onExit: () {
            exitCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(findCartoon('Exit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(exitCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Stay calls onStay callback', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool stayCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        ExitGameDialog(
          onStay: () {
            stayCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(findCartoon('Stay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(stayCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Close icon calls onStay callback', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool stayCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        ExitGameDialog(
          onStay: () {
            stayCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final closeFinder = find.byWidgetPredicate(
      (w) => w is Image && (w.image as AssetImage).assetName == 'assets/icons/icon_close.webp',
    );
    expect(closeFinder, findsOneWidget);

    await tester.tap(closeFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(stayCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}

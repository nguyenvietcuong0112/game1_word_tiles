import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/widgets/app_popup.dart';
import 'package:word_tiles_flutter/widgets/common/game_dialog.dart';

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

  Finder findAssetImage(String assetPath) => find.byWidgetPredicate(
        (w) => w is Image && (w.image as AssetImage).assetName == assetPath,
      );

  Finder findDecorationImage(String assetPath) => find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          final img = box.image?.image;
          return img is AssetImage && img.assetName == assetPath;
        }
        return false;
      });

  group('AppPopup UI Tests', () {
    testWidgets('Renders coin reward with icon_coin.webp and blue banner', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          const AppPopup(
            title: 'Coins Received!',
            message: 'You earned 50 Coins from watching a video!',
            icon: '🪙',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header CartoonText
      expect(findCartoon('Coins Received!'), findsOneWidget);

      // Blue banner header asset
      expect(findDecorationImage('assets/images/btn_gift.webp'), findsOneWidget);

      // Coin icon asset resolved from emoji
      expect(findAssetImage('assets/icons/icon_coin.webp'), findsOneWidget);

      // Message body
      expect(find.text('You earned 50 Coins from watching a video!'), findsOneWidget);

      // OK action button with CartoonText
      expect(findCartoon('OK'), findsOneWidget);

      // Close 'X' button
      expect(findAssetImage('assets/icons/icon_close.webp'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Renders error notice with icon_notice.webp and purple banner', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          const AppPopup(
            title: 'Purchase Notice',
            message: 'Unable to complete purchase at this time.',
            icon: '❌',
            isError: true,
            buttonText: 'Got It',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header CartoonText
      expect(findCartoon('Purchase Notice'), findsOneWidget);

      // Purple banner header asset for notice/error
      expect(findDecorationImage('assets/icons/bg_btn_setting.webp'), findsOneWidget);

      // Notice icon asset
      expect(findAssetImage('assets/icons/icon_notice.webp'), findsOneWidget);

      // Custom button text
      expect(findCartoon('Got It'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tapping OK button dismisses dialog and triggers onClose', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool closed = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    AppPopup.show(
                      ctx,
                      title: 'Pack Unlocked!',
                      message: 'Enjoy your boosters!',
                      icon: '✨',
                      onClose: () => closed = true,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(findCartoon('Pack Unlocked!'), findsOneWidget);
      expect(findAssetImage('assets/icons/icon_congrats.webp'), findsOneWidget);

      // Tap OK button
      await tester.tap(findCartoon('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(closed, isTrue);
      expect(findCartoon('Pack Unlocked!'), findsNothing);
    });

    testWidgets('GameDialog.showAlert delegates to modern AppPopup', (tester) async {
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
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GameDialog.showAlert(
                      ctx,
                      title: 'Reward Claimed',
                      message: 'You received extra coins!',
                      icon: '🪙',
                    );
                  },
                  child: const Text('Show Alert'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies modern 3D AppPopup elements
      expect(findCartoon('Reward Claimed'), findsOneWidget);
      expect(findAssetImage('assets/icons/icon_coin.webp'), findsOneWidget);
      expect(findAssetImage('assets/icons/icon_close.webp'), findsOneWidget);
    });

    testWidgets('AppPopup renders dual buttons when secondaryButtonText is provided', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool actionTriggered = false;
      bool secondaryTriggered = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppPopup(
            title: 'Not Enough Coins!',
            message: 'You need 180 coins. Go to Shop?',
            icon: '🪙',
            buttonText: 'Go to Shop',
            secondaryButtonText: 'Cancel',
            onAction: () => actionTriggered = true,
            onSecondaryAction: () => secondaryTriggered = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(findCartoon('Not Enough Coins!'), findsOneWidget);
      expect(findCartoon('Go to Shop'), findsOneWidget);
      expect(findCartoon('Cancel'), findsOneWidget);

      // Tap Go to Shop
      await tester.tap(findCartoon('Go to Shop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(actionTriggered, isTrue);
      expect(secondaryTriggered, isFalse);
    });
  });
}


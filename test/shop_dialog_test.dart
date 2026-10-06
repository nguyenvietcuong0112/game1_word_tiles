import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/ads_manager.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/widgets/app_popup.dart';
import 'package:word_tiles_flutter/views/widgets/shop_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'player_coins': 1000,
      'inventory_hint_count': 0,
      'inventory_rocket_count': 0,
      'last_daily_gift_claim_ms': 0,
    });
    await GameStorage.init();
    final coins = GameStorage.getCoins();
    if (coins != 1000) {
      await GameStorage.addCoins(1000 - coins);
    }
    final hints = GameStorage.getHintCount();
    if (hints != 0) {
      await GameStorage.addHintCount(-hints);
    }
    final rockets = GameStorage.getRocketCount();
    if (rockets != 0) {
      await GameStorage.addRocketCount(-rockets);
    }
    await GameStorage.setLastDailyGiftClaimTime(0);
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
    AdsManager.enableAds = false;
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

  testWidgets('ShopDialog renders Daily & Gift packs and titles', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(findCartoon('Daily & Gift'), findsOneWidget);
    expect(findCartoon('Free Pack'), findsOneWidget);
    expect(findCartoon('Explorer Pack'), findsOneWidget);
    expect(findCartoon('Master Pack'), findsOneWidget);
    expect(findCartoon('Free'), findsOneWidget);
    expect(findCartoon('300'), findsOneWidget);
    expect(findCartoon('800'), findsOneWidget);
  });

  testWidgets('Claiming Free Pack adds rewards and activates cooldown', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool updated = false;
    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {
          updated = true;
        }),
      ),
    );
    await tester.pump();

    // Free button is present
    expect(findCartoon('Free'), findsOneWidget);

    // Tap Free button
    await tester.tap(findCartoon('Free'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(updated, isTrue);
    expect(GameStorage.getHintCount(), 1);
    expect(GameStorage.getRocketCount(), 1);
    expect(GameStorage.canClaimDailyGift(), isFalse);

    // Pop the alert if shown
    if (find.text('OK').evaluate().isNotEmpty) {
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Buying Explorer Pack spends 300 coins and adds 3 hints and 1 rocket', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {}),
      ),
    );
    await tester.pump();

    final initialCoins = GameStorage.getCoins();
    expect(initialCoins, 1000);

    // Tap 300 button
    await tester.tap(findCartoon('300'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(GameStorage.getCoins(), 700);
    expect(GameStorage.getHintCount(), 3);
    expect(GameStorage.getRocketCount(), 1);
  });

  testWidgets('Buying Master Pack spends 800 coins and adds 8 hints and 4 rockets', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {}),
      ),
    );
    await tester.pump();

    final initialCoins = GameStorage.getCoins();
    expect(initialCoins, 1000);

    // Tap 800 button
    await tester.tap(findCartoon('800'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(GameStorage.getCoins(), 200);
    expect(GameStorage.getHintCount(), 8);
    expect(GameStorage.getRocketCount(), 4);
  });

  testWidgets('Countdown timer renders with grey background when on cooldown', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Set cooldown to 10 hours ago (so 14 hours remaining)
    final now = DateTime.now().millisecondsSinceEpoch;
    await GameStorage.setLastDailyGiftClaimTime(now - const Duration(hours: 10).inMilliseconds);

    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(findCartoon('Free'), findsNothing);
    // Find button container with btn_grey.png
    final greyBtn = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).image?.image is AssetImage &&
        ((w.decoration as BoxDecoration).image!.image as AssetImage).assetName.contains('btn_grey'));
    expect(greyBtn, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Buying pack with insufficient coins shows AppPopup with Go to Shop', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Set coins to 50 (insufficient for 300 coins Explorer Pack)
    final coins = GameStorage.getCoins();
    await GameStorage.addCoins(50 - coins);
    expect(GameStorage.getCoins(), 50);

    await tester.pumpWidget(
      buildTestWidget(
        ShopDialog(onUpdated: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 300 button
    await tester.tap(findCartoon('300'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // AppPopup should appear with 'Not Enough Coins!' and 'Go to Shop'
    expect(find.byType(AppPopup), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Not Enough Coins!'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Go to Shop'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is CartoonText && w.text == 'Cancel'),
      findsOneWidget,
    );
  });
}


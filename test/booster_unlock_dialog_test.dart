import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/views/widgets/booster_unlock_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'player_coins': 500,
      'inventory_hint_count': 0,
      'inventory_rocket_count': 0,
    });
    await GameStorage.init();
    final coins = GameStorage.getCoins();
    if (coins != 500) {
      await GameStorage.addCoins(500 - coins);
    }
    final hints = GameStorage.getHintCount();
    if (hints != 0) {
      await GameStorage.addHintCount(-hints);
    }
    final rockets = GameStorage.getRocketCount();
    if (rockets != 0) {
      await GameStorage.addRocketCount(-rockets);
    }
    await GameStorage.setSoundEnabled(false);
    await GameStorage.setHapticEnabled(false);
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

  testWidgets('BoosterUnlockDialog renders Hint popup correctly', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        const BoosterUnlockDialog(
          boosterType: BoosterType.hint,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title & Text
    expect(find.text('Hint Booster'), findsOneWidget);
    expect(find.text('Reveals a letter to help you find words!'), findsOneWidget);
    expect(find.text('x3'), findsWidgets);
    expect(find.text('180'), findsWidgets);
    expect(find.text('x1'), findsWidgets);
    expect(find.text('FREE'), findsWidgets);
  });

  testWidgets('BoosterUnlockDialog Free button grants +1 Hint', (tester) async {
    expect(GameStorage.getHintCount(), equals(0));

    await tester.pumpWidget(
      buildTestWidget(
        const BoosterUnlockDialog(
          boosterType: BoosterType.hint,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the Free button (Yellow button)
    final freeButton = find.text('FREE').last;
    await tester.tap(freeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(GameStorage.getHintCount(), equals(1));
  });

  testWidgets('BoosterUnlockDialog Coins button buys +3 Hints for 180 coins', (tester) async {
    expect(GameStorage.getCoins(), equals(500));
    expect(GameStorage.getHintCount(), equals(0));

    await tester.pumpWidget(
      buildTestWidget(
        const BoosterUnlockDialog(
          boosterType: BoosterType.hint,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the Buy button (Green button with 180 coins)
    final priceButton = find.text('180').last;
    await tester.tap(priceButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(GameStorage.getCoins(), equals(500 - 180));
    expect(GameStorage.getHintCount(), equals(3));
  });

  testWidgets('BoosterUnlockDialog renders Rocket popup correctly', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        const BoosterUnlockDialog(
          boosterType: BoosterType.rocket,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title & Text
    expect(find.text('Rocket Booster'), findsOneWidget);
    expect(find.text('Blasts and clears a hidden word instantly!'), findsOneWidget);
    expect(find.text('x3'), findsWidgets);
    expect(find.text('450'), findsWidgets);
    expect(find.text('x1'), findsWidgets);
    expect(find.text('FREE'), findsWidgets);
  });
}

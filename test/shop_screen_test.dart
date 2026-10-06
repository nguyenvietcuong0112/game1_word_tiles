import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/models/iap_product_model.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/iap_manager.dart';
import 'package:word_tiles_flutter/theme/app_typography.dart';
import 'package:word_tiles_flutter/views/shop_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'player_coins': 250,
      'inventory_hint_count': 2,
      'inventory_rocket_count': 1,
      'is_no_ads_purchased': false,
    });
    await GameStorage.init();
    await IapManager.init();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  Finder findCartoon(String text) =>
      find.byWidgetPredicate((w) => w is CartoonText && w.text == text);

  group('IapProduct Model & Catalog Tests', () {
    test('All 12 products are defined correctly', () {
      expect(IapProduct.allBundles.length, equals(6));
      expect(IapProduct.allGoldPacks.length, equals(6));
      expect(IapProduct.allProducts.length, equals(12));

      // Check Starter Pack
      final starter = IapProduct.starterPack;
      expect(starter.priceUsd, equals(2.99));
      expect(starter.coins, equals(400));
      expect(starter.hints, equals(2));
      expect(starter.rockets, equals(2));
      expect(starter.totalBoosters, equals(4));

      // Check No Ads Bundle
      final noAdsBundle = IapProduct.noAdsBundle;
      expect(noAdsBundle.priceUsd, equals(6.99));
      expect(noAdsBundle.coins, equals(400));
      expect(noAdsBundle.hints, equals(2));
      expect(noAdsBundle.rockets, equals(2));
      expect(noAdsBundle.isNoAds, isTrue);

      // Check No Ads
      final noAds = IapProduct.noAds;
      expect(noAds.priceUsd, equals(5.99));
      expect(noAds.isNoAds, isTrue);
      expect(noAds.isConsumable, isFalse);

      // Check Gold 0 (Free Ads Reward)
      final gold0 = IapProduct.gold0;
      expect(gold0.isAdsReward, isTrue);
      expect(gold0.coins, equals(50));
      expect(gold0.priceUsd, equals(0.0));
      expect(gold0.defaultPriceText, equals('Free'));

      // Check Gold 1
      final gold1 = IapProduct.gold1;
      expect(gold1.priceUsd, equals(0.99));
      expect(gold1.coins, equals(300));
    });

    test('IapManager price display falls back to USD default when offline', () {
      expect(IapManager.getDisplayPrice(IapProduct.starterPack), equals('\$2.99'));
      expect(IapManager.getDisplayPrice(IapProduct.noAds), equals('\$5.99'));
      expect(IapManager.getDisplayPrice(IapProduct.gold0), equals('Free'));
    });
  });

  group('GameStorage & No Ads Integration Tests', () {
    test('No Ads flag starts false and can be activated', () async {
      expect(GameStorage.isNoAdsPurchased(), isFalse);

      await GameStorage.setNoAdsPurchased(true);
      expect(GameStorage.isNoAdsPurchased(), isTrue);
      expect(GameStorage.noAdsNotifier.value, isTrue);

      // Reset testing
      await GameStorage.resetAllData();
      expect(GameStorage.isNoAdsPurchased(), isFalse);
    });
  });

  group('ShopScreen Widget UI Tests (Categorized Layout)', () {
    testWidgets('ShopScreen renders header with Shop title and Coin balance', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ShopScreen(currentLevel: 5)));
      await tester.pumpAndSettle();

      expect(findCartoon('Shop'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('ShopScreen renders section headers and No Ads card with custom icon', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ShopScreen(currentLevel: 5)));
      await tester.pumpAndSettle();

      // Section 1 Header
      expect(find.text('SPECIAL BUNDLES'), findsOneWidget);
      expect(findCartoon('Starter Pack'), findsOneWidget);
      expect(findCartoon('Limited Pack'), findsOneWidget);
      expect(findCartoon('No Ads Bundle'), findsOneWidget);
      expect(findCartoon('No Ads'), findsOneWidget);

      // Clapperboard custom icon is rendered
      expect(find.byType(ClapperboardNoAdsIcon), findsWidgets);

      // Badges
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);
    });

    testWidgets('ShopScreen renders Coin Shop with all tiers and Restore Purchases button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ShopScreen(currentLevel: 5)));
      await tester.pumpAndSettle();

      // Scroll to Coin Shop
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('COIN SHOP'), findsOneWidget);

      // Gold 0 (Free)
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);

      // Gold 1 (300)
      expect(find.text('300'), findsOneWidget);
      expect(find.text('\$0.99'), findsOneWidget);

      // Scroll to bottom for remaining gold cards and restore purchases
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Restore Purchases'), findsOneWidget);
    });
  });
}

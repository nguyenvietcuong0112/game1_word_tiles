enum IapCategory {
  bundle,
  gold,
}

class IapProduct {
  final String productId;
  final String enumId;
  final String title;
  final double priceUsd;
  final String defaultPriceText;
  final int coins;
  final int hints;
  final int rockets;
  final bool isNoAds;
  final bool isAdsReward;
  final bool isConsumable;
  final IapCategory category;
  final String? badgeText;

  const IapProduct({
    required this.productId,
    required this.enumId,
    required this.title,
    required this.priceUsd,
    required this.defaultPriceText,
    this.coins = 0,
    this.hints = 0,
    this.rockets = 0,
    this.isNoAds = false,
    this.isAdsReward = false,
    this.isConsumable = true,
    required this.category,
    this.badgeText,
  });

  int get totalBoosters => hints + rockets;

  // ── Special & Bundle Packs ──────────────────────────────────────────────────
  static const noAds = IapProduct(
    productId: 'com.fw.word.connect.puzzle.no_ads',
    enumId: 'no_ads',
    title: 'No Ads',
    priceUsd: 5.99,
    defaultPriceText: '\$5.99',
    isNoAds: true,
    isConsumable: false,
    category: IapCategory.bundle,
  );

  static const noAdsBundle = IapProduct(
    productId: 'com.fw.word.connect.puzzle.no_ads_bundle',
    enumId: 'no_ads_bundle',
    title: 'No Ads Bundle',
    priceUsd: 6.99,
    defaultPriceText: '\$6.99',
    coins: 400,
    hints: 2,
    rockets: 2,
    isNoAds: true,
    isConsumable: false,
    category: IapCategory.bundle,
    badgeText: 'BEST VALUE',
  );

  static const starterPack = IapProduct(
    productId: 'com.fw.word.connect.puzzle.starter_pack',
    enumId: 'starter_pack',
    title: 'Starter Pack',
    priceUsd: 2.99,
    defaultPriceText: '\$2.99',
    coins: 400,
    hints: 2,
    rockets: 2,
    category: IapCategory.bundle,
    badgeText: 'POPULAR',
  );

  static const limitedPack = IapProduct(
    productId: 'com.fw.word.connect.puzzle.limited_pack',
    enumId: 'limited_pack',
    title: 'Limited Pack',
    priceUsd: 5.99,
    defaultPriceText: '\$5.99',
    coins: 800,
    hints: 4,
    rockets: 4,
    category: IapCategory.bundle,
    badgeText: 'LIMITED',
  );

  static const beginnerBundle = IapProduct(
    productId: 'com.fw.word.connect.puzzle.beginner_bundle',
    enumId: 'beginner_bundle',
    title: 'Beginner Bundle',
    priceUsd: 14.99,
    defaultPriceText: '\$14.99',
    coins: 1500,
    hints: 4,
    rockets: 4,
    category: IapCategory.bundle,
  );

  static const masterBundle = IapProduct(
    productId: 'com.fw.word.connect.puzzle.master_bundle',
    enumId: 'master_bundle',
    title: 'Master Bundle',
    priceUsd: 29.99,
    defaultPriceText: '\$29.99',
    coins: 2500,
    hints: 5,
    rockets: 5,
    category: IapCategory.bundle,
    badgeText: 'MEGA',
  );

  // ── Gold Packs ─────────────────────────────────────────────────────────────
  static const gold0 = IapProduct(
    productId: 'gold_0',
    enumId: 'gold_0',
    title: 'Gold 0',
    priceUsd: 0.0,
    defaultPriceText: 'Free',
    coins: 50,
    isAdsReward: true,
    category: IapCategory.gold,
  );

  static const gold1 = IapProduct(
    productId: 'com.fw.word.connect.puzzle.gold_1',
    enumId: 'gold_1',
    title: 'Gold 1',
    priceUsd: 0.99,
    defaultPriceText: '\$0.99',
    coins: 300,
    category: IapCategory.gold,
  );

  static const gold2 = IapProduct(
    productId: 'com.fw.word.connect.puzzle.gold_2',
    enumId: 'gold_2',
    title: 'Gold 2',
    priceUsd: 7.99,
    defaultPriceText: '\$7.99',
    coins: 1000,
    category: IapCategory.gold,
  );

  static const gold3 = IapProduct(
    productId: 'com.fw.word.connect.puzzle.gold_3',
    enumId: 'gold_3',
    title: 'Gold 3',
    priceUsd: 15.99,
    defaultPriceText: '\$15.99',
    coins: 2000,
    category: IapCategory.gold,
  );

  static const gold4 = IapProduct(
    productId: 'com.fw.word.connect.puzzle.gold_4',
    enumId: 'gold_4',
    title: 'Gold 4',
    priceUsd: 29.99,
    defaultPriceText: '\$29.99',
    coins: 3000,
    category: IapCategory.gold,
  );

  static const gold5 = IapProduct(
    productId: 'com.fw.word.connect.puzzle.gold_5',
    enumId: 'gold_5',
    title: 'Gold 5',
    priceUsd: 55.99,
    defaultPriceText: '\$55.99',
    coins: 6000,
    category: IapCategory.gold,
  );

  static const List<IapProduct> allBundles = [
    starterPack,
    noAdsBundle,
    noAds,
    limitedPack,
    beginnerBundle,
    masterBundle,
  ];

  static const List<IapProduct> allGoldPacks = [
    gold0,
    gold1,
    gold2,
    gold3,
    gold4,
    gold5,
  ];

  static const List<IapProduct> allProducts = [
    ...allBundles,
    ...allGoldPacks,
  ];
}

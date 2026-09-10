import 'package:flutter/foundation.dart';
import 'package:funtap_global_sdk/funtap_global_sdk.dart';

/// Remote Config Service for Word Tiles Ads & Gameplay parameters.
/// Reads values from Funtap Global SDK with robust defaults matching the ad spec.
class RemoteConfigService {
  RemoteConfigService._();

  // Keys from Ad Specification
  static const String keyInterLevelX = 'Inter_level_x';
  static const String keyAdsInterval = 'Ads_interval';
  static const String keyAoaFormat = 'Aoa_format';
  static const String keyAdsReplay = 'Ads_replay';
  static const String keyAdsResume = 'Ads_resume';

  // Cached values with defaults
  static int _interLevelX = 10;
  static int _adsInterval = 25;
  static bool _aoaFormat = false; // false = AdMob, true = MAX
  static bool _adsReplay = false; // false = Inter, true = Native full screen
  static bool _adsResume = false; // false = AOA, true = Inter

  static int get interLevelX => _interLevelX;
  static int get adsInterval => _adsInterval;
  static bool get aoaFormat => _aoaFormat;
  static bool get adsReplay => _adsReplay;
  static bool get adsResume => _adsResume;

  /// Fetch all Remote Configs from FGSDK
  static Future<void> fetchConfigs() async {
    try {
      final isReady = await FGSDK.isRemoteConfigReady();
      debugPrint('[RemoteConfig] isRemoteConfigReady: $isReady');

      _interLevelX = await FGSDK.getRemoteConfigInt(keyInterLevelX, 10);
      _adsInterval = await FGSDK.getRemoteConfigInt(keyAdsInterval, 25);
      _aoaFormat = await FGSDK.getRemoteConfigBool(keyAoaFormat, false);
      _adsReplay = await FGSDK.getRemoteConfigBool(keyAdsReplay, false);
      _adsResume = await FGSDK.getRemoteConfigBool(keyAdsResume, false);

      debugPrint(
        '[RemoteConfig] Configs loaded -> '
        'interLevelX: $_interLevelX, '
        'adsInterval: ${_adsInterval}s, '
        'aoaFormat: $_aoaFormat, '
        'adsReplay: $_adsReplay, '
        'adsResume: $_adsResume',
      );
    } catch (e) {
      debugPrint('[RemoteConfig] Error fetching remote configs: $e');
    }
  }

  /// Listen to real-time remote config fetched event
  static void listenToUpdates() {
    FGSDK.onRemoteConfigFetched.listen((_) {
      debugPrint('[RemoteConfig] onRemoteConfigFetched triggered, refreshing...');
      fetchConfigs();
    });
  }

  @visibleForTesting
  static void setMockValues({
    int? interLevelX,
    int? adsInterval,
    bool? aoaFormat,
    bool? adsReplay,
    bool? adsResume,
  }) {
    if (interLevelX != null) _interLevelX = interLevelX;
    if (adsInterval != null) _adsInterval = adsInterval;
    if (aoaFormat != null) _aoaFormat = aoaFormat;
    if (adsReplay != null) _adsReplay = adsReplay;
    if (adsResume != null) _adsResume = adsResume;
  }
}

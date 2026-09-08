# funtap_global_sdk — Funtap Global SDK cho Flutter

Plugin Flutter (Android + iOS) của **Funtap Global SDK** `3.2.6`: ads (AppLovin MAX + AdMob backfill), tracking (Firebase / AppsFlyer / Facebook / AppLovin), remote config, IAP, deeplink.

**Dùng chung lõi native** với 2 package Cocos (`funtap-global-sdk-cocos`, `funtap-global-sdk-cocos2x`) qua đúng một protocol bridge (`FGBridgeCore`) ⇒ tên event / param / hành vi **y hệt**, chỉ khác đường truyền:

```
Dart  ──MethodChannel "fgsdk"────────►  FGSDKFlutterPlugin ──► FGBridgeCore ──► FGSDK native
      ◄─EventChannel  "fgsdk/events"──
```

---

## 1. Cài

Copy `install-fgsdk-flutter-<batver>.bat` vào **root project Flutter** (ngang `pubspec.yaml`) → **double-click**.

Bat sẽ: kéo package từ registry → giải nén vào `<project>/funtap_global_sdk/` → thêm `path:` dependency vào `pubspec.yaml` → ép `minSdk >= 24` → rải `fetch-config-flutter.*` ra root.

> **Vì sao phải qua bat?** `pub` chỉ đọc được pub.dev / pub server / git / thư mục local — **không đọc được npm registry**. Nên package phải được tải xuống đĩa trước, rồi `pubspec.yaml` trỏ `path:`. Bat chỉ tự động hoá đúng 3 bước đó.
>
> Số trong tên bat = version **của file bat**, KHÔNG phải version SDK (bat luôn kéo SDK mới nhất, và in cả 2 số lúc chạy).

Rồi:
```bash
flutter pub get
```

## 2. Config

Double-click **`fetch-config-flutter.bat`** ở root → nhập **API Key**. Nó kéo về và đặt đúng chỗ:

| File | Đích |
|---|---|
| `fg_main_config.json` | `android/app/src/main/assets/` + `ios/Runner/` |
| `google-services.json` | `android/app/` |
| `GoogleService-Info.plist` | `ios/Runner/` |
| keystore + `key.properties` | `android/` |
| AdMob app id | ghi `FGSDK_ADMOB_APP_ID=…` vào `android/gradle.properties` |

> ⚠️ **Thiếu `fg_main_config.json` = SDK không init** (`isInit()` trả `false`).
> ⚠️ `key.properties` + keystore chứa secret — **đừng commit vào git**.
> ⚠️ iOS: nhớ add `GoogleService-Info.plist` + `fg_main_config.json` vào Xcode project `Runner` nếu chưa có.

## 3. Dùng

```dart
import 'package:funtap_global_sdk/funtap_global_sdk.dart';

// SDK TỰ init lúc app khởi động — không cần gọi hàm init nào.
final ready = await FGSDK.isInit();

// Ads
FGSDK.onRewardedCompleted.listen((info) => grantReward(info));   // nhận thưởng ở đây
await FGSDK.showRewarded('double_coin', 'classic', 12);
await FGSDK.showInterstitial('main_menu', 'classic', 12);
FGSDK.showBanner('bottom', 'classic', 12);

// Tracking (event/param VERBATIM, bắn Firebase)
FGSDK.logLevelStart(12, 3, 1, 'classic');
FGSDK.logLevelEnd(12, 3, 1, 'classic', 45.2, true, 'clear');
FGSDK.logSpendResource('classic', 12, 'booster', 'gold', 30, 'shop', 'buy', 'sword', 'booster', 170);
FGSDK.logTutorial('success', 'step_3');
FGSDK.logEvent('custom_event', params: {'k': 'v'});

// IAP
final r = await FGSDK.buyProduct('com.game.pack1', 'shop', 'classic', 12);
if (r.ok) print(r.transactionId);
```

Quy ước: getter / `show*` / `buy*` trả **`Future`**; `on*` trả **`Stream`** (broadcast). Không có native (unit test / web / desktop) → **no-op**, getter trả default.

App mẫu đầy đủ nút test: [`example/lib/main.dart`](example/lib/main.dart).

### Hàm tracking gọi sẵn

| Hàm | Event Firebase |
|---|---|
| `logLevelStart(level, playCount, loseCount, playMode, {extra})` | `level_start` |
| `logLevelEnd(level, playCount, loseCount, playMode, playDuration, success, reason, {extra})` | `level_end` |
| `logEarnResource(playMode, level, itemType, name, amount, earnPlacement, item, booster, balance, {extra})` | `resource_source` |
| `logSpendResource(playMode, level, itemType, name, amount, spendPlacement, spendReason, item, booster, balance, {extra})` | `resource_sink` |
| `logTutorial(actionName, actionValue, {extra})` | `tut_action` |
| `logLoadingStart(placement, {extra})` / `logLoadingEnd(placement, isLoad, loadTime, {extra})` | `loading_start` / `loading_finish` |
| `logIAPShow(...)` / `logIAPClick(...)` | `iap_show` / `iap_click` |

`logEvent` không truyền `providers` = **chỉ Firebase** (không phải tất cả provider).

### Event SDK tự log (không cần gọi tay)

- **Firebase**: `ad_request`, `ad_display`, `ad_completed`, `ad_impression`, `ad_revenue_sdk`, `ad_click`.
- **AppLovin** (tự mirror từ event ở trên): `ad_view`, `rewarded_ad_opportunity`, `ad_click`, `level_start`, `level_complete`, `virtual_resource_transaction`, `tutorial_complete`, `use_prop`, `app_open`. Không cần init riêng — bám instance MAX SDK (điều kiện: app dùng mediation có MAX).

---

## 4. iOS

Phần native iOS được đóng gói dạng **`ios/Frameworks/FGSDK.xcframework`** (binary, kín source — đồng bộ với `fgsdk-release.aar` bên Android).

⚠️ Nếu bản package bạn nhận **chưa kèm** xcframework thì `pod install` sẽ báo lỗi rõ ràng và **chỉ build được Android**. Xin Funtap bản có kèm binary iOS.

*Maintainer:* build trên máy Mac —
```bash
brew install xcodegen cocoapods
bash native/ios/tools/build-xcframework.sh
```
→ sinh `flutter/funtap_global_sdk/ios/Frameworks/FGSDK.xcframework`, rồi publish lại package.

---

## 5. Cập nhật version mới

Chạy lại `install-fgsdk-flutter-<batver>.bat` → `flutter pub get` → build lại. Config giữ nguyên, khỏi fetch lại.

## 6. Troubleshooting

| Triệu chứng | Xử lý |
|---|---|
| `isInit()` = false | Thiếu `fg_main_config.json` trong `android/app/src/main/assets` → chạy fetch config |
| Quảng cáo không ra tiền (bản release) | AdMob app id vẫn là bản TEST. Kiểm `FGSDK_ADMOB_APP_ID` trong `android/gradle.properties` — thiếu thì chạy lại fetch config. (Đặt ở `app/build.gradle` **không có tác dụng**: meta-data nằm trong manifest của plugin.) |
| `pod install` báo thiếu `FGSDK.xcframework` | Package chưa kèm binary iOS (xem §4) |
| Gọi hàm mới mà im re | Package cũ — chạy lại install bat + `flutter pub get` |
| Build lỗi minSdk | Cần `minSdk >= 24`; wire script tự sửa, kiểm lại `android/app/build.gradle` |

---

Version package ≠ version native SDK (`getSdkVersion()` = `3.2.6`, verbatim Unity).

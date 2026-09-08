# Changelog — funtap_global_sdk (Flutter)

## 1.0.0

Bản đầu tiên. Plugin Flutter cho Funtap Global SDK `3.2.6`, **dùng chung lõi native** với 2 package Cocos.

### Added
- **Dart API** mirror 1:1 wrapper Cocos (`fgsdk.ts`): core, tracking (9 hàm gọi sẵn + `logEvent`/`setUserProperties`), ads (interstitial/reward/banner/app-open/mrec), remote config, IAP, deeplink. `on*` trả `Stream` broadcast; getter/`show*`/`buy*` trả `Future`.
- **Bridge** MethodChannel `fgsdk` + EventChannel `fgsdk/events`, giữ **nguyên protocol JSON** `{m,args,cb}` / `{e,…}` của `FGBridgeCore` ⇒ hành vi y hệt bản Cocos.
- **Android**: `FGSDKFlutterPlugin.kt` (ActivityAware — init SDK, forward event, `onNewIntent` deeplink) + nhúng `fgsdk-release.aar` + `fgsdk-deps.gradle`. Manifest plugin tự merge permission + AdMob meta-data (không phải dán tay như Cocos).
- **iOS**: `FGSDKFlutterPlugin.mm` (ObjC++) + podspec vendor `FGSDK.xcframework` + khai third-party pods (spec §17). Nhận `openURL` cho deeplink.
- **Tooling**: `install-fgsdk-flutter-1.0.0.bat` (kéo registry → `path:` dependency → wire minSdk), `fetch-config-flutter.{bat,js}` (API Key → config/google-services/keystore + chèn AdMob app id), `publish-fgsdk-flutter.bat`, `native/ios/tools/build-xcframework.sh`.
- **example/** app tester đủ nút test API + log panel.

### Notes
- Event phát sinh trước khi Dart kịp `listen` được **đệm** (tối đa 64) rồi flush — bản Cocos không cần vì bridge cài đồng bộ lúc khởi động.
- Chưa build được `FGSDK.xcframework` từ Windows → bản đầu chỉ chạy thật ở **Android**; iOS cần chạy `build-xcframework.sh` trên Mac rồi publish lại.

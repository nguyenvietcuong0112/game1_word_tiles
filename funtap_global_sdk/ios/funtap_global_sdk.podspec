#
# funtap_global_sdk.podspec — phần iOS của plugin Flutter.
#
# Lõi SDK được vendor dưới dạng **FGSDK.xcframework** (binary, KHÔNG ship source ObjC++) —
# đồng bộ với cách Android dùng fgsdk-release.aar.
#
# ⚠️ `Frameworks/FGSDK.xcframework` KHÔNG có sẵn trong repo (không build được trên Windows).
#    Chạy trên máy Mac:  tools/build-xcframework.sh   → sinh ra ios/Frameworks/FGSDK.xcframework
#    Thiếu file này thì `pod install` sẽ báo lỗi ngay (xem check bên dưới).
#
Pod::Spec.new do |s|
  s.name             = 'funtap_global_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Funtap Global SDK — ads, tracking, remote config, IAP, deeplink cho Flutter.'
  s.description      = 'Plugin Flutter dùng chung lõi native với 2 package Cocos (protocol FGBridgeCore).'
  s.homepage         = 'https://funtapglobal.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Funtap' => 'ducta@funtap.vn' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '13.0'   # ATT (§6.1/§6.2) + connectedScenes cần iOS 13+
  s.requires_arc     = true

  # Glue plugin (ObjC++). Lõi SDK nằm trong xcframework bên dưới.
  s.source_files        = 'Classes/**/*.{h,mm}'
  s.public_header_files  = 'Classes/**/*.h'

  s.vendored_frameworks = 'Frameworks/FGSDK.xcframework'

  s.dependency 'Flutter'

  # ObjC++ C++17 (SDK dùng std::function / std::optional / inline variable)
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY'           => 'libc++',
    'DEFINES_MODULE'              => 'YES',
    # Flutter build cho iOS device: loại i386
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64',
  }

  s.frameworks = 'StoreKit', 'AppTrackingTransparency', 'AdSupport', 'Network', 'UIKit', 'Foundation'

  # Third-party mà FGSDK cần (baseline spec §17 — khớp FGSDK.podspec bản Cocos).
  s.dependency 'AppLovinSDK'                    # ads MAX §7 (+ UMP đi kèm)
  s.dependency 'Google-Mobile-Ads-SDK'          # admob backfill §8
  s.dependency 'GoogleUserMessagingPlatform'    # consent UMP §6.1
  s.dependency 'FirebaseAnalytics'              # tracking §9
  s.dependency 'FirebaseRemoteConfig'           # remote config §10
  s.dependency 'AppsFlyerFramework'             # tracking §9.4
  s.dependency 'PurchaseConnector'              # ROI360 af_purchase §11 (StoreKit 1)
  s.dependency 'FBSDKCoreKit'                   # facebook §9.5

  # Báo lỗi SỚM + rõ ràng thay vì để CocoaPods fail khó hiểu.
  unless File.directory?(File.join(__dir__, 'Frameworks', 'FGSDK.xcframework'))
    raise <<~MSG
      [funtap_global_sdk] Thiếu ios/Frameworks/FGSDK.xcframework — bản package này chưa kèm binary iOS.
      Android vẫn chạy bình thường; muốn build iOS hãy xin Funtap bản package có kèm xcframework.
      (Maintainer: build bằng native/ios/tools/build-xcframework.sh trên máy Mac rồi publish lại.)
    MSG
  end
end

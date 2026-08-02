import 'dart:io' show Platform;

/// The set of AdMob ad unit IDs for a single platform (Android or iOS).
///
/// Create one of these per platform and combine them into an [AdUnitIdSet]
/// to pass to `AdsManager.init`.
class AdUnitIds {
  /// Ad unit ID used for standard and adaptive banners.
  final String banner;

  /// Ad unit ID for the "Large Banner" (320x100) size.
  ///
  /// Falls back to [banner] if not provided — AdMob test/real banner units
  /// serve every banner size, so a dedicated ID is only needed if you want
  /// separate reporting.
  final String? largeBanner;

  /// Ad unit ID for the "Medium Rectangle" (300x250) size.
  ///
  /// Falls back to [banner] if not provided.
  final String? mediumRectangle;

  /// Ad unit ID for interstitial ads (also used by [CountedInterstitialController]).
  final String interstitial;

  /// Ad unit ID for rewarded ads.
  final String rewarded;

  /// Ad unit ID for rewarded interstitial ads.
  final String rewardedInterstitial;

  /// Ad unit ID for app open ads.
  final String appOpen;

  const AdUnitIds({
    required this.banner,
    this.largeBanner,
    this.mediumRectangle,
    required this.interstitial,
    required this.rewarded,
    required this.rewardedInterstitial,
    required this.appOpen,
  });

  /// [largeBanner] if set, otherwise [banner].
  String get largeBannerOrBanner => largeBanner ?? banner;

  /// [mediumRectangle] if set, otherwise [banner].
  String get mediumRectangleOrBanner => mediumRectangle ?? banner;
}

/// Holds the Android and iOS [AdUnitIds] for your app.
///
/// Pass this to `AdsManager.init(adUnitIds: ...)`. `AdsManager` picks the
/// right platform automatically via [current].
class AdUnitIdSet {
  final AdUnitIds android;
  final AdUnitIds ios;

  const AdUnitIdSet({required this.android, required this.ios});

  /// The [AdUnitIds] for the platform the app is currently running on.
  AdUnitIds get current => Platform.isAndroid ? android : ios;
}

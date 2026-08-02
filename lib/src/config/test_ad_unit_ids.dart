import 'dart:io' show Platform;

import 'ad_unit_ids.dart';

/// Google's official sample/test ad unit IDs.
///
/// `AdsManager` uses these automatically when `useTestAds` is true (the
/// default in debug builds), so you never show real ads while developing.
///
/// See: https://developers.google.com/admob/flutter/test-ads
class TestAdUnitIds {
  TestAdUnitIds._();

  static const AdUnitIds _android = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
    rewardedInterstitial: 'ca-app-pub-3940256099942544/5354046379',
    appOpen: 'ca-app-pub-3940256099942544/9257395921',
  );

  static const AdUnitIds _ios = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/2934735716',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
    rewardedInterstitial: 'ca-app-pub-3940256099942544/6978759866',
    appOpen: 'ca-app-pub-3940256099942544/5662855259',
  );

  /// The test [AdUnitIds] for the platform the app is currently running on.
  static AdUnitIds get current => Platform.isAndroid ? _android : _ios;
}

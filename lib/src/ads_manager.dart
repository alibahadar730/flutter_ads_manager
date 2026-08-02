import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config/ad_unit_ids.dart';
import 'config/test_ad_unit_ids.dart';
import 'consent/consent_manager.dart';
import 'controllers/app_open_ad_controller.dart';
import 'controllers/counted_interstitial_controller.dart';
import 'controllers/interstitial_ad_controller.dart';
import 'controllers/rewarded_ad_controller.dart';
import 'controllers/rewarded_interstitial_ad_controller.dart';

/// Single entry point for every ad type this package supports.
///
/// Call [init] once, at app startup, then use [interstitial], [rewarded],
/// [rewardedInterstitial], [appOpen] and [countedInterstitial] to show ads,
/// and [AdBannerWidget] anywhere in your widget tree for banners.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AdsManager.instance.init(
///     adUnitIds: const AdUnitIdSet(
///       android: AdUnitIds(
///         banner: 'ca-app-pub-.../...',
///         interstitial: 'ca-app-pub-.../...',
///         rewarded: 'ca-app-pub-.../...',
///         rewardedInterstitial: 'ca-app-pub-.../...',
///         appOpen: 'ca-app-pub-.../...',
///       ),
///       ios: AdUnitIds(
///         banner: 'ca-app-pub-.../...',
///         interstitial: 'ca-app-pub-.../...',
///         rewarded: 'ca-app-pub-.../...',
///         rewardedInterstitial: 'ca-app-pub-.../...',
///         appOpen: 'ca-app-pub-.../...',
///       ),
///     ),
///   );
///   runApp(const MyApp());
/// }
/// ```
class AdsManager {
  AdsManager._internal()
      : interstitial = InterstitialAdController(
          () => AdsManager.instance.unitIds.interstitial,
          fullScreenAdVisibility: _fullScreenAdVisibility,
          keywordsResolver: () => AdsManager.instance.keywords,
        ),
        rewarded = RewardedAdController(
          () => AdsManager.instance.unitIds.rewarded,
          fullScreenAdVisibility: _fullScreenAdVisibility,
          keywordsResolver: () => AdsManager.instance.keywords,
        ),
        rewardedInterstitial = RewardedInterstitialAdController(
          () => AdsManager.instance.unitIds.rewardedInterstitial,
          fullScreenAdVisibility: _fullScreenAdVisibility,
          keywordsResolver: () => AdsManager.instance.keywords,
        ),
        appOpen = AppOpenAdController(
          () => AdsManager.instance.unitIds.appOpen,
          fullScreenAdVisibility: _fullScreenAdVisibility,
          keywordsResolver: () => AdsManager.instance.keywords,
        ) {
    countedInterstitial = CountedInterstitialController(interstitial);
  }

  /// The shared [AdsManager] instance.
  static final AdsManager instance = AdsManager._internal();

  static final ValueNotifier<bool> _fullScreenAdVisibility = ValueNotifier(
    false,
  );

  /// True while any full-screen ad (interstitial, rewarded, rewarded
  /// interstitial or app open) is on screen.
  ///
  /// `AdBannerWidget` listens to this itself, so you don't need to; it's
  /// exposed in case you want to react to it too (e.g. pausing a game).
  ValueListenable<bool> get fullScreenAdVisibility => _fullScreenAdVisibility;

  /// GDPR/UK/US consent (UMP) handling. `init` uses this automatically
  /// unless you pass `requestConsent: false`.
  final ConsentManager consent = ConsentManager();

  /// Keywords describing your app or its current content (e.g. `['sports',
  /// 'basketball']`), sent with every ad request this package makes —
  /// banners, interstitials, rewarded, rewarded interstitial and app open —
  /// to help AdMob pick more relevant (and often better-paying) ads.
  ///
  /// Set this via `init(keywords: ...)` up front, or reassign it any time
  /// (e.g. when the user navigates to different content); the next ad load
  /// picks up the new value.
  List<String> keywords = const [];

  /// Full-screen ad shown between content transitions.
  final InterstitialAdController interstitial;

  /// Full-screen ad that rewards the user for watching to completion.
  final RewardedAdController rewarded;

  /// Full-screen ad shown at natural transition points that also rewards
  /// the user for watching (opt-in, unlike a plain rewarded ad).
  final RewardedInterstitialAdController rewardedInterstitial;

  /// Full-screen ad shown when the user brings the app to the foreground.
  final AppOpenAdController appOpen;

  /// Shows an interstitial only every Nth time a named trigger fires.
  late final CountedInterstitialController countedInterstitial;

  AdUnitIdSet? _configuredIds;
  bool _useTestAds = false;
  bool _initialized = false;

  /// Whether [init] has completed.
  bool get isInitialized => _initialized;

  /// The ad unit IDs currently in effect: Google's [TestAdUnitIds] if
  /// `useTestAds` was true at [init] time, otherwise the [AdUnitIdSet] you
  /// configured.
  AdUnitIds get unitIds =>
      _useTestAds ? TestAdUnitIds.current : _requireConfiguredIds().current;

  AdUnitIdSet _requireConfiguredIds() {
    final ids = _configuredIds;
    if (ids == null) {
      throw StateError(
        'AdsManager.init() must be called before requesting ads.',
      );
    }
    return ids;
  }

  /// Initializes the Google Mobile Ads SDK, requests GDPR/UMP consent if
  /// needed, and optionally preloads ad types up front.
  ///
  /// [adUnitIds] are your real, production ad unit IDs. Pass
  /// [useTestAds] (defaults to [kDebugMode]) to use Google's sample test ad
  /// unit IDs instead, so you never accidentally serve real ads — and never
  /// risk a policy-violating invalid-traffic strike — while developing.
  ///
  /// Set [requestConsent] to false only if your app handles UMP consent
  /// itself elsewhere.
  ///
  /// [testDeviceIds] registers this device as a test device with AdMob
  /// (find your device ID in the console log the first time you request a
  /// real ad on it) so you can safely test with real ad unit IDs too.
  ///
  /// [keywords] seeds [AdsManager.keywords] — see its docs for what it does.
  Future<void> init({
    required AdUnitIdSet adUnitIds,
    bool useTestAds = kDebugMode,
    bool requestConsent = true,
    List<String> testDeviceIds = const [],
    List<String> keywords = const [],
    bool preloadInterstitial = true,
    bool preloadRewarded = false,
    bool preloadRewardedInterstitial = false,
    bool preloadAppOpen = false,
    bool showAppOpenOnResume = false,
  }) async {
    _configuredIds = adUnitIds;
    _useTestAds = useTestAds;
    this.keywords = keywords;

    if (requestConsent) {
      await consent.requestConsent(testDeviceIds: testDeviceIds);
    }

    await MobileAds.instance.initialize();

    if (testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }

    _initialized = true;

    if (preloadInterstitial) unawaited(interstitial.load());
    if (preloadRewarded) unawaited(rewarded.load());
    if (preloadRewardedInterstitial) unawaited(rewardedInterstitial.load());
    if (preloadAppOpen) unawaited(appOpen.load());
    if (showAppOpenOnResume) appOpen.enableShowOnAppResume();
  }

  /// Releases every cached ad and stops app-open lifecycle observation.
  /// Most apps never need to call this since `AdsManager` lives for the
  /// whole app lifetime.
  void dispose() {
    interstitial.dispose();
    rewarded.dispose();
    rewardedInterstitial.dispose();
    appOpen.dispose();
  }
}

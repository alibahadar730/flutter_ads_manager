import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads, caches and shows rewarded interstitial ads.
///
/// Call [load] once (e.g. right after `AdsManager.init`) and the controller
/// keeps itself topped up: after every [show], and after every failed load,
/// it automatically schedules the next load (with capped exponential
/// backoff on failure). You normally only ever call [show].
class RewardedInterstitialAdController {
  /// The ad unit ID to load. Set by `AdsManager` before first use.
  String Function() adUnitIdResolver;

  /// Flipped to true while a full-screen ad is on screen and back to false
  /// once it's dismissed. `AdBannerWidget` watches this (via
  /// `AdsManager.instance.fullScreenAdVisibility`) to remove itself from
  /// the widget tree for that window — working around an Android bug on
  /// some devices where a banner's native SurfaceView can stay composited
  /// on top of a subsequently-shown full-screen ad Activity.
  final ValueNotifier<bool>? fullScreenAdVisibility;

  RewardedInterstitialAdController(
    this.adUnitIdResolver, {
    this.fullScreenAdVisibility,
  });

  RewardedInterstitialAd? _ad;
  bool _isLoading = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  Completer<void>? _dismissCompleter;

  /// Whether an ad is loaded and ready to show.
  bool get isReady => _ad != null;

  /// Loads a rewarded interstitial ad if one isn't already loaded or loading.
  Future<void> load() async {
    if (_isLoading || _ad != null) return;
    _isLoading = true;
    await RewardedInterstitialAd.load(
      adUnitId: adUnitIdResolver(),
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryAttempt = 0;
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              fullScreenAdVisibility?.value = false;
              _completeDismiss();
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
              fullScreenAdVisibility?.value = false;
              _completeDismiss();
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          _scheduleRetry();
        },
      ),
    );
  }

  void _completeDismiss() {
    final completer = _dismissCompleter;
    _dismissCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _scheduleRetry() {
    _retryAttempt++;
    final seconds = math.min(_retryAttempt * 2, 60);
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), load);
  }

  /// Shows the loaded rewarded interstitial ad, if any.
  ///
  /// [onUserEarnedReward] is called if and only if the user should be
  /// granted the reward (i.e. they watched the ad to completion). It is
  /// always called (if at all) before this method returns, so it's safe to
  /// inspect whatever state it set as soon as `await show(...)` completes.
  ///
  /// Returns true if an ad was shown — after it has been dismissed (or
  /// failed to show), not merely after it was launched. Automatically
  /// preloads the next ad once this one is dismissed. If no ad is ready,
  /// returns false immediately (nothing is shown, [onUserEarnedReward] is
  /// not called) — call [load] earlier and check [isReady] if you need to
  /// guarantee availability.
  Future<bool> show({
    required void Function(AdWithoutView ad, RewardItem reward)
        onUserEarnedReward,
  }) async {
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;
    fullScreenAdVisibility?.value = true;
    final dismissCompleter = Completer<void>();
    _dismissCompleter = dismissCompleter;
    // Let a frame render with the banner removed from the tree before the
    // full-screen ad's native Activity launches on top of it.
    await SchedulerBinding.instance.endOfFrame;
    await ad.show(onUserEarnedReward: onUserEarnedReward);
    // `ad.show()` only resolves once the platform call to launch the ad
    // Activity returns — not once the user has actually finished with it.
    // Wait for the real dismissal (or failure) signal so callers can trust
    // that `onUserEarnedReward` has already fired (or never will) by the
    // time this method returns.
    await dismissCompleter.future;
    return true;
  }

  /// Releases the cached ad, if any, and cancels any pending retry.
  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads, caches and shows app open ads.
///
/// App open ads are meant to be shown when the user brings your app to the
/// foreground (cold start or resume from background). Call
/// [enableShowOnAppResume] once (e.g. right after `AdsManager.init`) to have
/// this controller automatically show a cached ad every time the app
/// resumes, or call [show] yourself for full control.
///
/// AdMob ad units expire after 4 hours; a stale cached ad is discarded and
/// reloaded automatically instead of being shown.
class AppOpenAdController with WidgetsBindingObserver {
  /// The ad unit ID to load. Set by `AdsManager` before first use.
  String Function() adUnitIdResolver;

  /// Flipped to true while a full-screen ad is on screen and back to false
  /// once it's dismissed. `AdBannerWidget` watches this (via
  /// `AdsManager.instance.fullScreenAdVisibility`) to remove itself from
  /// the widget tree for that window — working around an Android bug on
  /// some devices where a banner's native SurfaceView can stay composited
  /// on top of a subsequently-shown full-screen ad Activity.
  final ValueNotifier<bool>? fullScreenAdVisibility;

  /// Keywords sent with every ad request from this controller. Set by
  /// `AdsManager` to reflect `AdsManager.instance.keywords`.
  final List<String> Function() keywordsResolver;

  AppOpenAdController(
    this.adUnitIdResolver, {
    this.fullScreenAdVisibility,
    List<String> Function()? keywordsResolver,
  }) : keywordsResolver = keywordsResolver ?? (() => const <String>[]);

  static const Duration _maxCacheDuration = Duration(hours: 4);

  AppOpenAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _autoShowEnabled = false;
  DateTime? _loadTime;
  Completer<void>? _dismissCompleter;

  /// Whether a non-expired ad is loaded and ready to show.
  bool get isReady => _ad != null && _isAdFresh;

  bool get _isAdFresh =>
      _loadTime != null &&
      DateTime.now().difference(_loadTime!) < _maxCacheDuration;

  /// Loads an app open ad if one isn't already loaded (and fresh) or loading.
  Future<void> load() async {
    if (_isLoading || isReady) return;
    _isLoading = true;
    final keywords = keywordsResolver();
    await AppOpenAd.load(
      adUnitId: adUnitIdResolver(),
      request: AdRequest(keywords: keywords.isEmpty ? null : keywords),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
          _loadTime = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _isShowing = false;
              fullScreenAdVisibility?.value = false;
              _completeDismiss();
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
              _isShowing = false;
              fullScreenAdVisibility?.value = false;
              _completeDismiss();
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  void _completeDismiss() {
    final completer = _dismissCompleter;
    _dismissCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Shows the loaded app open ad, if any and not expired, and not already
  /// showing one. Returns true if an ad was shown — after it has been
  /// dismissed (or failed to show), not merely after it was launched.
  Future<bool> show() async {
    if (_isShowing || !isReady) return false;
    _isShowing = true;
    fullScreenAdVisibility?.value = true;
    final dismissCompleter = Completer<void>();
    _dismissCompleter = dismissCompleter;
    // Let a frame render with the banner removed from the tree before the
    // full-screen ad's native Activity launches on top of it.
    await WidgetsBinding.instance.endOfFrame;
    await _ad!.show();
    // `_ad.show()` only resolves once the platform call to launch the ad
    // Activity returns — not once the user has actually finished with it.
    await dismissCompleter.future;
    return true;
  }

  /// Starts observing app lifecycle changes and automatically calls [show]
  /// whenever the app is resumed from the background, if a fresh ad is
  /// cached (loading one otherwise for next time).
  void enableShowOnAppResume() {
    if (_autoShowEnabled) return;
    _autoShowEnabled = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops the automatic show-on-resume behavior started by
  /// [enableShowOnAppResume].
  void disableShowOnAppResume() {
    if (!_autoShowEnabled) return;
    _autoShowEnabled = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isReady) {
        show();
      } else {
        load();
      }
    }
  }

  /// Releases the cached ad, if any, and stops lifecycle observation.
  void dispose() {
    disableShowOnAppResume();
    _ad?.dispose();
    _ad = null;
  }
}

import 'interstitial_ad_controller.dart';

/// Shows an interstitial only every Nth time a named trigger fires, instead
/// of on every single call.
///
/// Useful for things like "show an interstitial every 3rd level completed"
/// without showing one on every single completion. Each named trigger keeps
/// its own independent counter.
///
/// ```dart
/// // On every level-complete event:
/// await AdsManager.instance.countedInterstitial.registerEventAndMaybeShow(
///   'level_complete',
///   every: 3, // shows on the 3rd, 6th, 9th... call for this trigger
/// );
/// ```
class CountedInterstitialController {
  final InterstitialAdController _interstitial;
  final Map<String, int> _counts = {};

  CountedInterstitialController(this._interstitial);

  /// Whether a cached ad is ready to show right now.
  bool get isReady => _interstitial.isReady;

  /// Preloads the underlying interstitial ad. `AdsManager.init` calls this
  /// for you when `preloadInterstitial` is true.
  Future<void> preload() => _interstitial.load();

  /// Registers one occurrence of [trigger] and shows the interstitial once
  /// every [every] occurrences (i.e. on the [every]th, `2 * every`th, ...
  /// call for that trigger), then resets the counter for that trigger.
  ///
  /// Returns true if an ad was shown this call.
  Future<bool> registerEventAndMaybeShow(
    String trigger, {
    required int every,
  }) async {
    assert(every > 0, 'every must be a positive count');
    final count = (_counts[trigger] ?? 0) + 1;
    if (count >= every) {
      _counts[trigger] = 0;
      return _interstitial.show();
    }
    _counts[trigger] = count;
    return false;
  }

  /// Resets the counter for [trigger] back to zero without showing an ad.
  void resetCounter(String trigger) => _counts[trigger] = 0;

  /// The current (not-yet-triggering) count for [trigger].
  int countFor(String trigger) => _counts[trigger] ?? 0;
}

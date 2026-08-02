import 'package:flutter_ads_manager/flutter_ads_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdUnitIds', () {
    test('falls back to banner id when large/medium rectangle unset', () {
      const ids = AdUnitIds(
        banner: 'banner-id',
        interstitial: 'interstitial-id',
        rewarded: 'rewarded-id',
        rewardedInterstitial: 'rewarded-interstitial-id',
        appOpen: 'app-open-id',
      );

      expect(ids.largeBannerOrBanner, 'banner-id');
      expect(ids.mediumRectangleOrBanner, 'banner-id');
    });

    test('prefers explicit large/medium rectangle id when set', () {
      const ids = AdUnitIds(
        banner: 'banner-id',
        largeBanner: 'large-banner-id',
        mediumRectangle: 'medium-rectangle-id',
        interstitial: 'interstitial-id',
        rewarded: 'rewarded-id',
        rewardedInterstitial: 'rewarded-interstitial-id',
        appOpen: 'app-open-id',
      );

      expect(ids.largeBannerOrBanner, 'large-banner-id');
      expect(ids.mediumRectangleOrBanner, 'medium-rectangle-id');
    });
  });

  group('CountedInterstitialController', () {
    test('only shows every Nth registered event', () async {
      final interstitial = InterstitialAdController(() => 'test-unit-id');
      final counted = CountedInterstitialController(interstitial);

      // No ad has been loaded, so show() always resolves to false, but the
      // counter logic itself is what's under test here.
      expect(counted.countFor('level_complete'), 0);

      await counted.registerEventAndMaybeShow('level_complete', every: 3);
      expect(counted.countFor('level_complete'), 1);

      await counted.registerEventAndMaybeShow('level_complete', every: 3);
      expect(counted.countFor('level_complete'), 2);

      final shown = await counted.registerEventAndMaybeShow(
        'level_complete',
        every: 3,
      );
      expect(shown, false); // no ad loaded in this unit test
      expect(counted.countFor('level_complete'), 0); // counter still resets
    });

    test('keeps independent counters per trigger', () async {
      final interstitial = InterstitialAdController(() => 'test-unit-id');
      final counted = CountedInterstitialController(interstitial);

      await counted.registerEventAndMaybeShow('a', every: 5);
      await counted.registerEventAndMaybeShow('b', every: 5);
      await counted.registerEventAndMaybeShow('a', every: 5);

      expect(counted.countFor('a'), 2);
      expect(counted.countFor('b'), 1);
    });
  });

  group('TestAdUnitIds', () {
    test('exposes non-empty ids for the current platform', () {
      final ids = TestAdUnitIds.current;
      expect(ids.banner, isNotEmpty);
      expect(ids.interstitial, isNotEmpty);
      expect(ids.rewarded, isNotEmpty);
      expect(ids.rewardedInterstitial, isNotEmpty);
      expect(ids.appOpen, isNotEmpty);
    });
  });
}

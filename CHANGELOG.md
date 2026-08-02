## 0.0.2

* Fix: `show()` on `InterstitialAdController`, `RewardedAdController`, `RewardedInterstitialAdController` and `AppOpenAdController` now resolves only after the ad has actually been dismissed (or failed to show), instead of right after the platform call to launch it was issued. Previously, `await controller.show(...)` could return while the ad was still on screen, so code that inspected state set inside `onUserEarnedReward` (or that expected the app to have "come back" from the ad) right after the `await` would see stale results.

## 0.0.1

Initial release.

* `AdsManager` singleton: one `init()` call wires up the Google Mobile Ads SDK, GDPR/UMP consent, and optional preloading.
* Banner ads via `AdBannerWidget`: standard, adaptive, large banner, and medium rectangle variants.
* `InterstitialAdController`, `RewardedAdController`, `RewardedInterstitialAdController`, `AppOpenAdController` — self-reloading, with capped retry/backoff on failed loads.
* `CountedInterstitialController` for "show an interstitial every Nth event" patterns.
* `ConsentManager` wrapping Google's UMP SDK, including the privacy-options entry point.
* `TestAdUnitIds` — Google's official test ad unit IDs, used automatically in debug builds.

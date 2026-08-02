## 0.0.1

Initial release.

* `AdsManager` singleton: one `init()` call wires up the Google Mobile Ads SDK, GDPR/UMP consent, and optional preloading.
* Banner ads via `AdBannerWidget`: standard, adaptive, large banner, and medium rectangle variants.
* `InterstitialAdController`, `RewardedAdController`, `RewardedInterstitialAdController`, `AppOpenAdController` — self-reloading, with capped retry/backoff on failed loads.
* `CountedInterstitialController` for "show an interstitial every Nth event" patterns.
* `ConsentManager` wrapping Google's UMP SDK, including the privacy-options entry point.
* `TestAdUnitIds` — Google's official test ad unit IDs, used automatically in debug builds.

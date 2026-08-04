## 0.0.5

* Add `BannerAdVariant.compactAdaptive` — full device-width banner using Google's compact "current orientation anchored" adaptive size (~50-90dp tall), as opposed to the existing `adaptive` variant which uses the taller "Large" anchored adaptive size (~90-100dp tall). Use `compactAdaptive` for an edge-to-edge footer banner that shouldn't take up much vertical space; use `adaptive` when you want the larger, more prominent size.

## 0.0.4

* Shorten the `pubspec.yaml` description to fit pub.dev's 60–180 character limit (was too long to be indexed properly by search engines).

## 0.0.3

* Add `AdsManager.instance.keywords` — a settable `List<String>` sent with every ad request (banner, interstitial, rewarded, rewarded interstitial, app open) for better ad targeting. Set it via `init(keywords: ...)` or reassign it any time content changes.

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

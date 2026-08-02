# flutter_ads_manager

Drop-in AdMob ads for Flutter. One `init()` call, then use `AdBannerWidget`
and `AdsManager.instance` for every ad format — banner, adaptive banner,
large banner, medium rectangle, interstitial, counted interstitial,
rewarded, rewarded interstitial and app open — without writing ad-loading
boilerplate in every app.

Built on [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads),
with:

- Automatic preloading, auto-reload after each impression, and capped
  retry-with-backoff on failed loads.
- Google's official test ad unit IDs used automatically in debug builds, so
  you can't accidentally ship real ad traffic from a dev build.
- Built-in GDPR/UK/US consent (UMP) handling — the consent form is shown
  automatically before ads are requested, when required.
- A `CountedInterstitialController` for "show an interstitial every Nth
  time" patterns (e.g. every 3rd level completed) instead of on every call.
- A single drop-in `AdBannerWidget` covering standard, adaptive, large
  banner and medium rectangle sizes.

> **One thing this package can't remove:** AdMob itself requires a native
> App ID entry in `AndroidManifest.xml` / `Info.plist` for *every* app that
> shows ads — that's a requirement of Google's SDK, not something any Dart
> package can bypass. Everything else (loading, showing, retrying,
> consent, frequency capping) is handled for you by this package.

## Setup (do this once per app)

### 1. Add the dependency

```yaml
dependencies:
  flutter_ads_manager: ^0.0.1
```

### 2. Add your AdMob App ID natively

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

(Google publishes the [full recommended `SKAdNetworkItems`
list](https://developers.google.com/admob/ios/quick-start#update_your_infoplist)
— copy the whole array from there for iOS ad networks to work correctly.)

**Android only — avoid a known ad-behind-your-UI rendering bug.** On some
Android devices (observed on Infinix/XOS + MediaTek hardware, likely others),
a full-screen ad's own Activity is laid out a few dozen pixels short of the
real screen height — it doesn't extend into the display-cutout/status-bar
strip the way your Flutter Activity does. That leaves a gap where your own
UI (e.g. your `AppBar`) stays visible behind the ad for its entire duration,
instead of the ad filling the screen.

Neither switching `FlutterActivity`'s render mode to `texture` nor disabling
Impeller changed this — it isn't a Flutter rendering-backend issue. What
fixed it was keeping the app in a consistent **immersive** (system bars
hidden) state throughout, so there's no bar-visibility change to animate
through when the ad's Activity takes over. Add this to `MainActivity.kt`
(already applied in this package's `example/`):

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        goImmersive()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) goImmersive()
    }

    private fun goImmersive() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller.hide(WindowInsetsCompat.Type.systemBars())
    }
}
```

This is a bigger change than a one-line tweak — it makes your whole app
immersive (status/nav bars hidden, revealed only on a swipe from the edge),
not just the moment an ad shows. If that trade-off doesn't fit your app,
you may not need this at all — the bug is device-specific and many devices
never show it.

That's the only native code you ever write — the rest of this README is
pure Dart.

### 3. Initialize once, at app startup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ads_manager/flutter_ads_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdsManager.instance.init(
    adUnitIds: const AdUnitIdSet(
      android: AdUnitIds(
        banner: 'ca-app-pub-xxxxxxxxxxxxxxxx/1111111111',
        interstitial: 'ca-app-pub-xxxxxxxxxxxxxxxx/2222222222',
        rewarded: 'ca-app-pub-xxxxxxxxxxxxxxxx/3333333333',
        rewardedInterstitial: 'ca-app-pub-xxxxxxxxxxxxxxxx/4444444444',
        appOpen: 'ca-app-pub-xxxxxxxxxxxxxxxx/5555555555',
      ),
      ios: AdUnitIds(
        banner: 'ca-app-pub-xxxxxxxxxxxxxxxx/6666666666',
        interstitial: 'ca-app-pub-xxxxxxxxxxxxxxxx/7777777777',
        rewarded: 'ca-app-pub-xxxxxxxxxxxxxxxx/8888888888',
        rewardedInterstitial: 'ca-app-pub-xxxxxxxxxxxxxxxx/9999999999',
        appOpen: 'ca-app-pub-xxxxxxxxxxxxxxxx/0000000000',
      ),
    ),
    // Defaults to true in debug builds — flips to your real IDs in release
    // builds automatically. You rarely need to pass this explicitly.
    useTestAds: false,
    showAppOpenOnResume: true, // auto-shows an app open ad on app resume
  );

  runApp(const MyApp());
}
```

That's it — every ad type below is now ready to use anywhere in the app via
`AdsManager.instance`, no per-screen setup required.

## Usage

### Banner / adaptive banner / large banner / medium rectangle

Just place the widget — it loads itself and renders nothing (zero size)
while loading or if the ad fails, so it never leaves a gap or shows an
error:

```dart
// Full-width, Google-optimized height for the device/orientation (recommended default)
const AdBannerWidget(variant: BannerAdVariant.adaptive)

// Fixed 320x50
const AdBannerWidget(variant: BannerAdVariant.standard)

// Fixed 320x100 ("larger banner")
const AdBannerWidget(variant: BannerAdVariant.largeBanner)

// Fixed 300x250, good for in-feed placements
const AdBannerWidget(variant: BannerAdVariant.mediumRectangle)
```

### Interstitial

```dart
// Preloaded automatically by AdsManager.init (preloadInterstitial: true by default).
await AdsManager.instance.interstitial.show();
```

### Counted interstitial ("every Nth time")

```dart
// Call this every time the trigger event happens. An interstitial is shown
// only on the 3rd, 6th, 9th... call for that trigger, not on every call.
await AdsManager.instance.countedInterstitial.registerEventAndMaybeShow(
  'level_complete',
  every: 3,
);
```

### Rewarded

Preload ahead of time (e.g. when entering the screen that offers the
reward) and show later:

```dart
// When the screen opens:
AdsManager.instance.rewarded.load();

// When the user taps "Watch ad for reward":
if (AdsManager.instance.rewarded.isReady) {
  await AdsManager.instance.rewarded.show(
    onUserEarnedReward: (ad, reward) => grantCoins(reward.amount.toInt()),
  );
} else {
  // show a "try again in a moment" message — an ad wasn't ready in time
}
```

### Rewarded interstitial

Same API shape as rewarded, shown at natural transition points:

```dart
AdsManager.instance.rewardedInterstitial.load();

await AdsManager.instance.rewardedInterstitial.show(
  onUserEarnedReward: (ad, reward) => grantCoins(reward.amount.toInt()),
);
```

### App open

```dart
// Automatic: pass showAppOpenOnResume: true to init() and it shows
// whenever the user brings the app back to the foreground.

// Manual, if you want control over exactly when:
AdsManager.instance.appOpen.load();
await AdsManager.instance.appOpen.show();
```

### GDPR / UK / US consent (UMP)

Handled automatically by `init()`. If your app needs a "Privacy options"
button in its settings screen (required by Google for users in some
regions even after they've made a choice):

```dart
if (await AdsManager.instance.consent.isPrivacyOptionsRequired) {
  // show a "Privacy options" button, which calls:
  await AdsManager.instance.consent.showPrivacyOptionsForm();
}
```

### Testing with real ad unit IDs on a physical device

Pass your device's advertising ID as a test device so you can safely test
real (non-test) ad unit IDs without accidentally generating invalid
traffic:

```dart
await AdsManager.instance.init(
  adUnitIds: ...,
  testDeviceIds: ['33BE2250B43518CCDA7DE426D04EE231'],
);
```

The real ID for your device is printed to the console the first time you
request a real ad on it.

## API surface

| Type | Purpose |
|---|---|
| `AdsManager.instance` | Singleton entry point; call `.init(...)` once |
| `AdBannerWidget` | Drop-in widget for all banner sizes |
| `AdsManager.instance.interstitial` | `InterstitialAdController` |
| `AdsManager.instance.countedInterstitial` | `CountedInterstitialController` |
| `AdsManager.instance.rewarded` | `RewardedAdController` |
| `AdsManager.instance.rewardedInterstitial` | `RewardedInterstitialAdController` |
| `AdsManager.instance.appOpen` | `AppOpenAdController` |
| `AdsManager.instance.consent` | `ConsentManager` (UMP/GDPR) |
| `AdUnitIds` / `AdUnitIdSet` | Your per-platform ad unit ID configuration |
| `TestAdUnitIds` | Google's official test ad unit IDs |

## Notes

- Requires the min SDK / deployment target versions
  [`google_mobile_ads` documents](https://pub.dev/packages/google_mobile_ads)
  (Android `minSdkVersion 21`+, iOS 13.0+).
- Not usable on web/desktop — AdMob is a mobile-only SDK.

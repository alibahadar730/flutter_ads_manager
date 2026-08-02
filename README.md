# flutter_ads_manager

Drop-in AdMob ads for Flutter. Call `init()` once, then use `AdBannerWidget`
and `AdsManager.instance` for every ad type — banner, interstitial, rewarded,
rewarded interstitial, and app open — without writing ad-loading code
yourself.

Built on [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads).
It handles:

- Loading, retrying, and reloading ads automatically
- Google's test ad IDs in debug builds, so you never show real ads by accident
- GDPR/UK/US consent (shown automatically before ads load)
- "Show an interstitial every 3rd time" style frequency capping
- Keywords for better ad targeting

> AdMob still requires a native App ID in `AndroidManifest.xml` /
> `Info.plist` for every app — that's a Google requirement, not something
> any package can remove. Everything else is handled for you.

## Setup

### 1. Add the dependency

```yaml
dependencies:
  flutter_ads_manager: ^0.0.1
```

### 2. Add your AdMob App ID

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
```

### 3. Initialize once, at startup

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
    showAppOpenOnResume: true, // auto-shows an app open ad on resume
  );

  runApp(const MyApp());
}
```

That's it — every ad type is now ready to use anywhere in your app.

## Usage

### Banner

```dart
const AdBannerWidget(variant: BannerAdVariant.adaptive)     // full-width, recommended
const AdBannerWidget(variant: BannerAdVariant.standard)     // 320x50
const AdBannerWidget(variant: BannerAdVariant.largeBanner)  // 320x100
const AdBannerWidget(variant: BannerAdVariant.mediumRectangle) // 300x250
```

Just place it in your layout — it loads itself and shows nothing while
loading or if it fails, so it never leaves a gap.

### Interstitial

```dart
await AdsManager.instance.interstitial.show();
```

### Counted interstitial (every Nth time)

```dart
// Shows an interstitial only on the 3rd, 6th, 9th... call for this trigger.
await AdsManager.instance.countedInterstitial.registerEventAndMaybeShow(
  'level_complete',
  every: 3,
);
```

### Rewarded

```dart
AdsManager.instance.rewarded.load(); // call ahead of time

if (AdsManager.instance.rewarded.isReady) {
  await AdsManager.instance.rewarded.show(
    onUserEarnedReward: (ad, reward) => grantCoins(reward.amount.toInt()),
  );
}
```

### Rewarded interstitial

Same as rewarded:

```dart
await AdsManager.instance.rewardedInterstitial.show(
  onUserEarnedReward: (ad, reward) => grantCoins(reward.amount.toInt()),
);
```

### App open

```dart
// Automatic: pass showAppOpenOnResume: true to init().

// Or manually:
await AdsManager.instance.appOpen.show();
```

### Consent (GDPR/UMP)

Handled automatically. If you need a "Privacy options" button in your
settings screen:

```dart
if (await AdsManager.instance.consent.isPrivacyOptionsRequired) {
  await AdsManager.instance.consent.showPrivacyOptionsForm();
}
```

### Keywords (better ad targeting)

Describe your app or its current content so AdMob can pick more relevant
ads:

```dart
AdsManager.instance.keywords = ['sports', 'basketball'];
```

### Testing on a real device with real ad unit IDs

```dart
await AdsManager.instance.init(
  adUnitIds: ...,
  testDeviceIds: ['33BE2250B43518CCDA7DE426D04EE231'], // printed to console on first request
);
```

## Troubleshooting

**An ad shows behind my app's UI (e.g. AppBar visible over an interstitial).**
This is a known issue on some Android devices, unrelated to this package —
the ad's Activity doesn't cover the status bar area the way yours does. Fix
it by keeping your app in immersive mode (already done in this repo's
`example/android/.../MainActivity.kt`):

```kotlin
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView)
            .hide(WindowInsetsCompat.Type.systemBars())
    }
}
```

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

- Android `minSdkVersion` 21+, iOS 13.0+ (same as `google_mobile_ads`).
- Not usable on web/desktop — AdMob is mobile-only.

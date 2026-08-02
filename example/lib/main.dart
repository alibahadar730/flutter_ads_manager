import 'package:flutter/material.dart';
import 'package:flutter_ads_manager/flutter_ads_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdsManager.instance.init(
    // Google's official test ad unit IDs are baked into TestAdUnitIds and
    // used automatically here because useTestAds defaults to kDebugMode.
    // In your own app, put your real IDs here.
    adUnitIds: const AdUnitIdSet(
      android: AdUnitIds(
        banner: 'ca-app-pub-3940256099942544/6300978111',
        interstitial: 'ca-app-pub-3940256099942544/1033173712',
        rewarded: 'ca-app-pub-3940256099942544/5224354917',
        rewardedInterstitial: 'ca-app-pub-3940256099942544/5354046379',
        appOpen: 'ca-app-pub-3940256099942544/9257395921',
      ),
      ios: AdUnitIds(
        banner: 'ca-app-pub-3940256099942544/2934735716',
        interstitial: 'ca-app-pub-3940256099942544/4411468910',
        rewarded: 'ca-app-pub-3940256099942544/1712485313',
        rewardedInterstitial: 'ca-app-pub-3940256099942544/6978759866',
        appOpen: 'ca-app-pub-3940256099942544/5662855259',
      ),
    ),
    preloadRewarded: true,
    preloadRewardedInterstitial: true,
    preloadAppOpen: true,
  );

  runApp(const AdsManagerExampleApp());
}

class AdsManagerExampleApp extends StatelessWidget {
  const AdsManagerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_ads_manager example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AdDemoPage(),
    );
  }
}

class AdDemoPage extends StatefulWidget {
  const AdDemoPage({super.key});

  @override
  State<AdDemoPage> createState() => _AdDemoPageState();
}

class _AdDemoPageState extends State<AdDemoPage> {
  String _status = '';
  int _levelsCompleted = 0;

  void _setStatus(String message) => setState(() => _status = message);

  Future<void> _showInterstitial() async {
    final shown = await AdsManager.instance.interstitial.show();
    _setStatus(shown ? 'Interstitial shown.' : 'Interstitial not ready yet.');
  }

  Future<void> _completeLevel() async {
    _levelsCompleted++;
    final shown = await AdsManager.instance.countedInterstitial
        .registerEventAndMaybeShow('level_complete', every: 3);
    _setStatus(
      shown
          ? 'Level $_levelsCompleted complete — interstitial shown (every 3rd time).'
          : 'Level $_levelsCompleted complete — no ad this time '
                '(${AdsManager.instance.countedInterstitial.countFor('level_complete')}/3).',
    );
  }

  Future<void> _showRewarded() async {
    if (!AdsManager.instance.rewarded.isReady) {
      _setStatus('Rewarded ad not ready yet — try again in a moment.');
      AdsManager.instance.rewarded.load();
      return;
    }
    await AdsManager.instance.rewarded.show(
      onUserEarnedReward: (ad, reward) {
        _setStatus('Reward earned: ${reward.amount} ${reward.type}');
      },
    );
  }

  Future<void> _showRewardedInterstitial() async {
    if (!AdsManager.instance.rewardedInterstitial.isReady) {
      _setStatus(
        'Rewarded interstitial not ready yet — try again in a moment.',
      );
      AdsManager.instance.rewardedInterstitial.load();
      return;
    }
    await AdsManager.instance.rewardedInterstitial.show(
      onUserEarnedReward: (ad, reward) {
        _setStatus('Reward earned: ${reward.amount} ${reward.type}');
      },
    );
  }

  Future<void> _showAppOpen() async {
    final shown = await AdsManager.instance.appOpen.show();
    _setStatus(shown ? 'App open ad shown.' : 'App open ad not ready yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_ads_manager example')),
      body: SafeArea(
        child: Column(
          children: [
            // The adaptive banner is full-bleed (no horizontal padding) so
            // it runs edge-to-edge, left to right, matching Google's
            // recommended placement for this format. Keep it outside any
            // padded container — padding is what caused the gap on each
            // side, and since its intrinsic width is the full device width,
            // it would otherwise overflow a padded parent instead of
            // shrinking to fit.
            const AdBannerWidget(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _status,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const Text(
                    'Large banner (320x100)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Center(
                    child: AdBannerWidget(variant: BannerAdVariant.largeBanner),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Medium rectangle (300x250)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Center(
                    child: AdBannerWidget(
                      variant: BannerAdVariant.mediumRectangle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _showInterstitial,
                    child: const Text('Show interstitial'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _completeLevel,
                    child: const Text(
                      'Complete a level (counted interstitial, every 3rd)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _showRewarded,
                    child: const Text('Show rewarded ad'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _showRewardedInterstitial,
                    child: const Text('Show rewarded interstitial'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _showAppOpen,
                    child: const Text('Show app open ad'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

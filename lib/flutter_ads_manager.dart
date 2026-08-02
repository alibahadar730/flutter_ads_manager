/// Drop-in AdMob ads for Flutter — banner, adaptive/large/medium-rectangle
/// banner, interstitial, counted interstitial, rewarded, rewarded
/// interstitial and app open ads, with built-in preloading, retry and
/// GDPR/UMP consent handling. See [AdsManager] for the main entry point.
library;

export 'package:google_mobile_ads/google_mobile_ads.dart'
    show
        AdRequest,
        AdSize,
        AdWithoutView,
        ConsentDebugSettings,
        ConsentStatus,
        DebugGeography,
        FormError,
        PrivacyOptionsRequirementStatus,
        RewardItem;

export 'src/ads_manager.dart';
export 'src/config/ad_unit_ids.dart';
export 'src/config/test_ad_unit_ids.dart';
export 'src/consent/consent_manager.dart';
export 'src/controllers/app_open_ad_controller.dart';
export 'src/controllers/counted_interstitial_controller.dart';
export 'src/controllers/interstitial_ad_controller.dart';
export 'src/controllers/rewarded_ad_controller.dart';
export 'src/controllers/rewarded_interstitial_ad_controller.dart';
export 'src/widgets/ad_banner_widget.dart';

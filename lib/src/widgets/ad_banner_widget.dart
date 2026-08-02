import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_manager.dart';

/// Which banner size an [AdBannerWidget] should request.
enum BannerAdVariant {
  /// Fixed 320x50 standard banner.
  standard,

  /// Fixed 320x100 "Large Banner". This is the "larger banner" size.
  largeBanner,

  /// Fixed 300x250 "Medium Rectangle" — bigger than [largeBanner], good for
  /// in-feed placements.
  mediumRectangle,

  /// Full-width banner whose height is chosen by Google for the device and
  /// current orientation. Recommended by Google over fixed sizes.
  adaptive,
}

/// A ready-to-drop-in banner ad widget.
///
/// Handles loading, error states and disposal for you — just place it in
/// your layout:
///
/// ```dart
/// AdBannerWidget(variant: BannerAdVariant.adaptive)
/// ```
///
/// Reads its ad unit ID from `AdsManager.instance` unless you pass
/// [adUnitId] explicitly. Renders nothing (zero size) while loading or if
/// the ad fails to load, so it never leaves a placeholder gap or shows an
/// error to the user.
class AdBannerWidget extends StatefulWidget {
  final BannerAdVariant variant;

  /// Overrides the ad unit ID that would otherwise be read from
  /// `AdsManager.instance`.
  final String? adUnitId;

  const AdBannerWidget({
    super.key,
    this.variant = BannerAdVariant.adaptive,
    this.adUnitId,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final adUnitId = widget.adUnitId ?? _resolveAdUnitId();
    final size = await _resolveAdSize();
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  String _resolveAdUnitId() {
    final unitIds = AdsManager.instance.unitIds;
    switch (widget.variant) {
      case BannerAdVariant.largeBanner:
        return unitIds.largeBannerOrBanner;
      case BannerAdVariant.mediumRectangle:
        return unitIds.mediumRectangleOrBanner;
      case BannerAdVariant.standard:
      case BannerAdVariant.adaptive:
        return unitIds.banner;
    }
  }

  Future<AdSize?> _resolveAdSize() async {
    switch (widget.variant) {
      case BannerAdVariant.standard:
        return AdSize.banner;
      case BannerAdVariant.largeBanner:
        return AdSize.largeBanner;
      case BannerAdVariant.mediumRectangle:
        return AdSize.mediumRectangle;
      case BannerAdVariant.adaptive:
        final width = MediaQuery.sizeOf(context).width.truncate();
        return AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: AdsManager.instance.fullScreenAdVisibility,
      builder: (context, fullScreenAdShowing, child) {
        // Removing the banner's platform view while a full-screen ad is up
        // works around an Android bug on some devices where the banner's
        // native SurfaceView stays composited on top of the newly-launched
        // full-screen ad Activity otherwise.
        if (fullScreenAdShowing) return const SizedBox.shrink();
        return child!;
      },
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

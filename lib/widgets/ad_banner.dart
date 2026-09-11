import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;

  static const String _adUnitIdAndroid = "ca-app-pub-2497070669800198/7257431694";
  static const String _adUnitIdIOS = 'ca-app-pub-2497070669800198/9718255373';

  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_bannerAd != null) return;

    final platform = Theme.of(context).platform;
    final adUnitId = platform == TargetPlatform.iOS
        ? _adUnitIdIOS
        : _adUnitIdAndroid;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Test Ad loaded');
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // keep a fixed space so layout doesn’t shift
      return const SizedBox(height: 50);
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
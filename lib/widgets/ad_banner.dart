import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;

  static const String _testAdUnitIdAndroid = "ca-app-pub-2497070669800198~9552422541";    //Test ID: 'ca-app-pub-3940256099942544/6300978111';    //real ID: ca-app-pub-2497070669800198/7257431694
  static const String _testAdUnitIdIOS = 'ca-app-pub-3940256099942544~2934735716';

  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_bannerAd != null) return;

    final platform = Theme.of(context).platform;
    final adUnitId = platform == TargetPlatform.iOS
        ? _testAdUnitIdIOS
        : _testAdUnitIdAndroid;

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
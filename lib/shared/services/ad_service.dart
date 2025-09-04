import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Use this in production with your actual ad unit ID
  static String get bannerAdUnitId {
    // Return test ad unit ID for development
    return _testBannerAdUnitId;
  }

  // Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Get a default ad request
  static AdRequest getAdRequest() {
    return const AdRequest();
  }

  // Get default banner ad size
  static AdSize getBannerAdSize() {
    return AdSize.banner;
  }
}

// Widget to display a banner ad
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: AdService.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Ad loaded successfully: ${ad.adUnitId}');
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
                'Ad failed to load: ${ad.adUnitId}, error code: ${error.code}, message: ${error.message}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
              });
            }
          },
          onAdOpened: (ad) => debugPrint('Ad opened: ${ad.adUnitId}'),
          onAdClosed: (ad) => debugPrint('Ad closed: ${ad.adUnitId}'),
          onAdImpression: (ad) =>
              debugPrint('Ad impression recorded: ${ad.adUnitId}'),
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      // Return a smaller placeholder when ad is not loaded
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'Advertisement',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

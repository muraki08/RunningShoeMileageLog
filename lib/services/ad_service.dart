import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // テスト用ID（本番リリース時に本番IDに差し替えてください）
  // Android テスト用
  static const String _androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // iOS テスト用
  static const String _iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return _androidBannerAdUnitId;
    if (Platform.isIOS) return _iosBannerAdUnitId;
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return _androidInterstitialAdUnitId;
    if (Platform.isIOS) return _iosInterstitialAdUnitId;
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  static void loadInterstitialAd({
    required void Function(InterstitialAd ad) onLoaded,
  }) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (error) {},
      ),
    );
  }
}

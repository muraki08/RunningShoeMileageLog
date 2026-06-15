import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return dotenv.get('ADMOB_ANDROID_BANNER_AD_UNIT_ID');
    if (Platform.isIOS) return dotenv.get('ADMOB_IOS_BANNER_AD_UNIT_ID');
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.get('ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID');
    }
    if (Platform.isIOS) return dotenv.get('ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID');
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await dotenv.load();
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

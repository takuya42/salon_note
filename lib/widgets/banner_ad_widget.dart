import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? bannerAd;

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();

    bannerAd = BannerAd(
      size: AdSize.banner,

      /// 🔥 本番ID
      adUnitId: 'ca-app-pub-7129278810058648/4858222382',

      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isLoaded = true;
          });
        },

        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          debugPrint(error.toString());
        },
      ),

      request: const AdRequest(),
    );

    bannerAd!.load();
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!isLoaded || bannerAd == null) {
      return const SizedBox();
    }

    return SizedBox(
      height: bannerAd!.size.height.toDouble(),
      width: bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: bannerAd!),
    );
  }
}
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// DİKKAT: AppProvider dosyasının yolunu kendi projene göre ayarla.
// Eğer import hata verirse, 'Quick Fix' (Ampul ikonu) ile doğru yolu seçebilirsin.
import '../providers/app_provider.dart';

class BannerReklamWidget extends StatefulWidget {
  const BannerReklamWidget({Key? key}) : super(key: key);

  @override
  _BannerReklamWidgetState createState() => _BannerReklamWidgetState();
}

class _BannerReklamWidgetState extends State<BannerReklamWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  final adUnitId = 'ca-app-pub-3248869134952228/1596049049'; // TEST ID

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Kullanıcı Premium mu diye anlık kontrol ediyoruz (isPremium değişken adı sende farklıysa düzelt kanka)
    final isPremium = context.watch<AppProvider>().isPremium;

    // Eğer kullanıcı premium DEĞİLSE ve reklam henüz yüklenmemişse reklamı çek
    if (!isPremium && _bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Hafıza sızıntısını önlemek için widget kapanınca reklamı yok et
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build içinde de durumu dinliyoruz ki kullanıcı o an satın alım yaparsa reklam anında yok olsun
    final isPremium = context.watch<AppProvider>().isPremium;

    // Eğer kullanıcı Premium ise ekranı hiç işgal etme, reklamı tamamen gizle
    if (isPremium) {
      return const SizedBox.shrink();
    }

    // Premium değilse ve reklam yüklendiyse banner'ı göster
    return _isLoaded && _bannerAd != null
        ? SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    )
        : const SizedBox.shrink(); // Yüklenene kadar da boşluk bırak
  }
}
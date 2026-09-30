import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  // DİL-AS v1.0.1 Gerçek Tam Ekran (Interstitial) Reklam Kimliği
  static const String _interstitialAdUnitId = 'ca-app-pub-3248869134952228/7609004612';

  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;

  /// 1. UYGULAMA BAŞLARKEN ÇOCUK KORUMASINI AKTİF EDER
  static Future<void> initializeSettings() async {
    RequestConfiguration requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes, // Çocuklara yöneliktir
      maxAdContentRating: MaxAdContentRating.g, // Genel izleyici kitlesi (G) reklamları
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    // Uygulama açılışında ilk reklamı arkada yüklemeye başla
    loadInterstitialAd();
  }

  /// 2. REKLAMI ARKA PLANDA GİZLİCE YÜKLER (Bekleme yapmamak için)
  static Future<void> loadInterstitialAd() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;

    // Eğer kullanıcı premium satın almışsa boşuna internet harcayıp reklam yükleme!
    if (isPremium) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// 3. EKRANDA REKLAMI GÖSTERİR
  static Future<void> showInterstitialAd({required Function onAdClosed}) async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;

    // Eğer premiumsa VEYA reklam yüklenemediyse çocuğu bekletme, direkt oyuna devam et
    if (isPremium || !_isAdLoaded || _interstitialAd == null) {
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        // Reklam kapatıldığında
        ad.dispose();
        _isAdLoaded = false;
        loadInterstitialAd(); // Bir sonraki tur için yenisini yükle
        onAdClosed(); // Oyuna/Ana Ekrana dönüş kodunu çalıştır
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        // Reklam gösterilirken hata çıkarsa
        ad.dispose();
        _isAdLoaded = false;
        loadInterstitialAd();
        onAdClosed();
      },
    );

    // Her şey tamamsa reklamı patlat!
    _interstitialAd!.show();
  }
}
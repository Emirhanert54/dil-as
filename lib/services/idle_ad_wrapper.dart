import 'dart:async';
import 'package:flutter/material.dart';
import 'ad_manager.dart'; // Reklam yöneticisinin olduğu dosya yolu

class IdleAdWrapper extends StatefulWidget {
  final Widget child;
  const IdleAdWrapper({super.key, required this.child});

  @override
  State<IdleAdWrapper> createState() => _IdleAdWrapperState();
}

class _IdleAdWrapperState extends State<IdleAdWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Uygulama açılınca kronometreyi başlat
  }

  // Kronometreyi sıfırlayan ve 5 dakikadan geriye saydıran fonksiyon
  void _startTimer() {
    _timer?.cancel(); // Eğer halihazırda çalışan bir sayaç varsa onu durdur
    _timer = Timer(const Duration(minutes: 5), _onIdle); // 5 dakikalık yeni sayaç aç
  }

  // 5 dakika boyunca ekrana dokunulmadığında tetiklenen fonksiyon
  void _onIdle() {
    // Çocuk inaktif oldu, tam ekran reklamı gösteriyoruz
    AdManager.showInterstitialAd(
      onAdClosed: () {
        _startTimer(); // Reklam kapatılınca sayacı 5 dakikadan tekrar başlat
      },
    );
  }

  // Çocuk ekrana her dokunduğunda bu fonksiyon tetiklenecek
  void _handleUserInteraction([_]) {
    _startTimer(); // Her dokunmada kronometreyi sıfırla (Başa sar)
  }

  @override
  void dispose() {
    _timer?.cancel(); // Bellek sızıntısı olmasın diye çıkışta sayacı yok et
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listener bileşeni, altındaki tüm ekranlardaki parmak hareketlerini gizlice dinler
    return Listener(
      onPointerDown: _handleUserInteraction, // Parmağı bastığında
      onPointerMove: _handleUserInteraction, // Parmağı kaydırdığında
      onPointerUp: _handleUserInteraction,   // Parmağı çektiğinde
      child: widget.child,
    );
  }
}
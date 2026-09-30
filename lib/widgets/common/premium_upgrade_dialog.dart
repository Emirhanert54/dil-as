import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Kendi dosya yoluna göre burayı ayarla
import '../../providers/app_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  const PremiumUpgradeDialog({super.key});

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  final TextEditingController _mathController = TextEditingController();
  late int num1;
  late int num2;
  late int correctAnswer;
  bool hasError = false;

  // UI Kontrol Değişkenleri
  bool showMathVerify = false; // Önce vitrini göster, soru gizli
  String selectedPlan = 'lifetime'; // Varsayılan olarak süresiz seçili gelsin
  bool isLoading = false; // Butonlara basıldığında yükleniyor animasyonu için

  @override
  void initState() {
    super.initState();
    _generateMathProblem();
  }

  void _generateMathProblem() {
    final random = Random();
    num1 = random.nextInt(20) + 10; // 10 ile 29 arası
    num2 = random.nextInt(20) + 10;
    correctAnswer = num1 + num2;
  }

  // YENİ EKLENEN: SATIN ALMALARI GERİ YÜKLE FONKSİYONU
  void _restorePurchases() async {
    setState(() {
      isLoading = true;
    });
    try {
      // RevenueCat'e git ve bu hesabın önceden alınmış paketlerini getir
      CustomerInfo customerInfo = await Purchases.restorePurchases();

      if (customerInfo.entitlements.active.isNotEmpty) {
        // Kullanıcı önceden almış, kilitleri aç!
        if (!mounted) return;
        context.read<AppProvider>().purchasePremium();
        Navigator.pop(context); // Dialogu kapat

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Satın almalarınız başarıyla geri yüklendi! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Hesabında aktif bir paket yok
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aktif bir premium planınız bulunamadı."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _verifyAndPurchase() async {
    final int? userAnswer = int.tryParse(_mathController.text.trim());

    if (userAnswer == correctAnswer) {
      setState(() {
        isLoading = true;
      });
      try {
        Offerings offerings = await Purchases.getOfferings();
        if (offerings.current != null) {
          Package? packageToBuy;
          if (selectedPlan == 'monthly') {
            packageToBuy = offerings.current!.monthly;
          } else {
            packageToBuy = offerings.current!.lifetime;
          }

          if (packageToBuy != null) {
            PurchaseResult result = await Purchases.purchasePackage(packageToBuy);

            if (result.customerInfo.entitlements.active.isNotEmpty) {
              if (!mounted) return;
              context.read<AppProvider>().purchasePremium();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Premium özellikler başarıyla açıldı! 🎉"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Satın alma işlemi iptal edildi veya hata oluştu: $e");
        // Eğer kullanıcıda zaten varsa, Google Play hata fırlatır.
        // Hata fırlattığında ekranda uyarı görebilmek için ufak bir kontrol:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("İşlem tamamlanamadı. Eğer daha önce satın aldıysanız 'Geri Yükle' butonunu kullanın."),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        hasError = true;
        _mathController.clear();
        _generateMathProblem();
      });
    }
  }

  @override
  void dispose() {
    _mathController.dispose();
    super.dispose();
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planId, String title, String price, String subtitle) {
    final isSelected = selectedPlan == planId;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = planId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.amber.shade600, size: 22)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: showMathVerify
                ? _buildMathVerification()
                : _buildPaywallVitrin(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaywallVitrin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text("👑", style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "DİL-AS Premium",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          "Çocuğunuzun gelişimini hızlandırmak için tüm kilitleri açın!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        _buildFeatureRow(Icons.dashboard_customize_rounded, "Kilitli 6 Özel Etkinlik"),
        _buildFeatureRow(Icons.videogame_asset_rounded, "Eğlenceli 3 Yeni Oyun"),
        _buildFeatureRow(Icons.analytics_rounded, "Detaylı Ebeveyn ve Öğretmen Paneli"),
        _buildFeatureRow(Icons.color_lens_rounded, "3 Özel Premium Tema"),
        _buildFeatureRow(Icons.block_rounded, "Tamamen Reklamsız Deneyim"),

        const SizedBox(height: 24),

        _buildPlanCard('monthly', 'Aylık Plan', '49.90 TL', 'Her ay yenilenir. İstediğiniz zaman iptal edin.'),
        const SizedBox(height: 12),
        _buildPlanCard('lifetime', 'Ömür Boyu', '249.90 TL', 'Tek seferlik ödeme. Sonsuza kadar sizin.'),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: isLoading ? null : () {
            setState(() {
              showMathVerify = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Devam Et", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ),

        // YENİ EKLENEN BUTONLAR: Geri Yükle ve Daha Sonra
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading ? null : _restorePurchases,
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Satın Almaları Geri Yükle", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Daha Sonra", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _buildMathVerification() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                setState(() {
                  showMathVerify = false;
                  _mathController.clear();
                  hasError = false;
                });
              },
            ),
            const Expanded(
              child: Text(
                "Ebeveyn Doğrulaması",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 24),
        const Icon(Icons.security_rounded, size: 48, color: Colors.indigo),
        const SizedBox(height: 16),
        Text(
          "Lütfen işlemi onaylamak için aşağıdaki soruyu çözün:\n$num1 + $num2 = ?",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _mathController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: "Cevap",
            errorText: hasError ? "Yanlış cevap, tekrar deneyin." : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyAndPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Satın Almayı Tamamla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/session_flow_service.dart';

Future<bool?> showChildOnboardingDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ChildOnboardingDialog(),
  );
}
Future<bool?> showRestoreProfileDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _RestoreProfileDialog(),
  );
}
class ChildOnboardingDialog extends StatefulWidget {
  const ChildOnboardingDialog({super.key});

  @override
  State<ChildOnboardingDialog> createState() => _ChildOnboardingDialogState();
}

class _ChildOnboardingDialogState extends State<ChildOnboardingDialog> {
  final _nicknameController = TextEditingController();

  String _ageGroup = "6-7";
  int _selectedStarterIndex = 0;
  bool _saving = false;

  final List<_StarterMascot> _starters = const [
    _StarterMascot(
      emoji: "🚀",
      title: "Roket",
      subtitle: "Uzay dünyası",
      themeId: "space",
      stickerId: "space_starter_roket",
      recoveryWord: "ROKET",
      gradient: [
        Color(0xFF6C63FF),
        Color(0xFF8E2DE2),
      ],
    ),
    _StarterMascot(
      emoji: "🐥",
      title: "Civciv",
      subtitle: "Gökkuşağı dünyası",
      themeId: "rainbow",
      stickerId: "rainbow_starter_civciv",
      recoveryWord: "CIVCIV",
      gradient: [
        Color(0xFFFF7EB6),
        Color(0xFFFFD166),
      ],
    ),
    _StarterMascot(
      emoji: "🦁",
      title: "Aslan",
      subtitle: "Orman dünyası",
      themeId: "forest",
      stickerId: "forest_starter_aslan",
      recoveryWord: "ASLAN",
      gradient: [
        Color(0xFF43A047),
        Color(0xFF8BC34A),
      ],
    ),
    _StarterMascot(
      emoji: "🚗",
      title: "Araba",
      subtitle: "Araba dünyası",
      themeId: "car",
      stickerId: "car_starter_araba",
      recoveryWord: "ARABA",
      gradient: [
        Color(0xFF2196F3),
        Color(0xFF00BCD4),
      ],
    ),
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<String> _generateUniquePlayerId() async {
    final firestore = FirebaseFirestore.instance;
    final random = Random();

    for (int i = 0; i < 20; i++) {
      final number = 100000 + random.nextInt(900000);
      final playerId = "DLAS-$number";

      final exists = await firestore
          .collection('users')
          .where('playerId', isEqualTo: playerId)
          .limit(1)
          .get();

      if (exists.docs.isEmpty) {
        return playerId;
      }
    }

    final fallback = DateTime.now().millisecondsSinceEpoch.toString();
    return "DLAS-${fallback.substring(fallback.length - 6)}";
  }

  String _generatePin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<void> _completeSetup() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Takma ad en az 2 karakter olsun."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Kullanıcı bulunamadı. Tekrar giriş yap."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final selected = _starters[_selectedStarterIndex];

      final playerId = await _generateUniquePlayerId();
      final recoveryPin = _generatePin();
      final recoveryCode = "${selected.recoveryWord}-$recoveryPin";

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'uid': uid,
          'role': 'student',
          'accountType': 'student',
          'mode': 'individual',
          'isAnonymousChild': true,

          'name': nickname,
          'displayName': nickname,
          'nickname': nickname,
          'ageGroup': _ageGroup,

          'playerId': playerId,
          'recoveryPin': recoveryPin,
          'recoveryCode': recoveryCode,
          'profileSetupDone': true,
          'profileSetupAt': FieldValue.serverTimestamp(),

          'activeThemeId': selected.themeId,
          'activeStickerId': selected.stickerId,
          'ownedStickerIds': FieldValue.arrayUnion([selected.stickerId]),
          'activeStickerIdsByTheme': {
            'space': 'space_starter_roket',
            'rainbow': 'rainbow_starter_civciv',
            'forest': 'forest_starter_aslan',
            'car': 'car_starter_araba',
          },

          'stats': {},
          'stars': 0,
          'className': '',
          'teachers': [],
          'teacherIds': [],
          'parentIds': [],
          'dailyTask': {
            'date': '',
            'completed': 0,
            'bonusClaimed': false,
          },

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      try {
        // 💣 YENİ PROFİL OLUŞMADAN ÖNCE CİHAZIN PREMİUM HAFIZASINI SIFIRLA
        await context.read<AppProvider>().forceResetPremium();

        await context.read<AppProvider>().loadFromFirebase();
      } catch (_) {}

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RecoveryInfoDialog(
          playerId: playerId,
          recoveryCode: recoveryCode,
          gradient: selected.gradient,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profil oluşturulamadı. Tekrar dene."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _openRestoreDialog() async {
    final restored = await showRestoreProfileDialog(context);

    if (restored != true) return;
    if (!mounted) return;

    try {
      // 💣 ESKİ PROFİL GERİ YÜKLENMEDEN ÖNCE CİHAZIN PREMİUM HAFIZASINI SIFIRLA
      await context.read<AppProvider>().forceResetPremium();

      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _starters[_selectedStarterIndex];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          color: const Color(0xFFF8F7FF),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selected.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "DİL-AS'a Hoş Geldin!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Yeni profil oluşturabilir ya da eski profilini geri getirebilirsin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _openRestoreDialog,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text(
                      "Eski Profilimi Geri Yükle",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selected.gradient.first,
                      side: BorderSide(
                        color: selected.gradient.first.withOpacity(0.35),
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "veya yeni profil oluştur",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _nicknameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Takma adın",
                    hintText: "Örn: Emir",
                    prefixIcon: const Icon(Icons.face_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Yaş grubun",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.78),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AgeChip(
                      text: "4-5",
                      selected: _ageGroup == "4-5",
                      gradient: selected.gradient,
                      onTap: () => setState(() => _ageGroup = "4-5"),
                    ),
                    _AgeChip(
                      text: "6-7",
                      selected: _ageGroup == "6-7",
                      gradient: selected.gradient,
                      onTap: () => setState(() => _ageGroup = "6-7"),
                    ),
                    _AgeChip(
                      text: "8-9",
                      selected: _ageGroup == "8-9",
                      gradient: selected.gradient,
                      onTap: () => setState(() => _ageGroup = "8-9"),
                    ),
                    _AgeChip(
                      text: "10+",
                      selected: _ageGroup == "10+",
                      gradient: selected.gradient,
                      onTap: () => setState(() => _ageGroup = "10+"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Arkadaşını seç",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.78),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _starters.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.22,
                  ),
                  itemBuilder: (context, index) {
                    final item = _starters[index];
                    final isSelected = _selectedStarterIndex == index;

                    return _StarterCard(
                      item: item,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedStarterIndex = index;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _completeSetup,
                    icon: _saving
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                        : const Icon(Icons.rocket_launch_rounded),
                    label: Text(
                      _saving ? "Hazırlanıyor..." : "Başla",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected.gradient.first,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestoreProfileDialog extends StatefulWidget {
  const _RestoreProfileDialog();

  @override
  State<_RestoreProfileDialog> createState() => _RestoreProfileDialogState();
}

class _RestoreProfileDialogState extends State<_RestoreProfileDialog> {
  final _playerIdController = TextEditingController();
  final _recoveryCodeController = TextEditingController();

  bool _loading = false;
  bool _hideCode = true;

  @override
  void dispose() {
    _playerIdController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  Future<void> _restoreProfile() async {
    final playerId = _playerIdController.text.trim().toUpperCase();
    final recoveryCode = _recoveryCodeController.text.trim().toUpperCase();

    if (playerId.isEmpty || recoveryCode.isEmpty) {
      _showError("Oyuncu ID ve kurtarma kodu gerekli.");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (currentUid == null) {
        _showError("Aktif cihaz hesabı bulunamadı.");
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final result = await firestore
          .collection('users')
          .where('playerId', isEqualTo: playerId)
          .where('recoveryCode', isEqualTo: recoveryCode)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        _showError("Bu bilgilerle profil bulunamadı.");
        return;
      }

      final oldDoc = result.docs.first;
      final oldData = oldDoc.data();

      final role = oldData['role']?.toString() ?? "student";

      if (role != "student") {
        _showError("Bu kurtarma bilgisi çocuk profiline ait değil.");
        return;
      }

      final restoredData = Map<String, dynamic>.from(oldData);

      restoredData['uid'] = currentUid;
      restoredData['role'] = 'student';
      restoredData['accountType'] = 'student';
      restoredData['isAnonymousChild'] = true;
      restoredData['profileSetupDone'] = true;
      restoredData['restoredFromUid'] = oldDoc.id;
      restoredData['restoredAt'] = FieldValue.serverTimestamp();
      restoredData['updatedAt'] = FieldValue.serverTimestamp();

      await firestore.collection('users').doc(currentUid).set(
        restoredData,
        SetOptions(merge: false),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Eski profil bu cihaza yüklendi."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showError("Profil geri yüklenemedi. Tekrar dene.");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Eski Profili Geri Yükle",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ayarlar kısmındaki Oyuncu ID ve Kurtarma Kodu ile eski profilini bu cihaza bağlayabilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.68),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _playerIdController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Oyuncu ID",
                hintText: "DLAS-123456",
                prefixIcon: const Icon(Icons.person_pin_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _recoveryCodeController,
              textCapitalization: TextCapitalization.characters,
              obscureText: _hideCode,
              decoration: InputDecoration(
                labelText: "Kurtarma Kodu",
                hintText: "ROKET-1234",
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hideCode = !_hideCode;
                    });
                  },
                  icon: Icon(
                    _hideCode
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text(
            "Vazgeç",
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _restoreProfile,
          icon: _loading
              ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.2,
            ),
          )
              : const Icon(Icons.restore_rounded),
          label: Text(
            _loading ? "Yükleniyor..." : "Geri Yükle",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgeChip extends StatelessWidget {
  final String text;
  final bool selected;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _AgeChip({
    required this.text,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w900,
        ),
      ),
      selected: selected,
      selectedColor: gradient.first,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? gradient.first : Colors.black.withOpacity(0.08),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _StarterCard extends StatelessWidget {
  final _StarterMascot item;
  final bool selected;
  final VoidCallback onTap;

  const _StarterCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.0)
                  : Colors.black.withOpacity(0.07),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? item.gradient.first.withOpacity(0.28)
                    : Colors.black.withOpacity(0.05),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.emoji,
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withOpacity(0.88)
                      : Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryInfoDialog extends StatelessWidget {
  final String playerId;
  final String recoveryCode;
  final List<Color> gradient;

  const _RecoveryInfoDialog({
    required this.playerId,
    required this.recoveryCode,
    required this.gradient,
  });

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: "Oyuncu ID: $playerId\nKurtarma Kodu: $recoveryCode",
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kurtarma bilgileri kopyalandı."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      title: const Text(
        "Profilin Hazır!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Bu bilgileri ebeveynine göster veya kopyala. Yeni tablette eski profilini geri getirmek için gerekir.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _InfoBox(
            title: "Oyuncu ID",
            value: playerId,
            gradient: gradient,
          ),
          const SizedBox(height: 10),
          _InfoBox(
            title: "Kurtarma Kodu",
            value: recoveryCode,
            gradient: gradient,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyAll(context),
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text(
                "Bilgileri Kopyala",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: gradient.first,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            "Tamam",
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradient;

  const _InfoBox({
    required this.title,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: gradient.first.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient.first.withOpacity(0.20),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withOpacity(0.58),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterMascot {
  final String emoji;
  final String title;
  final String subtitle;
  final String themeId;
  final String stickerId;
  final String recoveryWord;
  final List<Color> gradient;

  const _StarterMascot({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.themeId,
    required this.stickerId,
    required this.recoveryWord,
    required this.gradient,
  });
}
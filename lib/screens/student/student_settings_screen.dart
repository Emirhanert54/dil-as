import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/voice_service.dart';

Future<void> showStudentSettingsDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const StudentSettingsDialog(),
  );
}

class StudentSettingsDialog extends StatefulWidget {
  const StudentSettingsDialog({super.key});

  @override
  State<StudentSettingsDialog> createState() => _StudentSettingsDialogState();
}

class _StudentSettingsDialogState extends State<StudentSettingsDialog> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _showRecoveryCode = false;

  String _playerId = "";
  String _recoveryCode = "";

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _voiceRate = 0.45;
  double _voicePitch = 1.05;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _generatePlayerId() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return "DLAS-$number";
  }

  String _generateRecoveryCode() {
    final random = Random();

    final words = [
      "ROKET",
      "ASLAN",
      "CIVCIV",
      "ARABA",
      "YILDIZ",
      "AY",
      "GUNES",
      "BULUT",
    ];

    final word = words[random.nextInt(words.length)];
    final number = 1000 + random.nextInt(9000);

    return "$word-$number";
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await ref.get();
    final data = doc.data() ?? {};

    String playerId = data['playerId']?.toString() ?? "";
    String recoveryCode = data['recoveryCode']?.toString() ?? "";

    final updateData = <String, dynamic>{};

    if (playerId.isEmpty) {
      playerId = _generatePlayerId();
      updateData['playerId'] = playerId;
      updateData['createdPlayerIdAt'] = FieldValue.serverTimestamp();
    }

    if (recoveryCode.isEmpty) {
      recoveryCode = _generateRecoveryCode();
      updateData['recoveryCode'] = recoveryCode;
      updateData['createdRecoveryCodeAt'] = FieldValue.serverTimestamp();
    }

    if (updateData.isNotEmpty) {
      updateData['accountType'] = data['accountType'] ?? 'student';
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await ref.set(
        updateData,
        SetOptions(merge: true),
      );
    }

    final settingsRaw = data['settings'];
    final settings =
    settingsRaw is Map<String, dynamic> ? settingsRaw : <String, dynamic>{};

    final visibleName =
        data['displayName']?.toString() ?? data['name']?.toString() ?? "";

    _nameController.text =
        data['realName']?.toString() ?? data['name']?.toString() ?? "";
    _surnameController.text = data['surname']?.toString() ?? "";
    _nicknameController.text = data['nickname']?.toString() ?? visibleName;

    _playerId = playerId;
    _recoveryCode = recoveryCode;

    _soundEnabled = settings['soundEnabled'] is bool
        ? settings['soundEnabled'] as bool
        : true;

    _vibrationEnabled = settings['vibrationEnabled'] is bool
        ? settings['vibrationEnabled'] as bool
        : true;

    _voiceRate = settings['voiceRate'] is num
        ? (settings['voiceRate'] as num).toDouble()
        : 0.45;

    _voicePitch = settings['voicePitch'] is num
        ? (settings['voicePitch'] as num).toDouble()
        : 1.05;

    await VoiceService.instance.updateSettings(
      enabled: _soundEnabled,
      rate: _voiceRate,
      pitch: _voicePitch,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
    });

    final realName = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final nickname = _nicknameController.text.trim();

    final visibleName = nickname.isNotEmpty
        ? nickname
        : realName.isNotEmpty
        ? realName
        : "Öğrenci";

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'name': visibleName,
        'realName': realName,
        'surname': surname,
        'nickname': nickname,
        'displayName': visibleName,
        'playerId': _playerId,
        'recoveryCode': _recoveryCode,
        'settings': {
          'soundEnabled': _soundEnabled,
          'vibrationEnabled': _vibrationEnabled,
          'voiceRate': _voiceRate,
          'voicePitch': _voicePitch,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await VoiceService.instance.updateSettings(
      enabled: _soundEnabled,
      rate: _voiceRate,
      pitch: _voicePitch,
    );

    try {
      final dynamic provider = context.read<AppProvider>();
      await provider.loadFromFirebase();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Ayarlar kaydedildi."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.read<AppProvider>().currentTheme.gradient.first,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _copyPlayerId() async {
    if (_playerId.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _playerId),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Oyuncu ID kopyalandı."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyRecoveryCode() async {
    if (_recoveryCode.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _recoveryCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kurtarma kodu kopyalandı."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyAllRecoveryInfo() async {
    if (_playerId.isEmpty && _recoveryCode.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(
        text: "Oyuncu ID: $_playerId\nKurtarma Kodu: $_recoveryCode",
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kurtarma bilgileri kopyalandı."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _testVoice() async {
    await VoiceService.instance.updateSettings(
      enabled: _soundEnabled,
      rate: _voiceRate,
      pitch: _voicePitch,
    );

    await VoiceService.instance.testVoice();
  }

  Future<void> _toggleSound() async {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });

    await VoiceService.instance.setEnabled(_soundEnabled);
  }

  Future<void> _toggleVibration() async {
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
    });

    if (_vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 390,
          ),
          color: const Color(0xFFF7F7FF),
          child: _loading
              ? SizedBox(
            height: 360,
            child: Center(
              child: CircularProgressIndicator(
                color: gradient.first,
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactHeader(
                  gradient: gradient,
                  mascot: u.currentMascot.emoji,
                  playerId: _playerId,
                  onCopy: _copyPlayerId,
                  onClose: () => Navigator.pop(context),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _MiniTextField(
                        controller: _nameController,
                        label: "Ad",
                        icon: Icons.badge_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniTextField(
                        controller: _surnameController,
                        label: "Soyad",
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _MiniTextField(
                  controller: _nicknameController,
                  label: "Takma ad / görünen ad",
                  icon: Icons.face_rounded,
                ),

                const SizedBox(height: 14),

                _RecoveryInfoCard(
                  gradient: gradient,
                  playerId: _playerId,
                  recoveryCode: _recoveryCode,
                  showRecoveryCode: _showRecoveryCode,
                  onToggleShow: () {
                    setState(() {
                      _showRecoveryCode = !_showRecoveryCode;
                    });
                  },
                  onCopyPlayerId: _copyPlayerId,
                  onCopyRecoveryCode: _copyRecoveryCode,
                  onCopyAll: _copyAllRecoveryInfo,
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CircleToggle(
                            icon: Icons.volume_up_rounded,
                            active: _soundEnabled,
                            gradient: gradient,
                            onTap: _toggleSound,
                          ),
                          const SizedBox(width: 10),
                          _CircleToggle(
                            icon: Icons.vibration_rounded,
                            active: _vibrationEnabled,
                            gradient: gradient,
                            onTap: _toggleVibration,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                              _soundEnabled ? _testVoice : null,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                "Ses Testi",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gradient.first,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                Colors.grey.shade300,
                                disabledForegroundColor:
                                Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _CompactSlider(
                        title: "Ses hızı",
                        value: _voiceRate,
                        min: 0.25,
                        max: 0.75,
                        divisions: 10,
                        gradient: gradient,
                        onChanged: (value) async {
                          setState(() {
                            _voiceRate = value;
                          });

                          await VoiceService.instance.updateSettings(
                            rate: _voiceRate,
                          );
                        },
                      ),

                      _CompactSlider(
                        title: "Ses tonu",
                        value: _voicePitch,
                        min: 0.75,
                        max: 1.45,
                        divisions: 14,
                        gradient: gradient,
                        onChanged: (value) async {
                          setState(() {
                            _voicePitch = value;
                          });

                          await VoiceService.instance.updateSettings(
                            pitch: _voicePitch,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    icon: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? "Kaydediliyor..." : "Kaydet",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradient.first,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
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

class _CompactHeader extends StatelessWidget {
  final List<Color> gradient;
  final String mascot;
  final String playerId;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  const _CompactHeader({
    required this.gradient,
    required this.mascot,
    required this.playerId,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(
              mascot,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ayarlar ve Profil",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onCopy,
                  child: Text(
                    "Oyuncu ID: $playerId",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.90),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryInfoCard extends StatelessWidget {
  final List<Color> gradient;
  final String playerId;
  final String recoveryCode;
  final bool showRecoveryCode;
  final VoidCallback onToggleShow;
  final VoidCallback onCopyPlayerId;
  final VoidCallback onCopyRecoveryCode;
  final VoidCallback onCopyAll;

  const _RecoveryInfoCard({
    required this.gradient,
    required this.playerId,
    required this.recoveryCode,
    required this.showRecoveryCode,
    required this.onToggleShow,
    required this.onCopyPlayerId,
    required this.onCopyRecoveryCode,
    required this.onCopyAll,
  });

  @override
  Widget build(BuildContext context) {
    final maskedCode = recoveryCode.isEmpty ? "Yok" : "••••••••••";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradient.first.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: gradient.first.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: gradient.first,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kurtarma Bilgilerim",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Yeni tablette eski profili açmak için saklanır.",
                      style: TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _RecoveryLine(
            title: "Oyuncu ID",
            value: playerId.isEmpty ? "Yok" : playerId,
            icon: Icons.person_pin_rounded,
            gradient: gradient,
            onCopy: onCopyPlayerId,
          ),

          const SizedBox(height: 8),

          _RecoveryLine(
            title: "Kurtarma Kodu",
            value: showRecoveryCode ? recoveryCode : maskedCode,
            icon: Icons.key_rounded,
            gradient: gradient,
            onCopy: onCopyRecoveryCode,
            trailing: IconButton(
              tooltip: showRecoveryCode ? "Gizle" : "Göster",
              onPressed: onToggleShow,
              icon: Icon(
                showRecoveryCode
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: gradient.first,
                size: 21,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onCopyAll,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text(
                "Tüm Kurtarma Bilgilerini Kopyala",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: gradient.first,
                side: BorderSide(
                  color: gradient.first.withOpacity(0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryLine extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onCopy;
  final Widget? trailing;

  const _RecoveryLine({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onCopy,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 46,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: gradient.first.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: gradient.first,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          IconButton(
            tooltip: "Kopyala",
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_rounded,
              color: gradient.first,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _MiniTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CircleToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CircleToggle({
    required this.icon,
    required this.active,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? gradient.first : Colors.grey;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.35),
                width: 1.4,
              ),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          if (!active)
            Transform.rotate(
              angle: -0.75,
              child: Container(
                width: 38,
                height: 3,
                decoration: BoxDecoration(
                  color: gradient.first,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;

  const _CompactSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: gradient.first,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
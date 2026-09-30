import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_theme_style.dart';
import '../models/sticker_reward.dart';
import '../repositories/child_profile_repository.dart';
import '../repositories/reward_repository.dart';
import '../repositories/theme_repository.dart';
import '../services/voice_service.dart';

class BadgeModel {
  final String title;
  final String icon;
  final Color color;
  final String description;

  BadgeModel(
      this.title,
      this.icon,
      this.color, {
        this.description = "",
      });
}

class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  bool _isDisposed = false;
  int _feedbackToken = 0;

  String name = "Yükleniyor...";
  String className = "";
  int stars = 0;

  bool isPremium = false;

  void setPremium() {
    isPremium = true;
    notifyListeners();
  }

  static const int dailyGoal = 3;
  static const int dailyBonus = 2;

  int dailyCompleted = 0;
  bool dailyBonusClaimed = false;
  String dailyTaskDate = "";

  List<String> ownedStickerIds = [];

  Map<String, String> activeStickerIdsByTheme = {};
  String activeThemeId = "space";

  String? _activeStickerId;

  String? get activeStickerId => _activeStickerId;

  set activeStickerId(String? value) {
    _activeStickerId = value;
  }

  final Map<String, int> _stats = {};
  List<BadgeModel> earnedBadges = [];

  String feedbackText = "";
  Color feedbackColor = Colors.transparent;

  String _lastSpokenText = "";

  Map<String, dynamic>? lastActivity;

  AppProvider() {
    VoiceService.instance.init();
  }

  @override
  void dispose() {
    _isDisposed = true;
    VoiceService.instance.stop();
    super.dispose();
  }

  String _todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String get lastSpokenText => _lastSpokenText;

  Map<String, int> get stats => _stats;

  ChildThemeStyle get currentTheme {
    return ThemeRepository.findById(activeThemeId);
  }

  int get dailyRemaining {
    final remaining = dailyGoal - dailyCompleted;
    return remaining < 0 ? 0 : remaining;
  }

  double get dailyProgress {
    if (dailyGoal == 0) return 0;

    final value = dailyCompleted / dailyGoal;
    return value > 1 ? 1 : value;
  }

  bool get hasLastActivity {
    return lastActivity != null &&
        lastActivity!['gameType'] != null &&
        lastActivity!['levelTitle'] != null &&
        lastActivity!['gameType'].toString().isNotEmpty &&
        lastActivity!['levelTitle'].toString().isNotEmpty;
  }

  StickerReward? get activeSticker {
    final selectedId = activeStickerIdsByTheme[activeThemeId];

    if (selectedId != null) {
      final selectedSticker = RewardRepository.findById(selectedId);

      if (selectedSticker != null &&
          selectedSticker.themeId == activeThemeId &&
          ownsSticker(selectedSticker.id)) {
        return selectedSticker;
      }
    }

    return RewardRepository.starterForTheme(activeThemeId);
  }

  StickerReward get currentMascot {
    return activeSticker ?? RewardRepository.starterForTheme(activeThemeId);
  }

  bool ownsSticker(String stickerId) {
    final sticker = RewardRepository.findById(stickerId);

    if (sticker == null) return false;

    if (sticker.isStarter || sticker.price == 0) {
      return true;
    }

    return ownedStickerIds.contains(stickerId);
  }

  Future<void> speak(
      String text, {
        bool interrupt = true,
      }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || _isDisposed) return;

    _lastSpokenText = cleanText;

    await VoiceService.instance.speak(
      cleanText,
      interrupt: interrupt,
    );
  }

  Future<void> stopVoice() async {
    await VoiceService.instance.stop();
  }

  Future<void> testVoice() async {
    await VoiceService.instance.testVoice();
  }

  Future<void> repeatLastSpoken() async {
    if (_lastSpokenText.trim().isEmpty || _isDisposed) return;

    await speak(
      _lastSpokenText,
      interrupt: true,
    );
  }

  void _normalizeActiveStickerForTheme(String themeId) {
    final currentId = activeStickerIdsByTheme[themeId];
    final currentSticker =
    currentId == null ? null : RewardRepository.findById(currentId);

    final invalidSticker = currentSticker == null ||
        currentSticker.themeId != themeId ||
        !ownsSticker(currentSticker.id);

    if (invalidSticker) {
      final starter = RewardRepository.starterForTheme(themeId);
      activeStickerIdsByTheme[themeId] = starter.id;
    }
  }

  void _normalizeAllThemeStickers() {
    for (final theme in ThemeRepository.themes) {
      _normalizeActiveStickerForTheme(theme.id);
    }

    _activeStickerId = activeStickerIdsByTheme[activeThemeId];
  }

  Future<Map<String, dynamic>?> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return null;

    try {
      await ChildProfileRepository.syncUserDocToActiveChildProfile();

      final childData = await ChildProfileRepository.getActiveChildProfileData();
      if (childData != null && childData.isNotEmpty) {
        return childData;
      }
    } catch (e) {
      debugPrint("childProfiles okuma hatası: $e");
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("users okuma hatası: $e");
      return null;
    }
  }

  Future<void> _saveProfilePatch(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    try {
      await ChildProfileRepository.updateActiveChildProfile(data);
    } catch (e) {
      debugPrint("childProfiles kaydetme hatası: $e");
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("users kaydetme hatası: $e");
    }
  }

  Future<void> loadFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    try {
      // 🚀 1. KORUMA ALANI: FİREBASE'DEN PREMİUM'U HEMEN GÜVENCEYE AL!
      // Senkronizasyon başlamadan önce gerçek veriyi kenara kopyalıyoruz.
      final preSyncDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool realPremium = preSyncDoc.exists && preSyncDoc.data()?['isPremium'] == true;

      // 🚀 2. TEHLİKELİ ALAN: Repo çalışsın (Firebase'deki Premium'u bilmeden silerse silsin, yedeğimiz var)
      final data = await _loadProfileData();

      if (data == null || _isDisposed) return;

      name = data['nickname']?.toString().trim().isNotEmpty == true
          ? data['nickname'].toString()
          : data['name']?.toString() ?? "Öğrenci";

      className = data['className']?.toString() ?? "";
      stars = data['stars'] is num ? (data['stars'] as num).toInt() : 0;

      _stats.clear();
      if (data['stats'] is Map) {
        final rawStats = Map<String, dynamic>.from(data['stats']);
        rawStats.forEach((key, value) {
          if (value is num) {
            _stats[key.toString()] = value.toInt();
          }
        });
      }

      if (data['lastActivity'] is Map) {
        final rawLastActivity = Map<String, dynamic>.from(data['lastActivity']);
        final gameType = rawLastActivity['gameType']?.toString() ?? "";
        final levelTitle = rawLastActivity['levelTitle']?.toString() ?? "";
        final savedStep = rawLastActivity['step'] is num
            ? (rawLastActivity['step'] as num).toInt()
            : int.tryParse(rawLastActivity['step']?.toString() ?? "0") ?? 0;

        if (gameType.isNotEmpty && levelTitle.isNotEmpty) {
          lastActivity = {
            ...rawLastActivity,
            'gameType': gameType,
            'levelTitle': levelTitle,
            'step': savedStep < 0 ? 0 : savedStep,
          };
        } else {
          lastActivity = null;
        }
      } else {
        lastActivity = null;
      }

      if (data['ownedStickerIds'] is List) {
        ownedStickerIds = List<String>.from(
          (data['ownedStickerIds'] as List).map((e) => e.toString()),
        );
      } else {
        ownedStickerIds = [];
      }

      activeThemeId = data['activeThemeId']?.toString() ?? "space";
      activeStickerIdsByTheme = {};

      if (data['activeStickerIdsByTheme'] is Map) {
        final rawMap = Map<String, dynamic>.from(data['activeStickerIdsByTheme']);
        rawMap.forEach((key, value) {
          final themeId = key.toString().trim();
          final stickerId = value?.toString().trim() ?? "";
          if (themeId.isNotEmpty && stickerId.isNotEmpty) {
            activeStickerIdsByTheme[themeId] = stickerId;
          }
        });
      }

      final loadedStickerId = data['activeStickerId']?.toString().trim();
      if (loadedStickerId != null && loadedStickerId.isNotEmpty) {
        activeStickerIdsByTheme.putIfAbsent(activeThemeId, () => loadedStickerId);
      }

      _normalizeAllThemeStickers();

      final today = _todayKey();
      if (data['dailyTasks'] is Map) {
        final dailyTasks = Map<String, dynamic>.from(data['dailyTasks']);
        final date = dailyTasks['date']?.toString() ?? today;

        if (date == today && dailyTasks['tasks'] is List) {
          final tasks = List<dynamic>.from(dailyTasks['tasks']);
          dailyTaskDate = today;
          dailyCompleted = tasks.where((task) {
            if (task is! Map) return false;
            return task['completed'] == true;
          }).length;
          dailyBonusClaimed = dailyTasks['bonusClaimed'] == true;
        } else {
          dailyTaskDate = today;
          dailyCompleted = 0;
          dailyBonusClaimed = false;
        }
      } else if (data['dailyTask'] is Map) {
        final dailyTask = Map<String, dynamic>.from(data['dailyTask']);
        dailyTaskDate = dailyTask['date']?.toString() ?? today;

        if (dailyTaskDate == today) {
          dailyCompleted = dailyTask['completed'] is num
              ? (dailyTask['completed'] as num).toInt()
              : 0;
          dailyBonusClaimed = dailyTask['bonusClaimed'] == true;
        } else {
          dailyTaskDate = today;
          dailyCompleted = 0;
          dailyBonusClaimed = false;
        }
      } else {
        dailyTaskDate = today;
        dailyCompleted = 0;
        dailyBonusClaimed = false;
      }

      _checkBadges(speakAlert: false);

      // 🚀 3. TAMİR ALANI: GERÇEK PREMİUM'U UYGULAMAYA YAPIŞTIR
      isPremium = realPremium;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', realPremium);

      // Eğer sistemdeki repo, Firebase'deki Premium'u sildiyse; zorla geri yazdırıyoruz!
      if (realPremium) {
        await _firestore.collection('users').doc(user.uid).set(
          {'isPremium': true},
          SetOptions(merge: true),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint("AppProvider loadFromFirebase hatası: $e");
    }
  }

  Future<void> _saveToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    await _saveProfilePatch({
      'stats': _stats,
      'stars': stars,
      'ownedStickerIds': ownedStickerIds,
      'activeStickerId': activeStickerId,
      'activeStickerIdsByTheme': activeStickerIdsByTheme,
      'activeThemeId': activeThemeId,
      'dailyTask': {
        'date': _todayKey(),
        'completed': dailyCompleted,
        'goal': dailyGoal,
        'bonus': dailyBonus,
        'bonusClaimed': dailyBonusClaimed,
      },
    });
  }

  void setLastActivity(Map<String, dynamic> value) {
    if (_isDisposed) return;

    final gameType = value['gameType']?.toString().trim() ?? "";
    final levelTitle = value['levelTitle']?.toString().trim() ?? "";

    if (gameType.isEmpty || levelTitle.isEmpty) return;

    lastActivity = Map<String, dynamic>.from(value);
    notifyListeners();
  }

  Future<void> saveLastActivity({
    required String gameType,
    required String levelTitle,
    required int step,
  }) async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    final safeStep = step < 0 ? 0 : step;

    lastActivity = {
      'gameType': gameType,
      'levelTitle': levelTitle,
      'step': safeStep,
      'updatedAt': Timestamp.now(),
    };

    try {
      await _saveProfilePatch({
        'lastActivity': {
          'gameType': gameType,
          'levelTitle': levelTitle,
          'step': safeStep,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'lastActivityUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Son etkinlik kaydedilemedi: $e");
    }
  }

  Future<void> clearLastActivity() async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    lastActivity = null;

    try {
      await _saveProfilePatch({
        'lastActivity': FieldValue.delete(),
        'lastActivityUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Son etkinlik temizlenemedi: $e");
    }
  }

  Future<bool> buySticker(StickerReward sticker) async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return false;

    if (sticker.isStarter || sticker.price == 0) {
      return setActiveSticker(sticker);
    }

    if (sticker.themeId != activeThemeId) {
      debugPrint("Farklı temanın stickerı satın alınamaz.");
      await speak("Bu sticker şu anki temaya ait değil.");
      return false;
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final result = await _firestore.runTransaction<Map<String, dynamic>>(
            (transaction) async {
          final snapshot = await transaction.get(userRef);

          if (!snapshot.exists) {
            return {
              'success': false,
              'reason': 'Kullanıcı profili bulunamadı.',
            };
          }

          final data = snapshot.data() ?? {};

          final int currentStars = data['stars'] is num
              ? (data['stars'] as num).toInt()
              : 0;

          final List<String> currentOwnedStickerIds =
          data['ownedStickerIds'] is List
              ? List<String>.from(
            (data['ownedStickerIds'] as List).map(
                  (e) => e.toString(),
            ),
          )
              : <String>[];

          if (currentOwnedStickerIds.contains(sticker.id)) {
            return {
              'success': false,
              'reason': 'Bu ödül zaten alınmış.',
              'stars': currentStars,
              'ownedStickerIds': currentOwnedStickerIds,
            };
          }

          if (currentStars < sticker.price) {
            return {
              'success': false,
              'reason': 'Yıldız yetersiz.',
              'stars': currentStars,
              'ownedStickerIds': currentOwnedStickerIds,
            };
          }

          final int newStars = currentStars - sticker.price;

          final List<String> newOwnedStickerIds = [
            ...currentOwnedStickerIds,
            sticker.id,
          ];

          transaction.update(userRef, {
            'stars': newStars,
            'ownedStickerIds': newOwnedStickerIds,
            'lastStickerPurchaseAt': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'reason': 'Satın alma başarılı.',
            'stars': newStars,
            'ownedStickerIds': newOwnedStickerIds,
          };
        },
      );

      if (result['stars'] is num) {
        stars = (result['stars'] as num).toInt();
      }

      if (result['ownedStickerIds'] is List) {
        ownedStickerIds = List<String>.from(
          (result['ownedStickerIds'] as List).map(
                (e) => e.toString(),
          ),
        );
      }

      if (result['success'] == true) {
        await _saveProfilePatch({
          'stars': stars,
          'ownedStickerIds': ownedStickerIds,
          'lastStickerPurchaseAt': FieldValue.serverTimestamp(),
        });
      }

      if (!_isDisposed) {
        notifyListeners();
      }

      if (result['success'] == true) {
        await speak("${sticker.title} satın alındı!");
        return true;
      }

      final reason = result['reason']?.toString() ?? "Satın alma başarısız.";
      debugPrint("Sticker satın alınamadı: $reason");

      if (reason.contains("Yıldız")) {
        await speak("Yıldızın yetmiyor. Biraz daha oyun oynayalım!");
      }

      return false;
    } catch (e) {
      debugPrint("Sticker satın alma hatası: $e");
      return false;
    }
  }

  Future<bool> setActiveSticker(StickerReward sticker) async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return false;

    if (sticker.themeId != activeThemeId) {
      debugPrint("Farklı temanın stickerı aktif yapılamaz.");
      return false;
    }

    if (!ownsSticker(sticker.id)) {
      return false;
    }

    activeStickerIdsByTheme[activeThemeId] = sticker.id;
    _activeStickerId = sticker.id;

    try {
      await _saveProfilePatch({
        'activeStickerId': sticker.id,
        'activeStickerIdsByTheme': activeStickerIdsByTheme,
      });

      await speak("${sticker.title} seçildi!");

      if (!_isDisposed) {
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint("Aktif sticker seçilemedi: $e");
      return false;
    }
  }

  Future<void> setActiveTheme(ChildThemeStyle theme) async {
    if (_isDisposed) return;

    activeThemeId = theme.id;
    _normalizeActiveStickerForTheme(activeThemeId);
    _activeStickerId = activeStickerIdsByTheme[activeThemeId];

    notifyListeners();

    await speak("${theme.title} seçildi.");
    await _saveToFirebase();
  }

  void addPoint(String activityKey) {
    if (_isDisposed) return;

    final today = _todayKey();

    if (dailyTaskDate != today) {
      dailyTaskDate = today;
      dailyCompleted = 0;
      dailyBonusClaimed = false;
    }

    _stats[activityKey] = (_stats[activityKey] ?? 0) + 1;
    stars += 1;

    if (dailyCompleted < dailyGoal) {
      dailyCompleted += 1;
    }

    if (dailyCompleted >= dailyGoal && !dailyBonusClaimed) {
      stars += dailyBonus;
      dailyBonusClaimed = true;

      speak(
        "Günlük görev tamamlandı! Bonus yıldız kazandın!",
        interrupt: true,
      );
    }

    _saveToFirebase();
    _checkBadges(speakAlert: true);

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _shortFeedbackSpeech({
    required bool isSuccess,
    required String screenText,
  }) {
    if (!isSuccess) {
      final wrongShorts = [
        "Tekrar dene.",
        "Olacak.",
        "Bir daha deneyelim.",
        "Yaklaştın.",
      ];
      return wrongShorts[_random.nextInt(wrongShorts.length)];
    }

    final firstWord = screenText.trim().split(RegExp(r'\s+')).first;
    final cleaned = firstWord
        .replaceAll("!", "")
        .replaceAll(".", "")
        .replaceAll(",", "")
        .replaceAll(":", "")
        .trim();

    if (cleaned.isNotEmpty) {
      return "$cleaned!";
    }

    final successShorts = [
      "Harikasın!",
      "Süper!",
      "Bravo!",
      "Çokiyi!",
    ];

    return successShorts[_random.nextInt(successShorts.length)];
  }

  void showFeedback(bool isSuccess) {
    if (_isDisposed) return;

    final successMessages = [
      "Harikasın! Çok güzel yaptın!",
      "Süpersin! Böyle devam et!",
      "Bravo! Harika ilerliyorsun!",
      "Mükemmel! Bir sonrakine geçebiliriz!",
      "Çokiyi! Dikkatin harika!",
      "Efsane gidiyorsun! Devam edelim!",
      "Muhteşem! Maskotun çok sevindi!",
      "Aferin! Bu cevap tam isabet!",
      "Süper odaklandın! Çok güzel!",
      "Harika seçim! Bir yıldız gibi parlıyorsun!",
    ];

    final tryAgainMessages = [
      "Tekrar dene! Yapabilirsin.",
      "Neredeyse oluyordu! Bir daha deneyelim.",
      "Sorun değil, tekrar deneyebilirsin.",
      "Biraz daha dikkat edelim, başaracaksın!",
      "Hadi tekrar bakalım, doğru cevaba çok yaklaştın!",
      "Olacak! Bir kez daha dene.",
      "Yaklaştın! Dikkatli bakarsan bulacaksın.",
      "Denemeye devam! Her deneme seni geliştirir.",
      "Küçük bir hata oldu, tekrar deneyelim.",
      "Pes etmek yok! Birlikte başaracağız.",
    ];

    final message = isSuccess
        ? successMessages[_random.nextInt(successMessages.length)]
        : tryAgainMessages[_random.nextInt(tryAgainMessages.length)];

    feedbackText = message;
    feedbackColor = isSuccess ? Colors.green.shade600 : Colors.deepOrange;

    final speech = _shortFeedbackSpeech(
      isSuccess: isSuccess,
      screenText: message,
    );

    notifyListeners();

    speak(
      speech,
      interrupt: true,
    );

    final token = ++_feedbackToken;

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (_isDisposed || token != _feedbackToken) return;

      feedbackText = "";
      feedbackColor = Colors.transparent;
      notifyListeners();
    });
  }

  void _checkBadges({required bool speakAlert}) {
    final oldTitles = earnedBadges.map((badge) => badge.title).toSet();

    final total = _stats.values.fold<int>(
      0,
          (sum, value) => sum + value,
    );

    earnedBadges.clear();

    void add(
        String title,
        String icon,
        Color color, {
          required String description,
        }) {
      earnedBadges.add(
        BadgeModel(
          title,
          icon,
          color,
          description: description,
        ),
      );
    }

    if (total >= 5) {
      add("Minik Kaşif", "🐣", Colors.orange, description: "İlk adımlar tamamlandı.");
    }
    if (total >= 15) {
      add("Çalışkan Yıldız", "⭐", Colors.amber, description: "Düzenli öğrenmeye başladın.");
    }
    if (total >= 30) {
      add("Süper Öğrenci", "🚀", Colors.deepPurple, description: "Etkinliklerde harika ilerliyorsun.");
    }
    if (total >= 60) {
      add("Efsane Kaşif", "🌈", Colors.teal, description: "Birçok görevi başarıyla tamamladın.");
    }
    if (total >= 100) {
      add("Dil-As Şampiyonu", "🏆", Colors.blue, description: "Öğrenme yolculuğunda zirvedesin.");
    }

    if (!speakAlert || _isDisposed) return;

    final newBadges = earnedBadges.where(
          (badge) => !oldTitles.contains(badge.title),
    );

    if (newBadges.isEmpty) return;

    final badge = newBadges.last;

    speak(
      "Yeni rozet kazandın! ${badge.title}.",
      interrupt: true,
    );
  }

  // Cihaz değişiminde lokal hafızayı sıfırlayan temiz fonksiyon
  Future<void> forceResetPremium() async {
    isPremium = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', false);
    notifyListeners();
  }

  // 🚀 KESİN ÇÖZÜM: REPO'YA BULAŞTIRMADAN SATIN ALMA (DIRECT TO FIREBASE)
  Future<void> purchasePremium() async {
    final user = _auth.currentUser;
    if (user == null || _isDisposed) return;

    isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    notifyListeners();

    // DİKKAT: _saveProfilePatch KULLANMIYORUZ! Direkt Firebase'in kalbine yazıyoruz.
    await _firestore.collection('users').doc(user.uid).set(
      {'isPremium': true},
      SetOptions(merge: true),
    );

    // KESİN ÇÖZÜM: Çocuğun yedeği varsa, yedeğin asıl dokümanına da mühürle!
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['restoredFromUid'] != null) {
        final originalDocId = data['restoredFromUid'].toString();
        await _firestore
            .collection('users')
            .doc(originalDocId)
            .set({'isPremium': true}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Yedek dokümana premium yazılamadı: $e");
    }

    await speak("Premium aktif edildi! Reklamlar tamamen kaldırıldı.", interrupt: true);
  }
}
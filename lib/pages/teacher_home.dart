import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/common/help_guide_button.dart';
import '../services/session_flow_service.dart';
import '../widgets/common/usage_today_card.dart';
import '../services/push_request_service.dart';
import '../repositories/game_repository.dart';
import 'login_page.dart';
import '../repositories/development_report_repository.dart';
import '../widgets/common/usage_last_three_days_card.dart';
import '../widgets/common/adult_panel_background.dart';

class _TeacherFoundChildProfile {
  final String childId;
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;

  const _TeacherFoundChildProfile({
    required this.childId,
    required this.ref,
    required this.data,
  });
}
class TeacherPalette {
  static const Color primary = Color(0xFF4454D6);
  static const Color purple2 = Color(0xFF6D3BEA);
  static const Color secondary = Color(0xFF172033);
  static const Color background = Color(0xFFEFF3FA);
  static const Color green = Color(0xFF0F9F8E);
  static const Color orange = Color(0xFFF59E0B);

  static const List<Color> mainGradient = [
    Color(0xFF172033),
    Color(0xFF4454D6),
  ];

  static const List<Color> lessonGradient = [
    Color(0xFF4454D6),
    Color(0xFF6D3BEA),
  ];

  // Sınıf / öğrenci alanları: lacivert + kurumsal mavi
  static const List<Color> classGradient = [
    Color(0xFF172033),
    Color(0xFF2563EB),
  ];

  // Mesaj alanları: gri-lacivert + amber
  static const List<Color> messageGradient = [
    Color(0xFF334155),
    Color(0xFFF59E0B),
  ];
  // Grafik / rapor gibi alanlar
  static const List<Color> blueGradient = [
    Color(0xFF2563EB),
    Color(0xFF6D3BEA),
  ];
}

class _TeacherGameInfo {
  final String gameType;
  final String title;
  final String emoji;
  final IconData icon;

  const _TeacherGameInfo({
    required this.gameType,
    required this.title,
    required this.emoji,
    required this.icon,
  });
}

const List<_TeacherGameInfo> _teacherGames = [
  _TeacherGameInfo(
    gameType: "Heceleme",
    title: "HECELEME",
    emoji: "🧩",
    icon: Icons.extension_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Tanıma",
    title: "TANIMA",
    emoji: "🖼️",
    icon: Icons.image_search_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Hız",
    title: "HIZLI GÖR",
    emoji: "⚡",
    icon: Icons.bolt_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Bellek",
    title: "BELLEK",
    emoji: "🧠",
    icon: Icons.psychology_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Yazma",
    title: "YAZMA",
    emoji: "✍️",
    icon: Icons.edit_note_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Hikaye",
    title: "HİKAYE",
    emoji: "📖",
    icon: Icons.auto_stories_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Sesler",
    title: "SESLER",
    emoji: "👂",
    icon: Icons.hearing_rounded,
  ),
  _TeacherGameInfo(
    gameType: "Okuma",
    title: "OKUMA",
    emoji: "📚",
    icon: Icons.menu_book_rounded,
  ),
];

const List<String> _allGameCategories = [
  "Heceleme: Meyveler",
  "Heceleme: Hayvanlar",
  "Heceleme: Taşıtlar",
  "Tanıma: Renkler",
  "Tanıma: Şekiller",
  "Tanıma: Sayılar",
  "Hız: Rakamlar",
  "Hız: Harfler",
  "Hız: Semboller",
  "Bellek: Doğa",
  "Bellek: Yiyecekler",
  "Bellek: Eşyalar",
  "Yazma: 3 Harfliler",
  "Yazma: 4 Harfliler",
  "Yazma: 5 Harfliler",
  "Hikaye: Kısa Cümleler",
  "Hikaye: Orta Cümleler",
  "Hikaye: Uzun Cümleler",
  "Sesler: Başlangıç Sesi",
  "Sesler: Bitiş Sesi",
  "Sesler: İçindeki Ses",
  "Okuma: Kolay",
  "Okuma: Orta",
  "Okuma: Zor",
];
String _childDisplayName(Map<String, dynamic> data) {
  final nickname = data['nickname']?.toString().trim() ?? "";
  if (nickname.isNotEmpty) return nickname;

  final displayName = data['displayName']?.toString().trim() ?? "";
  if (displayName.isNotEmpty) return displayName;

  final name = data['name']?.toString().trim() ?? "";
  final surname = data['surname']?.toString().trim() ?? "";
  final fullName = "$name $surname".trim();

  if (fullName.isNotEmpty) return fullName;

  final playerId = data['playerId']?.toString().trim() ?? "";
  if (playerId.isNotEmpty) return playerId;

  return "Öğrenci";
}
String _playerIdKey(String value) {
  return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String _normalizePlayerId(String value) {
  final key = _playerIdKey(value);

  if (key.startsWith("DLAS") && key.length > 4) {
    return "DLAS-${key.substring(4)}";
  }

  return value
      .trim()
      .toUpperCase()
      .replaceAll(" ", "")
      .replaceAll("–", "-")
      .replaceAll("—", "-")
      .replaceAll("_", "-");
}

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _classNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String teacherName = "Öğretmen";
  int _currentIndex = 0;
  List<String> _teacherClasses = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    _getTeacherInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _classNameController.dispose();
    _studentEmailController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _getTeacherInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!mounted) return;

    final data = doc.data() ?? {};

    final rawClassNames = data['classNames'];
    final classes = rawClassNames is List
        ? rawClassNames.map((e) => e.toString()).toList()
        : <String>[];

    classes.sort();

    setState(() {
      teacherName = "${data['name'] ?? ''} ${data['surname'] ?? ''}".trim();

      if (teacherName.isEmpty) {
        teacherName = "Öğretmen";
      }

      _teacherClasses = classes;
    });
  }

  String _normalizeClassName(String value) {
    final raw = value.trim().replaceAll(" ", "").toUpperCase();

    final match = RegExp(r'^([1-9])[-]?([A-ZÇĞİÖŞÜ])$').firstMatch(raw);
    if (match != null) {
      return "${match.group(1)}-${match.group(2)}";
    }

    return raw;
  }

  void _showSnack(String message, {Color color = TeacherPalette.primary}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F7FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: TeacherPalette.primary.withOpacity(0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: TeacherPalette.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    SessionFlowService.goToAdultLogin();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _addClass(String className) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final normalized = _normalizeClassName(className);

    if (normalized.isEmpty) {
      _showSnack("Sınıf adı boş olamaz.", color: Colors.redAccent);
      return;
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'classNames': FieldValue.arrayUnion([normalized]),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    setState(() {
      if (!_teacherClasses.contains(normalized)) {
        _teacherClasses.add(normalized);
        _teacherClasses.sort();
      }
    });

    _showSnack("$normalized sınıfı eklendi.", color: TeacherPalette.green);
  }

  void _showAddClassDialog() {
    _classNameController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DialogHeader(
                  emoji: "🏫",
                  title: "Sınıf Ekle",
                  subtitle: "Örneğin 1A yazarsan otomatik 1-A olarak kaydedilir.",
                  gradient: TeacherPalette.classGradient,
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _classNameController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: "Sınıf adı",
                    icon: Icons.class_rounded,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "İPTAL",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _addClass(_classNameController.text);

                          if (!mounted) return;

                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherPalette.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "EKLE",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<_TeacherFoundChildProfile?> _findChildForTeacherByPlayerId(
      String rawPlayerId,
      ) async {
    final wantedKey = _teacherPlayerKeyFromText(rawPlayerId);

    if (wantedKey.isEmpty) return null;

    // 1) Önce childProfiles içinde ara
    try {
      final snap = await FirebaseFirestore.instance
          .collection('childProfiles')
          .limit(2500)
          .get();

      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        if (_teacherPlayerKeyFromData(data) == wantedKey) {
          matches.add(doc);
        }
      }

      if (matches.isNotEmpty) {
        matches.sort((a, b) {
          return _teacherStudentScore(b.data())
              .compareTo(_teacherStudentScore(a.data()));
        });

        final best = matches.first;

        return _TeacherFoundChildProfile(
          childId: best.id,
          ref: best.reference,
          data: best.data(),
        );
      }
    } catch (_) {}

    // 2) childProfiles içinde yoksa users içinde ara
    final userDoc = await _findUserForTeacherByPlayerId(rawPlayerId);

    if (userDoc == null) return null;

    // 3) users içinde bulunduysa güvenli şekilde childProfiles'a taşı
    return _migrateUserToChildProfileForTeacher(
      userDoc: userDoc,
      rawPlayerId: rawPlayerId,
    );
  }
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserForTeacherByPlayerId(
      String rawPlayerId,
      ) async {
    final wantedKey = _teacherPlayerKeyFromText(rawPlayerId);

    if (wantedKey.isEmpty) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .limit(2500)
          .get();

      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        final role = data['role']?.toString() ?? "";
        final accountType = data['accountType']?.toString() ?? "";

        final looksStudent = role == 'student' ||
            accountType == 'student' ||
            (data['playerId']?.toString().trim().isNotEmpty ?? false);

        if (!looksStudent) continue;

        if (_teacherPlayerKeyFromData(data) == wantedKey) {
          matches.add(doc);
        }
      }

      if (matches.isEmpty) return null;

      matches.sort((a, b) {
        return _teacherStudentScore(b.data())
            .compareTo(_teacherStudentScore(a.data()));
      });

      return matches.first;
    } catch (_) {
      return null;
    }
  }

  Future<_TeacherFoundChildProfile> _migrateUserToChildProfileForTeacher({
    required DocumentSnapshot<Map<String, dynamic>> userDoc,
    required String rawPlayerId,
  }) async {
    final wantedKey = _teacherPlayerKeyFromText(rawPlayerId);
    final userData = userDoc.data() ?? {};
    final ownerUid = userDoc.id;

    // Güvenlik: users içindeki playerId gerçekten yazdığın ID mi?
    if (_teacherPlayerKeyFromData(userData) != wantedKey) {
      throw Exception("Oyuncu ID eşleşmeyen kullanıcı taşınamaz.");
    }

    final normalizedPlayerId = _teacherNormalizePlayerId(rawPlayerId);

    // activeChildId varsa sadece gerçekten aynı Oyuncu ID ise onu kullan
    final activeChildId = userData['activeChildId']?.toString().trim() ?? "";

    if (activeChildId.isNotEmpty) {
      final activeDoc = await FirebaseFirestore.instance
          .collection('childProfiles')
          .doc(activeChildId)
          .get();

      final activeData = activeDoc.data();

      if (activeDoc.exists &&
          activeData != null &&
          _teacherPlayerKeyFromData(activeData) == wantedKey) {
        final fixedData = _buildTeacherChildProfileData(
          childId: activeDoc.id,
          ownerUid: ownerUid,
          source: {
            ...userData,
            ...activeData,
          },
          normalizedPlayerId: normalizedPlayerId,
          playerIdKey: wantedKey,
        );

        await activeDoc.reference.set(
          fixedData,
          SetOptions(merge: true),
        );

        final fresh = await activeDoc.reference.get();

        return _TeacherFoundChildProfile(
          childId: activeDoc.id,
          ref: activeDoc.reference,
          data: fresh.data() ?? fixedData,
        );
      }
    }

    // activeChildId yoksa veya başka çocuğa aitse yeni doğru childProfiles oluştur
    final childRef =
    FirebaseFirestore.instance.collection('childProfiles').doc();

    final childData = _buildTeacherChildProfileData(
      childId: childRef.id,
      ownerUid: ownerUid,
      source: userData,
      normalizedPlayerId: normalizedPlayerId,
      playerIdKey: wantedKey,
    );

    await childRef.set(
      childData,
      SetOptions(merge: true),
    );

    await FirebaseFirestore.instance.collection('users').doc(ownerUid).set(
      {
        'activeChildId': childRef.id,
        'hasChildProfiles': true,
        'playerId': normalizedPlayerId,
        'playerIdNormalized': normalizedPlayerId,
        'playerIdKey': wantedKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final fresh = await childRef.get();

    return _TeacherFoundChildProfile(
      childId: childRef.id,
      ref: childRef,
      data: fresh.data() ?? childData,
    );
  }

  Map<String, dynamic> _buildTeacherChildProfileData({
    required String childId,
    required String ownerUid,
    required Map<String, dynamic> source,
    required String normalizedPlayerId,
    required String playerIdKey,
  }) {
    return {
      'childId': childId,
      'ownerUid': ownerUid,

      'role': 'student',
      'profileType': 'child',
      'isAnonymousChild': source['isAnonymousChild'] ?? true,
      'profileSetupDone': source['profileSetupDone'] == true,

      'name': source['name'] ?? source['nickname'] ?? 'Arkadaşım',
      'displayName': source['displayName'] ?? source['nickname'] ?? 'Arkadaşım',
      'nickname': source['nickname'] ?? '',
      'surname': source['surname'] ?? '',
      'ageGroup': source['ageGroup'] ?? '',
      'className': source['className'] ?? '',

      'playerId': normalizedPlayerId,
      'playerIdNormalized': normalizedPlayerId,
      'playerIdKey': playerIdKey,
      'recoveryPin': source['recoveryPin'] ?? '',
      'recoveryCode': source['recoveryCode'] ?? '',

      'teachers': source['teachers'] ?? [],
      'teacherIds': source['teacherIds'] ?? [],
      'parentIds': source['parentIds'] ?? [],
      'linkedParentIds': source['linkedParentIds'] ?? [],

      'activeThemeId': source['activeThemeId'] ?? 'space',
      'activeStickerId': source['activeStickerId'] ?? 'space_starter_roket',
      'activeStickerIdsByTheme': source['activeStickerIdsByTheme'] ?? {},
      'ownedStickerIds': source['ownedStickerIds'] ?? [],

      'stats': source['stats'] ?? {},
      'stars': source['stars'] ?? 0,
      'earnedBadges': source['earnedBadges'] ?? [],

      'lastActivity': source['lastActivity'],
      'dailyTask': source['dailyTask'] ?? {},
      'dailyTasks': source['dailyTasks'] ?? {},
      'miniGames': source['miniGames'] ?? {},

      'migratedFromUserUid': ownerUid,
      'migrationVersion': 8,
      'createdAt': source['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<_TeacherFoundChildProfile?> _findChildProfileForTeacherDirectly({
    required String normalizedPlayerId,
    required String playerIdKey,
  }) async {
    final queries = [
      _firestore
          .collection('childProfiles')
          .where('playerId', isEqualTo: normalizedPlayerId)
          .limit(1)
          .get(),
      _firestore
          .collection('childProfiles')
          .where('playerIdNormalized', isEqualTo: normalizedPlayerId)
          .limit(1)
          .get(),
      _firestore
          .collection('childProfiles')
          .where('playerIdKey', isEqualTo: playerIdKey)
          .limit(1)
          .get(),
    ];

    for (final query in queries) {
      try {
        final snap = await query;

        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;

          return _TeacherFoundChildProfile(
            childId: doc.id,
            ref: doc.reference,
            data: doc.data(),
          );
        }
      } catch (_) {}
    }

    try {
      final fallback =
      await _firestore.collection('childProfiles').limit(1500).get();

      for (final doc in fallback.docs) {
        final data = doc.data();

        final storedPlayerId = data['playerId']?.toString() ?? "";
        final storedNormalized = data['playerIdNormalized']?.toString() ?? "";
        final storedKey = data['playerIdKey']?.toString() ?? "";

        if (_playerIdKey(storedPlayerId) == playerIdKey ||
            _playerIdKey(storedNormalized) == playerIdKey ||
            _playerIdKey(storedKey) == playerIdKey) {
          return _TeacherFoundChildProfile(
            childId: doc.id,
            ref: doc.reference,
            data: data,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?>
  _findUserProfileForTeacherByPlayerId({
    required String normalizedPlayerId,
    required String playerIdKey,
  }) async {
    final queries = [
      _firestore
          .collection('users')
          .where('playerId', isEqualTo: normalizedPlayerId)
          .limit(1)
          .get(),
      _firestore
          .collection('users')
          .where('playerIdNormalized', isEqualTo: normalizedPlayerId)
          .limit(1)
          .get(),
      _firestore
          .collection('users')
          .where('playerIdKey', isEqualTo: playerIdKey)
          .limit(1)
          .get(),
    ];

    for (final query in queries) {
      try {
        final snap = await query;

        if (snap.docs.isNotEmpty) {
          return snap.docs.first;
        }
      } catch (_) {}
    }

    try {
      final fallback = await _firestore.collection('users').limit(1500).get();

      for (final doc in fallback.docs) {
        final data = doc.data();

        final role = data['role']?.toString() ?? "";
        final accountType = data['accountType']?.toString() ?? "";

        final storedPlayerId = data['playerId']?.toString() ?? "";
        final storedNormalized = data['playerIdNormalized']?.toString() ?? "";
        final storedKey = data['playerIdKey']?.toString() ?? "";

        final looksLikeStudent = role == 'student' ||
            accountType == 'student' ||
            storedPlayerId.trim().isNotEmpty;

        if (!looksLikeStudent) continue;

        if (_playerIdKey(storedPlayerId) == playerIdKey ||
            _playerIdKey(storedNormalized) == playerIdKey ||
            _playerIdKey(storedKey) == playerIdKey) {
          return doc;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<_TeacherFoundChildProfile>
  _createOrLoadChildProfileForTeacherFromUserDoc({
    required DocumentSnapshot<Map<String, dynamic>> userDoc,
    required String requestedPlayerId,
    required String requestedPlayerIdKey,
  }) async {
    final userData = userDoc.data() ?? {};
    final ownerUid = userDoc.id;

    final activeChildId = userData['activeChildId']?.toString().trim() ?? "";

    if (activeChildId.isNotEmpty) {
      final childDoc =
      await _firestore.collection('childProfiles').doc(activeChildId).get();

      if (childDoc.exists && childDoc.data() != null) {
        final existingData = childDoc.data() ?? {};

        final existingPlayerKey = _playerIdKey(
          existingData['playerId']?.toString() ?? "",
        );

        final existingNormalizedKey = _playerIdKey(
          existingData['playerIdNormalized']?.toString() ?? "",
        );

        final existingSavedKey = _playerIdKey(
          existingData['playerIdKey']?.toString() ?? "",
        );

        final matchesRequested = existingPlayerKey == requestedPlayerIdKey ||
            existingNormalizedKey == requestedPlayerIdKey ||
            existingSavedKey == requestedPlayerIdKey;

        if (matchesRequested) {
          final mergedData = {
            ...userData,
            ...existingData,
            'childId': childDoc.id,
            'ownerUid': existingData['ownerUid'] ?? ownerUid,
            'playerId': existingData['playerId'] ?? requestedPlayerId,
            'playerIdNormalized':
            existingData['playerIdNormalized'] ?? requestedPlayerId,
            'playerIdKey': existingData['playerIdKey'] ?? requestedPlayerIdKey,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await childDoc.reference.set(
            mergedData,
            SetOptions(merge: true),
          );

          final freshDoc = await childDoc.reference.get();

          return _TeacherFoundChildProfile(
            childId: childDoc.id,
            ref: childDoc.reference,
            data: freshDoc.data() ?? mergedData,
          );
        }
      }
    }

    final childRef = _firestore.collection('childProfiles').doc();

    final playerId = requestedPlayerId.isNotEmpty
        ? requestedPlayerId
        : _normalizePlayerId(userData['playerId']?.toString() ?? "");

    final childData = <String, dynamic>{
      'childId': childRef.id,
      'ownerUid': ownerUid,

      'role': 'student',
      'profileType': 'child',
      'isAnonymousChild': userData['isAnonymousChild'] ?? true,
      'profileSetupDone': userData['profileSetupDone'] == true,

      'name': userData['name'] ?? userData['nickname'] ?? 'Arkadaşım',
      'displayName':
      userData['displayName'] ?? userData['nickname'] ?? 'Arkadaşım',
      'nickname': userData['nickname'] ?? '',
      'surname': userData['surname'] ?? '',
      'ageGroup': userData['ageGroup'] ?? '',
      'className': userData['className'] ?? '',

      'playerId': playerId,
      'playerIdNormalized': playerId,
      'playerIdKey': _playerIdKey(playerId),
      'recoveryPin': userData['recoveryPin'] ?? '',
      'recoveryCode': userData['recoveryCode'] ?? '',

      'teachers': userData['teachers'] ?? [],
      'teacherIds': userData['teacherIds'] ?? [],
      'parentIds': userData['parentIds'] ?? [],
      'linkedParentIds': userData['linkedParentIds'] ?? [],

      'activeThemeId': userData['activeThemeId'] ?? 'space',
      'activeStickerId':
      userData['activeStickerId'] ?? 'space_starter_roket',
      'activeStickerIdsByTheme': userData['activeStickerIdsByTheme'] ?? {},
      'ownedStickerIds': userData['ownedStickerIds'] ?? [],

      'stats': userData['stats'] ?? {},
      'stars': userData['stars'] ?? 0,
      'earnedBadges': userData['earnedBadges'] ?? [],

      'lastActivity': userData['lastActivity'],
      'dailyTask': userData['dailyTask'] ?? {},
      'dailyTasks': userData['dailyTasks'] ?? {},
      'miniGames': userData['miniGames'] ?? {},

      'migratedFromUserUid': ownerUid,
      'migrationVersion': 5,
      'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await childRef.set(
      childData,
      SetOptions(merge: true),
    );

    await _firestore.collection('users').doc(ownerUid).set(
      {
        'activeChildId': childRef.id,
        'hasChildProfiles': true,
        'playerIdNormalized': playerId,
        'playerIdKey': _playerIdKey(playerId),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final freshDoc = await childRef.get();

    return _TeacherFoundChildProfile(
      childId: childRef.id,
      ref: childRef,
      data: freshDoc.data() ?? childData,
    );
  }
  String _teacherPlayerKeyFromText(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _teacherPlayerKeyFromData(Map<String, dynamic> data) {
    final playerId = data['playerId']?.toString().trim() ?? "";
    if (playerId.isNotEmpty) {
      return _teacherPlayerKeyFromText(playerId);
    }

    final normalized = data['playerIdNormalized']?.toString().trim() ?? "";
    if (normalized.isNotEmpty) {
      return _teacherPlayerKeyFromText(normalized);
    }

    final savedKey = data['playerIdKey']?.toString().trim() ?? "";
    if (savedKey.isNotEmpty) {
      return _teacherPlayerKeyFromText(savedKey);
    }

    return "";
  }

  String _teacherNormalizePlayerId(String value) {
    final key = _teacherPlayerKeyFromText(value);

    if (key.startsWith("DLAS") && key.length > 4) {
      return "DLAS-${key.substring(4)}";
    }

    return value
        .trim()
        .toUpperCase()
        .replaceAll(" ", "")
        .replaceAll("–", "-")
        .replaceAll("—", "-")
        .replaceAll("_", "-");
  }

  String _teacherStudentName(Map<String, dynamic> data) {
    final nickname = data['nickname']?.toString().trim() ?? "";
    if (nickname.isNotEmpty) return nickname;

    final displayName = data['displayName']?.toString().trim() ?? "";
    if (displayName.isNotEmpty) return displayName;

    final name = data['name']?.toString().trim() ?? "";
    final surname = data['surname']?.toString().trim() ?? "";
    final fullName = "$name $surname".trim();
    if (fullName.isNotEmpty) return fullName;

    final playerId = data['playerId']?.toString().trim() ?? "";
    if (playerId.isNotEmpty) return playerId;

    return "Öğrenci";
  }

  int _teacherStudentScore(Map<String, dynamic> data) {
    int score = 0;

    if (data['profileType'] == 'child') score += 30;
    if (data['profileSetupDone'] == true) score += 20;

    final nickname = data['nickname']?.toString().trim() ?? "";
    final name = data['name']?.toString().trim() ?? "";
    final playerId = data['playerId']?.toString().trim() ?? "";
    final recoveryCode = data['recoveryCode']?.toString().trim() ?? "";

    if (nickname.isNotEmpty) score += 10;
    if (name.isNotEmpty) score += 8;
    if (playerId.isNotEmpty) score += 8;
    if (recoveryCode.isNotEmpty) score += 6;

    final stars = data['stars'];
    if (stars is num) {
      final starValue = stars.toInt();
      score += starValue > 100 ? 100 : starValue;
    }

    return score;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _dedupeTeacherStudentDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final byPlayerId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final doc in docs) {
      final data = doc.data();

      final key = _teacherPlayerKeyFromData(data).isNotEmpty
          ? _teacherPlayerKeyFromData(data)
          : doc.id;

      final existing = byPlayerId[key];

      if (existing == null) {
        byPlayerId[key] = doc;
        continue;
      }

      final existingScore = _teacherStudentScore(existing.data());
      final newScore = _teacherStudentScore(data);

      if (newScore > existingScore) {
        byPlayerId[key] = doc;
      }
    }

    final result = byPlayerId.values.toList();

    result.sort((a, b) {
      final an = _teacherStudentName(a.data()).toLowerCase();
      final bn = _teacherStudentName(b.data()).toLowerCase();
      return an.compareTo(bn);
    });

    return result;
  }
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadTeacherStudentsForMessage({
    required String className,
    required String teacherUid,
  }) async {
    try {
      final snap = await _firestore
          .collection('childProfiles')
          .where('className', isEqualTo: className)
          .limit(1000)
          .get();

      final filtered = snap.docs.where((doc) {
        final data = doc.data();

        final profileType = data['profileType']?.toString() ?? "";
        final role = data['role']?.toString() ?? "";
        final playerId = data['playerId']?.toString().trim() ?? "";

        final looksChild = profileType == 'child' ||
            role == 'student' ||
            playerId.isNotEmpty;

        if (!looksChild) return false;

        final teachersRaw = data['teachers'];
        final teacherIdsRaw = data['teacherIds'];

        final teachers = teachersRaw is List
            ? teachersRaw.map((e) => e.toString()).toList()
            : <String>[];

        final teacherIds = teacherIdsRaw is List
            ? teacherIdsRaw.map((e) => e.toString()).toList()
            : <String>[];

        final hasTeacherField = teachers.isNotEmpty || teacherIds.isNotEmpty;

        final teacherMatches =
            teachers.contains(teacherUid) || teacherIds.contains(teacherUid);

        // Eski kayıtlarda teachers/teacherIds boş kalmış olabilir.
        // Sınıf eşleşiyorsa ve öğretmen alanı yoksa öğrenciyi düşürmeyelim.
        return teacherMatches || !hasTeacherField;
      }).toList();

      return _dedupeTeacherStudentDocs(filtered);
    } catch (_) {
      return [];
    }
  }
  Future<_TeacherFoundChildProfile?> _findAlreadyStudentInClass({
    required String className,
    required String rawPlayerId,
  }) async {
    final wantedKey = _teacherPlayerKeyFromText(rawPlayerId);

    if (wantedKey.isEmpty) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('childProfiles')
          .where('className', isEqualTo: className)
          .limit(1000)
          .get();

      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        if (_teacherPlayerKeyFromData(data) == wantedKey) {
          matches.add(doc);
        }
      }

      if (matches.isEmpty) return null;

      matches.sort((a, b) {
        return _teacherStudentScore(b.data())
            .compareTo(_teacherStudentScore(a.data()));
      });

      final best = matches.first;

      return _TeacherFoundChildProfile(
        childId: best.id,
        ref: best.reference,
        data: best.data(),
      );
    } catch (_) {
      return null;
    }
  }
  Future<bool> _addStudentToClass({
    required String className,
    required String email,
  }) async {
    final teacherUid = FirebaseAuth.instance.currentUser?.uid;

    if (teacherUid == null) {
      _showSnack(
        "Öğretmen oturumu bulunamadı.",
        color: Colors.redAccent,
      );
      return false;
    }

    final rawPlayerId = email.trim();

    if (rawPlayerId.isEmpty) {
      _showSnack(
        "Öğrenci Oyuncu ID boş olamaz.",
        color: Colors.redAccent,
      );
      return false;
    }

    final normalizedPlayerId = _teacherNormalizePlayerId(rawPlayerId);
    final playerIdKey = _teacherPlayerKeyFromText(rawPlayerId);

    final alreadyInClass = await _findAlreadyStudentInClass(
      className: className,
      rawPlayerId: rawPlayerId,
    );

    if (alreadyInClass != null) {
      await alreadyInClass.ref.set(
        {
          'teachers': FieldValue.arrayUnion([teacherUid]),
          'teacherIds': FieldValue.arrayUnion([teacherUid]),
          'className': className,
          'playerIdNormalized': normalizedPlayerId,
          'playerIdKey': playerIdKey,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance.collection('users').doc(teacherUid).set(
        {
          'classNames': FieldValue.arrayUnion([className]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showSnack(
        "${_teacherStudentName(alreadyInClass.data)} zaten $className sınıfında.",
        color: Colors.orange,
      );

      return true;
    }

    final foundChild = await _findChildForTeacherByPlayerId(rawPlayerId);

    if (foundChild == null) {
      _showSnack(
        "Bu Oyuncu ID ile öğrenci bulunamadı.",
        color: Colors.redAccent,
      );
      return false;
    }

    final childData = foundChild.data;
    final foundKey = _teacherPlayerKeyFromData(childData);

    if (foundKey != playerIdKey) {
      _showSnack(
        "Oyuncu ID başka bir profile karıştı. Ekleme iptal edildi.",
        color: Colors.redAccent,
      );
      return false;
    }

    await foundChild.ref.set(
      {
        'teachers': FieldValue.arrayUnion([teacherUid]),
        'teacherIds': FieldValue.arrayUnion([teacherUid]),
        'className': className,
        'playerIdNormalized': normalizedPlayerId,
        'playerIdKey': playerIdKey,
        'linkedTeacherAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final ownerUid = childData['ownerUid']?.toString().trim() ?? "";

    if (ownerUid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(ownerUid).set(
        {
          'teachers': FieldValue.arrayUnion([teacherUid]),
          'teacherIds': FieldValue.arrayUnion([teacherUid]),
          'className': className,
          'activeChildId': foundChild.childId,
          'hasChildProfiles': true,
          'playerIdNormalized': normalizedPlayerId,
          'playerIdKey': playerIdKey,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await FirebaseFirestore.instance.collection('users').doc(teacherUid).set(
      {
        'classNames': FieldValue.arrayUnion([className]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    _showSnack(
      "${_teacherStudentName(childData)} $className sınıfına eklendi.",
      color: TeacherPalette.green,
    );

    return true;
  }

  void _showAddStudentDialog({required String className}) {
    _studentEmailController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  emoji: "🎒",
                  title: "$className Öğrenci Ekle",
                  subtitle: "Öğrencinin ayarlarda görünen Oyuncu ID bilgisini yaz.",
                  gradient: TeacherPalette.classGradient,
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _studentEmailController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: "Öğrenci Oyuncu ID",
                    icon: Icons.confirmation_number_rounded,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "İPTAL",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final added = await _addStudentToClass(
                            className: className,
                            email: _studentEmailController.text,
                          );

                          if (!mounted || !added) return;

                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherPalette.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "EKLE",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Set<String>> _findMessageInboxUserIdsForChild({
    required String childId,
    required Map<String, dynamic> childData,
  }) async {
    final ids = <String>{};

    Future<void> tryAddExistingUser(dynamic rawValue) async {
      final userId = rawValue?.toString().trim() ?? "";
      if (userId.isEmpty) return;

      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          ids.add(userId);
        }
      } catch (_) {}
    }

    await tryAddExistingUser(childData['ownerUid']);
    await tryAddExistingUser(childData['migratedFromUserUid']);
    await tryAddExistingUser(childData['studentUid']);
    await tryAddExistingUser(childData['uid']);
    await tryAddExistingUser(childId);

    try {
      final activeUsers = await _firestore
          .collection('users')
          .where('activeChildId', isEqualTo: childId)
          .limit(20)
          .get();

      for (final doc in activeUsers.docs) {
        ids.add(doc.id);
      }
    } catch (_) {}

    final playerIdKey = _teacherPlayerKeyFromData(childData);

    if (playerIdKey.isNotEmpty) {
      try {
        final playerUsers = await _firestore
            .collection('users')
            .where('playerIdKey', isEqualTo: playerIdKey)
            .limit(20)
            .get();

        for (final doc in playerUsers.docs) {
          ids.add(doc.id);
        }
      } catch (_) {}
    }

    debugPrint(
      "DILAS_MESSAGE_DEBUG: $childId için inbox user sayısı: ${ids.length} -> ${ids.join(", ")}",
    );

    return ids;
  }

  Future<void> _safeWriteTeacherAnnouncement({
    required String teacherUid,
    required String dialogClass,
    required String selectedStudentId,
    required String title,
    required String content,
    required String type,
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'teacherId': teacherUid,
        'teacherName': teacherName,
        'className': dialogClass,
        'target': selectedStudentId,
        'targetChildId': selectedStudentId == "ALL" ? null : selectedStudentId,
        'targetType': selectedStudentId == "ALL" ? "class" : "child",
        'title': title,
        'content': content,
        'date': FieldValue.serverTimestamp(),
        'type': type,
      });
    } catch (e) {
      debugPrint(
        "DILAS_MESSAGE_DEBUG: announcements yazılamadı ama mesaj gönderimi devam etti: $e",
      );
    }
  }

  Future<void> _sendMessageToChildProfile({
    required String childId,
    required String className,
    required String title,
    required String content,
    required String type,
    required String teacherUid,
  }) async {
    final childRef = _firestore.collection('childProfiles').doc(childId);
    final childDoc = await childRef.get();
    final childData = childDoc.data() ?? {};

    final bool rewardEnabled = type == 'tebrik';
    final String todayKey = DateFormat('yyyyMMdd').format(DateTime.now());

    // ✅ DÜZELTME 1:
    // rewardId'yi yine oluşturuyoruz ama bunu mesaj ID'si olarak kullanacağız.
    final String? rewardKey = rewardEnabled
        ? 'teacher_tebrik_${teacherUid}_${childId}_$todayKey'
        : null;

    // ✅ DÜZELTME 2:
    // Artık rastgele ID oluşturmak yerine, yıldız varsa o benzersiz rewardKey'i,
    // yoksa yine rastgele bir ID'yi belge ID'si olarak kullanıyoruz.
    final messageId = rewardKey ?? childRef.collection('messages').doc().id;
    final messageDoc = childRef.collection('messages').doc(messageId);

    // Veritabanına yazılacak veri
    final messageData = {
      'messageId': messageId, // ✅ DÜZELTME 3: Mesajın ID'si artık rewardKey veya rastgele ID.
      'messageVersion': 2,
      'title': title,
      'content': content,
      'teacherName': teacherName,
      'teacherId': teacherUid,
      'className': className,
      'targetChildId': childId,
      'childId': childId,
      'date': FieldValue.serverTimestamp(),
      'type': type,
      'seenBy': [], // Okunma bilgisi boş başlar
      'rewardOnOpen': rewardEnabled,
      // rewardKey varsa, onu da rewardId alanına yazıyoruz.
      if (rewardKey != null) 'rewardId': rewardKey,
    };

    // ✅ DÜZELTME 4:
    // Firebase'e set metodu ile o mesaj ID'sine sahip belgeye veriyi yazıyoruz.
    // SetOptions(merge: true) ile o ID'li mesaj varsa üzerine yazar (tekrarlı gönderimi engeller).
    await messageDoc.set(
      messageData,
      SetOptions(merge: true),
    );

    // Öğrenci inbox kopyasını da users/{uid}/messages altına yazıyoruz (Reliability için).
    final inboxUserIds = await _findMessageInboxUserIdsForChild(
      childId: childId,
      childData: childData,
    );

    for (final userId in inboxUserIds) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('messages')
          .doc(messageId) // ✅ DÜZELTME 5: Inbox kopyası da aynı benzersiz ID'yi kullanmalı.
          .set(
        {
          ...messageData,
          'mirroredFromChildProfile': true,
        },
        SetOptions(merge: true),
      );
    }

    // Bildirim gönderimi
    await PushRequestService.sendMessageNotificationToChild(
      childId: childId,
      messageTitle: title,
      messageBody: content,
      rewardOnOpen: rewardEnabled,
      // Ödül varsa, rewardKey'i oraya da gönderiyoruz (Bildirimden açınca ödül vermek için).
      rewardId: rewardKey,
    );
  }

  void _showAddMessageDialog() {
    _titleController.clear();
    _contentController.clear();

    String? dialogClass;
    String? selectedStudentId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _DialogHeader(
                        emoji: "💬",
                        title: "Mesaj Gönder",
                        subtitle: "Sınıfa veya tek bir öğrenciye mesaj ilet.",
                        gradient: TeacherPalette.messageGradient,
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        value: dialogClass,
                        isExpanded: true,
                        hint: const Text("Sınıf seç"),
                        items: _teacherClasses
                            .map(
                              (className) => DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            dialogClass = value;
                            selectedStudentId = null;
                          });
                        },
                        decoration: _inputDecoration(
                          label: "Sınıf",
                          icon: Icons.class_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (dialogClass != null)
                        FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                          future: _loadTeacherStudentsForMessage(
                            className: dialogClass!,
                            teacherUid: _auth.currentUser!.uid,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }

                            final students = snapshot.data ?? [];

                            final items = <DropdownMenuItem<String>>[
                              const DropdownMenuItem(
                                value: "ALL",
                                child: Text(
                                  "📢 Tüm sınıf",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              ...students.map(
                                    (student) {
                                  final data = student.data();
                                  final name = _childDisplayName(data);
                                  final playerId = data['playerId']?.toString() ?? "";

                                  return DropdownMenuItem(
                                    value: student.id,
                                    child: Text(
                                      playerId.isEmpty ? name : "$name • $playerId",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ];

                            return DropdownButtonFormField<String>(
                              value: selectedStudentId,
                              isExpanded: true,
                              hint: const Text("Kime?"),
                              items: items,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedStudentId = value;
                                });
                              },
                              decoration: _inputDecoration(
                                label: "Alıcı",
                                icon: Icons.person_rounded,
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _TemplateButton(
                              emoji: "🌟",
                              label: "Tebrik",
                              color: TeacherPalette.green,
                              onTap: () {
                                _titleController.text = "Tebrikler! 🌟";
                                _contentController.text =
                                "Harika gidiyorsun! Çalışmalarını takdir ediyorum.";
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TemplateButton(
                              emoji: "⏰",
                              label: "Hatırlat",
                              color: TeacherPalette.orange,
                              onTap: () {
                                _titleController.text = "Ödev Hatırlatması ⏰";
                                _contentController.text =
                                "Lütfen ödevlerini zamanında tamamlamaya dikkat et.";
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _titleController,
                        decoration: _inputDecoration(
                          label: "Konu",
                          icon: Icons.subject_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: "Mesaj",
                          icon: Icons.message_rounded,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "İPTAL",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final teacherUid = _auth.currentUser?.uid;
                                if (teacherUid == null) return;

                                if (_titleController.text.trim().isEmpty ||
                                    _contentController.text.trim().isEmpty ||
                                    dialogClass == null ||
                                    selectedStudentId == null) {
                                  _showSnack(
                                    "Lütfen tüm alanları doldur.",
                                    color: Colors.redAccent,
                                  );
                                  return;
                                }

                                final title = _titleController.text.trim();
                                final content = _contentController.text.trim();
                                final type = title.toLowerCase().contains("tebrik")
                                    ? "tebrik"
                                    : "duyuru";

                                if (selectedStudentId == "ALL") {
                                  final uniqueStudents = await _loadTeacherStudentsForMessage(
                                    className: dialogClass!,
                                    teacherUid: teacherUid,
                                  );

                                  if (uniqueStudents.isEmpty) {
                                    _showSnack(
                                      "Bu sınıfta mesaj gönderilecek öğrenci bulunamadı.",
                                      color: Colors.redAccent,
                                    );
                                    return;
                                  }

                                  for (final student in uniqueStudents) {
                                    await _sendMessageToChildProfile(
                                      childId: student.id,
                                      className: dialogClass!,
                                      title: title,
                                      content: content,
                                      type: type,
                                      teacherUid: teacherUid,
                                    );
                                  }
                                } else {
                                  await _sendMessageToChildProfile(
                                    childId: selectedStudentId!,
                                    className: dialogClass!,
                                    title: title,
                                    content: content,
                                    type: type,
                                    teacherUid: teacherUid,
                                  );
                                }

                                await _safeWriteTeacherAnnouncement(
                                  teacherUid: teacherUid,
                                  dialogClass: dialogClass!,
                                  selectedStudentId: selectedStudentId!,
                                  title: title,
                                  content: content,
                                  type: type,
                                );

                                if (!mounted) return;

                                Navigator.pop(dialogContext);
                                _showSnack(
                                  "Mesaj iletildi!",
                                  color: TeacherPalette.orange,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TeacherPalette.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "GÖNDER",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStudentStats(
      String childId,
      Map<String, dynamic> studentData,
      ) {
    final report = DevelopmentReportRepository.fromChildData(
      childId: childId,
      data: studentData,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DefaultTabController(
          length: 4,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: TeacherPalette.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(height: 14),

                _DialogHeader(
                  emoji: "📊",
                  title: "${report.name} Gelişim Karnesi",
                  subtitle:
                  "⭐ ${report.stars} • ${report.className} • ${report.playerId}",
                  gradient: TeacherPalette.mainGradient,
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: TeacherPalette.primary.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TeacherPalette.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: TeacherPalette.primary,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: TeacherPalette.mainGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.dashboard_rounded, size: 18),
                        text: "Genel",
                      ),
                      Tab(
                        icon: Icon(Icons.timer_rounded, size: 18),
                        text: "Süre",
                      ),
                      Tab(
                        icon: Icon(Icons.bar_chart_rounded, size: 18),
                        text: "Etkinlik",
                      ),
                      Tab(
                        icon: Icon(Icons.videogame_asset_rounded, size: 18),
                        text: "Mini Oyun",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: TabBarView(
                    children: [
                      _teacherReportGeneralTab(report),
                      _teacherReportUsageTab(
                        childId: childId,
                        reportName: report.name,
                      ),
                      _teacherReportActivityTab(report),
                      _teacherReportMiniGameTab(report),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "KAPAT",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _teacherReportGeneralTab(dynamic report) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _SectionTitle(
          title: "Genel Özet",
          subtitle: "Öğrencinin uygulamadaki genel ilerlemesi.",
        ),

        const SizedBox(height: 10),

        _TeacherReportInfoTile(
          icon: Icons.star_rounded,
          title: "Toplam Yıldız",
          value: "${report.stars} yıldız toplandı",
          color: TeacherPalette.orange,
        ),

        _TeacherReportInfoTile(
          icon: Icons.extension_rounded,
          title: "Toplam Etkinlik",
          value: "${report.totalActivities} etkinlik tamamlandı",
          color: TeacherPalette.primary,
        ),

        _TeacherReportInfoTile(
          icon: Icons.today_rounded,
          title: "Günlük Görev",
          value: "${report.dailyCompleted} / ${report.dailyGoal} tamamlandı",
          color: TeacherPalette.green,
        ),

        _TeacherReportInfoTile(
          icon: Icons.sports_esports_rounded,
          title: "Mini Oyunlar",
          value: "${report.totalMiniGames} mini oyun tamamlandı",
          color: TeacherPalette.orange,
        ),

        const SizedBox(height: 12),

        const _SectionTitle(
          title: "Öğrenme Yorumu",
          subtitle: "En çok ve en az çalışılan alanlar.",
        ),

        const SizedBox(height: 10),

        _TeacherReportInfoTile(
          icon: Icons.emoji_events_rounded,
          title: "En Güçlü Alan",
          value: report.strongestArea.toString(),
          color: TeacherPalette.green,
        ),

        _TeacherReportInfoTile(
          icon: Icons.lightbulb_rounded,
          title: "Daha Çok Çalışılması Gereken Alan",
          value: report.needsPracticeArea.toString(),
          color: TeacherPalette.orange,
        ),
      ],
    );
  }

  Widget _teacherReportUsageTab({
    required String childId,
    required String reportName,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _SectionTitle(
          title: "Süre Raporu",
          subtitle: "Bugünkü kullanım ve son 3 gün karşılaştırması.",
        ),

        const SizedBox(height: 10),

        UsageTodayCard(
          childId: childId,
          title: "$reportName - Bugünkü Süre",
        ),

        const SizedBox(height: 12),

        UsageLastThreeDaysCard(
          childId: childId,
          title: "Son 3 Gün Kullanım",
        ),
      ],
    );
  }

  Widget _teacherReportActivityTab(dynamic report) {
    final rawStats = report.stats;

    final entries = rawStats is Map
        ? rawStats.entries.toList()
        : const [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _SectionTitle(
          title: "Etkinlik İstatistikleri",
          subtitle: "Öğrencinin hangi alanlarda ne kadar çalıştığını gösterir.",
        ),

        const SizedBox(height: 10),

        if (entries.isEmpty)
          const _SmallEmptyCard(
            emoji: "📊",
            title: "Henüz istatistik yok",
            subtitle: "Öğrenci etkinlik yaptıkça burada görünür.",
          )
        else
          ...entries.map((entry) {
            final value = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;

            return _TeacherReportStatTile(
              title: entry.key.toString(),
              value: value,
            );
          }),
      ],
    );
  }

  Widget _teacherReportMiniGameTab(dynamic report) {
    final rawMiniGames = report.miniGameCounts;

    final entries = rawMiniGames is Map
        ? rawMiniGames.entries.toList()
        : const [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _SectionTitle(
          title: "Mini Oyun Kayıtları",
          subtitle: "Kısa oyunlardaki tamamlanma durumları.",
        ),

        const SizedBox(height: 10),

        if (entries.isEmpty)
          const _SmallEmptyCard(
            emoji: "🎮",
            title: "Henüz mini oyun kaydı yok",
            subtitle: "Öğrenci mini oyun oynadıkça burada görünür.",
          )
        else
          ...entries.map((entry) {
            final value = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;

            return _TeacherReportInfoTile(
              icon: Icons.videogame_asset_rounded,
              title: _teacherMiniGameDisplayName(entry.key.toString()),
              value: "$value kez tamamlandı",
              color: TeacherPalette.primary,
            );
          }),
      ],
    );
  }

  String _teacherMiniGameDisplayName(String key) {
    switch (key) {
      case "balloonLetter":
      case "mini_balloonLetter":
      case "mini_balloonletter":
        return "Balon Harf Avı";

      case "memoryCards":
      case "mini_memoryCards":
      case "mini_memorycards":
        return "Hafıza Kartları";

      case "matching":
      case "mini_matching":
        return "Eşleştirme";

      case "fruitBasket":
      case "mini_fruitBasket":
      case "mini_fruitbasket":
        return "Meyveleri Sepete Taşı";

      default:
        return key
            .replaceAll("mini_", "")
            .replaceAll("_", " ");
    }
  }

  Future<void> _deleteLesson(String id) async {
    await _firestore.collection('lessons').doc(id).delete();
    _showSnack("Ödev silindi.", color: Colors.redAccent);
  }

  Future<void> _deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
    _showSnack("Mesaj kaydı silindi.", color: Colors.redAccent);
  }

  List<Color> get _currentFabGradient {
    if (_currentIndex == 2) {
      return TeacherPalette.messageGradient;
    }
    return TeacherPalette.classGradient;
  }

  String get _currentFabLabel {
    if (_currentIndex == 2) {
      return "MESAJ GÖNDER";
    }
    return "SINIF EKLE";
  }

  IconData get _currentFabIcon {
    if (_currentIndex == 2) {
      return Icons.send_rounded;
    }
    return Icons.add_home_work_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const LoginPage();
    }

    return Scaffold(
      backgroundColor: TeacherPalette.background,
      appBar: AppBar(
        title: Text(
          "Merhaba, $teacherName",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: TeacherPalette.mainGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          HelpGuideButton.teacher(),
          IconButton(
            tooltip: "Çıkış yap",
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              labelColor: TeacherPalette.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment_rounded, size: 20),
                  text: "ÖDEVLER",
                ),
                Tab(
                  icon: Icon(Icons.school_rounded, size: 20),
                  text: "SINIFIM",
                ),
                Tab(
                  icon: Icon(Icons.message_rounded, size: 20),
                  text: "MESAJLAR",
                ),
              ],
            ),
          ),
        ),
      ),
      body: AdultPanelBackground(
        background: TeacherPalette.background,
        gradient: TeacherPalette.mainGradient,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeworkClassesTab(uid),
            _buildClassHomeTab(uid),
            _buildMessagesTab(uid),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _currentFabGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _currentFabGradient.first.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_currentIndex == 2) {
              _showAddMessageDialog();
            } else {
              _showAddClassDialog();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: Icon(_currentFabIcon),
          label: Text(
            _currentFabLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
  void _showClassLessonsSheet({
    required String uid,
    required String className,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ClassLessonsSheetContent(
          className: className,
          teacherUid: uid,
          onDelete: (lessonId) async {
            await _firestore.collection('lessons').doc(lessonId).delete();

            if (!mounted) return;

            _showSnack(
              "Ödev silindi.",
              color: Colors.redAccent,
            );
          },
        );
      },
    );
  }

  Widget _buildHomeworkClassesTab(String uid) {
    if (_teacherClasses.isEmpty) {
      return const _TeacherEmptyState(
        emoji: "🏫",
        title: "Henüz sınıf yok",
        subtitle: "Sağ alttaki butonla sınıf ekle. Sonra o sınıfa etkinlik ödevi verebilirsin.",
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        const _SectionTitle(
          title: "Ödev verilecek sınıfı seç",
          subtitle: "Sınıfa tıkla, etkinlik ve bölüm seçerek ödev oluştur.",
        ),

        const SizedBox(height: 12),

        ..._teacherClasses.map((className) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('lessons')
                .where('teacherId', isEqualTo: uid)
                .where('className', isEqualTo: className)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              final last = snapshot.data?.docs.isNotEmpty == true
                  ? snapshot.data!.docs.last.data()['title']?.toString()
                  : null;

              return _ClassActionCard(
                className: className,
                emoji: "📝",
                title: "$className Ödevleri",
                subtitle: count == 0
                    ? "Bu sınıfa henüz ödev verilmedi."
                    : "$count ödev verildi${last == null ? "" : " • Son: $last"}",
                gradient: TeacherPalette.lessonGradient,
                sideButtonLabel: "Verilen\nÖdevler",
                sideButtonIcon: Icons.assignment_rounded,
                onSideButtonTap: () {
                  _showClassLessonsSheet(
                    uid: uid,
                    className: className,
                  );
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ClassHomeworkPage(
                        className: className,
                        teacherUid: uid,
                        teacherName: teacherName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildClassHomeTab(String uid) {
    if (_teacherClasses.isEmpty) {
      return const _TeacherEmptyState(
        emoji: "🎒",
        title: "Henüz sınıf yok",
        subtitle: "Sağ alttaki butonla sınıf ekle. Sonra içine öğrenci ekleyebilirsin.",
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        const _SectionTitle(
          title: "Sınıflarım",
          subtitle: "Sınıfa tıkla, öğrenci listesini ve gelişim karnelerini görüntüle.",
        ),

        const SizedBox(height: 12),

        ..._teacherClasses.map((className) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('childProfiles')
                .where('teachers', arrayContains: uid)
                .where('className', isEqualTo: className)
                .where('profileType', isEqualTo: 'child')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return _ClassActionCard(
                className: className,
                emoji: "🎒",
                title: "$className Sınıfı",
                subtitle: "$count öğrenci kayıtlı",
                gradient: TeacherPalette.classGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ClassStudentsPage(
                        className: className,
                        teacherUid: uid,
                        onAddStudent: () => _showAddStudentDialog(
                          className: className,
                        ),
                        onShowStats: _showStudentStats,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildMessagesTab(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('announcements')
          .where('teacherId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TeacherEmptyState(
            emoji: "⚠️",
            title: "Mesajlar yüklenemedi",
            subtitle: "Bağlantı veya index sorunu olabilir.",
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const _TeacherEmptyState(
            emoji: "💬",
            title: "Henüz mesaj yok",
            subtitle: "Sağ alttaki butonla öğrencilere mesaj gönderebilirsin.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return _AnnouncementCard(
              title: data['title']?.toString() ?? "Mesaj",
              content: data['content']?.toString() ?? "",
              className: data['className']?.toString() ?? "-",
              type: data['type']?.toString() ?? "duyuru",
              date: data['date'],
              onDelete: () => _deleteAnnouncement(doc.id),
            );
          },
        );
      },
    );
  }
}

class _ClassHomeworkPage extends StatefulWidget {
  final String className;
  final String teacherUid;
  final String teacherName;

  const _ClassHomeworkPage({
    required this.className,
    required this.teacherUid,
    required this.teacherName,
  });

  @override
  State<_ClassHomeworkPage> createState() => _ClassHomeworkPageState();
}

class _ClassHomeworkPageState extends State<_ClassHomeworkPage> {
  final _firestore = FirebaseFirestore.instance;

  String _selectedLessonFilter = "Tümü";

  String _lessonTypeOf(Map<String, dynamic> data) {
    final gameType = data['gameType']?.toString().trim() ?? "";
    if (gameType.isNotEmpty) return gameType;

    final subject = data['subject']?.toString().trim() ?? "";
    if (subject.isNotEmpty) return subject;

    final gameKey = data['gameKey']?.toString().trim() ?? "";
    if (gameKey.contains(":")) {
      return gameKey.split(":").first.trim();
    }

    return "Diğer";
  }

  List<String> _buildLessonFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final existingTypes = docs
        .map((doc) => _lessonTypeOf(doc.data()))
        .where((type) => type.trim().isNotEmpty)
        .toSet();

    final ordered = <String>["Tümü"];

    for (final game in _teacherGames) {
      if (existingTypes.contains(game.gameType)) {
        ordered.add(game.gameType);
      }
    }

    final extra = existingTypes.where((type) {
      return type != "Tümü" && !ordered.contains(type);
    }).toList();

    extra.sort();
    ordered.addAll(extra);

    return ordered;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredLessonDocs({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String selectedFilter,
  }) {
    if (selectedFilter == "Tümü") return docs;

    return docs.where((doc) {
      return _lessonTypeOf(doc.data()) == selectedFilter;
    }).toList();
  }

  int _lessonCountForFilter({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String filter,
  }) {
    if (filter == "Tümü") return docs.length;

    return docs.where((doc) {
      return _lessonTypeOf(doc.data()) == filter;
    }).length;
  }

  Widget _lessonFilterTabs({
    required List<String> filters,
    required String selectedFilter,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (filters.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;
          final count = _lessonCountForFilter(
            docs: docs,
            filter: filter,
          );

          return ChoiceChip(
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedLessonFilter = filter;
              });
            },
            label: Text(
              "$filter ($count)",
              style: TextStyle(
                color: selected ? Colors.white : TeacherPalette.secondary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            selectedColor: TeacherPalette.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? TeacherPalette.primary
                  : TeacherPalette.primary.withOpacity(0.12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          );
        },
      ),
    );
  }

  void _showLevelSheet({
    required _TeacherGameInfo game,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> existingLessons,
  }) {
    final levels = GameRepository.getLevels(game.gameType);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: const BoxDecoration(
            color: TeacherPalette.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              const SizedBox(height: 14),

              _DialogHeader(
                emoji: game.emoji,
                title: "${game.title} Bölümleri",
                subtitle: "${widget.className} sınıfına verilecek bölümü seç.",
                gradient: TeacherPalette.lessonGradient,
              ),

              const SizedBox(height: 14),

              Expanded(
                child: ListView.separated(
                  itemCount: levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final levelTitle = level['title']?.toString() ?? "Bölüm";
                    final gameKey = "${game.gameType}: $levelTitle";

                    final alreadyGiven = existingLessons.any((doc) {
                      final data = doc.data();
                      return data['gameKey']?.toString() == gameKey ||
                          (data['gameType']?.toString() == game.gameType &&
                              data['levelTitle']?.toString() == levelTitle);
                    });

                    return _LevelSelectCard(
                      title: levelTitle,
                      subtitle: alreadyGiven
                          ? "Bu sınıfa daha önce verildi"
                          : "Bu sınıfa henüz verilmedi",
                      emoji: _levelEmoji(levelTitle),
                      alreadyGiven: alreadyGiven,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Future.delayed(
                          const Duration(milliseconds: 120),
                              () {
                            if (!mounted) return;

                            _showAssignmentForm(
                              game: game,
                              levelTitle: levelTitle,
                              alreadyGiven: alreadyGiven,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssignmentForm({
    required _TeacherGameInfo game,
    required String levelTitle,
    required bool alreadyGiven,
  }) {
    final titleController = TextEditingController(
      text: "${game.title} - $levelTitle",
    );
    final contentController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogHeader(
                        emoji: game.emoji,
                        title: alreadyGiven ? "Ödevi Tekrar Ver" : "Ödevi Hazırla",
                        subtitle: "${widget.className} • ${game.title} • $levelTitle",
                        gradient: TeacherPalette.lessonGradient,
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: titleController,
                        decoration: _teacherInputDecoration(
                          label: "Ödev başlığı",
                          icon: Icons.title_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: _teacherInputDecoration(
                          label: "Açıklama",
                          icon: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: TeacherPalette.primary.withOpacity(0.10),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: TeacherPalette.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? "Teslim tarihi seç"
                                      : DateFormat('dd/MM/yyyy').format(selectedDate!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "İPTAL",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty ||
                                    selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text("Başlık ve tarih gerekli."),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final gameKey = "${game.gameType}: $levelTitle";
                                final assignedStudents = await _firestore
                                    .collection('childProfiles')
                                    .where('className', isEqualTo: widget.className)
                                    .where('teachers', arrayContains: widget.teacherUid)
                                    .where('profileType', isEqualTo: 'child')
                                    .get();

                                final assignedChildIds = assignedStudents.docs.map((doc) => doc.id).toList();
                                final lessonRef =
                                await _firestore.collection('lessons').add({
                                  'teacherId': widget.teacherUid,
                                  'teacherName': widget.teacherName,
                                  'title': titleController.text.trim(),
                                  'content': contentController.text.trim(),
                                  'description': contentController.text.trim(),
                                  'subject': game.gameType,
                                  'className': widget.className,
                                  'gameType': game.gameType,
                                  'levelTitle': levelTitle,
                                  'gameKey': gameKey,
                                  'dueDate': Timestamp.fromDate(selectedDate!),
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'completedBy': [],
                                  'assignmentVersion': 2,
                                  'targetType': 'class',
                                  'assignedChildIds': assignedChildIds,
                                  'assignedClassName': widget.className,
                                  'lessonId': null,
                                });

                                await lessonRef.set({
                                  'lessonId': lessonRef.id,
                                }, SetOptions(merge: true));

                                await PushRequestService
                                    .sendHomeworkNotificationToClass(
                                  className: widget.className,
                                  homeworkTitle: titleController.text.trim(),
                                );

                                if (!mounted) return;

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${widget.className} sınıfına ödev gönderildi.",
                                    ),
                                    backgroundColor: TeacherPalette.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TeacherPalette.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                alreadyGiven ? "TEKRAR GÖNDER" : "GÖNDER",
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.background,
      appBar: AppBar(
        title: Text(
          "${widget.className} Ödev Planı",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: TeacherPalette.lessonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Ana sayfa",
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('lessons')
            .where('teacherId', isEqualTo: widget.teacherUid)
            .where('className', isEqualTo: widget.className)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
            children: [
              _ClassPageHero(
                emoji: "📝",
                title: "${widget.className} Sınıfı",
                subtitle:
                "Etkinliği seç, bölümü belirle ve bu sınıfa ödev gönder.",
                gradient: TeacherPalette.lessonGradient,
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                title: "Etkinlikler",
                subtitle: "Ödev vermek istediğin etkinliği seç.",
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _teacherGames.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 170,
                ),
                itemBuilder: (context, index) {
                  final game = _teacherGames[index];

                  final levels = GameRepository.getLevels(game.gameType);
                  final givenCount = levels.where((level) {
                    final levelTitle = level['title']?.toString() ?? "";
                    final gameKey = "${game.gameType}: $levelTitle";

                    return docs.any((doc) {
                      final data = doc.data();
                      return data['gameKey']?.toString() == gameKey ||
                          (data['gameType']?.toString() == game.gameType &&
                              data['levelTitle']?.toString() == levelTitle);
                    });
                  }).length;

                  return _GameHomeworkCard(
                    game: game,
                    givenCount: givenCount,
                    totalCount: levels.length,
                    onTap: () => _showLevelSheet(
                      game: game,
                      existingLessons: docs,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
class _ClassLessonsSheetContent extends StatefulWidget {
  final String className;
  final String teacherUid;
  final Future<void> Function(String lessonId) onDelete;

  const _ClassLessonsSheetContent({
    required this.className,
    required this.teacherUid,
    required this.onDelete,
  });

  @override
  State<_ClassLessonsSheetContent> createState() =>
      _ClassLessonsSheetContentState();
}

class _ClassLessonsSheetContentState extends State<_ClassLessonsSheetContent> {
  final _firestore = FirebaseFirestore.instance;

  String _selectedLessonFilter = "Tümü";

  String _lessonTypeOf(Map<String, dynamic> data) {
    final gameType = data['gameType']?.toString().trim() ?? "";
    if (gameType.isNotEmpty) return gameType;

    final subject = data['subject']?.toString().trim() ?? "";
    if (subject.isNotEmpty) return subject;

    final gameKey = data['gameKey']?.toString().trim() ?? "";
    if (gameKey.contains(":")) {
      return gameKey.split(":").first.trim();
    }

    return "Diğer";
  }

  List<String> _buildLessonFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final existingTypes = docs
        .map((doc) => _lessonTypeOf(doc.data()))
        .where((type) => type.trim().isNotEmpty)
        .toSet();

    final ordered = <String>["Tümü"];

    for (final game in _teacherGames) {
      if (existingTypes.contains(game.gameType)) {
        ordered.add(game.gameType);
      }
    }

    final extra = existingTypes.where((type) {
      return type != "Tümü" && !ordered.contains(type);
    }).toList();

    extra.sort();
    ordered.addAll(extra);

    return ordered;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredLessonDocs({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String selectedFilter,
  }) {
    if (selectedFilter == "Tümü") return docs;

    return docs.where((doc) {
      return _lessonTypeOf(doc.data()) == selectedFilter;
    }).toList();
  }

  int _lessonCountForFilter({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String filter,
  }) {
    if (filter == "Tümü") return docs.length;

    return docs.where((doc) {
      return _lessonTypeOf(doc.data()) == filter;
    }).length;
  }

  Widget _lessonFilterTabs({
    required List<String> filters,
    required String selectedFilter,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (filters.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;
          final count = _lessonCountForFilter(
            docs: docs,
            filter: filter,
          );

          return ChoiceChip(
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedLessonFilter = filter;
              });
            },
            label: Text(
              "$filter ($count)",
              style: TextStyle(
                color: selected ? Colors.white : TeacherPalette.secondary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            selectedColor: TeacherPalette.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? TeacherPalette.primary
                  : TeacherPalette.primary.withOpacity(0.12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          );
        },
      ),
    );
  }

  int _timestampSortValue(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: TeacherPalette.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const SizedBox(height: 14),

          _DialogHeader(
            emoji: "📋",
            title: "${widget.className} Verilen Ödevler",
            subtitle: "Ödevleri sekmelere göre filtreleyebilir ve yapan öğrencileri görebilirsin.",
            gradient: TeacherPalette.lessonGradient,
          ),

          const SizedBox(height: 14),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('lessons')
                  .where('teacherId', isEqualTo: widget.teacherUid)
                  .where('className', isEqualTo: widget.className)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _TeacherEmptyState(
                    emoji: "⚠️",
                    title: "Ödevler yüklenemedi",
                    subtitle: "Bağlantı veya Firestore index sorunu olabilir.",
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.toList();

                docs.sort((a, b) {
                  final bTime = _timestampSortValue(b.data()['createdAt']);
                  final aTime = _timestampSortValue(a.data()['createdAt']);
                  return bTime.compareTo(aTime);
                });

                final filters = _buildLessonFilters(docs);

                final activeLessonFilter = filters.contains(_selectedLessonFilter)
                    ? _selectedLessonFilter
                    : "Tümü";

                final filteredDocs = _filteredLessonDocs(
                  docs: docs,
                  selectedFilter: activeLessonFilter,
                );

                return ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    const _SectionTitle(
                      title: "Verilen Ödevler",
                      subtitle: "Yapan öğrenci isimleri ödev kartının içinde görünür.",
                    ),

                    const SizedBox(height: 12),

                    _lessonFilterTabs(
                      filters: filters,
                      selectedFilter: activeLessonFilter,
                      docs: docs,
                    ),

                    const SizedBox(height: 12),

                    if (docs.isEmpty)
                      const _SmallEmptyCard(
                        emoji: "📭",
                        title: "Henüz ödev verilmedi",
                        subtitle: "Etkinlik sayfasından bölüm seçerek ilk ödevi oluştur.",
                      )
                    else if (filteredDocs.isEmpty)
                      const _SmallEmptyCard(
                        emoji: "🔎",
                        title: "Bu sekmede ödev yok",
                        subtitle: "Başka bir etkinlik sekmesini seçebilirsin.",
                      )
                    else
                      ...filteredDocs.map((doc) {
                        final data = doc.data();

                        return _TeacherLessonCard(
                          title: data['title']?.toString() ?? "Ödev",
                          description: data['description']?.toString() ??
                              data['content']?.toString() ??
                              "Açıklama yok.",
                          className: data['className']?.toString() ??
                              widget.className,
                          completedBy: data['completedBy'] is List
                              ? List<dynamic>.from(data['completedBy'])
                              : const [],
                          dueDate: data['dueDate'],
                          gameKey: data['gameKey']?.toString(),
                          onDelete: () async {
                            await widget.onDelete(doc.id);
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "KAPAT",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassStudentsPage extends StatelessWidget {
  final String className;
  final String teacherUid;
  final VoidCallback onAddStudent;
  final void Function(String childId, Map<String, dynamic>) onShowStats;

  const _ClassStudentsPage({
    required this.className,
    required this.teacherUid,
    required this.onAddStudent,
    required this.onShowStats,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: TeacherPalette.background,
      appBar: AppBar(
        title: Text(
          "$className Öğrencileri",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: TeacherPalette.classGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Ana sayfa",
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('childProfiles')
            .where('teachers', arrayContains: teacherUid)
            .where('className', isEqualTo: className)
            .where('profileType', isEqualTo: 'child')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _TeacherEmptyState(
              emoji: "⚠️",
              title: "Öğrenciler yüklenemedi",
              subtitle: "Bağlantı veya izin sorunu olabilir.",
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _dedupeTeacherStudentDocs(snapshot.data!.docs);

          if (docs.isEmpty) {
            return const _TeacherEmptyState(
              emoji: "🎒",
              title: "Bu sınıfta öğrenci yok",
              subtitle: "Sağ alttaki butonla bu sınıfa öğrenci ekleyebilirsin.",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return _StudentCard(
                studentData: data,
                onTap: () => onShowStats(doc.id, data),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: TeacherPalette.classGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: TeacherPalette.green.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: onAddStudent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text(
            "ÖĞRENCİ EKLE",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

InputDecoration _teacherInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF7F7FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: TeacherPalette.primary.withOpacity(0.10),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: TeacherPalette.primary,
        width: 1.5,
      ),
    ),
  );
}

String _levelEmoji(String title) {
  final t = title.toLowerCase();

  if (t.contains("meyve")) return "🍐";
  if (t.contains("hayvan")) return "🐾";
  if (t.contains("taşıt") || t.contains("tasit")) return "🚗";
  if (t.contains("renk")) return "🎨";
  if (t.contains("şekil") || t.contains("sekil")) return "🔷";
  if (t.contains("sayı") || t.contains("sayi")) return "🔢";
  if (t.contains("rakam")) return "🔢";
  if (t.contains("harf")) return "🔤";
  if (t.contains("sembol")) return "🔣";
  if (t.contains("doğa") || t.contains("doga")) return "🍃";
  if (t.contains("yiyecek")) return "🍽️";
  if (t.contains("eşya") || t.contains("esya")) return "🎒";
  if (t.contains("kısa") || t.contains("kisa")) return "💬";
  if (t.contains("orta")) return "🗣️";
  if (t.contains("uzun")) return "📜";
  if (t.contains("başlangıç") || t.contains("baslangic")) return "🔈";
  if (t.contains("bitiş") || t.contains("bitis")) return "🔊";
  if (t.contains("içindeki") || t.contains("icindeki")) return "🎧";
  if (t.contains("kolay")) return "🌱";
  if (t.contains("zor")) return "🏆";

  return "🎯";
}
String _teacherMiniGameName(String key) {
  switch (key) {
    case 'balloonLetter':
      return "Balon Harf Avı";
    case 'fruitBasket':
      return "Meyveleri Sepete Taşı";
    case 'memoryCards':
      return "Hafıza Kartları";
    case 'matching':
      return "Eşleştirme";
    default:
      return key;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: TeacherPalette.mainGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TeacherPalette.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassActionCard extends StatelessWidget {
  final String className;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  final String? sideButtonLabel;
  final IconData? sideButtonIcon;
  final VoidCallback? onSideButtonTap;

  const _ClassActionCard({
    required this.className,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.sideButtonLabel,
    this.sideButtonIcon,
    this.onSideButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSideButton =
        sideButtonLabel != null && sideButtonIcon != null && onSideButtonTap != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.11),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: gradient.first.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: TextStyle(
                          color: gradient.first,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: TeacherPalette.secondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                if (hasSideButton)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onSideButtonTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sideButtonIcon,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sideButtonLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: TeacherPalette.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassPageHero extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _ClassPageHero({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHomeworkCard extends StatelessWidget {
  final _TeacherGameInfo game;
  final int givenCount;
  final int totalCount;
  final VoidCallback onTap;

  const _GameHomeworkCard({
    required this.game,
    required this.givenCount,
    required this.totalCount,
    required this.onTap,
  });

  List<Color> get _gradient {
    switch (game.gameType) {
      case "Heceleme":
        return const [Color(0xFF172033), Color(0xFF4454D6)];
      case "Tanıma":
        return const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
      case "Hız":
        return const [Color(0xFF334155), Color(0xFF64748B)];
      case "Bellek":
        return const [Color(0xFF312E81), Color(0xFF6D3BEA)];
      case "Yazma":
        return const [Color(0xFF0F766E), Color(0xFF0F9F8E)];
      case "Hikaye":
        return const [Color(0xFF7C2D12), Color(0xFFF59E0B)];
      case "Sesler":
        return const [Color(0xFF1E40AF), Color(0xFF4F8CFF)];
      case "Okuma":
        return const [Color(0xFF374151), Color(0xFF4454D6)];
      default:
        return TeacherPalette.lessonGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = totalCount > 0 && givenCount >= totalCount;
    final progress = totalCount <= 0
        ? 0.0
        : (givenCount / totalCount).clamp(0.0, 1.0).toDouble();

    final gradient = completed
        ? const [Color(0xFF0F766E), Color(0xFF0F9F8E)]
        : _gradient;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -14,
                child: Text(
                  game.emoji,
                  style: TextStyle(
                    fontSize: 58,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Icon(
                          game.icon,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$givenCount/$totalCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    completed
                        ? "Tüm bölümler verildi"
                        : "$givenCount/$totalCount bölüm verildi",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.86),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 7,
                          color: Colors.white.withOpacity(0.18),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelSelectCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool alreadyGiven;
  final VoidCallback onTap;

  const _LevelSelectCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.alreadyGiven,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = alreadyGiven ? TeacherPalette.green : TeacherPalette.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withOpacity(0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: TeacherPalette.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                alreadyGiven
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _CompletedStudentInfo {
  final String? name;
  final String idText;

  const _CompletedStudentInfo({
    required this.name,
    required this.idText,
  });
}

class _TeacherLessonCard extends StatelessWidget {
  final String title;
  final String description;
  final String className;
  final List<dynamic> completedBy;
  final dynamic dueDate;
  final String? gameKey;
  final VoidCallback onDelete;

  const _TeacherLessonCard({
    required this.title,
    required this.description,
    required this.className,
    required this.completedBy,
    required this.dueDate,
    required this.gameKey,
    required this.onDelete,
  });

  String _formatDueDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(value.toDate());
    }

    return "Tarih yok";
  }

  List<String> _completedIds() {
    final ids = <String>[];

    for (final item in completedBy) {
      if (item is String && item.trim().isNotEmpty) {
        ids.add(item.trim());
      } else if (item is Map) {
        final name = item['name']?.toString().trim() ?? "";
        final displayName = item['displayName']?.toString().trim() ?? "";
        final nickname = item['nickname']?.toString().trim() ?? "";
        final playerId = item['playerId']?.toString().trim() ?? "";
        final childId = item['childId']?.toString().trim() ?? "";
        final id = item['id']?.toString().trim() ?? "";
        final uid = item['uid']?.toString().trim() ?? "";

        if (name.isNotEmpty ||
            displayName.isNotEmpty ||
            nickname.isNotEmpty ||
            playerId.isNotEmpty) {
          ids.add(
            childId.isNotEmpty
                ? childId
                : id.isNotEmpty
                ? id
                : uid.isNotEmpty
                ? uid
                : playerId,
          );
        } else if (childId.isNotEmpty) {
          ids.add(childId);
        } else if (id.isNotEmpty) {
          ids.add(id);
        } else if (uid.isNotEmpty) {
          ids.add(uid);
        }
      }
    }

    return ids.where((id) => id.trim().isNotEmpty).toSet().toList();
  }

  Future<List<_CompletedStudentInfo>> _loadCompletedStudents() async {
    final ids = _completedIds();

    if (ids.isEmpty) return [];

    final students = <_CompletedStudentInfo>[];

    for (final id in ids.take(60)) {
      String fallbackId = id;

      try {
        final childDoc = await FirebaseFirestore.instance
            .collection('childProfiles')
            .doc(id)
            .get();

        final childData = childDoc.data();

        if (childData != null) {
          final name = _childDisplayName(childData);
          final playerId = childData['playerId']?.toString().trim() ?? "";

          students.add(
            _CompletedStudentInfo(
              name: name.trim().isNotEmpty ? name : null,
              idText: playerId.isNotEmpty ? playerId : fallbackId,
            ),
          );

          continue;
        }
      } catch (_) {}

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();

        final userData = userDoc.data();

        if (userData != null) {
          final name = _childDisplayName(userData);
          final playerId = userData['playerId']?.toString().trim() ?? "";

          students.add(
            _CompletedStudentInfo(
              name: name.trim().isNotEmpty ? name : null,
              idText: playerId.isNotEmpty ? playerId : fallbackId,
            ),
          );

          continue;
        }
      } catch (_) {}

      students.add(
        _CompletedStudentInfo(
          name: null,
          idText: fallbackId,
        ),
      );
    }

    return students;
  }

  void _showCompletedStudentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.62,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: TeacherPalette.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              const SizedBox(height: 14),

              _DialogHeader(
                emoji: "✅",
                title: "Ödevi Yapanlar",
                subtitle: title,
                gradient: TeacherPalette.lessonGradient,
              ),

              const SizedBox(height: 14),

              Expanded(
                child: FutureBuilder<List<_CompletedStudentInfo>>(
                  future: _loadCompletedStudents(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final students = snapshot.data ?? [];

                    if (students.isEmpty) {
                      return const _SmallEmptyCard(
                        emoji: "📭",
                        title: "Henüz yapan öğrenci yok",
                        subtitle: "Öğrenci ödevi tamamlayınca burada görünür.",
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = students[index];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: TeacherPalette.primary.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: TeacherPalette.primary.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: TeacherPalette.lessonGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name ?? student.idText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: TeacherPalette.secondary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      student.name == null
                                          ? "İsim bulunamadı • ID: ${student.idText}"
                                          : "ID: ${student.idText}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "KAPAT",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedIds().length;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TeacherPalette.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(
          color: TeacherPalette.primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: TeacherPalette.lessonGradient,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameKey ?? "Ödev",
                  style: TextStyle(
                    color: TeacherPalette.primary.withOpacity(0.88),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Yapan: $completedCount • ${_formatDueDate(dueDate)}",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: completedCount == 0
                    ? null
                    : () => _showCompletedStudentsSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: completedCount == 0
                        ? Colors.grey.shade200
                        : TeacherPalette.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: completedCount == 0
                          ? Colors.grey.shade300
                          : TeacherPalette.green.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 18,
                        color: completedCount == 0
                            ? Colors.grey.shade500
                            : TeacherPalette.green,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Yapanlar",
                        style: TextStyle(
                          color: completedCount == 0
                              ? Colors.grey.shade500
                              : TeacherPalette.green,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final VoidCallback onTap;

  const _StudentCard({
    required this.studentData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = _childDisplayName(studentData);
    final playerId = studentData['playerId']?.toString() ?? "-";
    final className = studentData['className']?.toString() ?? "-";
    final stars = studentData['stars'] is num
        ? (studentData['stars'] as num).toInt()
        : int.tryParse(studentData['stars']?.toString() ?? "0") ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TeacherPalette.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: TeacherPalette.classGradient,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(
          fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: TeacherPalette.secondary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Oyuncu ID: $playerId\nSınıf: $className • ⭐ $stars",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(
          Icons.bar_chart_rounded,
          color: TeacherPalette.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String className;
  final String type;
  final dynamic date;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.title,
    required this.content,
    required this.className,
    required this.type,
    required this.date,
    required this.onDelete,
  });

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    return "Tarih yok";
  }

  @override
  Widget build(BuildContext context) {
    final isCongrats = type == "tebrik";

    final color = isCongrats ? TeacherPalette.green : TeacherPalette.orange;
    final icon = isCongrats ? Icons.star_rounded : Icons.message_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: TeacherPalette.secondary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            "Sınıf: $className • ${_formatDate(date)}\n$content",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_rounded,
            color: Colors.redAccent,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _DialogHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TemplateButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallEmptyCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _SmallEmptyCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TeacherPalette.primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _TeacherEmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: TeacherPalette.primary.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TeacherPalette.secondary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _TeacherReportInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _TeacherReportInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherReportStatTile extends StatelessWidget {
  final String title;
  final int value;

  const _TeacherReportStatTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 10).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TeacherPalette.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: TeacherPalette.primary.withOpacity(0.10),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: TeacherPalette.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: TeacherPalette.primary.withOpacity(0.10),
                    valueColor: const AlwaysStoppedAnimation(
                      TeacherPalette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$value",
            style: const TextStyle(
              color: TeacherPalette.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
String _teacherPlayerKeyFromTextGlobal(String value) {
  return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String _teacherPlayerKeyFromDataGlobal(Map<String, dynamic> data) {
  final playerId = data['playerId']?.toString().trim() ?? "";
  if (playerId.isNotEmpty) {
    return _teacherPlayerKeyFromTextGlobal(playerId);
  }

  final normalized = data['playerIdNormalized']?.toString().trim() ?? "";
  if (normalized.isNotEmpty) {
    return _teacherPlayerKeyFromTextGlobal(normalized);
  }

  final savedKey = data['playerIdKey']?.toString().trim() ?? "";
  if (savedKey.isNotEmpty) {
    return _teacherPlayerKeyFromTextGlobal(savedKey);
  }

  return "";
}

String _teacherStudentNameGlobal(Map<String, dynamic> data) {
  final nickname = data['nickname']?.toString().trim() ?? "";
  if (nickname.isNotEmpty) return nickname;

  final displayName = data['displayName']?.toString().trim() ?? "";
  if (displayName.isNotEmpty) return displayName;

  final name = data['name']?.toString().trim() ?? "";
  final surname = data['surname']?.toString().trim() ?? "";
  final fullName = "$name $surname".trim();
  if (fullName.isNotEmpty) return fullName;

  final playerId = data['playerId']?.toString().trim() ?? "";
  if (playerId.isNotEmpty) return playerId;

  return "Öğrenci";
}

int _teacherStudentScoreGlobal(Map<String, dynamic> data) {
  int score = 0;

  if (data['profileType'] == 'child') score += 30;
  if (data['profileSetupDone'] == true) score += 20;

  final nickname = data['nickname']?.toString().trim() ?? "";
  final name = data['name']?.toString().trim() ?? "";
  final playerId = data['playerId']?.toString().trim() ?? "";
  final recoveryCode = data['recoveryCode']?.toString().trim() ?? "";

  if (nickname.isNotEmpty) score += 10;
  if (name.isNotEmpty) score += 8;
  if (playerId.isNotEmpty) score += 8;
  if (recoveryCode.isNotEmpty) score += 6;

  final stars = data['stars'];
  if (stars is num) {
    final starValue = stars.toInt();
    score += starValue > 100 ? 100 : starValue;
  }

  return score;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _dedupeTeacherStudentDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
  final byPlayerId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

  for (final doc in docs) {
    final data = doc.data();

    final key = _teacherPlayerKeyFromDataGlobal(data).isNotEmpty
        ? _teacherPlayerKeyFromDataGlobal(data)
        : doc.id;

    final existing = byPlayerId[key];

    if (existing == null) {
      byPlayerId[key] = doc;
      continue;
    }

    final existingScore = _teacherStudentScoreGlobal(existing.data());
    final newScore = _teacherStudentScoreGlobal(data);

    if (newScore > existingScore) {
      byPlayerId[key] = doc;
    }
  }

  final result = byPlayerId.values.toList();

  result.sort((a, b) {
    final an = _teacherStudentNameGlobal(a.data()).toLowerCase();
    final bn = _teacherStudentNameGlobal(b.data()).toLowerCase();
    return an.compareTo(bn);
  });

  return result;
}


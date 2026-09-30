import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/common/help_guide_button.dart';
import '../repositories/development_report_repository.dart';
import '../services/session_flow_service.dart';
import '../widgets/common/usage_today_card.dart';
import '../widgets/common/usage_last_three_days_card.dart';
import '../widgets/common/adult_panel_background.dart';
import 'login_page.dart' hide ParentHome;

class ParentPalette {
  static const Color primary = Color(0xFF3F51B5);
  static const Color purple = Color(0xFF6D3BEA);
  static const Color green = Color(0xFF00A884);
  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFFEFF3FA);
  static const Color dark = Color(0xFF172033);

  static const List<Color> mainGradient = [
    Color(0xFF172033),
    Color(0xFF3F51B5),
  ];

  static const List<Color> greenGradient = [
    Color(0xFF43A047),
    Color(0xFF00A884),
  ];
}

class _FoundChild {
  final String childId;
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;

  const _FoundChild({
    required this.childId,
    required this.ref,
    required this.data,
  });
}

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _playerIdController = TextEditingController();
  final TextEditingController _recoveryController = TextEditingController();

  String _parentName = "Ebeveyn";
  bool _isLinking = false;
  int _refreshKey = 0;

  late Future<List<_FoundChild>> _childrenFuture;

  @override
  void initState() {
    super.initState();

    _childrenFuture = _loadLinkedChildren();

    _loadParentName();
  }
  void _reloadChildren() {
    setState(() {
      _refreshKey++;
      _childrenFuture = _loadLinkedChildren();
    });
  }

  @override
  void dispose() {
    _playerIdController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _loadParentName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      final name = data['name']?.toString().trim() ?? "";
      final surname = data['surname']?.toString().trim() ?? "";
      final fullName = "$name $surname".trim();

      if (!mounted) return;

      setState(() {
        _parentName = fullName.isEmpty ? "Ebeveyn" : fullName;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _parentName = "Ebeveyn";
      });
    }
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

  String _recoveryKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _displayName(Map<String, dynamic> data) {
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

    return "Çocuk Profili";
  }

  String _trustedPlayerKey(Map<String, dynamic> data) {
    final playerId = data['playerId']?.toString().trim() ?? "";
    if (playerId.isNotEmpty) return _playerIdKey(playerId);

    final normalized = data['playerIdNormalized']?.toString().trim() ?? "";
    if (normalized.isNotEmpty) return _playerIdKey(normalized);

    final key = data['playerIdKey']?.toString().trim() ?? "";
    if (key.isNotEmpty) return _playerIdKey(key);

    return "";
  }

  String _trustedPlayerId(Map<String, dynamic> data, String fallback) {
    final playerId = data['playerId']?.toString().trim() ?? "";
    if (playerId.isNotEmpty) return _normalizePlayerId(playerId);

    final normalized = data['playerIdNormalized']?.toString().trim() ?? "";
    if (normalized.isNotEmpty) return _normalizePlayerId(normalized);

    return _normalizePlayerId(fallback);
  }

  int _profileScore(Map<String, dynamic> data) {
    int score = 0;

    if (data['profileType'] == 'child') score += 8;
    if ((data['playerId']?.toString().trim() ?? "").isNotEmpty) score += 7;
    if ((data['recoveryCode']?.toString().trim() ?? "").isNotEmpty) score += 4;
    if ((data['recoveryPin']?.toString().trim() ?? "").isNotEmpty) score += 4;
    if ((data['ownerUid']?.toString().trim() ?? "").isNotEmpty) score += 3;
    if ((data['nickname']?.toString().trim() ?? "").isNotEmpty) score += 2;
    if ((data['name']?.toString().trim() ?? "").isNotEmpty) score += 1;

    final stars = data['stars'];
    if (stars is num && stars > 0) score += 1;

    return score;
  }

  void _showSnack(String message, {Color color = ParentPalette.primary}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Future<_FoundChild?> _findChildByPlayerId(String rawPlayerId) async {
    final wantedKey = _playerIdKey(rawPlayerId);
    if (wantedKey.isEmpty) return null;

    final child = await _findInChildProfiles(wantedKey);
    if (child != null) return child;

    final userDoc = await _findInUsers(wantedKey);
    if (userDoc == null || userDoc.data() == null) return null;

    return _migrateUserToChildProfile(
      userDoc: userDoc,
      wantedKey: wantedKey,
      requestedPlayerId: _normalizePlayerId(rawPlayerId),
    );
  }

  Future<_FoundChild?> _findInChildProfiles(String wantedKey) async {
    _FoundChild? pickFromDocs(
        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
        ) {
      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in docs) {
        final data = doc.data();

        if (_trustedPlayerKey(data) == wantedKey) {
          matches.add(doc);
        }
      }

      if (matches.isEmpty) return null;

      matches.sort((a, b) {
        return _profileScore(b.data()).compareTo(_profileScore(a.data()));
      });

      final best = matches.first;

      return _FoundChild(
        childId: best.id,
        ref: best.reference,
        data: best.data(),
      );
    }

    final normalized = _normalizePlayerId(wantedKey);

    final queries = [
      _db
          .collection('childProfiles')
          .where('playerIdKey', isEqualTo: wantedKey)
          .limit(20)
          .get(),
      _db
          .collection('childProfiles')
          .where('playerId', isEqualTo: normalized)
          .limit(20)
          .get(),
      _db
          .collection('childProfiles')
          .where('playerIdNormalized', isEqualTo: normalized)
          .limit(20)
          .get(),
    ];

    for (final query in queries) {
      try {
        final snap = await query;
        final found = pickFromDocs(snap.docs);
        if (found != null) return found;
      } catch (_) {}
    }

    try {
      final fallback = await _db.collection('childProfiles').limit(2500).get();
      return pickFromDocs(fallback.docs);
    } catch (_) {
      return null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findInUsers(
      String wantedKey,
      ) async {
    DocumentSnapshot<Map<String, dynamic>>? pickFromDocs(
        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
        ) {
      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in docs) {
        final data = doc.data();

        final role = data['role']?.toString() ?? "";
        final accountType = data['accountType']?.toString() ?? "";
        final looksStudent =
            role == 'student' ||
                accountType == 'student' ||
                (data['playerId']?.toString().trim().isNotEmpty ?? false);

        if (!looksStudent) continue;

        if (_trustedPlayerKey(data) == wantedKey) {
          matches.add(doc);
        }
      }

      if (matches.isEmpty) return null;

      matches.sort((a, b) {
        return _profileScore(b.data()).compareTo(_profileScore(a.data()));
      });

      return matches.first;
    }

    final normalized = _normalizePlayerId(wantedKey);

    final queries = [
      _db
          .collection('users')
          .where('playerIdKey', isEqualTo: wantedKey)
          .limit(20)
          .get(),
      _db
          .collection('users')
          .where('playerId', isEqualTo: normalized)
          .limit(20)
          .get(),
      _db
          .collection('users')
          .where('playerIdNormalized', isEqualTo: normalized)
          .limit(20)
          .get(),
    ];

    for (final query in queries) {
      try {
        final snap = await query;
        final found = pickFromDocs(snap.docs);
        if (found != null) return found;
      } catch (_) {}
    }

    try {
      final fallback = await _db.collection('users').limit(2500).get();
      return pickFromDocs(fallback.docs);
    } catch (_) {
      return null;
    }
  }

  Future<_FoundChild> _migrateUserToChildProfile({
    required DocumentSnapshot<Map<String, dynamic>> userDoc,
    required String wantedKey,
    required String requestedPlayerId,
  }) async {
    final userData = userDoc.data() ?? {};
    final ownerUid = userDoc.id;

    if (_trustedPlayerKey(userData) != wantedKey) {
      throw Exception("Oyuncu ID eşleşmeyen kullanıcı profili taşınamaz.");
    }

    final activeChildId = userData['activeChildId']?.toString().trim() ?? "";

    if (activeChildId.isNotEmpty) {
      final activeDoc =
      await _db.collection('childProfiles').doc(activeChildId).get();
      final activeData = activeDoc.data();

      if (activeDoc.exists &&
          activeData != null &&
          _trustedPlayerKey(activeData) == wantedKey) {
        final merged = _buildChildData(
          childId: activeDoc.id,
          ownerUid: ownerUid,
          source: {
            ...userData,
            ...activeData,
          },
          requestedPlayerId: requestedPlayerId,
          wantedKey: wantedKey,
        );

        await activeDoc.reference.set(merged, SetOptions(merge: true));
        final fresh = await activeDoc.reference.get();

        return _FoundChild(
          childId: activeDoc.id,
          ref: activeDoc.reference,
          data: fresh.data() ?? merged,
        );
      }
    }

    final childRef = _db.collection('childProfiles').doc();
    final childData = _buildChildData(
      childId: childRef.id,
      ownerUid: ownerUid,
      source: userData,
      requestedPlayerId: requestedPlayerId,
      wantedKey: wantedKey,
    );

    await childRef.set(childData, SetOptions(merge: true));

    await _db.collection('users').doc(ownerUid).set(
      {
        'activeChildId': childRef.id,
        'hasChildProfiles': true,
        'playerId': childData['playerId'],
        'playerIdNormalized': childData['playerIdNormalized'],
        'playerIdKey': wantedKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final fresh = await childRef.get();

    return _FoundChild(
      childId: childRef.id,
      ref: childRef,
      data: fresh.data() ?? childData,
    );
  }

  Map<String, dynamic> _buildChildData({
    required String childId,
    required String ownerUid,
    required Map<String, dynamic> source,
    required String requestedPlayerId,
    required String wantedKey,
  }) {
    final playerId = _trustedPlayerId(source, requestedPlayerId);

    return {
      'childId': childId,
      'ownerUid': ownerUid,
      'role': 'student',
      'profileType': 'child',
      'isAnonymousChild': source['isAnonymousChild'] ?? true,
      'profileSetupDone': source['profileSetupDone'] == true,
      'name': source['name'] ?? source['nickname'] ?? 'Arkadaşım',
      'surname': source['surname'] ?? '',
      'displayName':
      source['displayName'] ?? source['nickname'] ?? 'Arkadaşım',
      'nickname': source['nickname'] ?? '',
      'ageGroup': source['ageGroup'] ?? '',
      'className': source['className'] ?? '',
      'playerId': playerId,
      'playerIdNormalized': playerId,
      'playerIdKey': wantedKey,
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

  Future<List<_FoundChild>> _loadLinkedChildren() async {
    final parentUid = _auth.currentUser?.uid;
    if (parentUid == null) return [];

    final result = <String, _FoundChild>{};

    Future<void> addChild(DocumentSnapshot<Map<String, dynamic>> doc) async {
      final data = doc.data();
      if (!doc.exists || data == null) return;

      result[doc.id] = _FoundChild(
        childId: doc.id,
        ref: doc.reference,
        data: data,
      );
    }

    try {
      final snap = await _db
          .collection('childProfiles')
          .where('parentIds', arrayContains: parentUid)
          .get();

      for (final doc in snap.docs) {
        await addChild(doc);
      }
    } catch (_) {}

    try {
      final snap = await _db
          .collection('childProfiles')
          .where('linkedParentIds', arrayContains: parentUid)
          .get();

      for (final doc in snap.docs) {
        await addChild(doc);
      }
    } catch (_) {}

    try {
      final parentDoc = await _db.collection('users').doc(parentUid).get();
      final parentData = parentDoc.data() ?? {};

      final ids = <String>{};

      final linkedChildIds = parentData['linkedChildIds'];
      if (linkedChildIds is List) {
        ids.addAll(
          linkedChildIds
              .map((e) => e.toString().trim())
              .where((id) => id.isNotEmpty),
        );
      }

      final childIds = parentData['childIds'];
      if (childIds is List) {
        ids.addAll(
          childIds.map((e) => e.toString().trim()).where((id) => id.isNotEmpty),
        );
      }

      for (final id in ids) {
        final childDoc = await _db.collection('childProfiles').doc(id).get();

        if (childDoc.exists && childDoc.data() != null) {
          await addChild(childDoc);
        }
      }
    } catch (_) {}

    final byPlayerId = <String, _FoundChild>{};

    for (final child in result.values) {
      final data = child.data;
      final key = _trustedPlayerKey(data).isNotEmpty
          ? _trustedPlayerKey(data)
          : child.childId;

      final existing = byPlayerId[key];

      if (existing == null) {
        byPlayerId[key] = child;
        continue;
      }

      final existingScore = _profileScore(existing.data);
      final newScore = _profileScore(data);

      if (newScore >= existingScore) {
        byPlayerId[key] = child;
      }
    }

    final docs = byPlayerId.values.toList();

    docs.sort((a, b) {
      final an = _displayName(a.data).toLowerCase();
      final bn = _displayName(b.data).toLowerCase();
      return an.compareTo(bn);
    });

    return docs;
  }

  Future<bool> _recoveryMatchesAndRepair({
    required _FoundChild foundChild,
    required String recoveryInput,
  }) async {
    final inputKey = _recoveryKey(recoveryInput);
    if (inputKey.isEmpty) return false;

    final candidates = <String>{};

    void addCandidate(dynamic value) {
      final text = value?.toString().trim() ?? "";
      if (text.isNotEmpty) candidates.add(text);
    }

    final childData = foundChild.data;

    addCandidate(childData['recoveryCode']);
    addCandidate(childData['recoveryPin']);
    addCandidate(childData['pin']);
    addCandidate(childData['recovery']);

    final ownerUids = <String>{
      childData['ownerUid']?.toString().trim() ?? "",
      childData['migratedFromUserUid']?.toString().trim() ?? "",
    }..removeWhere((e) => e.isEmpty);

    Map<String, dynamic> ownerData = {};

    for (final uid in ownerUids) {
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        final data = userDoc.data();
        if (data == null) continue;

        ownerData = {
          ...ownerData,
          ...data,
        };

        addCandidate(data['recoveryCode']);
        addCandidate(data['recoveryPin']);
        addCandidate(data['pin']);
        addCandidate(data['recovery']);
      } catch (_) {}
    }

    final matches = candidates.any((candidate) {
      return _recoveryKey(candidate) == inputKey;
    });

    if (!matches) return false;

    final ownerRecoveryCode = ownerData['recoveryCode']?.toString().trim() ?? "";
    final ownerRecoveryPin = ownerData['recoveryPin']?.toString().trim() ?? "";

    final childRecoveryCode = childData['recoveryCode']?.toString().trim() ?? "";
    final childRecoveryPin = childData['recoveryPin']?.toString().trim() ?? "";

    final repairData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'recoverySyncedAt': FieldValue.serverTimestamp(),
    };

    if (ownerRecoveryCode.isNotEmpty &&
        (_recoveryKey(ownerRecoveryCode) == inputKey ||
            childRecoveryCode.isEmpty)) {
      repairData['recoveryCode'] = ownerRecoveryCode;
    }

    if (ownerRecoveryPin.isNotEmpty &&
        (_recoveryKey(ownerRecoveryPin) == inputKey ||
            childRecoveryPin.isEmpty)) {
      repairData['recoveryPin'] = ownerRecoveryPin;
    }

    try {
      await foundChild.ref.set(repairData, SetOptions(merge: true));
    } catch (_) {}

    return true;
  }

  Future<void> _linkChildProfile(BuildContext dialogContext) async {
    if (_isLinking) return;

    final parentUid = _auth.currentUser?.uid;
    if (parentUid == null) return;

    final rawPlayerId = _playerIdController.text;
    final requestedKey = _playerIdKey(rawPlayerId);
    final normalizedPlayerId = _normalizePlayerId(rawPlayerId);
    final recoveryInput = _recoveryController.text;

    if (requestedKey.isEmpty || _recoveryKey(recoveryInput).isEmpty) {
      _showSnack(
        "Oyuncu ID ve kurtarma kodu gerekli.",
        color: Colors.redAccent,
      );
      return;
    }

    setState(() => _isLinking = true);

    try {
      final foundChild = await _findChildByPlayerId(rawPlayerId);

      if (foundChild == null) {
        _showSnack(
          "Bu Oyuncu ID ile çocuk profili bulunamadı.",
          color: Colors.redAccent,
        );
        return;
      }

      final childData = foundChild.data;
      final foundKey = _trustedPlayerKey(childData);

      if (foundKey != requestedKey) {
        _showSnack(
          "Oyuncu ID başka profile karışmış. Ekleme iptal edildi.",
          color: Colors.redAccent,
        );
        return;
      }

      final recoveryOk = await _recoveryMatchesAndRepair(
        foundChild: foundChild,
        recoveryInput: recoveryInput,
      );

      if (!recoveryOk) {
        _showSnack(
          "Kurtarma kodu veya PIN hatalı.",
          color: Colors.redAccent,
        );
        return;
      }

      await foundChild.ref.set(
        {
          'parentIds': FieldValue.arrayUnion([parentUid]),
          'linkedParentIds': FieldValue.arrayUnion([parentUid]),
          'linkedParentAt': FieldValue.serverTimestamp(),
          'playerIdNormalized': normalizedPlayerId,
          'playerIdKey': requestedKey,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _db.collection('users').doc(parentUid).set(
        {
          'role': 'parent',
          'linkedChildIds': FieldValue.arrayUnion([foundChild.childId]),
          'childIds': FieldValue.arrayUnion([foundChild.childId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final ownerUid = childData['ownerUid']?.toString().trim() ?? "";
      if (ownerUid.isNotEmpty) {
        await _db.collection('users').doc(ownerUid).set(
          {
            'parentIds': FieldValue.arrayUnion([parentUid]),
            'linkedParentIds': FieldValue.arrayUnion([parentUid]),
            'activeChildId': foundChild.childId,
            'hasChildProfiles': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;

      Navigator.of(dialogContext).pop();

      _reloadChildren();

      _showSnack(
        "${_displayName(childData)} profili bağlandı.",
        color: ParentPalette.green,
      );
    } catch (e) {
      _showSnack(
        "Çocuk profili bağlanamadı: $e",
        color: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  void _showLinkChildDialog() {
    _playerIdController.clear();
    _recoveryController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ParentDialogHeader(
                        emoji: "🔗",
                        title: "Çocuk Profili Bağla",
                        subtitle:
                        "Çocuğun ayarlardaki Oyuncu ID ve Kurtarma Kodu/PIN bilgisini yaz.",
                        gradient: ParentPalette.mainGradient,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _playerIdController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          label: "Oyuncu ID",
                          icon: Icons.confirmation_number_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _recoveryController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          label: "Kurtarma Kodu veya PIN",
                          icon: Icons.lock_reset_rounded,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLinking
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                              onPressed: _isLinking
                                  ? null
                                  : () async {
                                await _linkChildProfile(dialogContext);
                                if (mounted) {
                                  setDialogState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ParentPalette.primary,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isLinking ? "BAĞLANIYOR..." : "BAĞLA",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
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
          color: ParentPalette.primary.withOpacity(0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: ParentPalette.primary,
          width: 1.6,
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  void _showChildDetail(_FoundChild child) {
    final report = DevelopmentReportRepository.fromChildData(
      childId: child.childId,
      data: child.data,
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
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: const BoxDecoration(
              color: ParentPalette.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(34),
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

                const SizedBox(height: 16),

                _ChildHeroCard(
                  name: report.name,
                  stars: report.stars,
                  playerId: report.playerId,
                  className: report.className,
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: ParentPalette.primary.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ParentPalette.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: ParentPalette.primary,
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
                        colors: ParentPalette.mainGradient,
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
                      _parentReportGeneralTab(report),
                      _parentReportUsageTab(
                        childId: child.childId,
                        reportName: report.name,
                      ),
                      _parentReportActivityTab(report),
                      _parentReportMiniGameTab(report),
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
                      backgroundColor: ParentPalette.primary,
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
  Widget _parentReportGeneralTab(dynamic report) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _ParentSectionTitle(
          title: "Genel Gelişim Özeti",
          subtitle: "Çocuğun uygulamadaki genel ilerlemesi.",
        ),

        const SizedBox(height: 10),

        _ParentInfoTile(
          icon: Icons.star_rounded,
          title: "Toplam Yıldız",
          value: "${report.stars} yıldız toplandı",
          color: ParentPalette.orange,
        ),

        _ParentInfoTile(
          icon: Icons.extension_rounded,
          title: "Toplam Etkinlik",
          value: "${report.totalActivities} etkinlik tamamlandı",
          color: ParentPalette.primary,
        ),

        _ParentInfoTile(
          icon: Icons.today_rounded,
          title: "Günlük Görev",
          value: "${report.dailyCompleted} / ${report.dailyGoal} tamamlandı",
          color: ParentPalette.green,
        ),

        _ParentInfoTile(
          icon: Icons.sports_esports_rounded,
          title: "Mini Oyun Başarıları",
          value: "${report.totalMiniGames} mini oyun tamamlandı",
          color: ParentPalette.orange,
        ),

        const SizedBox(height: 12),

        const _ParentSectionTitle(
          title: "Öğrenme Yorumu",
          subtitle: "En çok ve en az çalışılan alanlar.",
        ),

        const SizedBox(height: 10),

        _ParentInfoTile(
          icon: Icons.emoji_events_rounded,
          title: "En Güçlü Alan",
          value: report.strongestArea.toString(),
          color: ParentPalette.green,
        ),

        _ParentInfoTile(
          icon: Icons.lightbulb_rounded,
          title: "Daha Çok Çalışılacak Alan",
          value: report.needsPracticeArea.toString(),
          color: ParentPalette.orange,
        ),
      ],
    );
  }

  Widget _parentReportUsageTab({
    required String childId,
    required String reportName,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _ParentSectionTitle(
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

  Widget _parentReportActivityTab(dynamic report) {
    final rawStats = report.stats;

    final entries = rawStats is Map
        ? rawStats.entries.toList()
        : <MapEntry<dynamic, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _ParentSectionTitle(
          title: "Etkinlik İstatistikleri",
          subtitle: "Çocuğun hangi alanlarda ne kadar çalıştığını gösterir.",
        ),

        const SizedBox(height: 10),

        if (entries.isEmpty)
          const _ParentSmallEmpty(
            emoji: "📊",
            title: "Henüz istatistik yok",
            subtitle: "Çocuk etkinlik yaptıkça burada görünür.",
          )
        else
          ...entries.map((entry) {
            final value = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;

            return _StatProgressTile(
              title: entry.key.toString(),
              value: value,
            );
          }),
      ],
    );
  }

  Widget _parentReportMiniGameTab(dynamic report) {
    final rawMiniGames = report.miniGameCounts;

    final entries = rawMiniGames is Map
        ? rawMiniGames.entries.toList()
        : <MapEntry<dynamic, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _ParentSectionTitle(
          title: "Mini Oyunlar",
          subtitle: "Kısa oyunlardaki tamamlanma kayıtları.",
        ),

        const SizedBox(height: 10),

        if (entries.isEmpty)
          const _ParentSmallEmpty(
            emoji: "🎮",
            title: "Henüz mini oyun kaydı yok",
            subtitle: "Mini oyun oynadıkça burada görünür.",
          )
        else
          ...entries.map((entry) {
            final value = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;

            return _ParentInfoTile(
              icon: Icons.videogame_asset_rounded,
              title: _parentMiniGameDisplayName(entry.key.toString()),
              value: "$value kez tamamlandı",
              color: ParentPalette.primary,
            );
          }),
      ],
    );
  }

  String _parentMiniGameDisplayName(String key) {
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

  String _miniGameName(String key) {
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

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("Oturum bulunamadı."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ParentPalette.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Geri",
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "Merhaba, $_parentName",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: ParentPalette.mainGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          HelpGuideButton.parent(),
          IconButton(
            tooltip: "Çıkış yap",
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AdultPanelBackground(
        background: ParentPalette.background,
        gradient: ParentPalette.mainGradient,
        child: FutureBuilder<List<_FoundChild>>(
          key: ValueKey(_refreshKey),
          future: _childrenFuture,
            builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ParentEmptyState(
              emoji: "⚠️",
              title: "Çocuk profilleri yüklenemedi",
              subtitle:
              "Bağlantı veya izin sorunu olabilir.\n${snapshot.error}",
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final children = snapshot.data ?? [];

          if (children.isEmpty) {
            return const _ParentEmptyState(
              emoji: "👨‍👩‍👧",
              title: "Henüz çocuk profili yok",
              subtitle:
              "Sağ alttaki butonla çocuğunun Oyuncu ID ve Kurtarma Kodu bilgisini girerek bağlayabilirsin.",
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final future = _loadLinkedChildren();

              setState(() {
                _refreshKey++;
                _childrenFuture = future;
              });

              await future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _ParentSectionTitle(
                  title: "Bağlı Çocuklarım",
                  subtitle:
                  "Çocuğunun yıldızlarını, görevlerini ve gelişimini buradan takip et.",
                ),
                const SizedBox(height: 14),

                ...children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ChildProfileCard(
                      data: child.data,
                      name: _displayName(child.data),
                      onTap: () => _showChildDetail(child),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
        ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: ParentPalette.mainGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: ParentPalette.primary.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.1,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: _showLinkChildDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.link_rounded),
          label: const Text(
            "ÇOCUK BAĞLA",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentDialogHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _ParentDialogHeader({
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
            width: 54,
            height: 54,
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

class _ParentEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _ParentEmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ParentPalette.primary.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 54),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ParentPalette.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ParentSectionTitle({
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
              colors: ParentPalette.mainGradient,
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
                  color: ParentPalette.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
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

class _ChildProfileCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final VoidCallback onTap;

  const _ChildProfileCard({
    required this.data,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stars = data['stars'] is num
        ? (data['stars'] as num).toInt()
        : int.tryParse(data['stars']?.toString() ?? "0") ?? 0;

    final playerId = data['playerId']?.toString() ?? "-";
    final className = data['className']?.toString() ?? "-";
    final themeId = data['activeThemeId']?.toString() ?? "space";

    String emoji = "🚀";
    if (themeId == "rainbow") emoji = "🌈";
    if (themeId == "forest") emoji = "🦁";
    if (themeId == "car") emoji = "🚗";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: ParentPalette.primary.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: ParentPalette.primary.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: ParentPalette.mainGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ParentPalette.dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Oyuncu ID: $playerId",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _SmallBadge(
                            text: "⭐ $stars",
                            color: ParentPalette.orange,
                          ),
                          const SizedBox(width: 6),
                          _SmallBadge(
                            text: className,
                            color: ParentPalette.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: ParentPalette.primary,
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

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _ChildHeroCard extends StatelessWidget {
  final String name;
  final int stars;
  final String playerId;
  final String className;

  const _ChildHeroCard({
    required this.name,
    required this.stars,
    required this.playerId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: ParentPalette.mainGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ParentPalette.primary.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Çocuk Gelişim Özeti",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "⭐ $stars • $className • $playerId",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _ParentInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ParentInfoTile({
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
                    color: ParentPalette.dark,
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

class _StatProgressTile extends StatelessWidget {
  final String title;
  final int value;

  const _StatProgressTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((value / 10).clamp(0.0, 1.0)).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ParentPalette.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ParentPalette.primary.withOpacity(0.10),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: ParentPalette.primary,
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
                    color: ParentPalette.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: ParentPalette.primary.withOpacity(0.10),
                    valueColor: const AlwaysStoppedAnimation(
                      ParentPalette.primary,
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
              color: ParentPalette.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentSmallEmpty extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _ParentSmallEmpty({
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
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 42),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ParentPalette.dark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}


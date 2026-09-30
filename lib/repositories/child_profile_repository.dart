import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_flow_service.dart';

class ChildProfileRepository {
  ChildProfileRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Eski sistemde bu key kullanılmıştı. Silmiyoruz, yeni sisteme taşıyoruz.
  static const String _legacyActiveChildIdKey = "activeChildId";

  static String? get currentUid => _auth.currentUser?.uid;

  static String _generatePlayerId() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return "DLAS-$number";
  }

  static String _generateRecoveryPin() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return number.toString();
  }

  static String _generateRecoveryCode(String pin) {
    const words = [
      "ROKET",
      "YILDIZ",
      "BALON",
      "KEDI",
      "ASLAN",
      "GUNES",
      "AY",
      "CICEK",
      "ELMA",
      "KUS",
    ];

    final random = Random();
    final word = words[random.nextInt(words.length)];

    return "$word-$pin";
  }

  static String _playerIdKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String _normalizePlayerId(String value) {
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

  static Future<String?> getActiveChildId() async {
    final serviceChildId = await SessionFlowService.getActiveChildId();

    if (serviceChildId != null && serviceChildId.trim().isNotEmpty) {
      return serviceChildId.trim();
    }

    // Eski kaydı yeni sisteme taşı.
    final prefs = await SharedPreferences.getInstance();
    final legacyChildId = prefs.getString(_legacyActiveChildIdKey)?.trim();

    if (legacyChildId != null && legacyChildId.isNotEmpty) {
      await SessionFlowService.saveActiveChildId(legacyChildId);
      return legacyChildId;
    }

    return null;
  }

  static Future<void> setActiveChildId(String childId) async {
    final clean = childId.trim();

    if (clean.isEmpty) return;

    await SessionFlowService.saveActiveChildId(clean);
    SessionFlowService.allowChildAutoStart();

    // Eski kodlar hâlâ bu key’i okuyorsa bozulmasın.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_legacyActiveChildIdKey, clean);
  }

  static Future<void> clearActiveChildId() async {
    await SessionFlowService.clearActiveChildId();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyActiveChildIdKey);
  }

  static Map<String, dynamic> _baseChildProfileData({
    required String childId,
    required String uid,
    required Map<String, dynamic> userData,
  }) {
    final oldPlayerId = userData['playerId']?.toString().trim() ?? "";
    final oldRecoveryPin = userData['recoveryPin']?.toString().trim() ?? "";
    final oldRecoveryCode = userData['recoveryCode']?.toString().trim() ?? "";

    final pin = oldRecoveryPin.isNotEmpty ? oldRecoveryPin : _generateRecoveryPin();

    final playerId = oldPlayerId.isNotEmpty
        ? _normalizePlayerId(oldPlayerId)
        : _generatePlayerId();

    final recoveryCode = oldRecoveryCode.isNotEmpty
        ? oldRecoveryCode
        : _generateRecoveryCode(pin);

    final now = FieldValue.serverTimestamp();

    return <String, dynamic>{
      'childId': childId,
      'ownerUid': uid,

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
      'recoveryPin': pin,
      'recoveryCode': recoveryCode,

      'parentIds': userData['parentIds'] ?? [],
      'linkedParentIds': userData['linkedParentIds'] ?? [],
      'teacherIds': userData['teacherIds'] ?? [],
      'teachers': userData['teachers'] ?? [],

      'activeThemeId': userData['activeThemeId'] ?? 'space',
      'activeStickerId':
      userData['activeStickerId'] ?? 'space_starter_roket',
      'activeStickerIdsByTheme': userData['activeStickerIdsByTheme'] ??
          {
            'space': 'space_starter_roket',
            'rainbow': 'rainbow_starter_civciv',
            'forest': 'forest_starter_aslan',
            'car': 'car_starter_araba',
          },
      'ownedStickerIds': userData['ownedStickerIds'] ?? [],

      'stats': userData['stats'] ?? {},
      'stars': userData['stars'] ?? 0,
      'earnedBadges': userData['earnedBadges'] ?? [],

      'lastActivity': userData['lastActivity'],
      'dailyTask': userData['dailyTask'] ?? {},
      'dailyTasks': userData['dailyTasks'] ?? {},
      'miniGames': userData['miniGames'] ?? {},

      'createdAt': userData['createdAt'] ?? now,
      'updatedAt': now,

      'migratedFromUserUid': uid,
      'migrationVersion': 6,
    };
  }

  static Future<DocumentReference<Map<String, dynamic>>>
  _createProfileFromUserDoc({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    final childRef = _db.collection('childProfiles').doc();

    final profileData = _baseChildProfileData(
      childId: childRef.id,
      uid: uid,
      userData: userData,
    );

    await childRef.set(
      profileData,
      SetOptions(merge: true),
    );

    await setActiveChildId(childRef.id);

    await _db.collection('users').doc(uid).set(
      {
        'activeChildId': childRef.id,
        'hasChildProfiles': true,
        'playerId': profileData['playerId'],
        'playerIdNormalized': profileData['playerIdNormalized'],
        'playerIdKey': profileData['playerIdKey'],
        'recoveryPin': profileData['recoveryPin'],
        'recoveryCode': profileData['recoveryCode'],
        'profileSetupDone': profileData['profileSetupDone'],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return childRef;
  }

  static Future<String> ensureActiveChildProfile() async {
    final uid = currentUid;

    if (uid == null) {
      throw Exception("Oturum bulunamadı.");
    }

    final savedChildId = await getActiveChildId();

    if (savedChildId != null && savedChildId.trim().isNotEmpty) {
      final savedDoc =
      await _db.collection('childProfiles').doc(savedChildId).get();

      if (savedDoc.exists) {
        await setActiveChildId(savedChildId);

        await _db.collection('users').doc(uid).set(
          {
            'activeChildId': savedChildId,
            'hasChildProfiles': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await savedDoc.reference.set(
          {
            'lastDeviceUid': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return savedChildId;
      }

      await clearActiveChildId();
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    final userActiveChildId = userData['activeChildId']?.toString().trim() ?? "";

    if (userActiveChildId.isNotEmpty) {
      final userActiveChildDoc =
      await _db.collection('childProfiles').doc(userActiveChildId).get();

      if (userActiveChildDoc.exists) {
        await setActiveChildId(userActiveChildId);

        return userActiveChildId;
      }
    }

    final existing = await _db
        .collection('childProfiles')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final childId = existing.docs.first.id;
      final data = existing.docs.first.data();

      final playerId = data['playerId']?.toString() ?? "";

      await existing.docs.first.reference.set(
        {
          'childId': childId,
          'ownerUid': uid,
          if (playerId.trim().isNotEmpty) 'playerIdNormalized': _normalizePlayerId(playerId),
          if (playerId.trim().isNotEmpty) 'playerIdKey': _playerIdKey(playerId),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await setActiveChildId(childId);

      await _db.collection('users').doc(uid).set(
        {
          'activeChildId': childId,
          'hasChildProfiles': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return childId;
    }

    final childRef = await _createProfileFromUserDoc(
      uid: uid,
      userData: userData,
    );

    await setActiveChildId(childRef.id);

    return childRef.id;
  }

  static Future<Map<String, dynamic>?> getActiveChildProfileData() async {
    final childId = await ensureActiveChildProfile();

    final doc = await _db.collection('childProfiles').doc(childId).get();

    return doc.data();
  }

  static Future<void> updateActiveChildProfile(
      Map<String, dynamic> data,
      ) async {
    final childId = await ensureActiveChildProfile();

    final updateData = {
      ...data,
      'childId': childId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final playerId = updateData['playerId']?.toString() ?? "";

    if (playerId.trim().isNotEmpty) {
      updateData['playerIdNormalized'] = _normalizePlayerId(playerId);
      updateData['playerIdKey'] = _playerIdKey(playerId);
    }

    await _db.collection('childProfiles').doc(childId).set(
      updateData,
      SetOptions(merge: true),
    );

    await setActiveChildId(childId);
  }

  static Future<void> mirrorImportantProfileFieldsToUserDoc() async {
    final uid = currentUid;

    if (uid == null) return;

    final childId = await ensureActiveChildProfile();

    final doc = await _db.collection('childProfiles').doc(childId).get();

    final data = doc.data();

    if (data == null) return;

    final playerId = data['playerId']?.toString() ?? "";

    await _db.collection('users').doc(uid).set(
      {
        'activeChildId': childId,
        'hasChildProfiles': true,

        'nickname': data['nickname'] ?? '',
        'ageGroup': data['ageGroup'] ?? '',
        'className': data['className'] ?? '',

        'playerId': playerId,
        'playerIdNormalized': _normalizePlayerId(playerId),
        'playerIdKey': _playerIdKey(playerId),
        'recoveryPin': data['recoveryPin'] ?? '',
        'recoveryCode': data['recoveryCode'] ?? '',

        'activeThemeId': data['activeThemeId'] ?? 'space',
        'activeStickerId': data['activeStickerId'] ?? '',
        'activeStickerIdsByTheme': data['activeStickerIdsByTheme'] ?? {},

        'ownedStickerIds': data['ownedStickerIds'] ?? [],
        'stars': data['stars'] ?? 0,
        'stats': data['stats'] ?? {},
        'earnedBadges': data['earnedBadges'] ?? [],

        'lastActivity': data['lastActivity'],
        'dailyTask': data['dailyTask'] ?? {},
        'dailyTasks': data['dailyTasks'] ?? {},
        'miniGames': data['miniGames'] ?? {},

        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await setActiveChildId(childId);
  }

  static Future<void> syncUserDocToActiveChildProfile() async {
    final uid = currentUid;

    if (uid == null) return;

    final childId = await ensureActiveChildProfile();

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    final childDoc = await _db.collection('childProfiles').doc(childId).get();
    final childData = childDoc.data() ?? {};

    final rawPlayerId =
        userData['playerId'] ?? childData['playerId'] ?? _generatePlayerId();

    final playerId = _normalizePlayerId(rawPlayerId.toString());

    final pin = (userData['recoveryPin'] ??
        childData['recoveryPin'] ??
        _generateRecoveryPin())
        .toString();

    final recoveryCode = (userData['recoveryCode'] ??
        childData['recoveryCode'] ??
        _generateRecoveryCode(pin))
        .toString();

    await _db.collection('childProfiles').doc(childId).set(
      {
        'childId': childId,
        'ownerUid': uid,

        'parentIds': userData['parentIds'] ?? childData['parentIds'] ?? [],
        'linkedParentIds':
        userData['linkedParentIds'] ?? childData['linkedParentIds'] ?? [],
        'teacherIds': userData['teacherIds'] ?? childData['teacherIds'] ?? [],
        'teachers': userData['teachers'] ?? childData['teachers'] ?? [],

        'role': 'student',
        'profileType': 'child',
        'isAnonymousChild':
        userData['isAnonymousChild'] ?? childData['isAnonymousChild'] ?? true,
        'profileSetupDone':
        userData['profileSetupDone'] ?? childData['profileSetupDone'] ?? false,

        'name': userData['name'] ??
            childData['name'] ??
            userData['nickname'] ??
            childData['nickname'] ??
            'Arkadaşım',
        'displayName': userData['displayName'] ??
            childData['displayName'] ??
            userData['nickname'] ??
            childData['nickname'] ??
            'Arkadaşım',
        'nickname': userData['nickname'] ?? childData['nickname'] ?? '',
        'surname': userData['surname'] ?? childData['surname'] ?? '',
        'ageGroup': userData['ageGroup'] ?? childData['ageGroup'] ?? '',
        'className': userData['className'] ?? childData['className'] ?? '',

        'playerId': playerId,
        'playerIdNormalized': playerId,
        'playerIdKey': _playerIdKey(playerId),
        'recoveryPin': pin,
        'recoveryCode': recoveryCode,

        'activeThemeId':
        userData['activeThemeId'] ?? childData['activeThemeId'] ?? 'space',
        'activeStickerId': userData['activeStickerId'] ??
            childData['activeStickerId'] ??
            'space_starter_roket',
        'activeStickerIdsByTheme': userData['activeStickerIdsByTheme'] ??
            childData['activeStickerIdsByTheme'] ??
            {},
        'ownedStickerIds':
        userData['ownedStickerIds'] ?? childData['ownedStickerIds'] ?? [],

        'stats': userData['stats'] ?? childData['stats'] ?? {},
        'stars': userData['stars'] ?? childData['stars'] ?? 0,
        'earnedBadges':
        userData['earnedBadges'] ?? childData['earnedBadges'] ?? [],

        'lastActivity': userData['lastActivity'] ?? childData['lastActivity'],
        'dailyTask': userData['dailyTask'] ?? childData['dailyTask'] ?? {},
        'dailyTasks': userData['dailyTasks'] ?? childData['dailyTasks'] ?? {},
        'miniGames': userData['miniGames'] ?? childData['miniGames'] ?? {},

        'migrationVersion': 6,
        'syncedFromUserDocAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _db.collection('users').doc(uid).set(
      {
        'activeChildId': childId,
        'hasChildProfiles': true,
        'playerId': playerId,
        'playerIdNormalized': playerId,
        'playerIdKey': _playerIdKey(playerId),
        'recoveryPin': pin,
        'recoveryCode': recoveryCode,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await setActiveChildId(childId);
  }
}
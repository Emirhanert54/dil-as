import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_flow_service.dart';
import 'login_page.dart' hide ParentHome;
import 'parent_home.dart' as parent;
import 'student_home.dart';
import 'teacher_home.dart';
import '../widgets/common/portrait_only_wrapper.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SessionFlowService.forceAdultLogin,
      builder: (context, forceAdultLogin, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            // ÖNEMLİ:
            // Öğrenci anonim girişli olsa bile öğretmen/ebeveyn paneline geçmek isterse
            // direkt yetişkin giriş sayfasını geri tuşlu aç.
            if (forceAdultLogin) {
              return const LoginPage(
                showBackToStudent: true,
              );
            }

            final user = snapshot.data;

            if (user == null) {
              return const _AnonymousStudentStarter();
            }

            return _RoleRouter(
              uid: user.uid,
              isAnonymous: user.isAnonymous,
            );
          },
        );
      },
    );
  }
}

class _AnonymousStudentStarter extends StatefulWidget {
  const _AnonymousStudentStarter();

  @override
  State<_AnonymousStudentStarter> createState() =>
      _AnonymousStudentStarterState();
}

class _AnonymousStudentStarterState extends State<_AnonymousStudentStarter> {
  bool _started = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAnonymousStudent();
  }

  Future<void> _startAnonymousStudent() async {
    if (_started) return;

    _started = true;

    try {
      SessionFlowService.allowChildAutoStart();

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final credential = await auth.signInAnonymously();
      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'anonymous-failed',
          message: 'Anonim çocuk profili başlatılamadı.',
        );
      }

      final savedChildId = await SessionFlowService.getActiveChildId();

      if (savedChildId != null && savedChildId.trim().isNotEmpty) {
        final childDoc = await firestore
            .collection('childProfiles')
            .doc(savedChildId.trim())
            .get();

        if (childDoc.exists && childDoc.data() != null) {
          final childData = childDoc.data()!;

          await firestore.collection('users').doc(user.uid).set(
            _studentUserMirrorFromChild(
              uid: user.uid,
              childId: childDoc.id,
              childData: childData,
            ),
            SetOptions(merge: true),
          );

          await childDoc.reference.set(
            {
              'lastDeviceUid': user.uid,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          return;
        }

        await SessionFlowService.clearActiveChildId();
      }

      final ref = firestore.collection('users').doc(user.uid);
      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set(
          _defaultAnonymousStudentData(uid: user.uid),
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _AuthErrorScreen(
        message: "Çocuk profili başlatılamadı.",
        detail: _error!,
      );
    }

    return const _SplashScreen();
  }
}

class _RoleRouter extends StatelessWidget {
  final String uid;
  final bool isAnonymous;

  const _RoleRouter({
    required this.uid,
    required this.isAnonymous,
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadOrCreateProfile() async {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('users').doc(uid);

    var doc = await ref.get();

    if (isAnonymous) {
      final savedChildId = await SessionFlowService.getActiveChildId();

      if (savedChildId != null && savedChildId.trim().isNotEmpty) {
        final data = doc.data() ?? {};
        final role = data['role']?.toString() ?? '';
        final activeChildId = data['activeChildId']?.toString().trim() ?? '';

        final shouldRepairStudentDoc =
            !doc.exists ||
                role == 'student' ||
                role.isEmpty ||
                activeChildId.isEmpty;

        if (shouldRepairStudentDoc) {
          final childDoc = await firestore
              .collection('childProfiles')
              .doc(savedChildId.trim())
              .get();

          if (childDoc.exists && childDoc.data() != null) {
            final childData = childDoc.data()!;

            await ref.set(
              _studentUserMirrorFromChild(
                uid: uid,
                childId: childDoc.id,
                childData: childData,
              ),
              SetOptions(merge: true),
            );

            await childDoc.reference.set(
              {
                'lastDeviceUid': uid,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            doc = await ref.get();
          } else {
            await SessionFlowService.clearActiveChildId();
          }
        }
      }
    }

    if (!doc.exists && isAnonymous) {
      await ref.set(
        _defaultAnonymousStudentData(uid: uid),
        SetOptions(merge: true),
      );

      doc = await ref.get();
    }

    if (doc.exists) {
      final data = doc.data() ?? {};
      final role = data['role']?.toString();

      if (role == 'student') {
        final activeChildId = data['activeChildId']?.toString().trim() ?? "";

        if (activeChildId.isNotEmpty) {
          await SessionFlowService.saveActiveChildId(activeChildId);
        }
      }
    }

    return doc;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _loadOrCreateProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasError) {
          return _AuthErrorScreen(
            message: "Kullanıcı bilgileri alınamadı.",
            detail: snapshot.error.toString(),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _AuthErrorScreen(
            message: "Bu hesaba ait kullanıcı profili bulunamadı.",
            detail: "Lütfen çıkış yapıp tekrar giriş yapın.",
          );
        }

        final data = snapshot.data!.data() ?? {};
        final role = data['role']?.toString();

        if (role == 'teacher') {
          return const PortraitOnlyWrapper(
            child: TeacherHome(),
          );
        }

        if (role == 'parent') {
          return const PortraitOnlyWrapper(
            child: parent.ParentHome(),
          );
        }

        if (role == 'student') {
          return const StudentHome();
        }

        return _AuthErrorScreen(
          message: "Kullanıcı rolü tanınamadı.",
          detail: "Bulunan rol: $role",
        );
      },
    );
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

Map<String, dynamic> _studentUserMirrorFromChild({
  required String uid,
  required String childId,
  required Map<String, dynamic> childData,
}) {
  final rawPlayerId = childData['playerId']?.toString() ?? '';
  final playerId = rawPlayerId.trim().isEmpty
      ? ''
      : _normalizePlayerId(rawPlayerId);

  return {
    'uid': uid,
    'role': 'student',
    'accountType': 'student',
    'mode': 'individual',
    'isAnonymousChild': true,

    'activeChildId': childId,
    'hasChildProfiles': true,
    'profileSetupDone': true,

    'name': childData['name'] ?? childData['nickname'] ?? 'Arkadaşım',
    'displayName':
    childData['displayName'] ?? childData['nickname'] ?? 'Arkadaşım',
    'nickname': childData['nickname'] ?? '',
    'surname': childData['surname'] ?? '',
    'ageGroup': childData['ageGroup'] ?? '',
    'className': childData['className'] ?? '',

    'playerId': playerId,
    'playerIdNormalized': childData['playerIdNormalized'] ?? playerId,
    'playerIdKey': childData['playerIdKey'] ?? _playerIdKey(playerId),
    'recoveryPin': childData['recoveryPin'] ?? '',
    'recoveryCode': childData['recoveryCode'] ?? '',

    'activeThemeId': childData['activeThemeId'] ?? 'space',
    'activeStickerId':
    childData['activeStickerId'] ?? 'space_starter_roket',
    'activeStickerIdsByTheme': childData['activeStickerIdsByTheme'] ?? {},
    'ownedStickerIds': childData['ownedStickerIds'] ?? [],

    'stars': childData['stars'] ?? 0,
    'stats': childData['stats'] ?? {},
    'earnedBadges': childData['earnedBadges'] ?? [],

    'dailyTask': childData['dailyTask'] ?? {},
    'dailyTasks': childData['dailyTasks'] ?? {},
    'miniGames': childData['miniGames'] ?? {},
    'lastActivity': childData['lastActivity'],

    'teachers': childData['teachers'] ?? [],
    'teacherIds': childData['teacherIds'] ?? [],
    'parentIds': childData['parentIds'] ?? [],
    'linkedParentIds': childData['linkedParentIds'] ?? [],

    'updatedAt': FieldValue.serverTimestamp(),
  };
}

Map<String, dynamic> _defaultAnonymousStudentData({
  required String uid,
}) {
  return {
    'uid': uid,
    'role': 'student',
    'accountType': 'student',
    'mode': 'individual',
    'isAnonymousChild': true,
    'profileSetupDone': false,

    'name': 'Arkadaşım',
    'displayName': 'Arkadaşım',
    'nickname': '',
    'surname': '',
    'ageGroup': '',
    'className': '',

    'teachers': [],
    'teacherIds': [],
    'parentIds': [],
    'linkedParentIds': [],

    'stats': {},
    'stars': 0,
    'earnedBadges': [],

    'ownedStickerIds': [],
    'activeThemeId': 'space',
    'activeStickerId': 'space_starter_roket',
    'activeStickerIdsByTheme': {
      'space': 'space_starter_roket',
      'rainbow': 'rainbow_starter_civciv',
      'forest': 'forest_starter_aslan',
      'car': 'car_starter_araba',
    },

    'dailyTask': {
      'date': '',
      'completed': 0,
      'bonusClaimed': false,
    },

    'dailyTasks': {},
    'miniGames': {},
    'lastActivity': null,

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF172033),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 72,
            ),
            SizedBox(height: 20),
            Text(
              "DİL-AS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;
  final String detail;

  const _AuthErrorScreen({
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        SessionFlowService.goToAdultLogin();

                        try {
                          await FirebaseAuth.instance.signOut();
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Çıkış Yap"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';
import 'dart:math';
import '../services/ad_manager.dart';
import '../widgets/banner_ad_widget.dart'; // Dosya yolunu kendi klasörüne göre ayarla
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_manager.dart';
import '../widgets/common/help_guide_button.dart';
import 'login_page.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../repositories/game_repository.dart';
import '../screens/student/activities_screen.dart';
import '../screens/student/child_onboarding_dialog.dart';
import '../screens/student/student_settings_screen.dart';
import '../screens/student/student_workspace.dart';
import '../services/voice_service.dart';
import '../widgets/common/kid_answer_button.dart';
import '../widgets/common/kid_choice_chip.dart';
import '../widgets/common/themed_background.dart';
import '../widgets/game/game_completion_screen.dart';
import '../widgets/game/game_mascot_card.dart';
import '../widgets/home/home_mascot_header.dart';
import '../widgets/home/home_notification_card.dart';
import '../widgets/home/home_progress_grid.dart';
import '../widgets/home/home_summary_grid.dart';
import '../widgets/home/student_drawer.dart';
import '../widgets/home/student_error_screen.dart';
import '../widgets/home/student_loading_screen.dart';
import '../widgets/home/home_daily_tasks_card.dart';
import '../repositories/daily_task_repository.dart';
import '../screens/student/mini_games_screen.dart';
import '../repositories/child_profile_repository.dart';
import '../core/responsive.dart';
import '../widgets/common/joy_motion.dart';
import '../repositories/usage_time_repository.dart';
import '../widgets/common/elapsed_time_pill.dart';

class HomeNotificationCard extends StatelessWidget {
  const HomeNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<String>(
        future: ChildProfileRepository.ensureActiveChildProfile(),
        builder: (context, childSnapshot) {
          if (!childSnapshot.hasData) return const SizedBox.shrink();
          final childId = childSnapshot.data!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('childProfiles').doc(childId).snapshots(),
              builder: (context, childProfileSnapshot) {
                if (!childProfileSnapshot.hasData) return const SizedBox.shrink();

                final childData = childProfileSnapshot.data!.data() ?? {};
                final className = childData['className']?.toString() ?? "";
                final rawTeachers = childData['teachers'] ?? childData['teacherIds'];

                final allowedTeacherIds = rawTeachers is List
                    ? rawTeachers.map((e) => e.toString()).toSet()
                    : <String>{};

                if (className.isEmpty) return const SizedBox.shrink();

                return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('lessons').where('className', isEqualTo: className).snapshots(),
                    builder: (context, lessonSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('announcements').where('className', isEqualTo: className).snapshots(),
                          builder: (context, annSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('messages').snapshots(),
                                builder: (context, userMsgSnapshot) {

                                  final lessonDocs = lessonSnapshot.data?.docs ?? [];
                                  final annDocs = annSnapshot.data?.docs ?? [];
                                  final userMsgDocs = userMsgSnapshot.data?.docs ?? [];

                                  // 1. ÖDEVLERİ HESAPLA
                                  int pendingLessonCount = 0;
                                  String? latestLessonTitle;
                                  for (final doc in lessonDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final teacherId = data['teacherId']?.toString();
                                    if (allowedTeacherIds.isNotEmpty && teacherId != null && !allowedTeacherIds.contains(teacherId)) continue;

                                    final targetType = data['targetType']?.toString() ?? 'class';
                                    final assignedChildIds = data['assignedChildIds'] as List?;
                                    if (targetType == 'child' && assignedChildIds != null && !assignedChildIds.contains(childId)) continue;

                                    final completedBy = data['completedBy'] is List ? List<String>.from((data['completedBy'] as List).map((e) => e.toString())) : <String>[];
                                    final completedByChildId = data['completedByChildId'] is List ? List<String>.from((data['completedByChildId'] as List).map((e) => e.toString())) : <String>[];
                                    final completedByUid = data['completedByUid'] is List ? List<String>.from((data['completedByUid'] as List).map((e) => e.toString())) : <String>[];

                                    final isCompleted = completedBy.contains(childId) || completedBy.contains(uid) || completedByChildId.contains(childId) || completedByUid.contains(uid);

                                    bool isExpired = false;
                                    if (data['dueDate'] is Timestamp) {
                                      final dueDate = (data['dueDate'] as Timestamp).toDate();
                                      if (!isCompleted && DateTime.now().isAfter(dueDate)) isExpired = true;
                                    }

                                    if (!isCompleted && !isExpired) {
                                      pendingLessonCount++;
                                      if (latestLessonTitle == null) {
                                        latestLessonTitle = data['gameKey']?.toString() ?? data['title']?.toString();
                                      }
                                    }
                                  }

                                  // 2. MESAJLARI HESAPLA (YENİ SİSTEM)
                                  int unreadMessageCount = 0;
                                  final Set<String> processedMessageIds = {};

                                  for (final doc in annDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final teacherId = data['teacherId']?.toString() ?? '';

// Eski mesajlarda teacherId boş kalmışsa engellememek için teacherId.isNotEmpty şartı eklendi:
                                    if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                                    final targetType = data['targetType']?.toString() ?? 'class';
                                    final targetChildId = data['targetChildId']?.toString().trim() ?? '';
                                    final msgChildId = data['childId']?.toString().trim() ?? '';

                                    // Özel mesajsa, hedef kimliklerden biri bizimle uyuşuyorsa göster
                                    if (targetType == 'child') {
                                      bool isMe = (targetChildId == childId || targetChildId == uid) ||
                                          (msgChildId == childId || msgChildId == uid);
                                      if (!isMe) continue;
                                    }

                                    final seenBy = data['seenBy'] is List ? (data['seenBy'] as List).map((e) => e.toString()).toList() : [];
                                    if (!seenBy.contains(childId)) {
                                      unreadMessageCount++;
                                      processedMessageIds.add(doc.id);
                                    }
                                  }

                                  for (final doc in userMsgDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final msgId = data['messageId']?.toString().isNotEmpty == true ? data['messageId']! : doc.id;

                                    if (processedMessageIds.contains(msgId)) continue;

                                    final teacherId = data['teacherId']?.toString() ?? '';

// Eski mesajlarda teacherId boş kalmışsa engellememek için teacherId.isNotEmpty şartı eklendi:
                                    if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                                    final seenBy = data['seenBy'] is List ? (data['seenBy'] as List).map((e) => e.toString()).toList() : [];
                                    if (!seenBy.contains(childId)) {
                                      unreadMessageCount++;
                                      processedMessageIds.add(msgId);
                                    }
                                  }

                                  if (pendingLessonCount == 0 && unreadMessageCount == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return _NotificationPanel(
                                    uid: uid,
                                    gradient: u.currentTheme.gradient,
                                    mascotEmoji: u.currentMascot.emoji,
                                    pendingLessonCount: pendingLessonCount,
                                    latestLessonTitle: latestLessonTitle,
                                    unreadMessageCount: unreadMessageCount,
                                  );
                                }
                            );
                          }
                      );
                    }
                );
              }
          );
        }
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final String uid;
  final List<Color> gradient;
  final String mascotEmoji;
  final int pendingLessonCount;
  final String? latestLessonTitle;
  final int unreadMessageCount;

  const _NotificationPanel({
    required this.uid,
    required this.gradient,
    required this.mascotEmoji,
    required this.pendingLessonCount,
    required this.latestLessonTitle,
    required this.unreadMessageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first,
            gradient.last,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    mascotEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bugün seni bekleyenler var!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Ödevlerini ve mesajlarını buradan hızlıca görebilirsin.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (pendingLessonCount > 0)
            _AlertRow(
              icon: Icons.assignment_rounded,
              title: "$pendingLessonCount yeni ödevin var",
              subtitle: latestLessonTitle ?? "Ödevlerini görmek için dokun.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentWorkSpace(initialIndex: 0),
                  ),
                );
              },
            ),

          if (pendingLessonCount > 0 && unreadMessageCount > 0)
            const SizedBox(height: 10),

          if (unreadMessageCount > 0)
            _AlertRow(
              icon: Icons.mark_email_unread_rounded,
              title: "$unreadMessageCount yeni mesajın var",
              subtitle: "Öğretmeninden gelen mesajları görüntüle.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentWorkSpace(initialIndex: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AlertRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
                child: Icon(
                  icon,
                  color: const Color(0xFF6C63FF),
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
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF6C63FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 ANA EKRAN - SON ETKİNLİKTEN DEVAM ET
Future<void> openLastActivityFromHome({
  required BuildContext context,
  required dynamic lastActivity,
  String? dailyTaskId,
}) async {
  String clean(String value) {
    return value
        .toLowerCase()
        .replaceAll("ı", "i")
        .replaceAll("ğ", "g")
        .replaceAll("ü", "u")
        .replaceAll("ş", "s")
        .replaceAll("ö", "o")
        .replaceAll("ç", "c")
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String normalizeGameType(String value) {
    final v = value.trim();

    if (clean(v) == clean("Hızlı Gör")) return "Hız";
    if (clean(v) == clean("Hizli Gor")) return "Hız";
    if (clean(v) == clean("Hız")) return "Hız";

    return v;
  }

  final raw = (lastActivity ?? "").toString().trim();

  if (raw.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Son oynanan bölüm bulunamadı."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final gameTypes = [
    "Heceleme",
    "Tanıma",
    "Hız",
    "Bellek",
    "Yazma",
    "Hikaye",
    "Sesler",
    "Okuma",
  ];

  String? foundGameType;
  String? foundLevelTitle;

  if (lastActivity is Map) {
    final mapGameType = lastActivity['gameType']?.toString();
    final mapLevelTitle =
        lastActivity['levelTitle']?.toString() ??
            lastActivity['title']?.toString() ??
            lastActivity['level']?.toString();

    if (mapGameType != null && mapLevelTitle != null) {
      foundGameType = normalizeGameType(mapGameType);
      foundLevelTitle = mapLevelTitle.trim();
    }
  }

  if ((foundGameType == null || foundLevelTitle == null) && raw.contains(":")) {
    final parts = raw.split(":");

    foundGameType = normalizeGameType(parts.first.trim());
    foundLevelTitle = parts.sublist(1).join(":").trim();
  }

  if (foundGameType == null || foundLevelTitle == null) {
    final rawKey = clean(raw);

    for (final gameType in gameTypes) {
      final levels = GameRepository.getLevels(gameType);

      for (final item in levels) {
        final level = Map<String, dynamic>.from(item);
        final title = level['title']?.toString().trim() ?? "";

        final titleKey = clean(title);
        final fullKey = clean("$gameType $title");
        final fullKey2 = clean("$gameType:$title");

        final matched = rawKey == titleKey ||
            rawKey == fullKey ||
            rawKey == fullKey2 ||
            rawKey.contains(titleKey) ||
            titleKey.contains(rawKey);

        if (matched) {
          foundGameType = gameType;
          foundLevelTitle = title;
          break;
        }
      }

      if (foundGameType != null && foundLevelTitle != null) {
        break;
      }
    }
  }

  if (foundGameType == null || foundLevelTitle == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Son oynanan bölüm bulunamadı: $raw"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final levels = GameRepository.getLevels(foundGameType);

  Map<String, dynamic>? selectedLevel;

  for (final item in levels) {
    final level = Map<String, dynamic>.from(item);
    final title = level['title']?.toString().trim() ?? "";

    if (clean(title) == clean(foundLevelTitle)) {
      selectedLevel = level;
      break;
    }
  }

  if (selectedLevel == null || selectedLevel['questions'] is! List) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bölüm bulundu ama soruları açılamadı: $foundLevelTitle"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final rawQuestions = List<Map<String, dynamic>>.from(
    (selectedLevel['questions'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
    ),
  );

  final questions = GameRepository.prepareRandomQuestions(rawQuestions);
  final gameKey = "$foundGameType: $foundLevelTitle";

  late Widget gameScreen;

  switch (foundGameType) {
    case 'Heceleme':
      gameScreen = GameSyllable(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Tanıma':
      gameScreen = GameRecognition(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Hız':
    case 'Hızlı Gör':
      gameScreen = GameSpeed(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Bellek':
      gameScreen = GameMemory(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Yazma':
      gameScreen = GameSpelling(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Hikaye':
      gameScreen = GameStory(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Sesler':
      gameScreen = GameSound(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    case 'Okuma':
      gameScreen = GameReading(
        questions: questions,
        gameKey: gameKey,
        initialStep: 0,
      );
      break;

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Etkinlik açılamadı: $foundGameType"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      settings: RouteSettings(
        arguments: {
          if (dailyTaskId != null) 'dailyTaskId': dailyTaskId,
        },
      ),
      builder: (_) => gameScreen,
    ),
  );
}

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      await ChildProfileRepository.ensureActiveChildProfile();

      await ChildProfileRepository.syncUserDocToActiveChildProfile();

      await context.read<AppProvider>().loadFromFirebase();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = "Öğrenci bilgileri yüklenemedi.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StudentLoadingScreen();
    }

    if (_errorMessage != null) {
      return StudentLoadErrorScreen(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });

          _loadStudentData();
        },
      );
    }

    return const Dashboard();
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}


class _DashboardState extends State<Dashboard> {
  StreamSubscription? _notificationSub;
  bool _childOnboardingChecked = false;
  int _dailyTasksRefreshKey = 0;
  Map<String, dynamic>? _freshLastActivity;
  Future<void> _syncDailyTasksOnStart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await DailyTaskRepository.ensureDailyTasks(uid: uid);

      if (!mounted) return;

      await context.read<AppProvider>().loadFromFirebase();

      if (!mounted) return;

      setState(() {
        _dailyTasksRefreshKey++;
      });
    } catch (_) {}
  }
  Map<String, dynamic>? _normalizeLastActivity(dynamic value) {
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);

    final gameType = map['gameType']?.toString().trim() ?? "";
    final levelTitle = map['levelTitle']?.toString().trim() ?? "";
    final title = map['title']?.toString().trim() ?? "";
    final gameKey = map['gameKey']?.toString().trim() ?? "";

    if (gameType.isEmpty &&
        levelTitle.isEmpty &&
        title.isEmpty &&
        gameKey.isEmpty) {
      return null;
    }

    return map;
  }
  bool _hasUsableLastActivity(dynamic lastActivity) {
    return _normalizeLastActivity(lastActivity) != null;
  }

  Future<void> _refreshLastActivityFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data() ?? {};
      final fresh = _normalizeLastActivity(data['lastActivity']);

      if (!mounted) return;

      setState(() {
        _freshLastActivity = fresh;
      });

      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
    _syncDailyTasksOnStart();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshLastActivityFromFirestore();
    });
  }

  @override
  void dispose() {
    VoiceService.instance.stop();
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _checkChildOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};

    final profileSetupDone = data['profileSetupDone'] == true;
    final nickname = data['nickname']?.toString() ?? "";
    final ageGroup = data['ageGroup']?.toString() ?? "";
    final playerId = data['playerId']?.toString() ?? "";

    final needsSetup = !profileSetupDone ||
        nickname.isEmpty ||
        ageGroup.isEmpty ||
        playerId.isEmpty;

    if (!needsSetup) return;
    if (!mounted) return;

    await showChildOnboardingDialog(context);

    if (!mounted) return;

    await context.read<AppProvider>().loadFromFirebase();

    await ChildProfileRepository.syncUserDocToActiveChildProfile();

    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _openDailyTasksSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: HomeDailyTasksCard(
              key: ValueKey(_dailyTasksRefreshKey),
              onOpenTask: (task) async {
                Navigator.pop(sheetContext);

                await Future.delayed(
                  const Duration(milliseconds: 180),
                );

                if (!mounted) return;

                await openLastActivityFromHome(
                  context: context,
                  dailyTaskId: task['id']?.toString(),
                  lastActivity: {
                    'gameType': task['gameType'],
                    'levelTitle': task['levelTitle'],
                    'step': 0,
                  },
                );

                if (!mounted) return;

                await context.read<AppProvider>().loadFromFirebase();

                if (!mounted) return;

                setState(() {
                  _dailyTasksRefreshKey++;
                });
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    await context.read<AppProvider>().loadFromFirebase();

    if (!mounted) return;

    setState(() {
      _dailyTasksRefreshKey++;
    });
  }

  void _listenForNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final u = Provider.of<AppProvider>(context, listen: false);

      if (u.className.isEmpty) return;

      _notificationSub?.cancel();

      _notificationSub = FirebaseFirestore.instance
          .collection('lessons')
          .where('className', isEqualTo: u.className)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isEmpty) return;

        final data = snapshot.docs.first.data();
        final Timestamp ts = data['createdAt'] ?? Timestamp.now();

        final isNew = ts.toDate().isAfter(
          DateTime.now().subtract(
            const Duration(seconds: 10),
          ),
        );

        if (!isNew) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔔 YENİ ÖDEV: ${data['title']}"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "BAK",
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentWorkSpace(),
                  ),
                );
              },
            ),
          ),
        );

        Provider.of<AppProvider>(context, listen: false).speak(
          "Yeni bir ödevin var!",
        );
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    final u = Provider.of<AppProvider>(context);
    final r = AppResponsive.of(context);

    final currentLastActivity =
        _normalizeLastActivity(u.lastActivity) ?? _freshLastActivity;

    final hasContinueActivity = _hasUsableLastActivity(currentLastActivity);

    if (!_childOnboardingChecked) {
      _childOnboardingChecked = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkChildOnboarding();
      });
    }

    final headerHeight = r.responsiveValue(
      phonePortrait: 185,
      phoneLandscape: 195,
      tabletPortrait: 210,
      tabletLandscape: 215,
      largeTabletPortrait: 230,
      largeTabletLandscape: 225,
    );

    final bodyPadding = EdgeInsets.fromLTRB(
      r.responsiveValue(
        phonePortrait: 16,
        phoneLandscape: 24,
        tabletPortrait: 22,
        tabletLandscape: 28,
        largeTabletPortrait: 26,
        largeTabletLandscape: 30,
      ),
      r.responsiveValue(
        phonePortrait: 16,
        phoneLandscape: 12,
        tabletPortrait: 22,
        tabletLandscape: 14,
        largeTabletPortrait: 26,
        largeTabletLandscape: 16,
      ),
      r.responsiveValue(
        phonePortrait: 20,
        phoneLandscape: 24,
        tabletPortrait: 30,
        tabletLandscape: 34,
        largeTabletPortrait: 42,
        largeTabletLandscape: 46,
      ),
      r.responsiveValue(
        phonePortrait: 24,
        phoneLandscape: 18,
        tabletPortrait: 30,
        tabletLandscape: 20,
        largeTabletPortrait: 34,
        largeTabletLandscape: 22,
      ),
    );

    final maxWidth = r.responsiveValue(
      phonePortrait: 520,
      phoneLandscape: 1050,
      tabletPortrait: 720,
      tabletLandscape: 1220,
      largeTabletPortrait: 820,
      largeTabletLandscape: 1320,
    );

    final buttonHeight = r.responsiveValue(
      phonePortrait: 56,
      phoneLandscape: 64,
      tabletPortrait: 68,
      tabletLandscape: 92,
      largeTabletPortrait: 72,
      largeTabletLandscape: 98,
    );

    final buttonTextSize = r.responsiveValue(
      phonePortrait: 15,
      phoneLandscape: 14,
      tabletPortrait: 16,
      tabletLandscape: 18,
      largeTabletPortrait: 17,
      largeTabletLandscape: 19,
    );

    final gap = 8.0;

    Widget activitiesButton() {
      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ActivitiesScreen(),
              ),
            );

            if (!mounted) return;

            await _refreshLastActivityFromFirestore();
          },
          icon: const Icon(Icons.sports_esports_rounded),
          label: Text(
            "Tüm Etkinliklere Git",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: buttonTextSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: u.currentTheme.gradient.first,
            foregroundColor: Colors.white,
            elevation: 5,
            shadowColor: u.currentTheme.gradient.first.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.isLandscape ? 18 : 22),
            ),
          ),
        ),
      );
    }

    Widget miniGamesButton() {
      return SizedBox(
        width: double.infinity,
        height: r.isLandscape ? buttonHeight : 54,
        child: OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MiniGamesScreen(),
              ),
            );

            if (!mounted) return;

            await context.read<AppProvider>().loadFromFirebase();
          },
          icon: const Icon(Icons.videogame_asset_rounded),
          label: Text(
            "Mini Oyunlar",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: buttonTextSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: u.currentTheme.gradient.first,
            backgroundColor: Colors.white.withOpacity(0.92),
            side: BorderSide(
              color: u.currentTheme.gradient.first.withOpacity(0.25),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.isLandscape ? 18 : 22),
            ),
          ),
        ),
      );
    }
    Widget actionButtons() {
      if (r.isLandscape) {
        return Row(
          children: [
            Expanded(
              child: activitiesButton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: miniGamesButton(),
            ),
          ],
        );
      }

      return Column(
        children: [
          activitiesButton(),
          const SizedBox(height: 12),
          miniGamesButton(),
        ],
      );
    }

    final progressGrid = HomeProgressGrid(
      completed: u.dailyCompleted,
      goal: AppProvider.dailyGoal,
      bonusClaimed: u.dailyBonusClaimed,
      lastActivity: currentLastActivity,
      onDailyTaskTap: _openDailyTasksSheet,
      onContinueTap: hasContinueActivity
          ? () async {
        await openLastActivityFromHome(
          context: context,
          lastActivity: currentLastActivity,
        );

        if (!mounted) return;

        await _refreshLastActivityFromFirestore();
      }
          : null,
    );

    final portraitContent = Column(
      children: [
        const HomeSummaryGrid(),

        SizedBox(height: gap),

        progressGrid,

        const _HomeIncomingAlertCard(topGap: 8),

        SizedBox(height: gap),

        activitiesButton(),

        SizedBox(height: gap),

        miniGamesButton(),
      ],
    );

    final landscapeContent = Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: HomeSummaryGrid(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: progressGrid,
            ),
          ],
        ),

        const _HomeIncomingAlertCard(topGap: 8),

        SizedBox(height: gap),

        Row(
          children: [
            Expanded(
              child: activitiesButton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: miniGamesButton(),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: headerHeight,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              HelpGuideButton.student(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: "Ayarlar",
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    showStudentSettingsDialog(context);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: u.currentTheme.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.isLandscape ? 22 : 18,
                      r.isLandscape ? 78 : 46,
                      r.isLandscape ? 22 : 18,
                      r.isLandscape ? 18 : 16,
                    ),
                    child: const HomeMascotHeader(),
                  ),
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: true,
            child: ThemedBackground(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: bodyPadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                      ),
                      child: r.isLandscape ? landscapeContent : portraitContent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: BannerReklamWidget(),
      ),
    );
  }
}
class _HomeIncomingAlertCard extends StatelessWidget {
  final double topGap;

  const _HomeIncomingAlertCard({
    this.topGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return FutureBuilder<String>(
        future: ChildProfileRepository.ensureActiveChildProfile(),
        builder: (context, childSnapshot) {
          if (!childSnapshot.hasData) return const SizedBox.shrink();
          final childId = childSnapshot.data!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('childProfiles').doc(childId).snapshots(),
              builder: (context, childProfileSnapshot) {
                if (!childProfileSnapshot.hasData) return const SizedBox.shrink();

                final childData = childProfileSnapshot.data!.data() ?? {};
                final className = childData['className']?.toString() ?? "";
                final rawTeachers = childData['teachers'] ?? childData['teacherIds'];

                final allowedTeacherIds = rawTeachers is List
                    ? rawTeachers.map((e) => e.toString()).toSet()
                    : <String>{};

                if (className.isEmpty) return const SizedBox.shrink();

                return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('lessons').where('className', isEqualTo: className).snapshots(),
                    builder: (context, lessonSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('announcements').where('className', isEqualTo: className).snapshots(),
                          builder: (context, annSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('messages').snapshots(),
                                builder: (context, userMsgSnapshot) {

                                  final lessonDocs = lessonSnapshot.data?.docs ?? [];
                                  final annDocs = annSnapshot.data?.docs ?? [];
                                  final userMsgDocs = userMsgSnapshot.data?.docs ?? [];

                                  // 1. ÖDEVLERİ HESAPLA
                                  int activeLessonCount = 0;
                                  for (final doc in lessonDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final teacherId = data['teacherId']?.toString();
                                    if (allowedTeacherIds.isNotEmpty && teacherId != null && !allowedTeacherIds.contains(teacherId)) continue;

                                    final targetType = data['targetType']?.toString() ?? 'class';
                                    final assignedChildIds = data['assignedChildIds'] as List?;
                                    if (targetType == 'child' && assignedChildIds != null && !assignedChildIds.contains(childId)) continue;

                                    final completedBy = data['completedBy'] is List ? List<String>.from((data['completedBy'] as List).map((e) => e.toString())) : <String>[];
                                    final completedByChildId = data['completedByChildId'] is List ? List<String>.from((data['completedByChildId'] as List).map((e) => e.toString())) : <String>[];
                                    final completedByUid = data['completedByUid'] is List ? List<String>.from((data['completedByUid'] as List).map((e) => e.toString())) : <String>[];

                                    final isCompleted = completedBy.contains(childId) || completedBy.contains(uid) || completedByChildId.contains(childId) || completedByUid.contains(uid);

                                    bool isExpired = false;
                                    if (data['dueDate'] is Timestamp) {
                                      final dueDate = (data['dueDate'] as Timestamp).toDate();
                                      if (!isCompleted && DateTime.now().isAfter(dueDate)) isExpired = true;
                                    }

                                    if (!isCompleted && !isExpired) {
                                      activeLessonCount++;
                                    }
                                  }

                                  // 2. MESAJLARI HESAPLA
                                  int unreadMessageCount = 0;
                                  final Set<String> processedMessageIds = {};

                                  for (final doc in annDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final teacherId = data['teacherId']?.toString() ?? '';

// Eski mesajlarda teacherId boş kalmışsa engellememek için teacherId.isNotEmpty şartı eklendi:
                                    if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                                    final targetType = data['targetType']?.toString() ?? 'class';
                                    final targetChildId = data['targetChildId']?.toString().trim() ?? '';
                                    final msgChildId = data['childId']?.toString().trim() ?? '';

                                    // Özel mesajsa, hedef kimliklerden biri bizimle uyuşuyorsa göster
                                    if (targetType == 'child') {
                                      bool isMe = (targetChildId == childId || targetChildId == uid) ||
                                          (msgChildId == childId || msgChildId == uid);
                                      if (!isMe) continue;
                                    }

                                    final seenBy = data['seenBy'] is List ? (data['seenBy'] as List).map((e) => e.toString()).toList() : [];
                                    if (!seenBy.contains(childId)) {
                                      unreadMessageCount++;
                                      processedMessageIds.add(doc.id);
                                    }
                                  }

                                  for (final doc in userMsgDocs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final msgId = data['messageId']?.toString().isNotEmpty == true ? data['messageId']! : doc.id;

                                    if (processedMessageIds.contains(msgId)) continue;

                                    final teacherId = data['teacherId']?.toString() ?? '';

// Eski mesajlarda teacherId boş kalmışsa engellememek için teacherId.isNotEmpty şartı eklendi:
                                    if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                                    final seenBy = data['seenBy'] is List ? (data['seenBy'] as List).map((e) => e.toString()).toList() : [];
                                    if (!seenBy.contains(childId)) {
                                      unreadMessageCount++;
                                      processedMessageIds.add(msgId);
                                    }
                                  }

                                  final totalCount = activeLessonCount + unreadMessageCount;

                                  if (totalCount <= 0) return const SizedBox.shrink();

                                  final onlyMessages = unreadMessageCount > 0 && activeLessonCount == 0;

                                  return Padding(
                                    padding: EdgeInsets.only(top: topGap),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(28),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(28),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StudentWorkSpace(
                                                initialIndex: onlyMessages ? 1 : 0,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                gradient.first,
                                                gradient.last,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(28),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gradient.first.withOpacity(0.28),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.32),
                                              width: 1.4,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 58,
                                                height: 58,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.20),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.notifications_active_rounded,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),

                                              const SizedBox(width: 14),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Bekleyen İşlerin Var',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 7),

                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        if (activeLessonCount > 0)
                                                          _HomeIncomingChip(
                                                            icon: Icons.assignment_rounded,
                                                            text:
                                                            '$activeLessonCount bekleyen ödev',
                                                          ),
                                                        if (unreadMessageCount > 0)
                                                          _HomeIncomingChip(
                                                            icon: Icons.mail_rounded,
                                                            text:
                                                            '$unreadMessageCount yeni mesaj',
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 10),

                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.20),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 23,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                            );
                          }
                      );
                    }
                );
              }
          );
        }
    );
  }
}

class _HomeIncomingChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HomeIncomingChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
class LevelSelectionScreen extends StatelessWidget {
  final String gameType; final Color color; final String title;
  const LevelSelectionScreen({super.key, required this.gameType, required this.color, required this.title});
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> levels = GameRepository.getLevels(gameType);
    return Scaffold(
        appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color, foregroundColor: Colors.white, elevation: 0),
        backgroundColor: Colors.grey[50],
        body: ListView.builder(padding: const EdgeInsets.all(20), itemCount: levels.length, itemBuilder: (context, index) { var level = levels[index]; return Container(margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: ListTile(contentPadding: const EdgeInsets.all(20), leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Text(level['icon'], style: const TextStyle(fontSize: 30))), title: Text(level['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)), trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Colors.white)), onTap: () {
          List<Map<String, dynamic>> qs = GameRepository.prepareRandomQuestions(
            List<Map<String, dynamic>>.from(level['questions']),
          );
          Widget gw;
          String detailedKey = "$gameType: ${level['title']}";
          switch (gameType) {
            case 'Heceleme': gw = GameSyllable(questions: qs, gameKey: detailedKey); break;
            case 'Tanıma': gw = GameRecognition(questions: qs, gameKey: detailedKey); break;
            case 'Hız': gw = GameSpeed(questions: qs, gameKey: detailedKey); break;
            case 'Bellek': gw = GameMemory(questions: qs, gameKey: detailedKey); break;
            case 'Yazma': gw = GameSpelling(questions: qs, gameKey: detailedKey); break;
            case 'Hikaye': gw = GameStory(questions: qs, gameKey: detailedKey); break;
            case 'Sesler': gw = GameSound(questions: qs, gameKey: detailedKey); break;
            case 'Okuma': gw = GameReading(questions: qs, gameKey: detailedKey); break;
            default: gw = const Scaffold();
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => gw));
        })); })
    );
  }
}
String cleanGameSymbol(dynamic value) {
  final raw = value?.toString().trim() ?? "";

  final cleaned = raw
      .replaceAll('\uFE0F', '')
      .replaceAll('\u20E3', '');

  if (RegExp(r'^[0-9]$').hasMatch(cleaned)) {
    return cleaned;
  }

  return raw;
}
abstract class BaseGameState<T extends StatefulWidget> extends State<T> {
  int step = 0;
  bool isWin = false;
  double _contentScale = 1.0;
  double _contentShakeX = 0.0;
  late DateTime _gameStartedAt;
  bool _usageTimeSaved = false;

  int get _elapsedSeconds {
    return DateTime
        .now()
        .difference(_gameStartedAt)
        .inSeconds;
  }

  int? _lastSavedProgressStep;
  int _speechSequenceId = 0;

  bool _homeworkAutoCompleted = false;
  bool _dailyTaskCompleted = false;
  bool _openingCompletionScreen = false;
  bool _completionHandled = false;

  late List<Map<String, dynamic>> questions;
  late ConfettiController confettiController;

  String get gameKey;

  String get mascotMessage => "Hadi başlayalım!";

  List<Color> get activeGradient {
    return context
        .read<AppProvider>()
        .currentTheme
        .gradient;
  }

  Color get activePrimary => activeGradient.first;

  Color get activeSecondary => activeGradient.last;

  void onStep() {}

  bool get _questionsReady {
    try {
      return questions.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _gameStartedAt = DateTime.now();

    confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // Oyun açılır açılmaz güvenli şekilde son etkinlik kaydı oluşsun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      saveCurrentProgress();
    });
  }

  @override
  void dispose() {
    unawaited(saveUsageTime(completed: false));

    // Tamamlandı ekranına geçiyorsak sesi kesme.
    // Normal çıkışta eski oyun sesi durabilir.
    if (!_openingCompletionScreen) {
      VoiceService.instance.stop();
    }

    confettiController.dispose();
    super.dispose();
  }

  Future<bool> handleBackNavigation() async {
    // Geri çıkmak oyunu tamamlamaz, yıldız vermez.
    // Sadece kaldığın yeri kaydeder.
    if (!_openingCompletionScreen) {
      final progressStep =
      isWin && step < questions.length - 1 ? step + 1 : step;

      saveCurrentProgress(stepOverride: progressStep);
    }

    await saveUsageTime(completed: false);

    await VoiceService.instance.stop();
    return true;
  }

  void saveCurrentProgress({
    int? stepOverride,
  }) {
    if (!mounted || !_questionsReady) return;

    final safeStep =
    (stepOverride ?? step).clamp(0, questions.length - 1).toInt();

    _lastSavedProgressStep = safeStep;

    final parts = gameKey.split(':');
    final gameType = parts.first.trim();
    final levelTitle = parts.length > 1
        ? parts.sublist(1).join(':').trim()
        : gameKey.trim();

    final selectedQuestionIds = GameRepository.questionIdsOf(questions);

    final progressData = {
      'gameKey': gameKey,
      'gameType': gameType,
      'levelTitle': levelTitle,
      'step': safeStep,
      if (selectedQuestionIds.isNotEmpty) 'questionIds': selectedQuestionIds,
      'updatedAt': DateTime
          .now()
          .millisecondsSinceEpoch,
    };

    try {
      final dynamic provider = context.read<AppProvider>();
      provider.setLastActivity(progressData);
    } catch (_) {}

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'lastActivity': progressData,
          'lastActivityUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).catchError((_) {});
    } catch (_) {}
  }

  void saveCurrentProgressIfNeeded() {
    if (_lastSavedProgressStep == step) return;
    saveCurrentProgress();
  }

  Future<void> saveUsageTime({
    required bool completed,
  }) async {
    if (_usageTimeSaved) return;

    final seconds = _elapsedSeconds;

    // Çocuk yanlışlıkla girip hemen çıktıysa boş kayıt atmayalım.
    if (!completed && seconds < 3) return;

    final parts = gameKey.split(':');

    final gameType = parts.first.trim();

    final levelTitle = parts.length > 1
        ? parts.sublist(1).join(':').trim()
        : gameKey.trim();

    final displayTitle = gameType.isNotEmpty &&
        levelTitle.isNotEmpty &&
        levelTitle != gameType
        ? "$gameType: $levelTitle"
        : levelTitle;

    _usageTimeSaved = true;

    try {
      await UsageTimeRepository.addActivityTime(
        activityKey: gameKey,
        title: displayTitle,
        type: "activity",
        category: gameType,
        levelTitle: levelTitle,
        seconds: seconds,
        completed: completed,
      );
    } catch (_) {
      // Kayıt tutmazsa oyunu bozmasın.
      _usageTimeSaved = false;
    }
  }

  void handle(bool correct) {
    if (!mounted) return;

    saveCurrentProgress();

    context.read<AppProvider>().showFeedback(correct);

    if (correct) {
      setState(() {
        isWin = true;
        _contentScale = 1.035;
        _contentShakeX = 0;
      });

      confettiController.play();

      Future.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) return;

        setState(() {
          _contentScale = 1.0;
          _contentShakeX = 0;
        });
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        if (!isWin) return;

        next();
      });
    } else {
      // Yanlış cevap eski gibi kalsın.
      // Sadece feedback yazısı/sesi çalışır, kart titremez veya küçülmez.
      setState(() {
        _contentScale = 1.0;
        _contentShakeX = 0;
      });
    }
  }

  Future<void> completeHomeworkIfNeeded() async {
    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments;

    if (args is! Map) return;

    final lessonId = args['homeworkLessonId']?.toString();
    final homeworkChildId = args['homeworkChildId']?.toString();

    if (lessonId == null || lessonId.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? childId = homeworkChildId;

    if (childId == null || childId.isEmpty) {
      try {
        childId = await ChildProfileRepository.ensureActiveChildProfile();
      } catch (_) {
        childId = null;
      }
    }

    await FirebaseFirestore.instance.collection('lessons').doc(lessonId).set(
      {
        if (childId != null && childId.isNotEmpty)
          'completedBy': FieldValue.arrayUnion([childId]),
        if (childId != null && childId.isNotEmpty)
          'completedByChildId': FieldValue.arrayUnion([childId]),
        'completedByUid': FieldValue.arrayUnion([uid]),
        'lastCompletedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> completeDailyTaskIfNeeded() async {
    if (_dailyTaskCompleted) return;

    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments;

    if (args is! Map) return;

    final dailyTaskId = args['dailyTaskId']?.toString();

    if (dailyTaskId == null || dailyTaskId.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    _dailyTaskCompleted = true;

    try {
      await DailyTaskRepository.completeDailyTask(
        uid: uid,
        taskId: dailyTaskId,
      );

      if (!mounted) return;

      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {
      _dailyTaskCompleted = false;
    }
  }

  Future<void> next() async {
    if (step < questions.length - 1) {
      setState(() {
        step++;
        isWin = false;
        onStep();
      });

      saveCurrentProgress();
      return;
    }

    if (_completionHandled) return;
    _completionHandled = true;

    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments;
    final isDailyTaskMode = args is Map &&
        args['dailyTaskId']
            ?.toString()
            .trim()
            .isNotEmpty == true;

    await completeHomeworkIfNeeded();
    await completeDailyTaskIfNeeded();

    if (!mounted) return;

    final finalElapsedSeconds = _elapsedSeconds;

    await saveUsageTime(completed: true);

    if (!mounted) return;

// Günlük görevden açıldıysa yıldızı DailyTaskRepository zaten +2 verdi.
// Eski addPoint çalışırsa ekstra günlük bonus / ekstra yıldız verir.
    if (!isDailyTaskMode) {
      context.read<AppProvider>().addPoint(gameKey);
    }

    context.read<AppProvider>().clearLastActivity();

    final safeTitle = gameKey.contains(':')
        ? gameKey.split(':')[1].trim()
        : gameKey;

    _openingCompletionScreen = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: {
            'elapsedSeconds': finalElapsedSeconds,
            'gameKey': gameKey,
          },
        ),
        builder: (_) =>
            GameCompletionScreen(
              levelTitle: safeTitle,
            ),
      ),
    );
  }


  Future<void> playSound([String? text]) async {
    final cleanText = text?.trim();

    if (!mounted || cleanText == null || cleanText.isEmpty) return;

    _speechSequenceId++;

    unawaited(
      context.read<AppProvider>().speak(
        cleanText,
        interrupt: true,
      ),
    );
  }

  Future<void> speakMascotMessage() async {
    if (!mounted) return;

    final cleanMascot = mascotMessage.trim();
    if (cleanMascot.isEmpty) return;

    _speechSequenceId++;

    unawaited(
      context.read<AppProvider>().speak(
        cleanMascot,
        interrupt: true,
      ),
    );
  }

  int _speechDelayForText(String text) {
    final clean = text.trim();

    if (clean.isEmpty) return 900;

    final wordCount = clean
        .split(RegExp(r'\s+'))
        .where((word) =>
    word
        .trim()
        .isNotEmpty)
        .length;

    // Türkçe TTS bazen emülatörde yavaş okuyor.
    // O yüzden kelime başına geniş süre veriyoruz.
    final calculated = 1000 + (wordCount * 670);

    if (calculated < 2600) return 2600;
    if (calculated > 12000) return 12000;

    return calculated;
  }

  Future<void> speakQuestionThenTarget(String? targetText) async {
    final cleanTarget = targetText?.trim();

    if (!mounted) return;

    final myId = ++_speechSequenceId;

    final fullMascotText = mascotMessage.trim();

    if (fullMascotText.isNotEmpty) {
      unawaited(
        context.read<AppProvider>().speak(
          fullMascotText,
          interrupt: true,
        ),
      );
    }

    await Future.delayed(
      Duration(
        milliseconds: _speechDelayForText(fullMascotText),
      ),
    );

    if (!mounted || myId != _speechSequenceId) return;

    if (cleanTarget == null || cleanTarget.isEmpty) return;

    // Maskot konuşması bitmeden hedefi okumaması için burada interrupt false yapıyoruz.
    unawaited(
      context.read<AppProvider>().speak(
        cleanTarget,
        interrupt: false,
      ),
    );
  }

  Future<void> speakTargetOnly(String? targetText) async {
    final cleanTarget = targetText?.trim();

    if (!mounted || cleanTarget == null || cleanTarget.isEmpty) return;

    _speechSequenceId++;

    unawaited(
      context.read<AppProvider>().speak(
        cleanTarget,
        interrupt: true,
      ),
    );
  }

  String _cleanDisplayValue(String value) {
    final raw = value.trim();

    final cleaned = raw
        .replaceAll('\uFE0F', '')
        .replaceAll('\u20E3', '');

    if (RegExp(r'^[0-9]$').hasMatch(cleaned)) {
      return cleaned;
    }

    return raw;
  }

  bool _isSingleTextDisplay(String value) {
    return RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü0-9]$').hasMatch(value.trim());
  }

  bool _looksLikeEmoji(String value) {
    final text = value.trim();

    if (text.isEmpty) return false;

    for (final rune in text.runes) {
      if ((rune >= 0x1F300 && rune <= 0x1FAFF) ||
          (rune >= 0x2600 && rune <= 0x27BF)) {
        return true;
      }
    }

    return false;
  }

  Widget themedDisplayBubble({
    required String value,
    double size = 120,
    double fontSize = 64,
    IconData? fallbackIcon,
    VoidCallback? onTap,
  }) {
    final gradient = activeGradient;
    final textValue = value.trim();

    final bubble = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            gradient.first.withValues(alpha: 0.95),
            gradient.last.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.6,
        ),
      ),
      child: textValue.isEmpty && fallbackIcon != null
          ? Icon(
        fallbackIcon,
        color: Colors.white,
        size: fontSize,
      )
          : Text(
        textValue,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            Shadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );

    final animatedBubble = JoyFloat(
      distance: 5,
      durationMs: 1850,
      child: JoyPulse(
        minScale: 0.985,
        maxScale: 1.035,
        durationMs: 1550,
        child: bubble,
      ),
    );

    if (onTap == null) {
      return animatedBubble;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(size),
      onTap: onTap,
      child: animatedBubble,
    );
  }

  Widget themedInfoCard({
    required String title,
    required String mainText,
    String? subtitle,
    IconData? icon,
    bool muted = false,
    double mainFontSize = 28,
    VoidCallback? onTap,
  }) {
    final gradient = activeGradient;
    final mainColor = muted ? Colors.grey.shade600 : gradient.last;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(
          color: gradient.first.withOpacity(0.22),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gradient.first,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mainText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: mainFontSize,
              fontWeight: FontWeight.w900,
              color: mainColor,
              height: 1.30,
              letterSpacing: muted ? 0 : 1.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: card,
    );
  }

  Widget themedChallengeCard({
    required String title,
    required String mainText,
    required String subtitle,
    IconData? icon,
    double mainFontSize = 90,
  }) {
    final gradient = activeGradient;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first,
            gradient.last,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),

          JoyFloat(
            distance: 4,
            durationMs: 1900,
            child: JoyPulse(
              minScale: 0.985,
              maxScale: 1.035,
              durationMs: 1600,
              child: Text(
                mainText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mainFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    Shadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget themedActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final gradient = activeGradient;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: gradient.first,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: onPressed == null ? 0 : 7,
        shadowColor: gradient.first.withValues(alpha: 0.30),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget themedDeleteButton({
    required VoidCallback? onPressed,
    String tooltip = "Sil",
  }) {
    return Material(
      color: Colors.redAccent.withValues(
        alpha: onPressed == null ? 0.18 : 0.95,
      ),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(
          Icons.backspace_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget themedSmallDeleteChip({
    required VoidCallback? onPressed,
    String tooltip = "Geri al",
  }) {
    final gradient = activeGradient;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: onPressed == null
                ? Colors.grey.withValues(alpha: 0.30)
                : Colors.redAccent.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: onPressed == null
                ? []
                : [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.backspace_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget buildGameScreen({
    required Widget content,
  }) {
    final screenTitle = gameKey.contains(':')
        ? gameKey.split(':')[1].trim()
        : "Etkinlik";

    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;

    // 🚀 TABLET KONTROLÜ EKLENDİ
    final isTablet = MediaQuery
        .of(context)
        .size
        .shortestSide >= 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      saveCurrentProgressIfNeeded();
    });

    return WillPopScope(
      onWillPop: handleBackNavigation,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            screenTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: ElapsedTimePill(
                  startedAt: _gameStartedAt,
                  gradient: theme.gradient,
                  compact: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "${step + 1}/${questions.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: ThemedBackground(
          variantIndex: step,
          // 🚀 BURASI DEĞİŞTİ: Stack artık tepeye hizalı çalışıyor
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              SafeArea(
                // 🚀 BÜYÜK YENİLİK: Scroll mekanizmasını baştan yazdık
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [

                    // 1. KISIM: STICKERLI BANNER (EN TEPEYE SABİTLENİR)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          isTablet ? 32 : 20,
                          isTablet ? 32 : 20,
                          isTablet ? 32 : 20,
                          0
                      ),
                      sliver: SliverToBoxAdapter(
                        child: GameMascotCard(
                          message: mascotMessage,
                          onSpeak: speakMascotMessage,
                        ),
                      ),
                    ),

                    // 2. KISIM: OYUN EKRANI (AŞAĞIDAKİ TÜM BOŞLUĞU DOLDURUR VE ORTALAR)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            isTablet ? 32 : 20,
                            isTablet ? 40 : 18,
                            isTablet ? 32 : 20,
                            120
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            transformAlignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translate(_contentShakeX)
                              ..scale(_contentScale),
                            child: content,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                ),
              ),

              if (isWin)
                Positioned(
                  bottom: 50,
                  left: 40,
                  right: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.gradient.first,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "SIRADAKİ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      next();
                    }
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// 7. OYUN ARAYÜZLERİ
class GameSyllable extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameSyllable({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameSyllable> createState() => _GSyll();
}

class _GSyll extends BaseGameState<GameSyllable> {
  List<String> cur = [];
  bool _introSpoken = false;

  @override
  String get mascotMessage =>
      "Süper! Ekrandaki resmi inceleyelim. Kelimeyi oluşturmak için heceleri sırayla seçelim.";

  @override
  String get gameKey => widget.gameKey;

  void _speakCurrentWord() {
    final word = questions[step]['w']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(word);
      } else {
        speakTargetOnly(word);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentWord();
  }

  @override
  void onStep() {
    cur.clear();
    _speakCurrentWord();
  }

  void _autoCheckIfReady() {
    final pieces = List.from(questions[step]['p'] as List);
    final answer = questions[step]['w'].toString();
    final selected = cur.join("");

    if (cur.length < pieces.length) return;

    handle(selected == answer);

    if (selected != answer) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || isWin) return;

        setState(() {
          cur.clear();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = cur.isEmpty ? "Önce ilk heceyi seç" : cur.join("-");
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // SADECE RESİM SOL TARAFTA DEV GİBİ DURACAK
    Widget leftImage = Center(
      child: themedDisplayBubble(
        value: questions[step]['e'].toString(),
        size: (isTablet && isLandscape) ? 340 : (isTablet ? 200 : 132),
        fontSize: (isTablet && isLandscape) ? 160 : (isTablet ? 90 : 70),
        onTap: () => playSound(questions[step]['w']),
      ),
    );

    // KELİME KUTUSU VE ALTINDAKİ HECELER SAĞ TARAFTA
    Widget rightContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        themedInfoCard(
          title: "Kelimeyi Oluştur",
          mainText: selectedText,
          muted: cur.isEmpty,
          mainFontSize: cur.isEmpty ? (isTablet ? 26 : 18) : (isTablet ? 48 : 34),
          subtitle: "🔊 Dinlemek için karta dokun",
          icon: Icons.extension_rounded,
          onTap: () => playSound(questions[step]['w']),
        ),
        SizedBox(height: isTablet ? 40 : 28),
        // Heceler ve silme tuşu büyütüldü
        Transform.scale(
          scale: isTablet ? 1.3 : 1.0,
          child: Wrap(
            spacing: 12,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              ...(questions[step]['p'] as List).map((h) {
                return KidChoiceChip(
                  text: h.toString(),
                  onTap: isWin ? null : () {
                    setState(() => cur.add(h.toString()));
                    _autoCheckIfReady();
                  },
                );
              }),
              themedSmallDeleteChip(
                tooltip: "Son heceyi sil",
                onPressed: cur.isEmpty || isWin ? null : () => setState(() => cur.removeLast()),
              ),
            ],
          ),
        ),
      ],
    );

    return buildGameScreen(
      content: (isTablet && isLandscape)
          ? Row(
        children: [
          Expanded(flex: 5, child: leftImage),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: rightContent),
        ],
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leftImage,
          SizedBox(height: isTablet ? 40 : 28),
          rightContent,
        ],
      ),
    );
  }
}

class GameRecognition extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameRecognition({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameRecognition> createState() => _GRec();
}

class _GRec extends BaseGameState<GameRecognition> {
  bool _introSpoken = false;

  @override
  String get gameKey => widget.gameKey;

  @override
  String get mascotMessage =>
      "Harika! Resme dikkatlice bak. Sence bu görsel hangi kelimeyi anlatıyor?";

  void _speakCurrentAnswer() {
    final answer = questions[step]['w']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(answer);
      } else {
        speakTargetOnly(answer);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentAnswer();
  }

  @override
  void onStep() {
    _speakCurrentAnswer();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = activeGradient;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    Widget leftImage = Center(
      child: themedDisplayBubble(
        value: questions[step]['e'].toString(),
        size: (isTablet && isLandscape) ? 340 : (isTablet ? 180 : 152),
        fontSize: (isTablet && isLandscape) ? 160 : (isTablet ? 90 : 82),
        onTap: () => playSound(questions[step]['w']),
      ),
    );

    Widget rightContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Doğru olduğunu düşündüğün cevabı seç",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activePrimary,
              fontSize: isTablet ? 26 : 20, // Bir tık küçültüldü
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16), // 🚀 BOŞLUK KISILDI TAŞMAYI ÖNLER
          Transform.scale(
            scale: isTablet ? 1.1 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: (questions[step]['opts'] as List).map((opt) {
                return Padding(
                  padding: EdgeInsets.only(bottom: isTablet ? 12 : 10), // 🚀 ŞIKLAR ARASI BOŞLUK KISILDI
                  child: KidAnswerButton(
                    text: opt.toString(),
                    icon: Icons.check_circle_rounded,
                    gradient: gradient,
                    onTap: isWin ? null : () => handle(opt == questions[step]['w']),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    return buildGameScreen(
      content: (isTablet && isLandscape)
          ? Row(
        children: [
          Expanded(flex: 5, child: leftImage),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: Center(child: rightContent)),
        ],
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leftImage,
          SizedBox(height: isTablet ? 26 : 26),
          rightContent,
        ],
      ),
    );
  }
}

class GameSpeed extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameSpeed({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameSpeed> createState() => _GSpd();
}

class _GSpd extends BaseGameState<GameSpeed> {
  bool hidden = false;
  bool _introSpoken = false;

  @override
  String get gameKey => widget.gameKey;

  @override
  String get mascotMessage =>
      "Hazır mısın? Ekranda kısa süre görünen şeyi aklında tut, sonra doğru seçeneği bulalım.";

  String _visibleSpeedSymbol(dynamic value) {
    final raw = value.toString().trim();

    if (raw == ".") return "●";
    if (raw == ",") return "‚";
    if (raw == ";") return ";";
    if (raw == ":") return "∶";
    if (raw == "-") return "−";
    if (raw == "_") return "＿";
    if (raw == "␣") return "␣";

    return raw;
  }

  String _speakableSpeedSymbol(dynamic value) {
    final raw = value.toString().trim();

    switch (raw) {
      case ".":
        return "nokta";
      case ",":
        return "virgül";
      case ";":
        return "noktalı virgül";
      case ":":
        return "iki nokta";
      case "?":
        return "soru işareti";
      case "!":
        return "ünlem";
      case "+":
        return "artı";
      case "-":
        return "eksi";
      case "=":
        return "eşittir";
      case "@":
        return "et işareti";
      case "#":
        return "diyez işareti";
      case "%":
        return "yüzde işareti";
      case "&":
        return "ve işareti";
      default:
        return raw;
    }
  }

  void _speakCurrentTarget() {
    final target = questions[step]['t'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final speakText = _speakableSpeedSymbol(target);

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(speakText);
      } else {
        speakTargetOnly(speakText);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentTarget();
  }

  @override
  void onStep() {
    hidden = false;
    _speakCurrentTarget();
  }

  @override
  Widget build(BuildContext context) {
    final target = questions[step]['t'].toString();
    final visibleTarget = _visibleSpeedSymbol(target);
    final gradient = activeGradient;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    if (!hidden) {
      return buildGameScreen(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              // 🚀 maxHeight SİLİNDİ! KART ARTIK İÇERİĞİ SIKIŞTIRIP TAŞIRMAYACAK
              constraints: BoxConstraints(maxWidth: isTablet ? 450 : 350),
              child: themedChallengeCard(
                title: "Hızlı Bak!",
                mainText: visibleTarget,
                subtitle: "Hazır olunca gördüm butonuna bas",
                icon: Icons.flash_on_rounded,
                mainFontSize: visibleTarget.length <= 2 ? (isTablet ? 120 : 116) : (isTablet ? 90 : 86),
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Transform.scale(
              scale: isTablet ? 1.2 : 1.0,
              child: themedActionButton(
                label: "GÖRDÜM!",
                icon: Icons.visibility_rounded,
                onPressed: () {
                  setState(() => hidden = true);
                  playSound("Şimdi aklında kalan doğru seçeneği bul.");
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget leftCard = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 420 : double.infinity, minHeight: isTablet ? 300 : 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            themedInfoCard(
              title: "Aklında Kalanı Seç",
              mainText: "Doğru olduğunu düşündüğün cevabı seç",
              mainFontSize: isTablet ? 28 : 20,
              subtitle: "👁️ Tekrar görmek için karta dokun",
              icon: Icons.flash_on_rounded,
              onTap: isWin ? null : () {
                setState(() => hidden = false);
                speakTargetOnly(_speakableSpeedSymbol(target));
              },
            ),
          ],
        ),
      ),
    );

    Widget rightOptions = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 480 : double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: (questions[step]['o'] as List).map((o) {
          final optionRaw = o.toString();
          final visibleOption = _visibleSpeedSymbol(optionRaw);
          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 14 : 12),
            child: Transform.scale(
              scale: isTablet ? 1.05 : 1.0,
              child: KidAnswerButton(
                text: visibleOption,
                icon: Icons.bolt_rounded,
                gradient: gradient,
                onTap: isWin ? null : () => handle(optionRaw == target),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return buildGameScreen(
      content: (isTablet && isLandscape)
          ? Row(
        children: [
          Expanded(flex: 1, child: Center(child: leftCard)),
          const SizedBox(width: 40),
          Expanded(flex: 1, child: Center(child: rightOptions)),
        ],
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leftCard,
          SizedBox(height: isTablet ? 30 : 30),
          rightOptions,
        ],
      ),
    );
  }
}

class GameMemory extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameMemory({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameMemory> createState() => _GMemState();
}

class _GMemState extends BaseGameState<GameMemory> {
  bool hide = false;
  bool _introSpoken = false;
  List<String> opts = [];
  Timer? _hideTimer;
  int _memoryRoundId = 0;

  @override
  String get mascotMessage =>
      "Minik hafıza oyunu başlıyor! Resme dikkatle bak, birazdan aynısını bulmanı isteyeceğim.";

  @override
  String get gameKey => widget.gameKey;

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  @override
  void dispose() {
    _memoryRoundId++;
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;

    _memoryRoundId++;
    final roundId = _memoryRoundId;

    _hideTimer?.cancel();

    setState(() {
      hide = false;
      opts.clear();
    });

    final name = questions[step]['n'].toString();
    final symbol = questions[step]['s'].toString();

    if (!_introSpoken) {
      _introSpoken = true;

      unawaited(
        context.read<AppProvider>().speak(
          mascotMessage,
          interrupt: true,
        ),
      );
    } else {
      unawaited(
        context.read<AppProvider>().speak(
          "Resme dikkatle bak.",
          interrupt: true,
        ),
      );
    }

    // Bellek oyununda görsel ekranda yeterince kalsın.
    // Eski değer 1200 ms idi, çok kısaydı.
    _hideTimer = Timer(const Duration(milliseconds: 4200), () {
      if (!mounted || roundId != _memoryRoundId) return;

      setState(() {
        hide = true;
        opts = [
          symbol,
          "🐱",
          "🦒",
          "🎲",
        ]
          ..shuffle();
      });

      unawaited(
        context.read<AppProvider>().speak(
          "Şimdi az önce gördüğün resmi seç.",
          interrupt: true,
        ),
      );
    });
  }

  @override
  void onStep() {
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final name = questions[step]['n'].toString();
    final symbol = questions[step]['s'].toString();
    final gradient = activeGradient;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    if (!hide) {
      return buildGameScreen(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              // 🚀 maxHeight SİLİNDİ! TAŞMA BİTTİ.
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : 350),
              child: themedChallengeCard(
                title: "Aklında Tut!",
                mainText: symbol,
                subtitle: name,
                icon: Icons.psychology_rounded,
                mainFontSize: isTablet ? 130 : 96,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            SizedBox(
              width: isTablet ? 70 : 42,
              height: isTablet ? 70 : 42,
              child: CircularProgressIndicator(
                color: gradient.first,
                strokeWidth: isTablet ? 8 : 4,
              ),
            ),
          ],
        ),
      );
    }

    Widget leftCard = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 420 : double.infinity, minHeight: isTablet ? 350 : 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            themedInfoCard(
              title: "Hatırladığın Resmi Seç",
              mainText: "Doğru resmi seç",
              mainFontSize: isTablet ? 32 : 22,
              subtitle: "👁️ Tekrar görmek için karta dokun",
              icon: Icons.psychology_rounded,
              onTap: isWin ? null : _start,
            ),
          ],
        ),
      ),
    );

    Widget rightOptions = SizedBox(
      width: isTablet ? 450 : double.infinity,
      child: Wrap(
        spacing: isTablet ? 24 : 14,
        runSpacing: isTablet ? 24 : 14,
        alignment: WrapAlignment.center,
        children: opts.map((o) {
          return JoyFloat(
            distance: 2.4,
            durationMs: 2200 + ((o.toString().length % 4) * 150),
            delayMs: (o.toString().length * 80) % 450,
            child: InkWell(
              borderRadius: BorderRadius.circular(isTablet ? 36 : 28),
              onTap: isWin ? null : () => handle(o == symbol),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: (isTablet && isLandscape) ? 170 : (isTablet ? 140 : 105),
                height: (isTablet && isLandscape) ? 170 : (isTablet ? 140 : 105),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 36 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  o.toString(),
                  style: TextStyle(fontSize: isTablet ? 76 : 48),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return buildGameScreen(
      content: (isTablet && isLandscape)
          ? Row(
        children: [
          Expanded(flex: 1, child: Center(child: leftCard)),
          const SizedBox(width: 40),
          Expanded(flex: 1, child: Center(child: rightOptions)),
        ],
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leftCard,
          SizedBox(height: isTablet ? 40 : 26),
          rightOptions,
        ],
      ),
    );
  }
}

class GameSpelling extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameSpelling({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameSpelling> createState() => _GSpell();
}

class _GSpell extends BaseGameState<GameSpelling> {
  List<String> c = [];
  bool _introSpoken = false;

  @override
  String get gameKey => widget.gameKey;

  @override
  String get mascotMessage =>
      "Şimdi kelimeyi birlikte yazalım. Harfleri sırayla seç, ben sana yardımcı olacağım.";

  void _speakCurrentWord() {
    final word = questions[step]['w']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(word);
      } else {
        speakTargetOnly(word);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentWord();
  }

  @override
  void onStep() {
    c.clear();
    _speakCurrentWord();
  }

  void _autoCheckIfReady() {
    final answer = questions[step]['w'].toString();
    final selected = c.join("");

    if (c.length < answer.length) return;

    handle(selected == answer);

    if (selected != answer) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || isWin) return;

        setState(() {
          c.clear();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedWord = c.isEmpty ? "İlk harfi seçerek başlayalım" : c.join(
        "");
    final isTablet = MediaQuery
        .of(context)
        .size
        .shortestSide >= 600;

    Widget questionPart = themedInfoCard(
      title: "Kelimeyi Yaz",
      mainText: selectedWord,
      muted: c.isEmpty,
      mainFontSize: c.isEmpty ? (isTablet ? 26 : 18) : (isTablet ? 60 : 40),
      subtitle: "🔊 Dinlemek için karta dokun",
      icon: Icons.edit_rounded,
      onTap: () => playSound(questions[step]['w']),
    );

    Widget answerPart = Wrap(
      spacing: isTablet ? 18 : 10,
      runSpacing: isTablet ? 20 : 12,
      alignment: WrapAlignment.center,
      children: [
        ...(questions[step]['l'] as List).map((letter) {
          return KidChoiceChip(
            text: letter.toString(),
            onTap: isWin ? null : () {
              setState(() => c.add(letter.toString()));
              _autoCheckIfReady();
            },
          );
        }),
        themedSmallDeleteChip(
          tooltip: "Son harfi sil",
          onPressed: c.isEmpty || isWin ? null : () =>
              setState(() => c.removeLast()),
        ),
      ],
    );

    return buildGameScreen(
      // Padding ile ekranı biraz aşağı ittik
      content: Padding(
        padding: EdgeInsets.only(top: isTablet ? 40.0 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity),
              child: questionPart,
            ),
            SizedBox(height: isTablet ? 50 : 28),
            // Harfleri devasa yaptık
            Transform.scale(
              scale: isTablet ? 1.4 : 1.0,
              child: answerPart,
            ),
          ],
        ),
      ),
    );
  }
}

class GameStory extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameStory({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameStory> createState() => _GStor();
}

class _GStor extends BaseGameState<GameStory> {
  List<String> c = [];
  bool _introSpoken = false;

  @override
  String get mascotMessage =>
      "Güzel bir cümle kuracağız. Kelimeleri doğru sıraya dizelim.";

  @override
  String get gameKey => widget.gameKey;

  void _speakCurrentSentence() {
    final sentence = questions[step]['w']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(sentence);
      } else {
        speakTargetOnly(sentence);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentSentence();
  }

  @override
  void onStep() {
    c.clear();
    _speakCurrentSentence();
  }
  void _autoCheckIfReady() {
    final pieces = List.from(questions[step]['p'] as List);
    final answer = questions[step]['w'].toString();
    final selected = c.join(" ");

    if (c.length < pieces.length) return;

    handle(selected == answer);

    if (selected != answer) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || isWin) return;

        setState(() {
          c.clear();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSentence = c.isEmpty ? "Kelimeleri sırayla seç" : c.join(" ");
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    Widget questionPart = themedInfoCard(
      title: "Cümleyi Oluştur",
      mainText: selectedSentence,
      muted: c.isEmpty,
      mainFontSize: c.isEmpty ? (isTablet ? 26 : 18) : (isTablet ? 40 : 26),
      subtitle: "🔊 Dinlemek için karta dokun",
      icon: Icons.auto_stories_rounded,
      onTap: () => playSound(questions[step]['w']),
    );

    Widget answerPart = Wrap(
      spacing: isTablet ? 18 : 10,
      runSpacing: isTablet ? 20 : 12,
      alignment: WrapAlignment.center,
      children: [
        ...(questions[step]['p'] as List).map((w) {
          return KidChoiceChip(
            text: w.toString(),
            onTap: isWin ? null : () {
              setState(() => c.add(w.toString()));
              _autoCheckIfReady();
            },
          );
        }),
        themedSmallDeleteChip(
          tooltip: "Son kelimeyi sil",
          onPressed: c.isEmpty || isWin ? null : () => setState(() => c.removeLast()),
        ),
      ],
    );

    return buildGameScreen(
      content: Padding(
        padding: EdgeInsets.only(top: isTablet ? 40.0 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
              child: questionPart,
            ),
            SizedBox(height: isTablet ? 50 : 28),
            // Kelime şıkları büyütüldü
            Transform.scale(
              scale: isTablet ? 1.35 : 1.0,
              child: answerPart,
            ),
          ],
        ),
      ),
    );
  }
}

class GameSound extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameSound({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameSound> createState() => _GSnd();
}

class _GSnd extends BaseGameState<GameSound> {
  bool _introSpoken = false;

  @override
  String get gameKey => widget.gameKey;

  @override
  String get mascotMessage =>
      "Kulağını açalım! Söylediğim sese uygun doğru kelimeyi birlikte bulalım.";

  void _speakCurrentSound() {
    final sound = questions[step]['q']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget(sound);
      } else {
        speakTargetOnly(sound);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentSound();
  }

  @override
  void onStep() {
    _speakCurrentSound();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = activeGradient;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    Widget questionPart = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        themedDisplayBubble(
          value: "",
          size: isTablet ? 220 : 140,
          fontSize: isTablet ? 100 : 66,
          fallbackIcon: Icons.volume_up_rounded,
          onTap: () => playSound(questions[step]['q']),
        ),
        SizedBox(height: isTablet ? 30 : 20),
        Text(
          "“${questions[step]['q']}” sesini bul",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 22,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ]
          ),
        ),
      ],
    );

    Widget answerPart = Wrap(
      alignment: WrapAlignment.center,
      // 🚀 BOŞLUKLAR 24'TEN 36'YA ÇIKARILDI (ŞIKLAR BİRBİRİNE YAPIŞMAYACAK)
      spacing: isTablet ? 36 : 16,
      runSpacing: isTablet ? 36 : 16,
      children: (questions[step]['o'] as List).map((o) {
        return SizedBox(
          width: isTablet ? 260 : 160,
          child: Transform.scale(
            scale: isTablet ? 1.1 : 1.0,
            child: KidAnswerButton(
              text: o.toString(),
              icon: Icons.hearing_rounded,
              gradient: gradient,
              onTap: isWin ? null : () => handle(o == questions[step]['a']),
            ),
          ),
        );
      }).toList(),
    );

    return buildGameScreen(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          questionPart,
          SizedBox(height: isTablet ? 60 : 26),
          answerPart,
        ],
      ),
    );
  }
}

class GameReading extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String gameKey;
  final int initialStep;

  const GameReading({
    super.key,
    required this.questions,
    required this.gameKey,
    this.initialStep = 0,
  });

  @override
  State<GameReading> createState() => _GRead();
}

class _GRead extends BaseGameState<GameReading> {
  bool _introSpoken = false;

  @override
  String get gameKey => widget.gameKey;

  @override
  String get mascotMessage =>
      "Kelimeyi sakin sakin oku. Sonra aynı kelimeyi seçeneklerin içinden bulalım.";

  void _speakCurrentPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_introSpoken) {
        _introSpoken = true;
        speakQuestionThenTarget("Hangisi doğru?");
      } else {
        speakTargetOnly("Hangisi doğru?");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    step = widget.initialStep.clamp(0, questions.length - 1).toInt();
    _speakCurrentPrompt();
  }

  @override
  void onStep() {
    _speakCurrentPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = activeGradient;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    Widget questionPart = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
      child: themedInfoCard(
        title: "Okunan Kelime",
        mainText: questions[step]['w'].toString(),
        mainFontSize: isTablet ? 64 : 42,
        icon: Icons.menu_book_rounded,
      ),
    );

    Widget answerPart = Wrap(
      alignment: WrapAlignment.center,
      spacing: isTablet ? 36 : 12, // 🚀 ŞIKLAR ARASI YATAY BOŞLUK ÇOK ARTIRILDI
      runSpacing: isTablet ? 36 : 12, // 🚀 ŞIKLAR ARASI DİKEY BOŞLUK ÇOK ARTIRILDI
      children: (questions[step]['o'] as List).map((o) {
        return SizedBox(
          width: isTablet ? 240 : 160,
          child: Transform.scale(
            scale: isTablet ? 1.1 : 1.0,
            child: KidAnswerButton(
              text: o.toString(),
              icon: Icons.menu_book_rounded,
              gradient: gradient,
              onTap: isWin ? null : () => handle(o == questions[step]['a']),
            ),
          ),
        );
      }).toList(),
    );

    return buildGameScreen(
      content: Column(
        mainAxisSize: MainAxisSize.min, // 🚀 TAM ORTADA DURMASINI SAĞLAR
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          questionPart,
          SizedBox(height: isTablet ? 60 : 28),
          answerPart,
        ],
      ),
    );
  }
}

// 8. DİĞER EKRANLAR
class DetailedReportScreen extends StatelessWidget {
  const DetailedReportScreen({super.key});
  final Map<String, List<String>> _gameCurriculum = const {
    "Heceleme": ["Meyveler", "Hayvanlar", "Taşıtlar"],
    "Tanıma": ["Renkler", "Şekiller", "Sayılar"],
    "Hız": ["Rakamlar", "Harfler", "Semboller"],
    "Bellek": ["Doğa", "Yiyecekler", "Eşyalar"],
    "Yazma": ["3 Harfliler", "4 Harfliler", "5 Harfliler"],
    "Hikaye": ["Kısa Cümleler", "Orta Cümleler", "Uzun Cümleler"],
    "Sesler": ["Başlangıç Sesi", "Bitiş Sesi", "İçindeki Ses"],
    "Okuma": ["Kolay", "Orta", "Zor"]
  };
  @override
  Widget build(BuildContext context) {
    final u = Provider.of<AppProvider>(context);

    return Scaffold(
        appBar: AppBar(title: const Text("Gelişim Raporum"), backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
        backgroundColor: AppColors.background,
        body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _gameCurriculum.length,
            itemBuilder: (context, index) {
              String gameName = _gameCurriculum.keys.elementAt(index);
              List<String> subLevels = _gameCurriculum[gameName]!;
              return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: ExpansionTile(
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary)),
                      title: Text(gameName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      childrenPadding: const EdgeInsets.all(15),
                      children: subLevels.map((levelName) {
                        String dbKey = "$gameName: $levelName";
                        int score = u.stats[dbKey] ?? 0;
                        bool isCompleted = score >= 10;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(levelName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  isCompleted ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)), child: Row(children: const [Text("Tamamlandı ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Icon(Icons.check_circle, color: Colors.green, size: 18)])) : Text("$score/10", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 16))
                                ]
                            )
                        );
                      }).toList()
                  )
              );
            }
        )
    );
  }
}

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final u = Provider.of<AppProvider>(context);
    return Scaffold(
        appBar: AppBar(title: const Text("Rozet Koleksiyonum"), backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
        backgroundColor: AppColors.background,
        body: u.earnedBadges.isEmpty ? const Center(child: Text("Henüz rozet kazanmadın. Oynamaya devam et!")) : GridView.builder(padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15), itemCount: u.earnedBadges.length, itemBuilder: (context, index) { var badge = u.earnedBadges[index]; return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(badge.icon, style: const TextStyle(fontSize: 50)), const SizedBox(height: 10), Text(badge.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: badge.color))])); })
    );
  }
}

class MotivationOverlay extends StatelessWidget {
  const MotivationOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<AppProvider>(context);
    if (p.feedbackText.isEmpty) return const SizedBox();
    return Positioned(top: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: p.feedbackColor, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: SafeArea(child: Text(p.feedbackText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)))));
  }
}
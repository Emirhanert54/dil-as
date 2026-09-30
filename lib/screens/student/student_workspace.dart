import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../widgets/common/empty_state_card.dart';
import '../../widgets/common/themed_background.dart';
import '../../pages/student_home.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/child_profile_repository.dart';
import '../../services/notification_service.dart';

class StudentWorkSpace extends StatefulWidget {
  final int initialIndex;

  const StudentWorkSpace({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<StudentWorkSpace> createState() => _StudentWorkSpaceState();
}

class _StudentWorkSpaceState extends State<StudentWorkSpace> {
  @override
  void initState() {
    super.initState();
    _healDuplicateProfiles();
  }

  Future<void> _healDuplicateProfiles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final activeChildId = userData['activeChildId']?.toString() ?? '';
      final playerIdKey = userData['playerIdKey']?.toString() ?? '';

      if (playerIdKey.isEmpty || activeChildId.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('childProfiles')
          .where('playerIdKey', isEqualTo: playerIdKey)
          .get();

      if (snap.docs.length > 1) {
        QueryDocumentSnapshot<Map<String, dynamic>>? bestDoc;
        int maxScore = -1;

        for (final doc in snap.docs) {
          final data = doc.data();
          int score = 0;
          final stars = data['stars'];
          if (stars is num) score += stars.toInt();

          if (data['stats'] != null && (data['stats'] as Map).isNotEmpty) score += 50;

          if (score > maxScore) {
            maxScore = score;
            bestDoc = doc;
          }
        }

        if (bestDoc != null && bestDoc.id != activeChildId) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'activeChildId': bestDoc.id,
          });

          if (mounted) {
            await context.read<AppProvider>().loadFromFirebase();
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint("Identity Heal Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex.clamp(0, 1).toInt(),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text(
            "Çalışma Alanım",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.24),
                ),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.gradient.first,
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
                    text: "ÖDEVLERİM",
                  ),
                  Tab(
                    icon: Icon(Icons.mail_rounded, size: 20),
                    text: "MESAJLARIM",
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            LessonListScreen(),
            MessagesScreen(),
          ],
        ),
      ),
    );
  }
}

class LessonListScreen extends StatelessWidget {
  const LessonListScreen({super.key});

  void _openHomeworkGame({
    required BuildContext context,
    required String lessonId,
    required String childId,
    required String gameType,
    required String levelTitle,
  }) {
    if (gameType.trim().isEmpty || levelTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Bu ödev eski formatta olduğu için etkinlik açılamıyor.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    final levels = GameRepository.getLevels(gameType);
    Map<String, dynamic>? selectedLevel;

    for (final item in levels) {
      final map = Map<String, dynamic>.from(item);
      if (map['title']?.toString() == levelTitle) {
        selectedLevel = map;
        break;
      }
    }

    if (selectedLevel == null || selectedLevel['questions'] is! List) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bu etkinlik bölümü bulunamadı."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
    final gameKey = "$gameType: $levelTitle";

    late Widget gameScreen;

    switch (gameType) {
      case 'Heceleme':
        gameScreen = GameSyllable(questions: questions, gameKey: gameKey);
        break;
      case 'Tanıma':
        gameScreen = GameRecognition(questions: questions, gameKey: gameKey);
        break;
      case 'Hız':
      case 'Hızlı Gör':
        gameScreen = GameSpeed(questions: questions, gameKey: gameKey);
        break;
      case 'Bellek':
        gameScreen = GameMemory(questions: questions, gameKey: gameKey);
        break;
      case 'Yazma':
        gameScreen = GameSpelling(questions: questions, gameKey: gameKey);
        break;
      case 'Hikaye':
        gameScreen = GameStory(questions: questions, gameKey: gameKey);
        break;
      case 'Sesler':
        gameScreen = GameSound(questions: questions, gameKey: gameKey);
        break;
      case 'Okuma':
        gameScreen = GameReading(questions: questions, gameKey: gameKey);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$gameType etkinliği açılamadı."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: {
            'homeworkLessonId': lessonId,
            'homeworkChildId': childId,
          },
        ),
        builder: (_) => gameScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return ThemedBackground(
        child: EmptyStateCard(
          emoji: u.currentMascot.emoji,
          title: "Oturum bulunamadı",
          subtitle: "Lütfen tekrar giriş yap.",
          gradient: u.currentTheme.gradient,
          icon: Icons.lock_rounded,
        ),
      );
    }

    if (u.className.isEmpty) {
      return ThemedBackground(
        child: EmptyStateCard(
          emoji: u.currentMascot.emoji,
          title: "Henüz sınıf bilgisi yok",
          subtitle:
          "Öğretmen seni bir sınıfa eklediğinde ödevlerin burada görünecek.",
          gradient: u.currentTheme.gradient,
          icon: Icons.school_rounded,
        ),
      );
    }

    return ThemedBackground(
      child: FutureBuilder<String>(
        future: ChildProfileRepository.ensureActiveChildProfile(),
        builder: (context, childSnapshot) {
          if (!childSnapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));
          }

          final childId = childSnapshot.data!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('childProfiles').doc(childId).snapshots(),
            builder: (context, childProfileSnapshot) {
              if (!childProfileSnapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));
              }

              final childData = childProfileSnapshot.data!.data() ?? {};
              final rawTeachers = childData['teachers'] ?? childData['teacherIds'];
              final className = childData['className']?.toString() ?? "";

              final allowedTeacherIds = rawTeachers is List
                  ? rawTeachers.map((e) => e.toString()).toSet()
                  : <String>{};

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('lessons').where('className', isEqualTo: className).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return EmptyStateCard(
                      emoji: u.currentMascot.emoji,
                      title: "Ödevler yüklenemedi",
                      subtitle: "Bir bağlantı sorunu oluştu.",
                      gradient: u.currentTheme.gradient,
                      icon: Icons.wifi_off_rounded,
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final teacherId = data['teacherId']?.toString();

                    // 🛡️ ESNETİLMİŞ GÜVENLİK: Liste doluysa ve öğretmen içinde yoksa engelle. (Boşsa sınıfa göre kabul et)
                    if (allowedTeacherIds.isNotEmpty && teacherId != null && !allowedTeacherIds.contains(teacherId)) {
                      return false;
                    }

                    final targetType = data['targetType']?.toString() ?? 'class';
                    final assignedChildIds = data['assignedChildIds'] as List?;

                    if (targetType == 'class') return true;
                    if (assignedChildIds != null && assignedChildIds.contains(childId)) return true;
                    if (targetType == 'class' && assignedChildIds == null) return true;

                    return false;
                  }).toList();

                  docs.sort((a, b) {
                    final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    return bTime.compareTo(aTime);
                  });

                  if (docs.isEmpty) {
                    return EmptyStateCard(
                      emoji: u.currentMascot.emoji,
                      title: "Henüz ödevin yok",
                      subtitle: "Harika gidiyorsun!",
                      gradient: u.currentTheme.gradient,
                      icon: Icons.celebration_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final title = data['title']?.toString() ?? "Ödev";
                      final description = data['description']?.toString() ?? data['content']?.toString() ?? "Açıklama yok.";
                      final subject = data['subject']?.toString() ?? "Genel";
                      final gameType = data['gameType']?.toString() ?? "";
                      final levelTitle = data['levelTitle']?.toString() ?? "";

                      final completedBy = data['completedBy'] is List
                          ? List<String>.from((data['completedBy'] as List).map((e) => e.toString()))
                          : <String>[];
                      final completedByChildId = data['completedByChildId'] is List
                          ? List<String>.from((data['completedByChildId'] as List).map((e) => e.toString()))
                          : <String>[];
                      final completedByUid = data['completedByUid'] is List
                          ? List<String>.from((data['completedByUid'] as List).map((e) => e.toString()))
                          : <String>[];

                      final isCompleted =
                          completedBy.contains(childId) ||
                              completedBy.contains(uid) ||
                              completedByChildId.contains(childId) ||
                              completedByUid.contains(uid);

                      DateTime? dueDate;
                      bool isExpired = false;

                      if (data['dueDate'] is Timestamp) {
                        dueDate = (data['dueDate'] as Timestamp).toDate();
                        if (!isCompleted && DateTime.now().isAfter(dueDate)) {
                          isExpired = true;
                        }
                      }

                      return _LessonCard(
                        lessonId: doc.id,
                        title: title,
                        description: description,
                        subject: subject,
                        gameType: gameType,
                        levelTitle: levelTitle,
                        dueDate: dueDate,
                        isCompleted: isCompleted,
                        isExpired: isExpired,
                        gradient: u.currentTheme.gradient,
                        onOpenGame: (isCompleted || isExpired)
                            ? null
                            : () {
                          _openHomeworkGame(
                            context: context,
                            lessonId: doc.id,
                            childId: childId,
                            gameType: gameType,
                            levelTitle: levelTitle,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String lessonId;
  final String title;
  final String description;
  final String subject;
  final String gameType;
  final String levelTitle;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isExpired;
  final List<Color> gradient;
  final VoidCallback? onOpenGame;

  const _LessonCard({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.subject,
    required this.gameType,
    required this.levelTitle,
    required this.dueDate,
    required this.isCompleted,
    required this.isExpired,
    required this.gradient,
    required this.onOpenGame,
  });

  @override
  Widget build(BuildContext context) {
    final dueText = dueDate == null
        ? "Teslim tarihi yok"
        : DateFormat('dd/MM/yyyy').format(dueDate!);

    final hasGameLink = gameType.isNotEmpty && levelTitle.isNotEmpty;

    Color statusColor = gradient.first;
    String statusText = "Başla";
    IconData statusIcon = Icons.play_arrow_rounded;
    List<Color> cardGradient = gradient;

    if (isCompleted) {
      statusColor = Colors.green;
      statusText = "Tamamlandı";
      statusIcon = Icons.check_rounded;
      cardGradient = [Colors.green.shade400, Colors.teal];
    } else if (isExpired) {
      statusColor = Colors.redAccent;
      statusText = "Süresi Geçti";
      statusIcon = Icons.timer_off_rounded;
      cardGradient = [Colors.redAccent, Colors.red];
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onOpenGame,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.16),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
            border: Border.all(
              color: statusColor.withOpacity(0.35),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasGameLink ? "$gameType • $levelTitle" : subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isExpired ? Colors.grey.shade600 : Colors.black87,
                        decoration: isExpired ? TextDecoration.lineThrough : null,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Teslim: $dueText",
                      style: TextStyle(
                        color: isExpired ? Colors.redAccent : Colors.grey.shade600,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Future<void> _openMessageDetail({
    required BuildContext context,
    required String childId,
    required Map<String, dynamic> messageData,
    required List<Color> gradient,
  }) async {
    final title = messageData['title']?.toString() ?? 'Mesaj';
    final content = messageData['content']?.toString() ?? '';
    final teacherName = messageData['teacherName']?.toString() ?? 'Öğretmen';
    final type = messageData['type']?.toString() ?? 'duyuru';
    final rewardId = messageData['rewardId']?.toString() ?? '';
    final rewardOnOpen = messageData['rewardOnOpen'] == true;
    final docRef = messageData['docRef'] as DocumentReference?;

    final isCongrats = type == 'tebrik';
    final icon = isCongrats ? Icons.star_rounded : Icons.mail_rounded;
    final color = isCongrats ? Colors.teal : gradient.first;

    var rewardGiven = false;

    if (rewardOnOpen && rewardId.isNotEmpty) {
      rewardGiven = await NotificationService.instance.giveNotificationStarOnce(
        rewardId: rewardId,
        reason: 'teacher_tebrik_message_open',
      );
      if (rewardGiven && context.mounted) {
        try {
          await context.read<AppProvider>().loadFromFirebase();
        } catch (_) {}
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // SOSİS EKRAN ENGELLENDİ
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(teacherName, textAlign: TextAlign.center, style: TextStyle(color: gradient.first, fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text(content, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w700, height: 1.35)),
                  ),
                  if (rewardGiven) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.16), borderRadius: BorderRadius.circular(999)),
                      child: const Text('+1 yıldız kazandın 🌟', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Tıklayınca kapat
                        if (docRef != null) {
                          try {
                            await docRef.set({
                              'seenBy': FieldValue.arrayUnion([childId]),
                              'seenAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                          } catch (_) {}
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradient.first, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('TAMAM', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return ThemedBackground(child: EmptyStateCard(emoji: u.currentMascot.emoji, title: 'Oturum bulunamadı', subtitle: 'Lütfen tekrar giriş yap.', gradient: u.currentTheme.gradient, icon: Icons.lock_rounded));
    }

    return ThemedBackground(
      child: FutureBuilder<String>(
        future: ChildProfileRepository.ensureActiveChildProfile(),
        builder: (context, childSnapshot) {
          if (!childSnapshot.hasData) return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));
          final childId = childSnapshot.data!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('childProfiles').doc(childId).snapshots(),
            builder: (context, childProfileSnapshot) {
              if (!childProfileSnapshot.hasData) return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));

              final childData = childProfileSnapshot.data!.data() ?? {};
              final className = childData['className']?.toString() ?? "";
              final rawTeachers = childData['teachers'] ?? childData['teacherIds'];
              final allowedTeacherIds = rawTeachers is List ? rawTeachers.map((e) => e.toString()).toSet() : <String>{};

              return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('announcements').where('className', isEqualTo: className).snapshots(),
                  builder: (context, annSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      // SENİN BULDUĞUN ASIL KAYNAK BURASI KANKA!
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('messages').snapshots(),
                        builder: (context, userSnap) {

                          if (annSnap.hasError && userSnap.hasError) {
                            return EmptyStateCard(emoji: u.currentMascot.emoji, title: 'Mesajlar yüklenemedi', subtitle: 'Bağlantı sorunu oluştu.', gradient: u.currentTheme.gradient, icon: Icons.wifi_off_rounded);
                          }

                          if (!annSnap.hasData && !userSnap.hasData) {
                            return Center(child: CircularProgressIndicator(color: u.currentTheme.gradient.first));
                          }

                          final Map<String, Map<String, dynamic>> allMessages = {};

                          // 1. SINIF DUYURULARI (Tüm Sınıf İçin Olanlar)
                          if (annSnap.hasData) {
                            for (final doc in annSnap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final teacherId = data['teacherId']?.toString() ?? '';

                              if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                              final targetType = data['targetType']?.toString() ?? 'class';
                              // Kişiye özelse (announcements'a yanlışlıkla atılmışsa) ve hedef biz değilsek atla
                              if (targetType == 'child' || targetType == 'individual') {
                                final tChild = data['targetChildId']?.toString() ?? '';
                                if (tChild != childId && tChild != uid) continue;
                              }

                              final msgId = doc.id;
                              final type = data['type']?.toString() ?? 'duyuru';
                              final isCongrats = type == 'tebrik';
                              final date = data['date'] ?? data['createdAt'];

                              final todayKey = date is Timestamp ? DateFormat('yyyyMMdd').format(date.toDate()) : DateFormat('yyyyMMdd').format(DateTime.now());
                              final rewardId = isCongrats ? 'teacher_tebrik_${teacherId}_${childId}_$todayKey' : '';

                              allMessages[msgId] = {
                                'messageId': msgId,
                                'title': data['title'] ?? 'Mesaj',
                                'content': data['content'] ?? data['body'] ?? '',
                                'teacherName': data['teacherName'] ?? 'Öğretmen',
                                'type': type,
                                'date': date,
                                'seenBy': data['seenBy'] ?? [],
                                'rewardOnOpen': isCongrats,
                                'rewardId': rewardId,
                                'docRef': doc.reference,
                              };
                            }
                          }

                          // 2. KİŞİYE ÖZEL MESAJLAR (Senin Bulduğun users/messages)
                          if (userSnap.hasData) {
                            for (final doc in userSnap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final teacherId = data['teacherId']?.toString() ?? '';

                              if (allowedTeacherIds.isNotEmpty && teacherId.isNotEmpty && !allowedTeacherIds.contains(teacherId)) continue;

                              // HEDEF KONTROLÜ: EĞER MESAJ BU ÇOCUĞA AİT DEĞİLSE GİZLE
                              final targetChildId = data['targetChildId']?.toString() ?? data['childId']?.toString() ?? '';
                              if (targetChildId.isNotEmpty && targetChildId != childId && targetChildId != uid) continue;

                              final msgId = data['messageId']?.toString().isNotEmpty == true ? data['messageId']! : doc.id;
                              final type = data['type']?.toString() ?? 'duyuru';
                              final date = data['date'] ?? data['createdAt'];

                              allMessages[msgId.toString()] = {
                                ...data,
                                'messageId': msgId.toString(),
                                'content': data['content'] ?? data['body'] ?? '',
                                'title': data['title'] ?? 'Özel Mesaj',
                                'type': type,
                                'date': date,
                                'docRef': doc.reference,
                              };
                            }
                          }

                          if (allMessages.isEmpty) {
                            return EmptyStateCard(emoji: u.currentMascot.emoji, title: 'Henüz yeni mesajın yok', subtitle: 'Öğretmeninden yeni bir mesaj geldiğinde burada görünecek.', gradient: u.currentTheme.gradient, icon: Icons.mark_email_unread_rounded);
                          }

                          final sortedMessages = allMessages.values.toList();
                          sortedMessages.sort((a, b) {
                            final aTime = a['date'] is Timestamp ? (a['date'] as Timestamp).millisecondsSinceEpoch : 0;
                            final bTime = b['date'] is Timestamp ? (b['date'] as Timestamp).millisecondsSinceEpoch : 0;
                            return bTime.compareTo(aTime);
                          });

                          return ListView.builder(
                            padding: const EdgeInsets.all(18),
                            itemCount: sortedMessages.length,
                            itemBuilder: (context, index) {
                              final data = sortedMessages[index];

                              final seenBy = data['seenBy'] is List ? (data['seenBy'] as List).map((e) => e.toString()).toList() : [];
                              final isNew = !seenBy.contains(childId);

                              return _MessageCard(
                                title: data['title']?.toString() ?? 'Mesaj',
                                content: data['content']?.toString() ?? '',
                                teacherName: data['teacherName']?.toString() ?? 'Öğretmen',
                                type: data['type']?.toString() ?? 'duyuru',
                                date: data['date'],
                                gradient: u.currentTheme.gradient,
                                isNew: isNew,
                                onTap: () {
                                  _openMessageDetail(
                                    context: context,
                                    childId: childId,
                                    messageData: data,
                                    gradient: u.currentTheme.gradient,
                                  );
                                },
                                onDelete: () async {
                                  // ÇÖP KUTUSUNA TIKLAYINCA SİLER
                                  if (data['docRef'] != null) {
                                    await (data['docRef'] as DocumentReference).delete();
                                  }
                                },
                              );
                            },
                          );
                        }
                    );
                  }
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String content;
  final String teacherName;
  final String type;
  final dynamic date;
  final List<Color> gradient;
  final bool isNew;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _MessageCard({
    required this.title,
    required this.content,
    required this.teacherName,
    required this.type,
    required this.date,
    required this.gradient,
    required this.isNew,
    required this.onTap,
    this.onDelete,
  });

  String _formatDate(dynamic value) {
    if (value is Timestamp) return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    return 'Tarih yok';
  }

  @override
  Widget build(BuildContext context) {
    final isCongrats = type == 'tebrik';
    final icon = isCongrats ? Icons.star_rounded : Icons.mail_rounded;
    final color = isCongrats ? Colors.teal : gradient.first;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.14), blurRadius: 14, offset: const Offset(0, 7))],
            border: Border.all(color: isNew ? Colors.orange.withOpacity(0.65) : color.withOpacity(0.18), width: isNew ? 2 : 1.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(teacherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: gradient.first, fontSize: 11, fontWeight: FontWeight.w900))),
                        if (isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(999)), child: const Text('Yeni', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35)),
                    const SizedBox(height: 8),
                    Text(_formatDate(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: onDelete,
                  tooltip: 'Mesajı Sil',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
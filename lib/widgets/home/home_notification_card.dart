import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../screens/student/student_workspace.dart';

class HomeNotificationCard extends StatelessWidget {
  const HomeNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() ?? {};

        final mode = userData['mode']?.toString() ?? "";
        final studentType = userData['studentType']?.toString() ?? "";
        final accountType = userData['accountType']?.toString() ?? "";

        final isIndividualStudent =
            mode == "individual" ||
                studentType == "individual" ||
                accountType == "individual";

        final className = (userData['className'] ?? u.className).toString();

        final rawTeachers = userData['teachers'];
        final teacherIds = rawTeachers is List
            ? rawTeachers.map((e) => e.toString()).toSet()
            : <String>{};

        final hasTeacherConnection = className.isNotEmpty && teacherIds.isNotEmpty;

        if (isIndividualStudent || !hasTeacherConnection) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('lessons')
              .where('className', isEqualTo: className)
              .snapshots(),
          builder: (context, lessonSnapshot) {
            final lessonDocs = lessonSnapshot.data?.docs ?? [];

            final pendingLessons = lessonDocs.where((doc) {
              final data = doc.data();

              final teacherId = data['teacherId']?.toString();
              final completedByRaw = data['completedBy'];

              final completedBy = completedByRaw is List
                  ? completedByRaw.map((e) => e.toString()).toSet()
                  : <String>{};

              final isTeacherOk =
                  teacherId != null && teacherIds.contains(teacherId);

              final isNotCompleted = !completedBy.contains(uid);

              return isTeacherOk && isNotCompleted;
            }).toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('messages')
                  .orderBy('date', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                final messageDocs = messageSnapshot.data?.docs ?? [];

                final unreadMessages = messageDocs.where((doc) {
                  final data = doc.data();
                  final seenByRaw = data['seenBy'];

                  if (seenByRaw is! List) {
                    return true;
                  }

                  final seenBy = seenByRaw.map((e) => e.toString()).toSet();
                  return !seenBy.contains(uid);
                }).length;

                if (pendingLessons.isEmpty && unreadMessages == 0) {
                  return const SizedBox.shrink();
                }

                final latestLessonTitle = pendingLessons.isEmpty
                    ? null
                    : (pendingLessons.first.data()['gameKey']?.toString() ??
                    pendingLessons.first.data()['title']?.toString());

                return _NotificationPanel(
                  uid: uid,
                  gradient: u.currentTheme.gradient,
                  mascotEmoji: u.currentMascot.emoji,
                  pendingLessonCount: pendingLessons.length,
                  latestLessonTitle: latestLessonTitle,
                  unreadMessageCount: unreadMessages,
                );
              },
            );
          },
        );
      },
    );
  }
}

Future<void> _markUnreadMessagesAsSeen(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('messages')
      .limit(50)
      .get();

  final batch = FirebaseFirestore.instance.batch();
  bool hasWrite = false;

  for (final doc in snap.docs) {
    final data = doc.data();
    final seenByRaw = data['seenBy'];

    final alreadySeen = seenByRaw is List &&
        seenByRaw.map((e) => e.toString()).contains(uid);

    if (!alreadySeen) {
      batch.set(
        doc.reference,
        {
          'seenBy': FieldValue.arrayUnion([uid]),
          'seenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      hasWrite = true;
    }
  }

  if (hasWrite) {
    await batch.commit();
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

                _markUnreadMessagesAsSeen(uid);
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
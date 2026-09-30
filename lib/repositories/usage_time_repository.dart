import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'child_profile_repository.dart';

class UsageTimeRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String todayKey() {
    final now = DateTime.now();

    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');

    return "$y-$m-$d";
  }

  static String safeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll("ı", "i")
        .replaceAll("ğ", "g")
        .replaceAll("ü", "u")
        .replaceAll("ş", "s")
        .replaceAll("ö", "o")
        .replaceAll("ç", "c")
        .replaceAll(RegExp(r'[^a-z0-9_]+'), "_")
        .replaceAll(RegExp(r'_+'), "_")
        .replaceAll(RegExp(r'^_|_$'), "");
  }

  static String formatSeconds(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;

    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final secs = safeSeconds % 60;

    if (hours > 0) {
      return "$hours sa ${minutes.toString().padLeft(2, '0')} dk";
    }

    if (minutes > 0) {
      return "$minutes dk ${secs.toString().padLeft(2, '0')} sn";
    }

    return "$secs sn";
  }

  static Future<void> addActivityTime({
    required String activityKey,
    required String title,
    required String type,
    required int seconds,
    bool completed = false,
    String? category,
    String? levelTitle,
  }) async {
    if (seconds <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) return;

    String? childId;

    try {
      childId = await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      childId = null;
    }

    final dateKey = todayKey();
    final key = safeKey(activityKey);

    final cleanTitle = title
        .trim()
        .isNotEmpty ? title.trim() : key;
    final cleanCategory = category?.trim() ?? "";
    final cleanLevelTitle = levelTitle?.trim() ?? "";

    final storedCategory = cleanCategory.isNotEmpty
        ? cleanCategory
        : type == "miniGame"
        ? "Mini Oyun"
        : "Etkinlik";

    final storedLevelTitle = cleanLevelTitle.isNotEmpty
        ? cleanLevelTitle
        : cleanTitle;

    Future<void> writeUsage(DocumentReference<Map<String, dynamic>> ref) async {
      await ref.set(
        {
          'date': dateKey,
          'updatedAt': FieldValue.serverTimestamp(),
          if (childId != null && childId!.trim().isNotEmpty)
            'childId': childId,
          'ownerUid': uid,
        },
        SetOptions(merge: true),
      );

      await ref.update({
        'totalSeconds': FieldValue.increment(seconds),
        'updatedAt': FieldValue.serverTimestamp(),

        'activities.$key.activityKey': activityKey,
        'activities.$key.title': cleanTitle,
        'activities.$key.type': type,
        'activities.$key.category': storedCategory,
        'activities.$key.levelTitle': storedLevelTitle,
        'activities.$key.seconds': FieldValue.increment(seconds),
        'activities.$key.lastPlayedAt': FieldValue.serverTimestamp(),

        if (completed)
          'activities.$key.completedCount': FieldValue.increment(1),
      });
    }

    final userUsageRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('usageDaily')
        .doc(dateKey);

    await writeUsage(userUsageRef);

    if (childId != null && childId!.trim().isNotEmpty) {
      final childUsageRef = _firestore
          .collection('childProfiles')
          .doc(childId)
          .collection('usageDaily')
          .doc(dateKey);

      await writeUsage(childUsageRef);
    }
  }
}
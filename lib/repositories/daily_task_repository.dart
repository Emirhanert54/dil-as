import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'child_profile_repository.dart';
import 'game_repository.dart';

class DailyTaskRepository {
  DailyTaskRepository._();

  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return "${now.year}-$month-$day";
  }

  static Future<String?> _safeActiveChildId() async {
    try {
      return await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _readProfileData({
    required String uid,
    required String? childId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    if (childId != null && childId.trim().isNotEmpty) {
      final childDoc =
      await firestore.collection('childProfiles').doc(childId).get();

      final childData = childDoc.data();

      if (childData != null && childData.isNotEmpty) {
        return childData;
      }
    }

    final userDoc = await firestore.collection('users').doc(uid).get();

    return userDoc.data() ?? {};
  }

  static Future<void> _writeProfileAndUser({
    required String uid,
    required String? childId,
    required Map<String, dynamic> data,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final patch = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (childId != null && childId.trim().isNotEmpty) {
      await firestore.collection('childProfiles').doc(childId).set(
        {
          ...patch,
          'childId': childId,
          'ownerUid': uid,
          'hasChildProfiles': true,
        },
        SetOptions(merge: true),
      );
    }

    await firestore.collection('users').doc(uid).set(
      {
        ...patch,
        if (childId != null && childId.trim().isNotEmpty)
          'activeChildId': childId,
        if (childId != null && childId.trim().isNotEmpty)
          'hasChildProfiles': true,
      },
      SetOptions(merge: true),
    );
  }

  static Future<List<Map<String, dynamic>>> ensureDailyTasks({
    required String uid,
  }) async {
    final childId = await _safeActiveChildId();

    final data = await _readProfileData(
      uid: uid,
      childId: childId,
    );

    final today = todayKey();
    final rawDailyTasks = data['dailyTasks'];

    if (rawDailyTasks is Map) {
      final dailyTasksMap = Map<String, dynamic>.from(rawDailyTasks);

      final savedDate = dailyTasksMap['date']?.toString() ?? "";
      final rawTasks = dailyTasksMap['tasks'];

      if (savedDate == today && rawTasks is List && rawTasks.length >= 3) {
        final tasks = rawTasks
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        final completedCount =
            tasks.where((task) => task['completed'] == true).length;

        final bonusClaimed = dailyTasksMap['bonusClaimed'] == true;

        await _writeProfileAndUser(
          uid: uid,
          childId: childId,
          data: {
            'dailyTask': {
              'date': today,
              'completed': completedCount,
              'bonusClaimed': bonusClaimed,
            },
            'dailyTasks': {
              ...dailyTasksMap,
              'date': today,
              'tasks': tasks,
              'completedCount': completedCount,
              'bonusClaimed': bonusClaimed,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
        );

        return tasks;
      }
    }

    final tasks = _generateTasks(
      uid: uid,
      date: today,
    );

    await _writeProfileAndUser(
      uid: uid,
      childId: childId,
      data: {
        'dailyTasks': {
          'date': today,
          'tasks': tasks,
          'completedCount': 0,
          'bonusClaimed': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'dailyTask': {
          'date': today,
          'completed': 0,
          'bonusClaimed': false,
        },
      },
    );

    return tasks;
  }

  static List<Map<String, dynamic>> _generateTasks({
    required String uid,
    required String date,
  }) {
    final seed = uid.hashCode ^ date.hashCode;
    final random = Random(seed);

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

    final shuffledGameTypes = [...gameTypes]..shuffle(random);
    final tasks = <Map<String, dynamic>>[];

    for (final gameType in shuffledGameTypes) {
      if (tasks.length >= 3) break;

      final rawLevels = GameRepository.getLevels(gameType);

      if (rawLevels.isEmpty) continue;

      final levels = rawLevels
          .map((item) => Map<String, dynamic>.from(item))
          .where((level) {
        final title = level['title']?.toString() ?? "";
        final questions = level['questions'];

        return title.trim().isNotEmpty &&
            questions is List &&
            questions.isNotEmpty;
      }).toList();

      if (levels.isEmpty) continue;

      final selectedLevel = levels[random.nextInt(levels.length)];
      final levelTitle = selectedLevel['title']?.toString() ?? "Bölüm";

      tasks.add(
        {
          'id': "${date}_${tasks.length + 1}",
          'gameType': gameType,
          'levelTitle': levelTitle,
          'title': gameType,
          'subtitle': levelTitle,
          'completed': false,
          'rewardStars': 2,
        },
      );
    }

    while (tasks.length < 3) {
      tasks.add(
        {
          'id': "${date}_${tasks.length + 1}",
          'gameType': "Heceleme",
          'levelTitle': "Başlangıç",
          'title': "Heceleme",
          'subtitle': "Başlangıç",
          'completed': false,
          'rewardStars': 2,
        },
      );
    }

    return tasks;
  }

  static Future<void> completeDailyTask({
    required String uid,
    required String taskId,
  }) async {
    final childId = await _safeActiveChildId();

    final data = await _readProfileData(
      uid: uid,
      childId: childId,
    );

    final rawDailyTasks = data['dailyTasks'];

    if (rawDailyTasks is! Map) return;

    final dailyTasksMap = Map<String, dynamic>.from(rawDailyTasks);

    final rawTasks = dailyTasksMap['tasks'];

    if (rawTasks is! List) return;

    bool changed = false;
    int earnedStars = 0;

    final tasks = rawTasks.whereType<Map>().map((item) {
      final task = Map<String, dynamic>.from(item);

      final id = task['id']?.toString() ?? "";
      final alreadyCompleted = task['completed'] == true;

      if (id == taskId && !alreadyCompleted) {
        task['completed'] = true;
        task['completedAt'] = Timestamp.now();

        final reward = task['rewardStars'];
        earnedStars = reward is num ? reward.toInt() : 2;

        changed = true;
      }

      return task;
    }).toList();

    if (!changed) return;

    final completedCount =
        tasks.where((task) => task['completed'] == true).length;

    final oldBonusClaimed = dailyTasksMap['bonusClaimed'] == true;
    final newBonusClaimed = oldBonusClaimed;

    final today = dailyTasksMap['date']?.toString() ?? todayKey();

    final currentStars = data['stars'] is num
        ? (data['stars'] as num).toInt()
        : int.tryParse(data['stars']?.toString() ?? "0") ?? 0;

    final newStars = currentStars + earnedStars;

    await _writeProfileAndUser(
      uid: uid,
      childId: childId,
      data: {
        'dailyTasks': {
          ...dailyTasksMap,
          'date': today,
          'tasks': tasks,
          'completedCount': completedCount,
          'bonusClaimed': newBonusClaimed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'dailyTask': {
          'date': today,
          'completed': completedCount,
          'bonusClaimed': newBonusClaimed,
        },
        'stars': newStars,
      },
    );
  }
}
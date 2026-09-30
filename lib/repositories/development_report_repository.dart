import 'package:cloud_firestore/cloud_firestore.dart';

class DevelopmentReport {
  final String childId;
  final String name;
  final String playerId;
  final String className;
  final int stars;
  final int totalActivities;
  final int totalMiniGames;
  final int dailyCompleted;
  final int dailyGoal;
  final String strongestArea;
  final String needsPracticeArea;
  final Map<String, int> stats;
  final Map<String, int> miniGameCounts;

  const DevelopmentReport({
    required this.childId,
    required this.name,
    required this.playerId,
    required this.className,
    required this.stars,
    required this.totalActivities,
    required this.totalMiniGames,
    required this.dailyCompleted,
    required this.dailyGoal,
    required this.strongestArea,
    required this.needsPracticeArea,
    required this.stats,
    required this.miniGameCounts,
  });
}

class DevelopmentReportRepository {
  DevelopmentReportRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _displayName(Map<String, dynamic> data) {
    final nickname = data['nickname']?.toString().trim() ?? "";
    if (nickname.isNotEmpty) return nickname;

    final displayName = data['displayName']?.toString().trim() ?? "";
    if (displayName.isNotEmpty) return displayName;

    final name = data['name']?.toString().trim() ?? "";
    if (name.isNotEmpty) return name;

    final playerId = data['playerId']?.toString().trim() ?? "";
    if (playerId.isNotEmpty) return playerId;

    return "Öğrenci";
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "0") ?? 0;
  }

  static Map<String, int> _readStats(dynamic rawStats) {
    final result = <String, int>{};

    if (rawStats is Map) {
      rawStats.forEach((key, value) {
        final k = key.toString();
        final v = _toInt(value);

        if (k.trim().isNotEmpty && v > 0) {
          result[k] = v;
        }
      });
    }

    return result;
  }

  static Map<String, int> _readMiniGames(dynamic rawMiniGames) {
    final result = <String, int>{};

    if (rawMiniGames is Map) {
      rawMiniGames.forEach((key, value) {
        if (value is Map) {
          final completed = _toInt(value['completedCount']);
          if (completed > 0) {
            result[key.toString()] = completed;
          }
        }
      });
    }

    return result;
  }

  static String _findStrongestArea(Map<String, int> stats) {
    if (stats.isEmpty) return "Henüz veri yok";

    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.first.key;
  }

  static String _findNeedsPracticeArea(Map<String, int> stats) {
    if (stats.isEmpty) return "Henüz veri yok";

    final entries = stats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return entries.first.key;
  }

  static int _dailyCompleted(Map<String, dynamic> data) {
    final rawDailyTasks = data['dailyTasks'];

    if (rawDailyTasks is Map) {
      final tasks = rawDailyTasks['tasks'];

      if (tasks is List) {
        return tasks.where((task) {
          if (task is! Map) return false;
          return task['completed'] == true;
        }).length;
      }

      return _toInt(rawDailyTasks['completedCount']);
    }

    final rawDailyTask = data['dailyTask'];

    if (rawDailyTask is Map) {
      return _toInt(rawDailyTask['completed']);
    }

    return 0;
  }

  static DevelopmentReport fromChildData({
    required String childId,
    required Map<String, dynamic> data,
  }) {
    final stats = _readStats(data['stats']);
    final miniGames = _readMiniGames(data['miniGames']);

    final totalActivities = stats.values.fold<int>(
      0,
          (sum, value) => sum + value,
    );

    final totalMiniGames = miniGames.values.fold<int>(
      0,
          (sum, value) => sum + value,
    );

    return DevelopmentReport(
      childId: childId,
      name: _displayName(data),
      playerId: data['playerId']?.toString() ?? "-",
      className: data['className']?.toString() ?? "-",
      stars: _toInt(data['stars']),
      totalActivities: totalActivities,
      totalMiniGames: totalMiniGames,
      dailyCompleted: _dailyCompleted(data),
      dailyGoal: 3,
      strongestArea: _findStrongestArea(stats),
      needsPracticeArea: _findNeedsPracticeArea(stats),
      stats: stats,
      miniGameCounts: miniGames,
    );
  }

  static Future<DevelopmentReport?> getChildReport(String childId) async {
    final doc = await _db.collection('childProfiles').doc(childId).get();
    final data = doc.data();

    if (data == null) return null;

    return fromChildData(
      childId: childId,
      data: data,
    );
  }
}
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../repositories/child_profile_repository.dart';
import '../../repositories/usage_time_repository.dart';
import 'joy_motion.dart';

class UsageLastThreeDaysCard extends StatelessWidget {
  final String? childId;
  final String title;

  const UsageLastThreeDaysCard({
    super.key,
    this.childId,
    this.title = "Son 3 Gün Kullanım",
  });

  Future<String?> _resolveChildId() async {
    if (childId != null && childId!.trim().isNotEmpty) {
      return childId!.trim();
    }

    try {
      return await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      return null;
    }
  }

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "0") ?? 0;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return "$y-$m-$d";
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();

    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
    final currentKey = _dateKey(date);

    if (currentKey == todayKey) return "Bugün";
    if (currentKey == yesterdayKey) return "Dün";

    const months = [
      "Oca",
      "Şub",
      "Mar",
      "Nis",
      "May",
      "Haz",
      "Tem",
      "Ağu",
      "Eyl",
      "Eki",
      "Kas",
      "Ara",
    ];

    return "${date.day} ${months[date.month - 1]}";
  }

  List<_UsageDayItem> _buildLastThreeDays(
      Map<String, Map<String, dynamic>> docs,
      ) {
    final now = DateTime.now();

    final days = [
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 1)),
      now,
    ];

    return days.map((day) {
      final key = _dateKey(day);
      final data = docs[key];

      return _UsageDayItem(
        dateKey: key,
        label: _dayLabel(day),
        seconds: _readInt(data?['totalSeconds']),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return FutureBuilder<String?>(
      future: _resolveChildId(),
      builder: (context, childSnapshot) {
        if (childSnapshot.connectionState == ConnectionState.waiting) {
          return _UsageChartLoadingCard(
            gradient: gradient,
          );
        }

        final resolvedChildId = childSnapshot.data;

        if (resolvedChildId == null || resolvedChildId.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('childProfiles')
              .doc(resolvedChildId)
              .collection('usageDaily')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = <String, Map<String, dynamic>>{};

            for (final doc in snapshot.data?.docs ?? []) {
              docs[doc.id] = doc.data();
            }

            final days = _buildLastThreeDays(docs);

            final totalSeconds = days.fold<int>(
              0,
                  (sum, item) => sum + item.seconds,
            );

            const dailyGoalSeconds = 15 * 60; // 15 dakika günlük hedef

            final maxActualSeconds = days.fold<int>(
              0,
                  (maxValue, item) => math.max(maxValue, item.seconds),
            );

            final maxSeconds = math.max(
              dailyGoalSeconds,
              maxActualSeconds,
            );

            final todaySeconds = days.isNotEmpty ? days.last.seconds : 0;

            return JoyEntrance(
              delayMs: 120,
              beginY: 14,
              child: JoyShine(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: gradient.first.withValues(alpha: 0.14),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradient.first.withValues(alpha: 0.18),
                                  gradient.last.withValues(alpha: 0.22),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bar_chart_rounded,
                              color: gradient.first,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  totalSeconds > 0
                                      ? "Son 3 günde toplam ${UsageTimeRepository.formatSeconds(totalSeconds)} çalışma kaydedildi. Barlar 15 dk günlük hedefe göre gösterilir."
                                      : "Son 3 gün için kullanım kaydı yok.",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: gradient.first.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Bugün ${UsageTimeRepository.formatSeconds(todaySeconds)}",
                              style: TextStyle(
                                color: gradient.first,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ...days.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: _UsageDayBar(
                            item: item,
                            maxSeconds: maxSeconds,
                            gradient: gradient,
                          ),
                        );
                      }),
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
}

class _UsageDayItem {
  final String dateKey;
  final String label;
  final int seconds;

  const _UsageDayItem({
    required this.dateKey,
    required this.label,
    required this.seconds,
  });
}

class _UsageDayBar extends StatelessWidget {
  final _UsageDayItem item;
  final int maxSeconds;
  final List<Color> gradient;

  const _UsageDayBar({
    required this.item,
    required this.maxSeconds,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxSeconds <= 0
        ? 0.0
        : (item.seconds / maxSeconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                item.label,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.seconds > 0
                    ? UsageTimeRepository.formatSeconds(item.seconds)
                    : "Kayıt yok",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.seconds > 0
                      ? gradient.first
                      : Colors.grey.shade500,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final filledWidth = fullWidth * ratio;

            return Stack(
              children: [
                Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: gradient.first.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  width: filledWidth,
                  height: 11,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UsageChartLoadingCard extends StatelessWidget {
  final List<Color> gradient;

  const _UsageChartLoadingCard({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: gradient.first.withValues(alpha: 0.12),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: gradient.first,
        ),
      ),
    );
  }
}
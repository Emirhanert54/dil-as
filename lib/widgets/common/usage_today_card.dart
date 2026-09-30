import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../repositories/child_profile_repository.dart';
import '../../repositories/usage_time_repository.dart';
import 'joy_motion.dart';

class UsageTodayCard extends StatelessWidget {
  final String? childId;
  final String title;

  const UsageTodayCard({
    super.key,
    this.childId,
    this.title = "Bugünkü Süre",
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
  String _cleanText(dynamic value) {
    return value?.toString().trim() ?? "";
  }

  String _humanizeKeyPart(String value) {
    final raw = value
        .replaceAll("_", " ")
        .trim();

    if (raw.isEmpty) return "";

    return raw
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      if (part.isEmpty) return part;

      if (RegExp(r'^[0-9]+$').hasMatch(part)) {
        return part;
      }

      return part[0].toUpperCase() + part.substring(1);
    })
        .join(" ");
  }

  String _miniGamePrettyName(String key) {
    switch (key) {
      case "mini_balloonletter":
      case "mini_balloonLetter":
        return "Balon Harf Avı";
      case "mini_fruitbasket":
      case "mini_fruitBasket":
        return "Meyveleri Sepete Taşı";
      case "mini_memorycards":
      case "mini_memoryCards":
        return "Hafıza Kartları";
      case "mini_matching":
        return "Eşleştirme";
      default:
        return _humanizeKeyPart(key.replaceFirst("mini_", ""));
    }
  }

  String _prettyActivityTitle(
      String key,
      Map<String, dynamic> data,
      ) {
    final type = _cleanText(data['type']);
    final rawTitle = _cleanText(data['title']);
    final category = _cleanText(data['category']);
    final levelTitle = _cleanText(data['levelTitle']);

    if (type == "miniGame") {
      if (rawTitle.isNotEmpty) return rawTitle;
      return _miniGamePrettyName(key);
    }

    if (category.isNotEmpty && levelTitle.isNotEmpty) {
      return "$category: $levelTitle";
    }

    if (rawTitle.contains(":")) {
      return rawTitle;
    }

    final normalizedKey = key.toLowerCase();

    const categoryPrefixes = {
      "heceleme": "Heceleme",
      "tanima": "Tanıma",
      "hiz": "Hız",
      "bellek": "Bellek",
      "yazma": "Yazma",
      "hikaye": "Hikaye",
      "sesler": "Sesler",
      "okuma": "Okuma",
    };

    for (final entry in categoryPrefixes.entries) {
      final prefix = "${entry.key}_";

      if (normalizedKey.startsWith(prefix)) {
        final rest = normalizedKey.replaceFirst(prefix, "");
        final cleanLevel = rawTitle.isNotEmpty
            ? rawTitle
            : _humanizeKeyPart(rest);

        return "${entry.value}: $cleanLevel";
      }
    }

    if (rawTitle.isNotEmpty) return rawTitle;

    return _humanizeKeyPart(key);
  }

  List<_UsageActivityItem> _parseActivities(dynamic raw) {
    if (raw is! Map) return [];

    final items = <_UsageActivityItem>[];

    raw.forEach((key, value) {
      if (value is! Map) return;

      final data = Map<String, dynamic>.from(value);

      final seconds = _readInt(data['seconds']);
      if (seconds <= 0) return;

      items.add(
        _UsageActivityItem(
          key: key.toString(),
          title: _prettyActivityTitle(
            key.toString(),
            data,
          ),
          type: data['type']?.toString() ?? "activity",
          seconds: seconds,
          completedCount: _readInt(data['completedCount']),
        ),
      );
    });

    items.sort((a, b) => b.seconds.compareTo(a.seconds));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return FutureBuilder<String?>(
      future: _resolveChildId(),
      builder: (context, childSnapshot) {
        if (childSnapshot.connectionState == ConnectionState.waiting) {
          return _UsageLoadingCard(
            gradient: gradient,
          );
        }

        final resolvedChildId = childSnapshot.data;

        if (resolvedChildId == null || resolvedChildId.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final todayKey = UsageTimeRepository.todayKey();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('childProfiles')
              .doc(resolvedChildId)
              .collection('usageDaily')
              .doc(todayKey)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            final totalSeconds = _readInt(data?['totalSeconds']);
            final activities = _parseActivities(data?['activities']);

            return JoyEntrance(
              delayMs: 90,
              beginY: 14,
              child: JoyShine(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: gradient.first.withValues(alpha: 0.14),
                      width: 1.3,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          JoyFloat(
                            distance: 4,
                            durationMs: 1800,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.timer_rounded,
                                color: Colors.black87,
                                size: 30,
                              ),
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
                                    color: Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalSeconds > 0
                                      ? "Bugün toplam ${UsageTimeRepository.formatSeconds(totalSeconds)} geçirdi."
                                      : "Bugün henüz etkinlik süresi yok.",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: gradient.first.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              UsageTimeRepository.formatSeconds(totalSeconds),
                              style: TextStyle(
                                color: gradient.first,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (activities.isEmpty)
                        _EmptyUsageState()
                      else
                        Column(
                          children: activities.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _UsageActivityRow(
                                item: item,
                              ),
                            );
                          }).toList(),
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
}

class _UsageActivityItem {
  final String key;
  final String title;
  final String type;
  final int seconds;
  final int completedCount;

  const _UsageActivityItem({
    required this.key,
    required this.title,
    required this.type,
    required this.seconds,
    required this.completedCount,
  });
}

class _UsageActivityRow extends StatelessWidget {
  final _UsageActivityItem item;

  const _UsageActivityRow({
    required this.item,
  });

  String get _icon {
    if (item.type == "miniGame") return "🎮";
    return "📘";
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first.withValues(alpha: 0.08),
            gradient.last.withValues(alpha: 0.11),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gradient.first.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient.first.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              _icon,
              style: const TextStyle(fontSize: 17),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.completedCount > 0
                      ? "${item.completedCount} tamamlanma"
                      : item.type == "miniGame"
                      ? "Mini oyun"
                      : "Etkinlik",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: gradient.first.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              UsageTimeRepository.formatSeconds(item.seconds),
              style: TextStyle(
                color: gradient.first,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsageState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: gradient.first.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gradient.first.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        "Çocuk bugün oyun oynadıkça burada süre raporu görünecek.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _UsageLoadingCard extends StatelessWidget {
  final List<Color> gradient;

  const _UsageLoadingCard({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first.withValues(alpha: 0.75),
            gradient.last.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Text(
            "Süre raporu yükleniyor...",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
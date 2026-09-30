import 'package:flutter/material.dart';
class DailyMissionCard extends StatelessWidget {
  final int completed;
  final int goal;
  final int bonus;
  final bool bonusClaimed;
  final double progress;

  const DailyMissionCard({
    super.key,
    required this.completed,
    required this.goal,
    required this.bonus,
    required this.bonusClaimed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final done = completed >= goal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: done
              ? const [Color(0xFF66BB6A), Color(0xFF43A047)]
              : const [Color(0xFFFFA726), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (done ? Colors.green : Colors.orange).withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              done ? "🎁" : "🎯",
              style: const TextStyle(fontSize: 34),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? "Bugünkü Görev Tamam!" : "Bugünkü Görev",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bonusClaimed
                      ? "$bonus bonus yıldız kazanıldı"
                      : "$goal etkinlik tamamla • +$bonus bonus yıldız",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              "${completed > goal ? goal : completed}/$goal",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
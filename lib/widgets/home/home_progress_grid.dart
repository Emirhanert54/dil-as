import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../common/joy_motion.dart';

class HomeProgressGrid extends StatelessWidget {
  final int completed;
  final int goal;
  final bool bonusClaimed;
  final Map<String, dynamic>? lastActivity;
  final VoidCallback? onDailyTaskTap;
  final VoidCallback? onContinueTap;

  const HomeProgressGrid({
    super.key,
    required this.completed,
    required this.goal,
    required this.bonusClaimed,
    required this.lastActivity,
    required this.onDailyTaskTap,
    required this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;

    final safeCompleted = completed.clamp(0, goal);
    final progressText = "$safeCompleted/$goal";

    final levelTitle =
    lastActivity?["levelTitle"]?.toString().trim().isNotEmpty == true
        ? lastActivity!["levelTitle"].toString()
        : "Etkinlik yok";

    return Row(
      children: [
        Expanded(
          child: JoyEntrance(
            delayMs: 240,
            child: _ProgressMiniCard(
              icon: "🎁",
              title: bonusClaimed ? "Görev Tamam" : "Günlük Görev",
              subtitle: bonusClaimed ? "Bonus alındı" : "$progressText ilerleme",
              badge: progressText,
              gradient: [
                theme.gradient.first,
                theme.gradient.last,
              ],
              onTap: onDailyTaskTap,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: JoyEntrance(
            delayMs: 320,
            child: _ProgressMiniCard(
              icon: "▶️",
              title: "Son Oyun",
              subtitle: levelTitle,
              badge: onContinueTap == null ? "Yok" : "Git",
              gradient: [
                theme.gradient.last,
                theme.gradient.first,
              ],
              onTap: onContinueTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressMiniCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _ProgressMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape =
        size.width > size.height && size.shortestSide >= 600;

    final cardHeight = isTabletLandscape ? 116.0 : 78.0;
    final iconSize = isTabletLandscape ? 58.0 : 42.0;
    final iconFont = isTabletLandscape ? 30.0 : 22.0;
    final titleFont = isTabletLandscape ? 15.0 : 12.0;
    final subtitleFont = isTabletLandscape ? 12.0 : 10.0;
    final badgeFont = isTabletLandscape ? 11.0 : 9.0;

    return JoyShine(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            height: cardHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: TextStyle(
                            fontSize: iconFont,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFont,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: subtitleFont,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: badgeFont,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
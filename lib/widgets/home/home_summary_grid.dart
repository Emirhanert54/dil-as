import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../common/joy_motion.dart';

class HomeSummaryGrid extends StatelessWidget {
  const HomeSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;

    return Row(
      children: [
        Expanded(
          child: JoyEntrance(
            delayMs: 80,
            child: _SummaryMiniCard(
              icon: "⭐",
              title: "Yıldız",
              subtitle: "${u.stars} yıldız",
              gradient: [
                theme.gradient.first,
                theme.gradient.last,
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: JoyEntrance(
            delayMs: 160,
            child: _SummaryMiniCard(
              icon: u.currentMascot.emoji,
              title: "Sticker",
              subtitle: u.currentMascot.title,
              gradient: [
                theme.gradient.last,
                theme.gradient.first,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _SummaryMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape =
        size.width > size.height && size.shortestSide >= 600;

    final cardHeight = isTabletLandscape ? 116.0 : 78.0;
    final iconSize = isTabletLandscape ? 58.0 : 42.0;
    final iconFont = isTabletLandscape ? 31.0 : 23.0;
    final titleFont = isTabletLandscape ? 15.0 : 12.0;
    final subtitleFont = isTabletLandscape ? 12.0 : 10.0;

    return JoyShine(
      borderRadius: BorderRadius.circular(22),
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
        child: Row(
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
          ],
        ),
      ),
    );
  }
}
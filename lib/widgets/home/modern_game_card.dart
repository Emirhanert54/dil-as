import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../providers/app_provider.dart';
import 'level_picker_dialog.dart';

class ModernGameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final String gameType;

  const ModernGameCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;
    final r = AppResponsive.of(context);

    final cardGradient = theme.id == "car"
        ? const [
      Color(0xFF6EC6FF),
      Color(0xFFFFB74D),
    ]
        : theme.gradient;

    final colors = _themeGradient(theme.id, gradient);
    final decorationEmoji = _themeDecoration(theme.id);
    final subtitle = _themeSubtitle(theme.id);

    final isLandscape = r.isLandscape;

    final radius = r.responsiveValue(
      phonePortrait: 28,
      phoneLandscape: 22,
      tabletPortrait: 30,
      tabletLandscape: 24,
      largeTabletPortrait: 32,
      largeTabletLandscape: 26,
    );

    final padding = r.responsiveValue(
      phonePortrait: 16,
      phoneLandscape: 10,
      tabletPortrait: 18,
      tabletLandscape: 12,
      largeTabletPortrait: 20,
      largeTabletLandscape: 13,
    );

    final iconBox = r.responsiveValue(
      phonePortrait: 52,
      phoneLandscape: 50,
      tabletPortrait: 62,
      tabletLandscape: 64,
      largeTabletPortrait: 68,
      largeTabletLandscape: 70,
    );

    final iconSize = r.responsiveValue(
      phonePortrait: 28,
      phoneLandscape: 23,
      tabletPortrait: 31,
      tabletLandscape: 25,
      largeTabletPortrait: 34,
      largeTabletLandscape: 27,
    );

    final titleSize = r.responsiveValue(
      phonePortrait: 13,
      phoneLandscape: 13,
      tabletPortrait: 15,
      tabletLandscape: 15.5,
      largeTabletPortrait: 16,
      largeTabletLandscape: 16,
    );

    final subtitleSize = r.responsiveValue(
      phonePortrait: 10,
      phoneLandscape: 10,
      tabletPortrait: 11.5,
      tabletLandscape: 12,
      largeTabletPortrait: 12,
      largeTabletLandscape: 12.5,
    );

    final emojiSize = r.responsiveValue(
      phonePortrait: 46,
      phoneLandscape: 34,
      tabletPortrait: 54,
      tabletLandscape: 38,
      largeTabletPortrait: 58,
      largeTabletLandscape: 42,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          showLevelPickerDialog(
            context: context,
            gameType: gameType,
            color: colors.first,
            title: title,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(isLandscape ? 0.18 : 0.28),
                blurRadius: isLandscape ? 10 : 16,
                offset: Offset(0, isLandscape ? 5 : 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.4,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: isLandscape ? -2 : -4,
                top: isLandscape ? -2 : -4,
                child: Opacity(
                  opacity: 0.16,
                  child: Text(
                    decorationEmoji,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              ),

              Positioned(
                left: isLandscape ? -14 : -10,
                bottom: isLandscape ? -16 : -12,
                child: Container(
                  width: isLandscape ? 46 : 58,
                  height: isLandscape ? 46 : 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),

                    SizedBox(height: isLandscape ? 7 : 12),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),

                    SizedBox(height: isLandscape ? 3 : 5),

                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _themeGradient(String themeId, List<Color> fallback) {
    switch (themeId) {
      case "space":
        return const [
          Color(0xFF321A80),
          Color(0xFF7B2FF7),
          Color(0xFF00C6FF),
        ];

      case "car":
        return const [
          Color(0xFFFF9800),
          Color(0xFFFF5252),
          Color(0xFF263238),
        ];

      case "forest":
        return const [
          Color(0xFF66BB6A),
          Color(0xFF2E7D32),
          Color(0xFF00796B),
        ];

      case "rainbow":
        return const [
          Color(0xFFFF8A80),
          Color(0xFFFFC107),
          Color(0xFF64B5F6),
        ];

      default:
        return fallback;
    }
  }

  String _themeDecoration(String themeId) {
    switch (themeId) {
      case "space":
        return "🪐";
      case "car":
        return "🏁";
      case "forest":
        return "🍃";
      case "rainbow":
        return "🌈";
      default:
        return "✨";
    }
  }

  String _themeSubtitle(String themeId) {
    switch (themeId) {
      case "space":
        return "Uzay görevi";
      case "car":
        return "Yarışa başla";
      case "forest":
        return "Doğa macerası";
      case "rainbow":
        return "Renkli oyun";
      default:
        return "Seviye seç";
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../pages/student_home.dart';
import '../../providers/app_provider.dart';
import '../../repositories/game_repository.dart';

Future<void> showLevelPickerDialog({
  required BuildContext context,
  required String gameType,
  required Color color,
  required String title,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (dialogContext) {
      return Consumer<AppProvider>(
        builder: (context, provider, _) {
          final theme = provider.currentTheme;
          final levels = GameRepository.getLevels(gameType);
          final r = AppResponsive.of(context);
          final screen = MediaQuery.of(context).size;

          final isWide = r.isLandscape || r.isTablet || r.isLargeTablet;

          final dialogMaxWidth = levels.length <= 3
              ? r.responsiveValue(
            phonePortrait: 430,
            phoneLandscape: 520,
            tabletPortrait: 540,
            tabletLandscape: 560,
            largeTabletPortrait: 600,
            largeTabletLandscape: 620,
          )
              : r.responsiveValue(
            phonePortrait: 430,
            phoneLandscape: 720,
            tabletPortrait: 560,
            tabletLandscape: 780,
            largeTabletPortrait: 620,
            largeTabletLandscape: 860,
          );

          final dialogMaxHeight = screen.height *
              r.responsiveValue(
                phonePortrait: 0.78,
                phoneLandscape: 0.78,
                tabletPortrait: 0.72,
                tabletLandscape: 0.76,
                largeTabletPortrait: 0.70,
                largeTabletLandscape: 0.74,
              );

          final headerPadding = EdgeInsets.fromLTRB(
            r.isLandscape ? 14 : 18,
            r.isLandscape ? 12 : 18,
            r.isLandscape ? 10 : 14,
            r.isLandscape ? 12 : 18,
          );

          final headerIconSize = r.responsiveValue(
            phonePortrait: 54,
            phoneLandscape: 44,
            tabletPortrait: 58,
            tabletLandscape: 48,
            largeTabletPortrait: 62,
            largeTabletLandscape: 52,
          );

          final titleSize = r.responsiveValue(
            phonePortrait: 18,
            phoneLandscape: 15,
            tabletPortrait: 20,
            tabletLandscape: 17,
            largeTabletPortrait: 22,
            largeTabletLandscape: 18,
          );

          final subtitleSize = r.responsiveValue(
            phonePortrait: 12,
            phoneLandscape: 10.5,
            tabletPortrait: 13,
            tabletLandscape: 11.5,
            largeTabletPortrait: 14,
            largeTabletLandscape: 12,
          );

          final radius = r.responsiveValue(
            phonePortrait: 34,
            phoneLandscape: 26,
            tabletPortrait: 36,
            tabletLandscape: 28,
            largeTabletPortrait: 38,
            largeTabletLandscape: 30,
          );

          final contentPadding = EdgeInsets.fromLTRB(
            r.isLandscape ? 14 : 16,
            r.isLandscape ? 12 : 16,
            r.isLandscape ? 14 : 16,
            r.isLandscape ? 14 : 18,
          );

          final tileHeight = r.responsiveValue(
            phonePortrait: 82,
            phoneLandscape: 70,
            tabletPortrait: 88,
            tabletLandscape: 76,
            largeTabletPortrait: 92,
            largeTabletLandscape: 80,
          );

          final baseColumns = r.responsiveValue(
            phonePortrait: 1,
            phoneLandscape: 2,
            tabletPortrait: 1,
            tabletLandscape: 2,
            largeTabletPortrait: 1,
            largeTabletLandscape: 2,
          ).round();

          final columns = levels.length <= 3 ? 1 : baseColumns;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: r.isLandscape ? 18 : 18,
              vertical: r.isLandscape ? 14 : 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogMaxWidth,
                  maxHeight: dialogMaxHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: theme.gradient.first.withOpacity(0.28),
                        blurRadius: r.isLandscape ? 18 : 28,
                        offset: Offset(0, r.isLandscape ? 9 : 14),
                      ),
                    ],
                    border: Border.all(
                      color: theme.gradient.first.withOpacity(0.20),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: headerPadding,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: theme.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: headerIconSize,
                                height: headerIconSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.32),
                                    width: 1.4,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _gameEmoji(gameType),
                                    style: TextStyle(
                                      fontSize: r.isLandscape ? 23 : 28,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: r.isLandscape ? 11 : 13),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Hangi bölümü oynayalım?",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: subtitleSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                visualDensity: r.isLandscape
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                icon: const Icon(Icons.close_rounded),
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),

                        Flexible(
                          child: isWide
                              ? GridView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: contentPadding,
                            itemCount: levels.length,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: tileHeight,
                            ),
                            itemBuilder: (context, index) {
                              final level = levels[index];
                              final levelTitle =
                                  level['title']?.toString() ?? "Bölüm";

                              return _ModernLevelTile(
                                compact: true,
                                emoji: _levelEmoji(gameType, levelTitle),
                                title: levelTitle,
                                subtitle:
                                _levelSubtitle(gameType, levelTitle),
                                gradient: theme.gradient,
                                onTap: () {
                                  _openSelectedLevel(
                                    context: context,
                                    dialogContext: dialogContext,
                                    gameType: gameType,
                                    levelTitle: levelTitle,
                                    level: level,
                                  );
                                },
                              );
                            },
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: contentPadding,
                            itemCount: levels.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final level = levels[index];
                              final levelTitle =
                                  level['title']?.toString() ?? "Bölüm";

                              return _ModernLevelTile(
                                compact: false,
                                emoji: _levelEmoji(gameType, levelTitle),
                                title: levelTitle,
                                subtitle:
                                _levelSubtitle(gameType, levelTitle),
                                gradient: theme.gradient,
                                onTap: () {
                                  _openSelectedLevel(
                                    context: context,
                                    dialogContext: dialogContext,
                                    gameType: gameType,
                                    levelTitle: levelTitle,
                                    level: level,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _openSelectedLevel({
  required BuildContext context,
  required BuildContext dialogContext,
  required String gameType,
  required String levelTitle,
  required Map<String, dynamic> level,
}) {
  final qs = GameRepository.prepareQuestions(
    List<Map<String, dynamic>>.from(
      (level['questions'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
      ),
    ),
  );

  final detailedKey = "$gameType: $levelTitle";

  final gameScreen = _buildGameScreen(
    gameType: gameType,
    gameKey: detailedKey,
    questions: qs,
  );

  Navigator.pop(dialogContext);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => gameScreen,
    ),
  );
}

Widget _buildGameScreen({
  required String gameType,
  required String gameKey,
  required List<Map<String, dynamic>> questions,
}) {
  switch (gameType) {
    case 'Heceleme':
      return GameSyllable(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Tanıma':
      return GameRecognition(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Hız':
    case 'Hızlı Gör':
      return GameSpeed(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Bellek':
      return GameMemory(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Yazma':
      return GameSpelling(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Hikaye':
      return GameStory(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Sesler':
      return GameSound(
        questions: questions,
        gameKey: gameKey,
      );

    case 'Okuma':
      return GameReading(
        questions: questions,
        gameKey: gameKey,
      );

    default:
      return const Scaffold(
        body: Center(
          child: Text("Etkinlik bulunamadı."),
        ),
      );
  }
}

class _ModernLevelTile extends StatelessWidget {
  final bool compact;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModernLevelTile({
    required this.compact,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 42.0 : 52.0;
    final emojiSize = compact ? 22.0 : 27.0;
    final playSize = compact ? 36.0 : 42.0;
    final titleSize = compact ? 12.5 : 14.0;
    final subtitleSize = compact ? 10.0 : 11.0;
    final padding = compact ? 10.0 : 13.0;
    final radius = compact ? 20.0 : 24.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: gradient.first.withOpacity(0.16),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradient.first.withOpacity(0.20),
                      gradient.last.withOpacity(0.20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              ),

              SizedBox(width: compact ? 10 : 13),

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
                        color: Colors.black87,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: compact ? 24 : 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _gameEmoji(String gameType) {
  switch (gameType) {
    case "Heceleme":
      return "🧩";
    case "Tanıma":
      return "🖼️";
    case "Hız":
    case "Hızlı Gör":
      return "⚡";
    case "Bellek":
      return "🧠";
    case "Yazma":
      return "✍️";
    case "Hikaye":
      return "📖";
    case "Sesler":
      return "👂";
    case "Okuma":
      return "📚";
    default:
      return "🎮";
  }
}

String _levelEmoji(String gameType, String title) {
  final t = title.toLowerCase();

  if (t.contains("meyve")) return "🍐";
  if (t.contains("hayvan")) return "🐾";
  if (t.contains("taşıt") || t.contains("tasit")) return "🚗";

  if (t.contains("renk")) return "🎨";
  if (t.contains("şekil") || t.contains("sekil")) return "🔷";
  if (t.contains("sayı") || t.contains("sayi")) return "🔢";

  if (t.contains("rakam")) return "🔢";
  if (t.contains("harf")) return "🔤";
  if (t.contains("sembol")) return "🔣";

  if (t.contains("doğa") || t.contains("doga")) return "🍃";
  if (t.contains("yiyecek")) return "🍽️";
  if (t.contains("eşya") || t.contains("esya")) return "🎒";

  if (t.contains("kısa") || t.contains("kisa")) return "💬";
  if (t.contains("orta")) return "🗣️";
  if (t.contains("uzun")) return "📜";

  if (t.contains("başlangıç") || t.contains("baslangic")) return "🔈";
  if (t.contains("bitiş") || t.contains("bitis")) return "🔊";
  if (t.contains("içindeki") || t.contains("icindeki")) return "🎧";

  if (t.contains("kolay")) return "🌱";
  if (t.contains("zor")) return "🏆";

  switch (gameType) {
    case "Heceleme":
      return "🧩";
    case "Tanıma":
      return "👀";
    case "Hız":
    case "Hızlı Gör":
      return "⚡";
    case "Bellek":
      return "🧠";
    case "Yazma":
      return "✏️";
    case "Hikaye":
      return "📖";
    case "Sesler":
      return "👂";
    case "Okuma":
      return "📚";
    default:
      return "🎯";
  }
}

String _levelSubtitle(String gameType, String title) {
  switch (gameType) {
    case "Heceleme":
      return "Heceleri sırayla birleştir";
    case "Tanıma":
      return "Resme bak ve doğruyu seç";
    case "Hız":
    case "Hızlı Gör":
      return "Hızlı gör, aklında tut";
    case "Bellek":
      return "Gördüğünü hatırla";
    case "Yazma":
      return "Harfleri sıraya diz";
    case "Hikaye":
      return "Cümleyi doğru kur";
    case "Sesler":
      return "Sesi dinle ve bul";
    case "Okuma":
      return "Okunanı doğru seç";
    default:
      return "$title bölümüne başla";
  }
}
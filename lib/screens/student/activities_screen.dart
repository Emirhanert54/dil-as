import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../pages/student_home.dart';
import '../../providers/app_provider.dart';
import '../../repositories/game_repository.dart';
import '../../widgets/common/joy_motion.dart';
import '../../widgets/common/premium_upgrade_dialog.dart'; // 👈 Kilitli karta tıklanınca açılacak premium ekranı importu

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.currentTheme;
    final gradient = theme.gradient;
    final isPremium = provider.isPremium; // 👈 Premium kontrolü

    // 👈 SADECE ÜCRETSİZ OLACAK OYUNLARIN LİSTESİ
    final freeGames = ['Heceleme', 'Tanıma'];

    final games = <Map<String, String>>[
      {
        'gameType': 'Heceleme',
        'title': 'Heceleme',
        'icon': '🧩',
        'desc': 'Heceleri birleştir',
      },
      {
        'gameType': 'Tanıma',
        'title': 'Tanıma',
        'icon': '🖼️',
        'desc': 'Resme bak ve doğruyu seç',
      },
      {
        'gameType': 'Hız',
        'title': 'Hızlı Gör',
        'icon': '⚡',
        'desc': 'Hızlı gör, aklında tut',
      },
      {
        'gameType': 'Bellek',
        'title': 'Bellek',
        'icon': '🧠',
        'desc': 'Gördüğünü hatırla',
      },
      {
        'gameType': 'Yazma',
        'title': 'Yazma',
        'icon': '✍️',
        'desc': 'Harfleri sıraya diz',
      },
      {
        'gameType': 'Hikaye',
        'title': 'Hikaye',
        'icon': '📖',
        'desc': 'Cümleyi doğru kur',
      },
      {
        'gameType': 'Sesler',
        'title': 'Sesler',
        'icon': '👂',
        'desc': 'Sesi dinle ve bul',
      },
      {
        'gameType': 'Okuma',
        'title': 'Okuma',
        'icon': '📚',
        'desc': 'Okunanı doğru seç',
      },
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text(
          'Etkinlikler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final isTabletPortrait = !isLandscape && constraints.maxWidth >= 600;

          final crossAxisCount = isLandscape ? 4 : 2;
          final spacing = isLandscape ? 18.0 : 14.0;

          final gridPadding = isLandscape
              ? const EdgeInsets.fromLTRB(24, 18, 24, 24)
              : const EdgeInsets.fromLTRB(18, 16, 18, 18);

          final availableHeight = constraints.maxHeight -
              gridPadding.vertical -
              (spacing * 3);

          final portraitCardHeight = (availableHeight / 4).clamp(
            isTabletPortrait ? 135.0 : 150.0,
            isTabletPortrait ? 210.0 : 185.0,
          );

          final landscapeCardHeight = (constraints.maxHeight -
              gridPadding.vertical -
              spacing) /
              2;

          final mainAxisExtent = isLandscape
              ? landscapeCardHeight.clamp(130.0, 600.0)
              : portraitCardHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient.first.withValues(alpha: 0.32),
                        theme.background,
                        gradient.last.withValues(alpha: 0.28),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: -70,
                left: -45,
                child: JoyFloat(
                  distance: 10,
                  durationMs: 2600,
                  child: _ThemeBlob(
                    size: isLandscape ? 260 : 190,
                    color: gradient.first.withValues(alpha: 0.25),
                  ),
                ),
              ),

              Positioned(
                top: isLandscape ? 70 : 110,
                right: -55,
                child: JoyFloat(
                  distance: 12,
                  durationMs: 3000,
                  delayMs: 250,
                  child: _ThemeBlob(
                    size: isLandscape ? 230 : 160,
                    color: gradient.last.withValues(alpha: 0.24),
                  ),
                ),
              ),

              Positioned(
                bottom: -80,
                left: -35,
                child: JoyFloat(
                  distance: 9,
                  durationMs: 2900,
                  delayMs: 500,
                  child: _ThemeBlob(
                    size: isLandscape ? 270 : 210,
                    color: gradient.first.withValues(alpha: 0.18),
                  ),
                ),
              ),

              Positioned(
                bottom: isLandscape ? 40 : 120,
                right: -70,
                child: JoyFloat(
                  distance: 11,
                  durationMs: 3100,
                  delayMs: 700,
                  child: _ThemeBlob(
                    size: isLandscape ? 250 : 190,
                    color: gradient.last.withValues(alpha: 0.16),
                  ),
                ),
              ),

              SafeArea(
                child: GridView.builder(
                  padding: gridPadding,
                  itemCount: games.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: mainAxisExtent,
                  ),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    // 👈 EĞER KULLANICI PREMİUM DEĞİLSE VE OYUN ÜCRETSİZLER LİSTESİNDE YOKSA KİLİTLE
                    final isLocked = !isPremium && !freeGames.contains(game['gameType']);

                    return _ActivityGameCard(
                      index: index,
                      gameType: game['gameType']!,
                      title: game['title']!,
                      icon: game['icon']!,
                      desc: game['desc']!,
                      gradient: gradient,
                      isLandscape: isLandscape,
                      isLocked: isLocked, // 👈 Karta kilit durumunu yolluyoruz
                      onTap: () {
                        if (isLocked) {
                          // 👈 Kilitliyse Premium Ekranını Fırlat
                          showDialog(
                            context: context,
                            builder: (context) => const PremiumUpgradeDialog(),
                          );
                        } else {
                          // 👈 Kilitsizse normal oyunu aç
                          showLevelPickerDialog(
                            context: context,
                            gameType: game['gameType']!,
                            color: gradient.first,
                            title: game['title']!,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: BannerReklamWidget(),
      ),
    );
  }
}

class _ActivityGameCard extends StatelessWidget {
  final int index;
  final String gameType;
  final String title;
  final String icon;
  final String desc;
  final List<Color> gradient;
  final bool isLandscape;
  final bool isLocked; // 👈 Kilit değişkenini ekledik
  final VoidCallback onTap;

  const _ActivityGameCard({
    required this.index,
    required this.gameType,
    required this.title,
    required this.icon,
    required this.desc,
    required this.gradient,
    required this.isLandscape,
    required this.isLocked, // 👈 Required yaptık
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30);

    return JoyEntrance(
      delayMs: 70 + (index * 55),
      beginY: 18,
      child: JoyShine(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(isLandscape ? 12 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient.first.withValues(alpha: 0.94),
                    gradient.last.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.36),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -18,
                    child: Container(
                      width: isLandscape ? 70 : 76,
                      height: isLandscape ? 70 : 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -25,
                    left: -20,
                    child: Container(
                      width: isLandscape ? 78 : 82,
                      height: isLandscape ? 78 : 82,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        JoyPulse(
                          minScale: 0.98,
                          maxScale: 1.045,
                          durationMs: 1450 + (index * 55),
                          child: Container(
                            width: isLandscape ? 86 : 66,
                            height: isLandscape ? 86 : 66,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.34),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.13),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: TextStyle(
                                  fontSize: isLandscape ? 44 : 35,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isLandscape ? 8 : 12),

                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isLandscape ? 20 : 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        SizedBox(height: isLandscape ? 8 : 5),

                        Text(
                          desc,
                          maxLines: isLandscape ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: isLandscape ? 13 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 👈 İŞTE KİLİT EKRANI (PERDE VE İKON) BURAYA GELDİ
                  if (isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55), // Siyah şık perde
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ... Kalan kısımlar (_ThemeBlob, showLevelPickerDialog, _ModernLevelTile vs.) olduğu gibi aynı ...

class _ThemeBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _ThemeBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

Future<void> showLevelPickerDialog({
  required BuildContext context,
  required String gameType,
  required Color color,
  required String title,
}) async {
  final rootContext = context;

  await showDialog(
    context: rootContext,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Consumer<AppProvider>(
        builder: (consumerContext, provider, _) {
          final theme = provider.currentTheme;
          final levels = GameRepository.getLevels(gameType);

          return JoyEntrance(
            delayMs: 0,
            beginY: 18,
            child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),

                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: theme.gradient.first.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                      border: Border.all(
                        color: theme.gradient.first.withValues(alpha: 0.20),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          JoyShine(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(34),
                              topRight: Radius.circular(34),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: theme.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  JoyPulse(
                                    minScale: 0.98,
                                    maxScale: 1.045,
                                    durationMs: 1450,
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                          Colors.white.withValues(alpha: 0.32),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _gameEmoji(gameType),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 13),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Hangi bölümü oynayalım?",
                                          style: TextStyle(
                                            color:
                                            Colors.white.withValues(alpha: 0.92),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                              itemCount: levels.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final level = levels[index];
                                final levelTitle =
                                    level['title']?.toString() ?? "Bölüm";

                                return JoyEntrance(
                                  delayMs: 80 + (index * 70),
                                  beginY: 12,
                                  child: _ModernLevelTile(
                                    emoji: _levelEmoji(gameType, levelTitle),
                                    title: levelTitle,
                                    subtitle: _levelSubtitle(gameType, levelTitle),
                                    gradient: theme.gradient,
                                    onTap: () {
                                      final qs =
                                      GameRepository.prepareRandomQuestions(
                                        List<Map<String, dynamic>>.from(
                                          level['questions'] as List,
                                        ),
                                      );

                                      final detailedKey = "$gameType: $levelTitle";

                                      final gameScreen = _buildGameScreen(
                                        gameType: gameType,
                                        gameKey: detailedKey,
                                        questions: qs,
                                      );

                                      Navigator.pop(dialogContext);

                                      Future.delayed(
                                        const Duration(milliseconds: 120),
                                            () {
                                          if (!rootContext.mounted) return;

                                          Navigator.push(
                                            rootContext,
                                            MaterialPageRoute(
                                              builder: (_) => gameScreen,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ),
          );
        },
      );
    },
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
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModernLevelTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JoyShine(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: gradient.first.withValues(alpha: 0.16),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                JoyPulse(
                  minScale: 0.98,
                  maxScale: 1.04,
                  durationMs: 1500,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradient.first.withValues(alpha: 0.20),
                          gradient.last.withValues(alpha: 0.20),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 27),
                      ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 27,
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
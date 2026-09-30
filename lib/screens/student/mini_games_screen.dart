import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../widgets/banner_ad_widget.dart';
import '../../services/ad_manager.dart';
import '../../widgets/common/mini_game_usage_tracker.dart';
import '../../providers/app_provider.dart';
import '../../services/voice_service.dart';
import '../../widgets/common/themed_background.dart';
import '../../repositories/child_profile_repository.dart';
import '../../core/responsive.dart';
import '../../repositories/usage_time_repository.dart';
import '../../widgets/common/joy_motion.dart';
// 👈 PREMİUM EKRAN İMPORTU (Bunu eklemeyi unutma!)
import '../../widgets/common/premium_upgrade_dialog.dart';

import 'fruit_basket_game_screen.dart'; // Eğer diğer dosyalardan importlar varsa sende olduğu gibi kalsın

Future<void> _saveMiniGameRewardToProfile({
  required String uid,
  required String gameKey,
  int rewardStars = 1,
  Map<String, dynamic> extraData = const {},
}) async {
  final firestore = FirebaseFirestore.instance;

  String? childId;

  try {
    childId = await ChildProfileRepository.ensureActiveChildProfile();
  } catch (_) {
    childId = null;
  }

  final rewardPatch = {
    'stars': FieldValue.increment(rewardStars),
    'miniGames': {
      gameKey: {
        'completedCount': FieldValue.increment(1),
        'lastCompletedAt': FieldValue.serverTimestamp(),
        ...extraData,
      },
    },
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (childId != null && childId.trim().isNotEmpty) {
    await firestore.collection('childProfiles').doc(childId).set(
      {
        ...rewardPatch,
        'childId': childId,
        'ownerUid': uid,
        'hasChildProfiles': true,
      },
      SetOptions(merge: true),
    );
  }

  await firestore.collection('users').doc(uid).set(
    {
      ...rewardPatch,
      if (childId != null && childId.trim().isNotEmpty)
        'activeChildId': childId,
      if (childId != null && childId.trim().isNotEmpty)
        'hasChildProfiles': true,
    },
    SetOptions(merge: true),
  );
}

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  static const List<_MiniGameMenuItem> _items = [
    _MiniGameMenuItem(
      emoji: "🎈",
      title: "Balon Harf Avı",
      subtitle: "Söylenen harfi balonların arasından bul.",
      reward: "+1 yıldız",
      screen: BalloonLetterGameScreen(),
    ),
    _MiniGameMenuItem(
      emoji: "🧺",
      title: "Meyveleri Sepete Taşı",
      subtitle: "Meyveleri sürükleyip sepete bırak.",
      reward: "+1 yıldız",
      screen: FruitBasketGameScreen(),
    ),
    _MiniGameMenuItem(
      emoji: "🃏",
      title: "Hafıza Kartları",
      subtitle: "Aynı kartları bul ve eşleştir.",
      reward: "+1 yıldız",
      screen: MemoryCardsMiniGameScreen(),
    ),
    _MiniGameMenuItem(
      emoji: "🧩",
      title: "Eşleştirme",
      subtitle: "Resmi doğru kelimeyle eşleştir.",
      reward: "+1 yıldız",
      screen: MatchingMiniGameScreen(),
    ),
  ];
  static const List<List<Color>> _cardGradients = [
    [Color(0xFFFF7A7A), Color(0xFFFF4D6D)],
    [Color(0xFFFFB86B), Color(0xFFFF7A59)],
    [Color(0xFF36D1DC), Color(0xFF5B86E5)],
    [Color(0xFF43CEA2), Color(0xFF185A9D)],
  ];

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;
    final r = AppResponsive.of(context);
    final isPremium = u.isPremium; // 👈 Premium durumu alındı

    final titleSize = r.responsiveValue(
      phonePortrait: 20,
      phoneLandscape: 17,
      tabletPortrait: 23,
      tabletLandscape: 20,
      largeTabletPortrait: 25,
      largeTabletLandscape: 22,
    );

    final horizontalPadding = r.responsiveValue(
      phonePortrait: 20,
      phoneLandscape: 40,
      tabletPortrait: 42,
      tabletLandscape: 64,
      largeTabletPortrait: 58,
      largeTabletLandscape: 78,
    );

    final verticalPadding = r.responsiveValue(
      phonePortrait: 20,
      phoneLandscape: 16,
      tabletPortrait: 28,
      tabletLandscape: 24,
      largeTabletPortrait: 34,
      largeTabletLandscape: 28,
    );

    final maxWidth = r.responsiveValue(
      phonePortrait: 520,
      phoneLandscape: 980,
      tabletPortrait: 720,
      tabletLandscape: 1120,
      largeTabletPortrait: 820,
      largeTabletLandscape: 1220,
    );

    final gridCount = r.gridCount(
      phonePortrait: 1,
      phoneLandscape: 2,
      tabletPortrait: 1,
      tabletLandscape: 2,
      largeTabletPortrait: 1,
      largeTabletLandscape: 2,
    );

    final cardHeight = r.responsiveValue(
      phonePortrait: 112,
      phoneLandscape: 112,
      tabletPortrait: 128,
      tabletLandscape: 126,
      largeTabletPortrait: 136,
      largeTabletLandscape: 132,
    );

    final spacing = r.responsiveValue(
      phonePortrait: 12,
      phoneLandscape: 14,
      tabletPortrait: 16,
      tabletLandscape: 18,
      largeTabletPortrait: 18,
      largeTabletLandscape: 20,
    );

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      appBar: AppBar(
        toolbarHeight: r.appBarHeight,
        title: Text(
          "Mini Oyunlar",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: titleSize,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
      body: ThemedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _MiniGameIntroCard(gradient: gradient),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      spacing,
                      horizontalPadding,
                      verticalPadding + 12,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final item = _items[index];

                          // 👈 KİLİT MANTIĞI BURADA DEVREYE GİRİYOR
                          final isLocked = !isPremium && item.title != "Balon Harf Avı";

                          if (isLocked) {
                            return _LockedMiniGameCard(
                              emoji: item.emoji,
                              title: item.title,
                              subtitle: item.subtitle,
                              gradient: _cardGradients[index % _cardGradients.length],
                              onTap: () {
                                // Kilitli karta tıklanınca premium ekranını aç
                                showDialog(
                                  context: context,
                                  builder: (context) => const PremiumUpgradeDialog(),
                                );
                              },
                            );
                          }

                          return _MiniGameCard(
                            emoji: item.emoji,
                            title: item.title,
                            subtitle: item.subtitle,
                            reward: item.reward,
                            gradient: _cardGradients[index % _cardGradients.length],
                            delayMs: 120 + (index * 90),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => item.screen,
                                ),
                              );
                            },
                          );
                        },
                        childCount: _items.length,
                      ),
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: cardHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BannerReklamWidget(),
      ),
    );
  }
}

class _MiniGameMenuItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String reward;
  final Widget screen;

  const _MiniGameMenuItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.screen,
  });
}

class _MiniGameIntroCard extends StatelessWidget {
  final List<Color> gradient;

  const _MiniGameIntroCard({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return JoyEntrance(
      delayMs: 60,
      beginY: 14,
      child: JoyShine(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.26),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              JoyFloat(
                distance: 5,
                durationMs: 1800,
                child: JoyPulse(
                  minScale: 0.96,
                  maxScale: 1.06,
                  durationMs: 1400,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "🎮",
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kısa Mini Oyunlar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Kısa görevler yap, eğlenerek yıldız kazan.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
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
}

class _MiniGameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String reward;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int delayMs;

  const _MiniGameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.gradient,
    required this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return JoyEntrance(
      delayMs: delayMs,
      beginY: 16,
      child: JoyShine(
        borderRadius: BorderRadius.circular(26),
        child: JoyPressable(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                JoyFloat(
                  distance: 4,
                  durationMs: 1800,
                  delayMs: delayMs,
                  child: JoyPulse(
                    minScale: 0.97,
                    maxScale: 1.05,
                    durationMs: 1450,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 29),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.8,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 7,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          reward,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 31,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 👈 DÜZENLENEN KİLİTLİ KART WIDGETI (Tıklanma Özelliği Eklendi)
class _LockedMiniGameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap; // 👈 Burası eklendi

  const _LockedMiniGameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap, // 👈 Burası eklendi
  });

  @override
  Widget build(BuildContext context) {
    return JoyPressable( // 👈 Tıklama animasyonu için sarıldı
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Opacity(
        opacity: 0.85, // Biraz daha canlı gösterdik
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              )
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: gradient.first.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Ortalaması eklendi
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // 👈 Güzel duran kilit ikonu
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.black38,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BalloonLetterGameScreen extends StatefulWidget {
  const BalloonLetterGameScreen({super.key});

  @override
  State<BalloonLetterGameScreen> createState() =>
      _BalloonLetterGameScreenState();
}

class _BalloonLetterGameScreenState extends State<BalloonLetterGameScreen>
    with SingleTickerProviderStateMixin, MiniGameUsageTracker<BalloonLetterGameScreen> {
  final _random = Random();

  final List<String> _letters = const [
    "A",
    "B",
    "C",
    "Ç",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "İ",
    "K",
    "L",
    "M",
    "N",
    "O",
    "Ö",
    "P",
    "R",
    "S",
    "Ş",
    "T",
    "U",
    "Ü",
    "Y",
    "Z",
  ];

  final List<List<Color>> _balloonPalettes = const [
    [Color(0xFFFF7A7A), Color(0xFFFF4D6D)],
    [Color(0xFF5AC8FA), Color(0xFF007AFF)],
    [Color(0xFFFFCC66), Color(0xFFFF9500)],
    [Color(0xFF7EE8A7), Color(0xFF34C759)],
    [Color(0xFFB78CFF), Color(0xFF7B61FF)],
    [Color(0xFFFF9AD5), Color(0xFFFF5DB1)],
  ];

  late AnimationController _floatController;

  int _round = 1;
  int _score = 0;
  int _shakeSeed = 0;
  int _roundSeed = 0;

  bool _completed = false;
  bool _rewardGiven = false;
  bool _inputLocked = false;

  String? _wrongLetter;
  String? _burstLetter;
  String? _selectedLetter;

  late String _target;
  late List<String> _options;

  @override
  void initState() {
    super.initState();

    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _newRound();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakTarget();
    });
  }

  @override
  void dispose() {
    saveMiniGameUsageOnDispose(
      gameKey: 'balloonLetter',
      title: 'Balon Harf Avı',
    );
    stopMiniGameVisibleTimer();
    _floatController.dispose();
    VoiceService.instance.stop();
    super.dispose();
  }

  void _newRound() {
    _target = _letters[_random.nextInt(_letters.length)];

    final pool = _letters.where((item) => item != _target).toList()
      ..shuffle(_random);

    _options = [
      _target,
      ...pool.take(5),
    ]..shuffle(_random);

    _roundSeed++;
    _wrongLetter = null;
    _burstLetter = null;
    _selectedLetter = null;
    _inputLocked = false;
  }

  Future<void> _speakTarget() async {
    await VoiceService.instance.speak(
      "bulman gereken harf $_target. $_target harfini bul.",
      interrupt: true,
    );
  }

  List<Color> _colorsForIndex(int index, List<Color> fallback) {
    if (index >= 0 && index < _balloonPalettes.length) {
      return _balloonPalettes[index];
    }

    return fallback;
  }

  Future<void> _handleAnswer(String selected) async {
    if (_completed || _inputLocked) return;

    final correct = selected == _target;

    if (!correct) {
      setState(() {
        _inputLocked = true;
        _selectedLetter = selected;
        _wrongLetter = selected;
        _shakeSeed++;
      });

      await VoiceService.instance.speak(
        "Tekrar dene.",
        interrupt: true,
      );

      await Future.delayed(const Duration(milliseconds: 520));

      if (!mounted) return;

      setState(() {
        _inputLocked = false;
        _selectedLetter = null;
        _wrongLetter = null;
      });

      return;
    }

    setState(() {
      _inputLocked = true;
      _selectedLetter = selected;
      _burstLetter = selected;
    });

    await VoiceService.instance.speak(
      "Doğru!",
      interrupt: true,
    );

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    if (_round >= 5) {
      freezeMiniGameVisibleTimer();

      setState(() {
        _score++;
        _completed = true;
        _burstLetter = null;
        _inputLocked = false;
      });

      await _giveReward();

      await VoiceService.instance.speak(
        "Harika! Mini oyunu tamamladın ve bir yıldız kazandın.",
        interrupt: true,
      );

      return;
    }

    setState(() {
      _score++;
      _round++;
      _newRound();
    });

    await VoiceService.instance.speak(
      "Sıradaki harf $_target.",
      interrupt: true,
    );
  }

  Future<void> _giveReward() async {
    if (_rewardGiven) return;

    _rewardGiven = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await saveMiniGameUsage(
      gameKey: 'balloonLetter',
      title: 'Balon Harf Avı',
      completed: true,
    );

    await _saveMiniGameRewardToProfile(
      uid: uid,
      gameKey: 'balloonLetter',
      rewardStars: 1,
    );

    if (!mounted) return;

    try {
      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}
  }

  void _restartGame() {
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();

    setState(() {
      _round = 1;
      _score = 0;
      _completed = false;
      _rewardGiven = false;
      _newRound();
    });

    _speakTarget();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      appBar: AppBar(
        title: const Text(
          "Balon Harf Avı",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
      body: ThemedBackground(
        variantIndex: _round,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            return SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _FloatingMiniBalloons(
                      animationValue: _floatController.value,
                      gradient: gradient,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      children: [
                        _MiniGameTopCard(
                          gradient: gradient,
                          round: _round,
                          score: _score,
                          completed: _completed,
                          target: _target,
                          elapsedSeconds: visibleMiniGameSeconds,
                          onSpeak: _speakTarget,
                        ),

                        const SizedBox(height: 22),

                        if (!_completed)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final r = AppResponsive.of(context);
                                final isLandscape = r.isLandscape;

                                final crossCount = isLandscape ? 3 : 2;

                                final spacing = isLandscape ? 10.0 : 8.0;

                                final balloonHeight = isLandscape
                                    ? (constraints.maxHeight - spacing) / 2
                                    : (constraints.maxHeight - (spacing * 2)) / 3;

                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _options.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    mainAxisExtent: balloonHeight.clamp(108.0, 170.0),
                                  ),
                                  itemBuilder: (context, index) {
                                    final letter = _options[index];
                                    final wrong = _wrongLetter == letter;
                                    final burst = _burstLetter == letter;
                                    final selected = _selectedLetter == letter;

                                    return _AnimatedBalloonButton(
                                      letter: letter,
                                      colors: _colorsForIndex(index, gradient),
                                      animationValue: _floatController.value,
                                      phase: index * 0.65 + _roundSeed,
                                      rotateDeg: index.isEven ? -3.8 : 3.8,
                                      wrong: wrong,
                                      burst: burst,
                                      selected: selected,
                                      disabled: _inputLocked && !selected,
                                      shakeSeed: _shakeSeed,
                                      onTap: () => _handleAnswer(letter),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: Center(
                              child: _MiniGameCompletedCard(
                                gradient: gradient,
                                finishTimeText: UsageTimeRepository.formatSeconds(completedMiniGameSeconds),
                                onBackHome: () {
                                  Navigator.pop(context);
                                },
                                onPlayAgain: _restartGame,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniGameTopCard extends StatelessWidget {
  final List<Color> gradient;
  final int round;
  final int score;
  final bool completed;
  final String target;
  final VoidCallback onSpeak;
  final int elapsedSeconds;

  const _MiniGameTopCard({
    required this.gradient,
    required this.round,
    required this.score,
    required this.completed,
    required this.target,
    required this.onSpeak,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.24),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                completed ? "🏆" : target,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
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
                  completed ? "Mini oyun bitti!" : "Hedef Harf: $target",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? "Ödül kazandın."
                      : "Tur $round/5 • Doğru: $score • ${UsageTimeRepository.formatSeconds(elapsedSeconds)}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!completed)
            IconButton(
              onPressed: onSpeak,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedBalloonButton extends StatelessWidget {
  final String letter;
  final List<Color> colors;
  final double animationValue;
  final double phase;
  final double rotateDeg;
  final bool wrong;
  final bool burst;
  final bool selected;
  final bool disabled;
  final int shakeSeed;
  final VoidCallback onTap;

  const _AnimatedBalloonButton({
    required this.letter,
    required this.colors,
    required this.animationValue,
    required this.phase,
    required this.rotateDeg,
    required this.wrong,
    required this.burst,
    required this.selected,
    required this.disabled,
    required this.shakeSeed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final floatY = sin((animationValue * 2 * pi) + phase) * 6;
    final wobble = sin((animationValue * 2 * pi) + phase) * 2.2;

    final activeColors = wrong
        ? const [Color(0xFFFF7676), Color(0xFFFF3B30)]
        : colors;

    return TweenAnimationBuilder<double>(
      key: ValueKey("shake-$letter-$shakeSeed-$wrong"),
      tween: Tween<double>(begin: 0, end: wrong ? 1 : 0),
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final shakeX = wrong ? sin(t * pi * 9) * (1 - t) * 13 : 0.0;

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.rotate(
            angle: (rotateDeg + wobble) * pi / 180,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: disabled || burst ? null : onTap,
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutBack,
                  scale: burst ? 0.18 : 1.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 210),
                    opacity: burst ? 0.0 : disabled ? 0.45 : 1.0,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _BalloonShape(
                        letter: letter,
                        colors: activeColors,
                      ),
                    ),
                  ),
                ),

                if (burst)
                  Positioned.fill(
                    child: _BurstEffect(
                      colors: colors,
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

class _BalloonShape extends StatelessWidget {
  final String letter;
  final List<Color> colors;

  const _BalloonShape({
    required this.letter,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 125,
      height: 168,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 6,
            child: Container(
              width: 108,
              height: 124,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.34, -0.42),
                  radius: 1.05,
                  colors: [
                    Colors.white.withOpacity(0.35),
                    colors.first,
                    colors.last,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 9),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: 22,
                    child: Container(
                      width: 20,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 43,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 124,
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colors.last,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 139,
            child: Container(
              width: 2.6,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstEffect extends StatelessWidget {
  final List<Color> colors;

  const _BurstEffect({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final opacity = (1 - t).clamp(0.0, 1.0);
        final ringSize = 42 + (t * 82);

        return Opacity(
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.first.withOpacity(0.55),
                    width: 3,
                  ),
                ),
              ),

              ...List.generate(12, (index) {
                final angle = (2 * pi / 12) * index;
                final distance = 18 + (t * 48);

                final isStar = index % 3 == 0;
                final isSmall = index % 2 == 0;

                return Transform.translate(
                  offset: Offset(
                    cos(angle) * distance,
                    sin(angle) * distance,
                  ),
                  child: Transform.rotate(
                    angle: angle + (t * pi),
                    child: isStar
                        ? Text(
                      "✨",
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 20,
                      ),
                    )
                        : Container(
                      width: isSmall ? 8 : 11,
                      height: isSmall ? 8 : 11,
                      decoration: BoxDecoration(
                        color: index.isEven ? colors.first : colors.last,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),

              Transform.scale(
                scale: 0.7 + (t * 0.65),
                child: Text(
                  "⭐",
                  style: TextStyle(
                    fontSize: 26 + (t * 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingMiniBalloons extends StatelessWidget {
  final double animationValue;
  final List<Color> gradient;

  const _FloatingMiniBalloons({
    required this.animationValue,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final safeWidth = max(1.0, width - 42);

          return Stack(
            children: List.generate(10, (index) {
              final size = 18.0 + ((index % 4) * 5);
              final left = ((index * 47.0) + sin(index + animationValue * 6) * 14)
                  .abs() %
                  safeWidth;

              final speed = 0.12 + (index * 0.018);
              final top =
                  height - ((animationValue + speed) * height + index * 67) %
                      (height + 80);

              final opacity = 0.055 + ((index % 3) * 0.025);

              return Positioned(
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: sin(animationValue * 2 * pi + index) * 0.16,
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        Container(
                          width: size,
                          height: size * 1.2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Container(
                          width: 1.4,
                          height: 15,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MiniGameCompletedCard extends StatelessWidget {
  final List<Color> gradient;
  final VoidCallback onBackHome;
  final VoidCallback onPlayAgain;
  final String finishTimeText;

  const _MiniGameCompletedCard({
    required this.gradient,
    required this.finishTimeText,
    required this.onPlayAgain,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: gradient.first.withOpacity(0.18),
          width: 1.3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "🏆",
                style: TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Harika iş!",
            style: TextStyle(
              color: gradient.first,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            "Harika! Oyunu $finishTimeText sürede tamamladın.\n"
                "1 yıldız kazandın!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              // 🚀 1. DEĞİŞİKLİK: TEKRAR OYNA
              onPressed: () {
                AdManager.showInterstitialAd(
                  onAdClosed: () {
                    onPlayAgain();
                  },
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text(
                "Tekrar Oyna",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradient.first,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              // 🚀 2. DEĞİŞİKLİK: GERİ DÖN
              onPressed: () {
                AdManager.showInterstitialAd(
                  onAdClosed: () {
                    onBackHome();
                  },
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text(
                "Geri Dön",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: gradient.first,
                side: BorderSide(
                  color: gradient.first.withOpacity(0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class MatchingMiniGameScreen extends StatefulWidget {
  const MatchingMiniGameScreen({super.key});

  @override
  State<MatchingMiniGameScreen> createState() => _MatchingMiniGameScreenState();
}

class _MatchingMiniGameScreenState extends State<MatchingMiniGameScreen>
    with MiniGameUsageTracker<MatchingMiniGameScreen> {
  final Random _random = Random();

  final List<Map<String, String>> _items = const [
    {'emoji': '🍎', 'word': 'Elma'},
    {'emoji': '🍌', 'word': 'Muz'},
    {'emoji': '🍓', 'word': 'Çilek'},
    {'emoji': '🍇', 'word': 'Üzüm'},
    {'emoji': '🍉', 'word': 'Karpuz'},
    {'emoji': '🍊', 'word': 'Portakal'},
    {'emoji': '🍐', 'word': 'Armut'},
    {'emoji': '🍒', 'word': 'Kiraz'},
    {'emoji': '🐱', 'word': 'Kedi'},
    {'emoji': '🐶', 'word': 'Köpek'},
    {'emoji': '🦁', 'word': 'Aslan'},
    {'emoji': '🐰', 'word': 'Tavşan'},
    {'emoji': '🐮', 'word': 'İnek'},
    {'emoji': '🐔', 'word': 'Tavuk'},
    {'emoji': '🚗', 'word': 'Araba'},
    {'emoji': '🚌', 'word': 'Otobüs'},
    {'emoji': '🚲', 'word': 'Bisiklet'},
    {'emoji': '✈️', 'word': 'Uçak'},
    {'emoji': '🚢', 'word': 'Gemi'},
    {'emoji': '🏠', 'word': 'Ev'},
    {'emoji': '⭐', 'word': 'Yıldız'},
    {'emoji': '☀️', 'word': 'Güneş'},
    {'emoji': '🌙', 'word': 'Ay'},
    {'emoji': '🌷', 'word': 'Çiçek'},
    {'emoji': '📚', 'word': 'Kitap'},
    {'emoji': '⚽', 'word': 'Top'},
    {'emoji': '🎈', 'word': 'Balon'},
    {'emoji': '🧸', 'word': 'Oyuncak'},
  ];

  int _round = 1;
  int _score = 0;
  int _shakeSeed = 0;

  bool _completed = false;
  bool _rewardGiven = false;
  bool _inputLocked = false;

  String? _wrongWord;
  String? _correctWord;

  late Map<String, String> _target;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();
    _newRound();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakTarget();
    });
  }

  @override
  void dispose() {
    saveMiniGameUsageOnDispose(
      gameKey: 'matching',
      title: 'Eşleştirme',
    );
    stopMiniGameVisibleTimer();

    VoiceService.instance.stop();
    super.dispose();
  }

  void _newRound() {
    _target = _items[_random.nextInt(_items.length)];

    final correctWord = _target['word']!;

    final wrongPool = _items
        .map((item) => item['word']!)
        .where((word) => word != correctWord)
        .toList()
      ..shuffle(_random);

    _options = [
      correctWord,
      ...wrongPool.take(3),
    ]..shuffle(_random);

    _wrongWord = null;
    _correctWord = null;
    _inputLocked = false;
  }

  Future<void> _speakTarget() async {
    await VoiceService.instance.speak(
      "Bu resmi doğru kelimeyle eşleştir.",
      interrupt: true,
    );
  }

  Future<void> _handleAnswer(String selected) async {
    if (_completed || _inputLocked) return;

    final answer = _target['word']!;
    final correct = selected == answer;

    if (!correct) {
      setState(() {
        _inputLocked = true;
        _wrongWord = selected;
        _shakeSeed++;
      });

      await VoiceService.instance.speak(
        "Tekrar dene.",
        interrupt: true,
      );

      await Future.delayed(const Duration(milliseconds: 520));

      if (!mounted) return;

      setState(() {
        _inputLocked = false;
        _wrongWord = null;
      });

      return;
    }

    setState(() {
      _inputLocked = true;
      _correctWord = selected;
    });

    await VoiceService.instance.speak(
      "Doğru!",
      interrupt: true,
    );

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    if (_round >= 5) {
      freezeMiniGameVisibleTimer();

      setState(() {
        _score++;
        _completed = true;
        _inputLocked = false;
      });

      await _giveReward();

      await VoiceService.instance.speak(
        "Harika! Eşleştirme oyununu tamamladın ve bir yıldız kazandın.",
        interrupt: true,
      );

      return;
    }

    setState(() {
      _score++;
      _round++;
      _newRound();
    });

    await VoiceService.instance.speak(
      "Sıradaki resmi eşleştir.",
      interrupt: true,
    );
  }

  Future<void> _giveReward() async {
    if (_rewardGiven) return;

    _rewardGiven = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await saveMiniGameUsage(
      gameKey: 'matching',
      title: 'Eşleştirme',
      completed: true,
    );

    await _saveMiniGameRewardToProfile(
      uid: uid,
      gameKey: 'matching',
      rewardStars: 1,
    );

    if (!mounted) return;

    try {
      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}
  }

  void _restartGame() {
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();
    setState(() {
      _round = 1;
      _score = 0;
      _completed = false;
      _rewardGiven = false;
      _newRound();
    });

    _speakTarget();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;
    final r = AppResponsive.of(context);
    final isLandscape = r.isLandscape;

    final pagePadding = EdgeInsets.fromLTRB(
      isLandscape ? 18 : 20,
      isLandscape ? 12 : 18,
      isLandscape ? 18 : 20,
      isLandscape ? 14 : 24,
    );

    Widget optionList({
      required double separator,
    }) {
      return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _options.length,
        separatorBuilder: (_, __) => SizedBox(height: separator),
        itemBuilder: (context, index) {
          final word = _options[index];

          return _MatchingOptionButton(
            word: word,
            gradient: gradient,
            wrong: _wrongWord == word,
            correct: _correctWord == word,
            disabled: _inputLocked &&
                _wrongWord != word &&
                _correctWord != word,
            shakeSeed: _shakeSeed,
            onTap: () => _handleAnswer(word),
          );
        },
      );
    }

    Widget activeGameBody() {
      if (_completed) {
        return Expanded(
          child: Center(
            child: _MatchingCompletedCard(
              gradient: gradient,
              finishTimeText: UsageTimeRepository.formatSeconds(completedMiniGameSeconds),
              onBackHome: () {
                Navigator.pop(context);
              },
              onPlayAgain: _restartGame,
            ),
          ),
        );
      }

      return Expanded(
        child: LayoutBuilder(
          builder: (context, box) {
            if (isLandscape) {
              // Limitleri devasa tabletlere göre iyice açtık
              final emojiCardHeight = min(420.0, box.maxHeight * 0.85);
              final emojiCardWidth = min(500.0, box.maxWidth * 0.48);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: SizedBox(
                        width: emojiCardWidth,
                        height: emojiCardHeight,
                        child: _MatchingEmojiCard(
                          gradient: gradient,
                          emoji: _target['emoji'] ?? "❓",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32), // Ortadaki boşluğu artırdık
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 550, // Seçenek butonlarının genişliği arttı
                        ),
                        child: optionList(separator: 22), // Butonlar arası boşluk arttı
                      ),
                    ),
                  ),
                ],
              );
            }

            final emojiCardHeight = min(260.0, box.maxHeight * 0.38);

            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: emojiCardHeight,
                  child: _MatchingEmojiCard(
                    gradient: gradient,
                    emoji: _target['emoji'] ?? "❓",
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: optionList(separator: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      appBar: AppBar(
        toolbarHeight: r.appBarHeight,
        title: Text(
          "Eşleştirme",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: r.responsiveValue(
              phonePortrait: 18,
              phoneLandscape: 16,
              tabletPortrait: 20,
              tabletLandscape: 18,
              largeTabletPortrait: 22,
              largeTabletLandscape: 19,
            ),
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
      body: ThemedBackground(
        variantIndex: _round,
        child: SafeArea(
          child: Padding(
            padding: pagePadding,
            child: Column(
              children: [
                _MatchingTopCard(
                  gradient: gradient,
                  round: _round,
                  score: _score,
                  completed: _completed,
                  emoji: _target['emoji'] ?? "❓",
                  elapsedSeconds: visibleMiniGameSeconds,
                  onSpeak: _speakTarget,
                ),
                SizedBox(height: isLandscape ? 12 : 18),
                activeGameBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchingTopCard extends StatelessWidget {
  final List<Color> gradient;
  final int round;
  final int score;
  final bool completed;
  final String emoji;
  final VoidCallback onSpeak;
  final int elapsedSeconds;

  const _MatchingTopCard({
    required this.gradient,
    required this.round,
    required this.score,
    required this.completed,
    required this.emoji,
    required this.onSpeak,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isLandscape = r.isLandscape;

    final iconSize = isLandscape ? 64.0 : 58.0;
    final emojiSize = isLandscape ? 34.0 : 31.0;
    final titleSize = isLandscape ? 22.0 : 17.0;
    final subSize = isLandscape ? 15.0 : 12.2;
    final padding = isLandscape ? 18.0 : 15.0;
    final radius = isLandscape ? 28.0 : 28.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.20),
            blurRadius: isLandscape ? 9 : 14,
            offset: Offset(0, isLandscape ? 4 : 7),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                completed ? "🏆" : emoji,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: emojiSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: isLandscape ? 10 : 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? "Mini oyun bitti!" : "Resmi Eşleştir",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? "Ödül kazandın."
                      : "Tur $round/5 • Doğru: $score • ${UsageTimeRepository.formatSeconds(elapsedSeconds)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: subSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!completed)
            IconButton(
              visualDensity: isLandscape
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              onPressed: onSpeak,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchingEmojiCard extends StatelessWidget {
  final List<Color> gradient;
  final String emoji;

  const _MatchingEmojiCard({
    required this.gradient,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isLandscape = r.isLandscape;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 22 : 20,
          vertical: isLandscape ? 16 : 22,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.first.withOpacity(0.95),
              gradient.last.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isLandscape ? 30 : 34),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.28),
            width: 1.5,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isLandscape ? 160 : 82, // Emoji devleşti
                    height: 1,
                  ),
                ),
                SizedBox(height: isLandscape ? 24 : 16),
                Text(
                  "Bu resmin adı hangisi?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.94),
                    fontSize: isLandscape ? 26 : 16, // Altındaki yazı devleşti
                    fontWeight: FontWeight.w900,
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

class _MatchingOptionButton extends StatelessWidget {
  final String word;
  final List<Color> gradient;
  final bool wrong;
  final bool correct;
  final bool disabled;
  final int shakeSeed;
  final VoidCallback onTap;

  const _MatchingOptionButton({
    required this.word,
    required this.gradient,
    required this.wrong,
    required this.correct,
    required this.disabled,
    required this.shakeSeed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isLandscape = r.isLandscape;

    final colors = correct
        ? [Colors.green.shade400, Colors.green.shade600]
        : wrong
        ? [Colors.redAccent.shade100, Colors.redAccent]
        : gradient;

    final button = Opacity(
      opacity: disabled ? 0.45 : 1,
      child: JoyPressable(
        borderRadius: BorderRadius.circular(24),
        onTap: disabled ? null : onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: isLandscape ? 80 : 56, // Butonlar iyice kalınlaştı
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 24 : 15,
            vertical: isLandscape ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isLandscape ? 48 : 38, // İkon çemberi büyüdü
                height: isLandscape ? 48 : 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : wrong
                      ? Icons.refresh_rounded
                      : Icons.touch_app_rounded,
                  color: Colors.white,
                  size: isLandscape ? 28 : 22, // İkon boyutu büyüdü
                ),
              ),
              SizedBox(width: isLandscape ? 18 : 12),
              Expanded(
                child: Text(
                  word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLandscape ? 22 : 17, // Seçenek yazıları devleşti
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: isLandscape ? 36 : 25, // Sağ ok büyüdü
              ),
            ],
          ),
        ),
      ),
    );

    final movingButton = disabled || wrong || correct
        ? button
        : JoyFloat(
      distance: 2.6 + (word.length % 3) * 0.5,
      durationMs: 1900 + ((word.length % 5) * 160),
      delayMs: (word.length * 85) % 500,
      child: JoyPulse(
        minScale: 0.985,
        maxScale: 1.025,
        durationMs: 1500 + ((word.length % 4) * 120),
        child: button,
      ),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey("match-$word-$shakeSeed-$wrong"),
      tween: Tween<double>(begin: 0, end: wrong ? 1 : 0),
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final shakeX = wrong ? sin(t * pi * 9) * (1 - t) * 13 : 0.0;

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: child,
        );
      },
      child: movingButton,
    );
  }
}

class _MatchingCompletedCard extends StatelessWidget {
  final List<Color> gradient;
  final VoidCallback onBackHome;
  final VoidCallback onPlayAgain;
  final String finishTimeText;

  const _MatchingCompletedCard({
    required this.gradient,
    required this.onBackHome,
    required this.onPlayAgain,
    required this.finishTimeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: gradient.first.withOpacity(0.18),
          width: 1.3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "🧩",
                style: TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Eşleştirme tamam!",
            style: TextStyle(
              color: gradient.first,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            "Harika! Oyunu $finishTimeText sürede tamamladın.\n"
                "1 yıldız kazandın!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              // 🚀 1. DEĞİŞİKLİK: TEKRAR OYNA
              onPressed: () {
                AdManager.showInterstitialAd(
                  onAdClosed: () {
                    onPlayAgain();
                  },
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text(
                "Tekrar Oyna",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradient.first,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              // 🚀 2. DEĞİŞİKLİK: GERİ DÖN
              onPressed: () {
                AdManager.showInterstitialAd(
                  onAdClosed: () {
                    onBackHome();
                  },
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text(
                "Geri Dön",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: gradient.first,
                side: BorderSide(
                  color: gradient.first.withOpacity(0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum MemoryDifficulty {
  easy,
  medium,
  hard,
}

class MemoryCardsMiniGameScreen extends StatefulWidget {
  const MemoryCardsMiniGameScreen({super.key});

  @override
  State<MemoryCardsMiniGameScreen> createState() =>
      _MemoryCardsMiniGameScreenState();
}

class _MemoryCardsMiniGameScreenState extends State<MemoryCardsMiniGameScreen>
    with MiniGameUsageTracker<MemoryCardsMiniGameScreen> {
  final Random _random = Random();

  final List<_MemoryPairItem> _pool = const [
    _MemoryPairItem(id: 'apple', emoji: '🍎', label: 'Elma'),
    _MemoryPairItem(id: 'banana', emoji: '🍌', label: 'Muz'),
    _MemoryPairItem(id: 'strawberry', emoji: '🍓', label: 'Çilek'),
    _MemoryPairItem(id: 'grapes', emoji: '🍇', label: 'Üzüm'),
    _MemoryPairItem(id: 'watermelon', emoji: '🍉', label: 'Karpuz'),
    _MemoryPairItem(id: 'orange', emoji: '🍊', label: 'Portakal'),
    _MemoryPairItem(id: 'pear', emoji: '🍐', label: 'Armut'),
    _MemoryPairItem(id: 'cherry', emoji: '🍒', label: 'Kiraz'),
    _MemoryPairItem(id: 'cat', emoji: '🐱', label: 'Kedi'),
    _MemoryPairItem(id: 'dog', emoji: '🐶', label: 'Köpek'),
    _MemoryPairItem(id: 'lion', emoji: '🦁', label: 'Aslan'),
    _MemoryPairItem(id: 'rabbit', emoji: '🐰', label: 'Tavşan'),
    _MemoryPairItem(id: 'car', emoji: '🚗', label: 'Araba'),
    _MemoryPairItem(id: 'bus', emoji: '🚌', label: 'Otobüs'),
    _MemoryPairItem(id: 'plane', emoji: '✈️', label: 'Uçak'),
    _MemoryPairItem(id: 'bike', emoji: '🚲', label: 'Bisiklet'),
    _MemoryPairItem(id: 'flower', emoji: '🌷', label: 'Çiçek'),
    _MemoryPairItem(id: 'star', emoji: '⭐', label: 'Yıldız'),
    _MemoryPairItem(id: 'sun', emoji: '☀️', label: 'Güneş'),
    _MemoryPairItem(id: 'moon', emoji: '🌙', label: 'Ay'),
    _MemoryPairItem(id: 'balloon', emoji: '🎈', label: 'Balon'),
    _MemoryPairItem(id: 'book', emoji: '📚', label: 'Kitap'),
    _MemoryPairItem(id: 'ball', emoji: '⚽', label: 'Top'),
    _MemoryPairItem(id: 'toy', emoji: '🧸', label: 'Oyuncak'),
  ];

  MemoryDifficulty _difficulty = MemoryDifficulty.easy;

  late List<_MemoryCardItem> _cards;

  final List<int> _openedIndexes = [];
  final Set<String> _matchedPairIds = {};
  final Set<int> _wrongIndexes = {};
  final Set<String> _freshMatchedPairIds = {};

  bool _locked = false;
  bool _completed = false;
  bool _rewardGiven = false;

  int _moveCount = 0;

  int get _cardCount {
    switch (_difficulty) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 8;
      case MemoryDifficulty.hard:
        return 16;
    }
  }

  int get _pairCount => _cardCount ~/ 2;

  String get _difficultyText {
    switch (_difficulty) {
      case MemoryDifficulty.easy:
        return "Kolay";
      case MemoryDifficulty.medium:
        return "Orta";
      case MemoryDifficulty.hard:
        return "Zor";
    }
  }

  @override
  void initState() {
    super.initState();
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();
    _prepareGame();
  }

  @override
  void dispose() {
    saveMiniGameUsageOnDispose(
      gameKey: 'memoryCards',
      title: 'Hafıza Kartları',
    );
    stopMiniGameVisibleTimer();
    VoiceService.instance.stop();
    super.dispose();
  }

  int _responsiveMemoryCrossAxisCount(BuildContext context) {
    final isLandscape = AppResponsive.of(context).isLandscape;
    final total = _cards.length;

    if (total == 4) return 2;
    if (total == 8) return isLandscape ? 4 : 2;
    return isLandscape ? 8 : 4; // Yatayda yüksekliğe takılmamak için 8 sütuna (2 satır) yayıyoruz
  }

  int _responsiveMemoryRowCount(BuildContext context) {
    final total = _cards.length;
    final cols = _responsiveMemoryCrossAxisCount(context);
    return (total / cols).ceil();
  }

  double _responsiveMemorySpacing(BuildContext context) {
    final isLandscape = AppResponsive.of(context).isLandscape;
    final total = _cards.length;

    if (total == 4) return isLandscape ? 18 : 14;
    if (total == 8) return isLandscape ? 14 : 12;
    return isLandscape ? 12 : 10;
  }

  double _responsiveMemoryCardSize(
      BuildContext context,
      BoxConstraints constraints,
      ) {
    final cols = _responsiveMemoryCrossAxisCount(context);
    final rows = _responsiveMemoryRowCount(context);
    final spacing = _responsiveMemorySpacing(context);

    final availableW = constraints.maxWidth - ((cols - 1) * spacing);
    final availableH = constraints.maxHeight - ((rows - 1) * spacing);

    final maxByWidth = availableW / cols;
    final maxByHeight = availableH / rows;

    final size = min(maxByWidth, maxByHeight);
    final total = _cards.length;

    // ✅ TABLET MAGIC: Maksimum limitler devasa tabletlere göre devleşti
    if (total == 4) return size.clamp(92.0, 320.0);
    if (total == 8) return size.clamp(78.0, 240.0);
    return size.clamp(58.0, 280.0); // Zor seviyede kartların büyüme limitini daha da artırdık
  }

  void _prepareGame() {
    final selectedPairs = List<_MemoryPairItem>.from(_pool)..shuffle(_random);
    final picked = selectedPairs.take(_pairCount).toList();

    final tempCards = <_MemoryCardItem>[];

    for (final pair in picked) {
      tempCards.add(
        _MemoryCardItem(
          uniqueId: '${pair.id}-1',
          pairId: pair.id,
          emoji: pair.emoji,
          label: pair.label,
        ),
      );

      tempCards.add(
        _MemoryCardItem(
          uniqueId: '${pair.id}-2',
          pairId: pair.id,
          emoji: pair.emoji,
          label: pair.label,
        ),
      );
    }

    tempCards.shuffle(_random);

    _cards = tempCards;
    _openedIndexes.clear();
    _matchedPairIds.clear();
    _wrongIndexes.clear();
    _freshMatchedPairIds.clear();
    _locked = false;
    _completed = false;
    _rewardGiven = false;
    _moveCount = 0;
  }

  Future<void> _speakIntro() async {
    await VoiceService.instance.speak(
      "Aynı kartları bulalım. Kartlara dokun ve eşlerini keşfet.",
      interrupt: true,
    );
  }

  Future<void> _handleCardTap(int index) async {
    if (_locked || _completed) return;
    if (_openedIndexes.contains(index)) return;
    if (_wrongIndexes.contains(index)) return;

    final card = _cards[index];

    if (_matchedPairIds.contains(card.pairId)) return;

    setState(() {
      _openedIndexes.add(index);
    });

    if (_openedIndexes.length < 2) return;

    _locked = true;
    _moveCount++;

    final firstIndex = _openedIndexes[0];
    final secondIndex = _openedIndexes[1];

    final first = _cards[firstIndex];
    final second = _cards[secondIndex];

    final matched = first.pairId == second.pairId;

    await Future.delayed(const Duration(milliseconds: 320));

    if (!mounted) return;

    if (matched) {
      setState(() {
        _matchedPairIds.add(first.pairId);
        _freshMatchedPairIds.add(first.pairId);
        _openedIndexes.clear();
        _locked = false;
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        setState(() {
          _freshMatchedPairIds.remove(first.pairId);
        });
      });

      if (_matchedPairIds.length >= _pairCount) {
        await Future.delayed(const Duration(milliseconds: 550));

        if (!mounted) return;

        freezeMiniGameVisibleTimer();

        setState(() {
          _completed = true;
        });

        await _giveReward();
      }

      return;
    }

    setState(() {
      _wrongIndexes.add(firstIndex);
      _wrongIndexes.add(secondIndex);
    });

    await Future.delayed(const Duration(milliseconds: 620));

    if (!mounted) return;

    setState(() {
      _wrongIndexes.clear();
      _openedIndexes.clear();
      _locked = false;
    });
  }

  Future<void> _giveReward() async {
    if (_rewardGiven) return;

    _rewardGiven = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await saveMiniGameUsage(
      gameKey: 'memoryCards',
      title: 'Hafıza Kartları',
      completed: true,
    );

    await _saveMiniGameRewardToProfile(
      uid: uid,
      gameKey: 'memoryCards',
      rewardStars: 1,
      extraData: {
        'lastDifficulty': _difficultyText,
      },
    );

    if (!mounted) return;

    try {
      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}
  }

  void _restartGame() {
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();

    setState(() {
      _prepareGame();
    });

    _speakIntro();
  }

  void _changeDifficulty(MemoryDifficulty difficulty) {
    if (_difficulty == difficulty) return;

    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();
    setState(() {
      _difficulty = difficulty;
      _prepareGame();
    });
  }

  bool _isCardFaceUp(int index) {
    final card = _cards[index];

    return _openedIndexes.contains(index) ||
        _matchedPairIds.contains(card.pairId);
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;
    final r = AppResponsive.of(context);
    final isLandscape = r.isLandscape;

    final pagePadding = EdgeInsets.fromLTRB(
      isLandscape ? 14 : 16,
      isLandscape ? 10 : 14,
      isLandscape ? 14 : 16,
      isLandscape ? 10 : 18,
    );

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      appBar: AppBar(
        toolbarHeight: r.appBarHeight,
        title: Text(
          "Hafıza Kartları",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: r.responsiveValue(
              phonePortrait: 18,
              phoneLandscape: 16,
              tabletPortrait: 20,
              tabletLandscape: 18,
              largeTabletPortrait: 22,
              largeTabletLandscape: 19,
            ),
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
      body: ThemedBackground(
        variantIndex: _moveCount,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600), // Sağ-sol boşlukları doldurması için genişletildi
              child: Stack(
                children: [
                  Padding(
                    padding: pagePadding,
                    child: Column(
                      children: [
                        _MemoryTopCard(
                          gradient: gradient,
                          difficultyText: _difficultyText,
                          matchedCount: _matchedPairIds.length,
                          pairCount: _pairCount,
                          moveCount: _moveCount,
                          elapsedSeconds: visibleMiniGameSeconds,
                          onSpeak: _speakIntro,
                        ),

                        SizedBox(height: isLandscape ? 14 : 18),

                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450), // Tablette bar gereksiz uzamasın
                          child: _MemoryDifficultySelector(
                            gradient: gradient,
                            selected: _difficulty,
                            onChanged: _changeDifficulty,
                          ),
                        ),

                        SizedBox(height: isLandscape ? 14 : 22),

                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = _responsiveMemorySpacing(context);
                              final crossAxisCount = _responsiveMemoryCrossAxisCount(context);
                              final rowCount = _responsiveMemoryRowCount(context);
                              final cardSize = _responsiveMemoryCardSize(context, constraints);

                              final gridWidth = (crossAxisCount * cardSize) + ((crossAxisCount - 1) * spacing);
                              final gridHeight = (rowCount * cardSize) + ((rowCount - 1) * spacing);

                              return Center(
                                child: SizedBox(
                                  width: gridWidth,
                                  height: gridHeight,
                                  child: GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _cards.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                      mainAxisExtent: cardSize,
                                    ),
                                    itemBuilder: (context, index) {
                                      final card = _cards[index];
                                      final faceUp = _isCardFaceUp(index);
                                      final matched = _matchedPairIds.contains(card.pairId);

                                      return _MemoryFlipCard(
                                        card: card,
                                        gradient: gradient,
                                        faceUp: faceUp,
                                        matched: matched,
                                        wrong: _wrongIndexes.contains(index),
                                        freshMatched: _freshMatchedPairIds.contains(card.pairId),
                                        onTap: () => _handleCardTap(index),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_completed)
                    _MemoryCompletedOverlay(
                      gradient: gradient,
                      difficultyText: _difficultyText,
                      moveCount: _moveCount,
                      finishTimeText: UsageTimeRepository.formatSeconds(completedMiniGameSeconds),
                      onRestart: _restartGame,
                      onClose: () => Navigator.pop(context),
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

class _MemoryPairItem {
  final String id;
  final String emoji;
  final String label;

  const _MemoryPairItem({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

class _MemoryCardItem {
  final String uniqueId;
  final String pairId;
  final String emoji;
  final String label;

  const _MemoryCardItem({
    required this.uniqueId,
    required this.pairId,
    required this.emoji,
    required this.label,
  });
}

class _MemoryTopCard extends StatelessWidget {
  final List<Color> gradient;
  final String difficultyText;
  final int matchedCount;
  final int pairCount;
  final int moveCount;
  final VoidCallback onSpeak;
  final int elapsedSeconds;

  const _MemoryTopCard({
    required this.gradient,
    required this.difficultyText,
    required this.matchedCount,
    required this.pairCount,
    required this.moveCount,
    required this.onSpeak,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "🃏",
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aynı Kartları Bul",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$difficultyText • $matchedCount/$pairCount eş • $moveCount hamle • ${UsageTimeRepository.formatSeconds(elapsedSeconds)}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryDifficultySelector extends StatelessWidget {
  final List<Color> gradient;
  final MemoryDifficulty selected;
  final ValueChanged<MemoryDifficulty> onChanged;

  const _MemoryDifficultySelector({
    required this.gradient,
    required this.selected,
    required this.onChanged,
  });

  int get _selectedIndex {
    switch (selected) {
      case MemoryDifficulty.easy:
        return 0;
      case MemoryDifficulty.medium:
        return 1;
      case MemoryDifficulty.hard:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = const ["Kolay", "Orta", "Zor"];
    final values = const [
      MemoryDifficulty.easy,
      MemoryDifficulty.medium,
      MemoryDifficulty.hard,
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gradient.first.withOpacity(0.18),
          width: 1.3,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            alignment: Alignment(
              _selectedIndex == 0 ? -1 : _selectedIndex == 1 ? 0 : 1, 0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(3, (index) {
              final active = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(values[index]),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: active ? Colors.white : gradient.first,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MemoryFlipCard extends StatelessWidget {
  final _MemoryCardItem card;
  final List<Color> gradient;
  final bool faceUp;
  final bool matched;
  final bool wrong;
  final bool freshMatched;
  final VoidCallback onTap;

  const _MemoryFlipCard({
    required this.card,
    required this.gradient,
    required this.faceUp,
    required this.matched,
    required this.wrong,
    required this.freshMatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey("shake-${card.uniqueId}-$wrong"),
      tween: Tween<double>(begin: 0, end: wrong ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOut,
      builder: (context, shakeT, child) {
        final shakeX = wrong ? sin(shakeT * pi * 9) * (1 - shakeT) * 12 : 0.0;

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: faceUp ? 0 : pi),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        builder: (context, angle, _) {
          final showBack = angle > pi / 2;
          final displayAngle = showBack ? angle - pi : angle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(displayAngle),
            child: GestureDetector(
              onTap: matched ? null : onTap,
              child: showBack
                  ? _MemoryCardBack(gradient: gradient)
                  : _MemoryCardFront(
                card: card,
                gradient: gradient,
                matched: matched,
                freshMatched: freshMatched,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryCardBack extends StatelessWidget {
  final List<Color> gradient;

  const _MemoryCardBack({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth; // ✅ SIVI TİPOGRAFİ MERKEZİ

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.15,
              colors: [
                Colors.white.withOpacity(0.32),
                gradient.first,
                gradient.last,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(size * 0.2), // Kart boyutuna göre dinamik köşe
            border: Border.all(
              color: Colors.white.withOpacity(0.36),
              width: max(1.0, size * 0.015),
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.20),
                blurRadius: size * 0.1,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: size * 0.1,
                left: size * 0.1,
                child: Container(
                  width: size * 0.15,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.23),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: size * 0.08,
                        offset: Offset(0, size * 0.03),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.08,
                left: 0,
                right: 0,
                child: Text(
                  size > 90 ? "Döndür" : "Aç",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: (size * 0.12).clamp(8.0, 16.0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryCardFront extends StatelessWidget {
  final _MemoryCardItem card;
  final List<Color> gradient;
  final bool matched;
  final bool freshMatched;

  const _MemoryCardFront({
    required this.card,
    required this.gradient,
    required this.matched,
    required this.freshMatched,
  });

  @override
  Widget build(BuildContext context) {
    final colors = matched
        ? [Colors.green.shade400, Colors.green.shade600]
        : [const Color(0xFFFFD86F), const Color(0xFFFFA94D)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth; // ✅ SIVI TİPOGRAFİ MERKEZİ
        final emojiSize = size * 0.45;
        final labelSize = size * 0.14;

        return AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: freshMatched ? 1.06 : matched ? 0.96 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 1.15,
                colors: [
                  Colors.white.withOpacity(0.36),
                  colors.first,
                  colors.last,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.42),
                width: max(1.0, size * 0.015),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(freshMatched ? 0.34 : 0.18),
                  blurRadius: freshMatched ? size * 0.15 : size * 0.1,
                  offset: Offset(0, size * 0.05),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (matched)
                  Positioned(
                    right: size * 0.06,
                    top: size * 0.06,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: size * 0.2,
                    ),
                  ),

                if (freshMatched)
                  Positioned.fill(
                    child: _MemorySoftMatchEffect(gradient: colors),
                  ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.emoji,
                        style: TextStyle(fontSize: emojiSize),
                      ),
                      // Boyut küçükse (16 kart zorda iken) sadece emojiyi göster, yoksa yazıyı da ekle
                      if (size > 80) ...[
                        SizedBox(height: size * 0.06),
                        Text(
                          card.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelSize.clamp(10.0, 22.0),
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: size * 0.06,
                                offset: Offset(0, size * 0.02),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemorySoftMatchEffect extends StatelessWidget {
  final List<Color> gradient;

  const _MemorySoftMatchEffect({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final opacity = (1 - t).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.8 + (t * 0.9),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.75),
                      width: 3,
                    ),
                  ),
                ),
              ),
              ...List.generate(8, (index) {
                final angle = (2 * pi / 8) * index;
                final distance = 12 + (t * 28);

                return Transform.translate(
                  offset: Offset(
                    cos(angle) * distance,
                    sin(angle) * distance,
                  ),
                  child: Text(
                    index.isEven ? "✨" : "⭐",
                    style: TextStyle(
                      fontSize: 12 + (t * 5),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryCompletedOverlay extends StatelessWidget {
  final List<Color> gradient;
  final String difficultyText;
  final int moveCount;
  final String finishTimeText;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _MemoryCompletedOverlay({
    required this.gradient,
    required this.difficultyText,
    required this.moveCount,
    required this.finishTimeText,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.28),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "🏆",
                      style: TextStyle(fontSize: 42),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Harika İş!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: gradient.first,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$difficultyText seviyede tüm kartları $moveCount hamlede eşleştirdin.\n"
                        "Oyunu $finishTimeText sürede tamamladın.\n"
                        "1 yıldız kazandın!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      // 🚀 1. DEĞİŞİKLİK: YENİDEN OYNA
                      onPressed: () {
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            onRestart();
                          },
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        "Yeniden Oyna",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradient.first,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      // 🚀 2. DEĞİŞİKLİK: ÇIK
                      onPressed: () {
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            onClose();
                          },
                        );
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text(
                        "Çık",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gradient.first,
                        side: BorderSide(
                          color: gradient.first.withOpacity(0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
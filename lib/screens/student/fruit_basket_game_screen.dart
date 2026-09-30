import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_manager.dart';
import '../../widgets/common/mini_game_usage_tracker.dart';
import '../../providers/app_provider.dart';
import '../../services/voice_service.dart';
import '../../widgets/common/themed_background.dart';
import '../../repositories/child_profile_repository.dart';
import '../../core/responsive.dart';
import '../../repositories/usage_time_repository.dart';
import '../../widgets/common/joy_motion.dart';


class FruitBasketGameScreen extends StatefulWidget {
  const FruitBasketGameScreen({super.key});

  @override
  State<FruitBasketGameScreen> createState() => _FruitBasketGameScreenState();
}

class _FruitBasketGameScreenState extends State<FruitBasketGameScreen>
    with MiniGameUsageTracker<FruitBasketGameScreen> {
  final Random _random = Random();

  final List<_DragItem> _fruitPool = const [
    _DragItem(id: 'apple', emoji: '🍎', label: 'Elma', isFruit: true),
    _DragItem(id: 'banana', emoji: '🍌', label: 'Muz', isFruit: true),
    _DragItem(id: 'pear', emoji: '🍐', label: 'Armut', isFruit: true),
    _DragItem(id: 'grapes', emoji: '🍇', label: 'Üzüm', isFruit: true),
    _DragItem(id: 'strawberry', emoji: '🍓', label: 'Çilek', isFruit: true),
    _DragItem(id: 'orange', emoji: '🍊', label: 'Portakal', isFruit: true),
    _DragItem(id: 'watermelon', emoji: '🍉', label: 'Karpuz', isFruit: true),
    _DragItem(id: 'pineapple', emoji: '🍍', label: 'Ananas', isFruit: true),
    _DragItem(id: 'peach', emoji: '🍑', label: 'Şeftali', isFruit: true),
    _DragItem(id: 'cherry', emoji: '🍒', label: 'Kiraz', isFruit: true),
    _DragItem(id: 'kiwi', emoji: '🥝', label: 'Kivi', isFruit: true),
    _DragItem(id: 'mango', emoji: '🥭', label: 'Mango', isFruit: true),
    _DragItem(id: 'melon', emoji: '🍈', label: 'Kavun', isFruit: true),
    _DragItem(id: 'blueberry', emoji: '🫐', label: 'Yaban Mersini', isFruit: true),
    _DragItem(id: 'coconut', emoji: '🥥', label: 'Hindistan Cevizi', isFruit: true),
    _DragItem(id: 'lemon', emoji: '🍋', label: 'Limon', isFruit: true),
    _DragItem(id: 'avocado', emoji: '🥑', label: 'Avokado', isFruit: true),
    _DragItem(id: 'tomato', emoji: '🍅', label: 'Domates', isFruit: true),
    _DragItem(id: 'apple_green', emoji: '🍏', label: 'Yeşil Elma', isFruit: true)
  ];

  final List<_DragItem> _otherPool = const [
    _DragItem(id: 'flower_tulip', emoji: '🌷', label: 'Lale', isFruit: false),
    _DragItem(id: 'flower_rose', emoji: '🌹', label: 'Gül', isFruit: false),
    _DragItem(id: 'sunflower', emoji: '🌻', label: 'Ayçiçeği', isFruit: false),
    _DragItem(id: 'tree', emoji: '🌳', label: 'Ağaç', isFruit: false),
    _DragItem(id: 'leaf', emoji: '🍃', label: 'Yaprak', isFruit: false),

    _DragItem(id: 'car', emoji: '🚗', label: 'Araba', isFruit: false),
    _DragItem(id: 'bus', emoji: '🚌', label: 'Otobüs', isFruit: false),
    _DragItem(id: 'bike', emoji: '🚲', label: 'Bisiklet', isFruit: false),
    _DragItem(id: 'plane', emoji: '✈️', label: 'Uçak', isFruit: false),
    _DragItem(id: 'ship', emoji: '🚢', label: 'Gemi', isFruit: false),
    _DragItem(id: 'train', emoji: '🚂', label: 'Tren', isFruit: false),
    _DragItem(id: 'tractor', emoji: '🚜', label: 'Traktör', isFruit: false),

    _DragItem(id: 'dog', emoji: '🐶', label: 'Köpek', isFruit: false),
    _DragItem(id: 'cat', emoji: '🐱', label: 'Kedi', isFruit: false),
    _DragItem(id: 'lion', emoji: '🦁', label: 'Aslan', isFruit: false),
    _DragItem(id: 'rabbit', emoji: '🐰', label: 'Tavşan', isFruit: false),
    _DragItem(id: 'bear', emoji: '🐻', label: 'Ayı', isFruit: false),
    _DragItem(id: 'cow', emoji: '🐮', label: 'İnek', isFruit: false),
    _DragItem(id: 'chicken', emoji: '🐔', label: 'Tavuk', isFruit: false),
    _DragItem(id: 'butterfly', emoji: '🦋', label: 'Kelebek', isFruit: false),

    _DragItem(id: 'star', emoji: '⭐', label: 'Yıldız', isFruit: false),
    _DragItem(id: 'sun', emoji: '☀️', label: 'Güneş', isFruit: false),
    _DragItem(id: 'moon', emoji: '🌙', label: 'Ay', isFruit: false),
    _DragItem(id: 'cloud', emoji: '☁️', label: 'Bulut', isFruit: false),
    _DragItem(id: 'rainbow', emoji: '🌈', label: 'Gökkuşağı', isFruit: false),
    _DragItem(id: 'snowflake', emoji: '❄️', label: 'Kar Tanesi', isFruit: false),

    _DragItem(id: 'book', emoji: '📚', label: 'Kitap', isFruit: false),
    _DragItem(id: 'pencil', emoji: '✏️', label: 'Kalem', isFruit: false),
    _DragItem(id: 'paint', emoji: '🎨', label: 'Boya', isFruit: false),
    _DragItem(id: 'ball', emoji: '⚽', label: 'Top', isFruit: false),
    _DragItem(id: 'toy', emoji: '🧸', label: 'Oyuncak', isFruit: false),
    _DragItem(id: 'balloon', emoji: '🎈', label: 'Balon', isFruit: false),
    _DragItem(id: 'guitar', emoji: '🎸', label: 'Gitar', isFruit: false),
    _DragItem(id: 'drum', emoji: '🥁', label: 'Davul', isFruit: false),

    _DragItem(id: 'house', emoji: '🏠', label: 'Ev', isFruit: false),
    _DragItem(id: 'robot', emoji: '🤖', label: 'Robot', isFruit: false),
    _DragItem(id: 'umbrella', emoji: '☂️', label: 'Şemsiye', isFruit: false),
    _DragItem(id: 'clock', emoji: '⏰', label: 'Saat', isFruit: false),
    _DragItem(id: 'gift', emoji: '🎁', label: 'Hediye', isFruit: false),
    _DragItem(id: 'crown', emoji: '👑', label: 'Taç', isFruit: false),

    _DragItem(id: 'pizza', emoji: '🍕', label: 'Pizza', isFruit: false),
    _DragItem(id: 'burger', emoji: '🍔', label: 'Hamburger', isFruit: false),
    _DragItem(id: 'fries', emoji: '🍟', label: 'Patates', isFruit: false),
    _DragItem(id: 'cake', emoji: '🍰', label: 'Pasta', isFruit: false),
    _DragItem(id: 'cookie', emoji: '🍪', label: 'Kurabiye', isFruit: false),
    _DragItem(id: 'milk', emoji: '🥛', label: 'Süt', isFruit: false),
  ];

  final List<List<Color>> _palettes = const [
    [Color(0xFFFFB86B), Color(0xFFFF7A59)],
    [Color(0xFF7C83FD), Color(0xFF5B5FEE)],
    [Color(0xFF61D4B3), Color(0xFF2FBF9F)],
    [Color(0xFFFF8FB1), Color(0xFFFF6F91)],
    [Color(0xFF8FD3FE), Color(0xFF5EBBFF)],
    [Color(0xFFC084FC), Color(0xFF8B5CF6)],
    [Color(0xFFFFD166), Color(0xFFFF9F1C)],
    [Color(0xFF90E0EF), Color(0xFF48CAE4)],
  ];

  late List<_DragItem> _items;
  late Map<String, List<Color>> _itemColors;

  final Set<String> _collectedIds = {};

  int _correctCount = 0;
  int _wrongCount = 0;
  int _shakeSeed = 0;

  bool _basketHover = false;
  bool _basketHappy = false;
  bool _showSuccess = false;
  bool _rewardGiven = false;

  String? _wrongItemId;
  String? _sparkleItemId;

  int get _goal => _items.where((item) => item.isFruit).length;

  @override
  void initState() {
    super.initState();
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();
    _newGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakIntro();
    });
  }

  @override
  void dispose() {
    saveMiniGameUsageOnDispose(
      gameKey: 'fruitBasket',
      title: 'Meyveleri Sepete Taşı',
    );

    stopMiniGameVisibleTimer();

    VoiceService.instance.stop();
    super.dispose();
  }

  void _newGame() {
    final fruits = List<_DragItem>.from(_fruitPool)..shuffle(_random);
    final others = List<_DragItem>.from(_otherPool)..shuffle(_random);

    _items = [
      ...fruits.take(5),
      ...others.take(3),
    ]..shuffle(_random);

    final shuffledPalettes = List<List<Color>>.from(_palettes)
      ..shuffle(_random);

    _itemColors = {};
    for (int i = 0; i < _items.length; i++) {
      _itemColors[_items[i].id] = shuffledPalettes[i % shuffledPalettes.length];
    }
  }

  Future<void> _speakIntro() async {
    await VoiceService.instance.speak(
      "Meyveleri bul ve sepete taşı.",
      interrupt: true,
    );
  }

  Future<void> _onDrop(_DragItem item) async {
    if (_showSuccess || _collectedIds.contains(item.id)) return;

    if (item.isFruit) {
      setState(() {
        _collectedIds.add(item.id);
        _correctCount++;
        _basketHappy = true;
        _sparkleItemId = item.id;
        _wrongItemId = null;
      });

      await Future.delayed(const Duration(milliseconds: 420));

      if (!mounted) return;

      setState(() {
        _basketHappy = false;
        _sparkleItemId = null;
      });

      if (_correctCount >= _goal) {
        await Future.delayed(const Duration(milliseconds: 250));

        if (!mounted) return;

        freezeMiniGameVisibleTimer();

        setState(() {
          _showSuccess = true;
        });

        await _giveReward();
      }

      return;
    }

    setState(() {
      _wrongCount++;
      _wrongItemId = item.id;
      _shakeSeed++;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _wrongItemId = null;
    });
  }

  Future<void> _giveReward() async {
    if (_rewardGiven) return;

    _rewardGiven = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await saveMiniGameUsage(
      gameKey: 'fruitBasket',
      title: 'Meyveleri Sepete Taşı',
      completed: true,
    );
    String? childId;

    try {
      childId = await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      childId = null;
    }

    final rewardPatch = {
      'stars': FieldValue.increment(1),
      'miniGames': {
        'fruitBasket': {
          'completedCount': FieldValue.increment(1),
          'lastCompletedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (childId != null && childId.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('childProfiles').doc(childId).set(
        {
          ...rewardPatch,
          'childId': childId,
          'ownerUid': uid,
          'hasChildProfiles': true,
        },
        SetOptions(merge: true),
      );
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        ...rewardPatch,
        if (childId != null && childId.trim().isNotEmpty)
          'activeChildId': childId,
        if (childId != null && childId.trim().isNotEmpty)
          'hasChildProfiles': true,
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    try {
      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}
  }

  void _restart() {
    resetMiniGameUsageTimer();
    startMiniGameVisibleTimer();

    setState(() {
      _collectedIds.clear();
      _correctCount = 0;
      _wrongCount = 0;
      _shakeSeed = 0;
      _basketHover = false;
      _basketHappy = false;
      _showSuccess = false;
      _rewardGiven = false;
      _wrongItemId = null;
      _sparkleItemId = null;
      _newGame();
    });

    _speakIntro();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    return Scaffold(
      backgroundColor: u.currentTheme.background,
      appBar: AppBar(
        title: const Text(
          "Meyveleri Sepete Taşı",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
      body: ThemedBackground(
        variantIndex: _correctCount + _wrongCount,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    _FruitHeaderCard(
                      gradient: gradient,
                      correct: _correctCount,
                      goal: _goal,
                      wrong: _wrongCount,
                      elapsedSeconds: visibleMiniGameSeconds,
                      onSpeak: _speakIntro,
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final r = AppResponsive.of(context);
                          final isLandscape = r.isLandscape;

                          final basketHeight = isLandscape
                              ? min(
                            118.0,
                            max(92.0, constraints.maxHeight * 0.22),
                          )
                              : min(
                            140.0,
                            max(118.0, constraints.maxHeight * 0.26),
                          );

                          final gridHeight = constraints.maxHeight - basketHeight - 10;

                          return Column(
                            children: [
                              SizedBox(
                                height: gridHeight,
                                child: _EmojiPlayField(
                                  items: _items,
                                  collectedIds: _collectedIds,
                                  wrongItemId: _wrongItemId,
                                  sparkleItemId: _sparkleItemId,
                                  itemColors: _itemColors,
                                  shakeSeed: _shakeSeed,
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                height: basketHeight,
                                child: DragTarget<_DragItem>(
                                  onWillAcceptWithDetails: (_) {
                                    setState(() {
                                      _basketHover = true;
                                    });
                                    return true;
                                  },
                                  onLeave: (_) {
                                    setState(() {
                                      _basketHover = false;
                                    });
                                  },
                                  onAcceptWithDetails: (details) {
                                    setState(() {
                                      _basketHover = false;
                                    });

                                    _onDrop(details.data);
                                  },
                                  builder: (
                                      context,
                                      candidateData,
                                      rejectedData,
                                      ) {
                                    return _BasketZone(
                                      gradient: gradient,
                                      hovering: _basketHover ||
                                          candidateData.isNotEmpty,
                                      happy: _basketHappy,
                                      score: _correctCount,
                                      goal: _goal,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (_showSuccess)
                _FruitSuccessOverlay(
                  gradient: gradient,
                  finishTimeText: UsageTimeRepository.formatSeconds(completedMiniGameSeconds),
                  onRestart: _restart,
                  onClose: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragItem {
  final String id;
  final String emoji;
  final String label;
  final bool isFruit;

  const _DragItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.isFruit,
  });
}

class _FruitHeaderCard extends StatelessWidget {
  final List<Color> gradient;
  final int correct;
  final int goal;
  final int wrong;
  final int elapsedSeconds;
  final VoidCallback onSpeak;

  const _FruitHeaderCard({
    required this.gradient,
    required this.correct,
    required this.goal,
    required this.wrong,
    required this.elapsedSeconds,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.22),
            blurRadius: 14,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.23),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "🧺",
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Meyveleri Bul",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "5 meyveyi sepete taşı",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    _MiniPill(
                      text: "$correct/$goal",
                      icon: "🍎",
                    ),
                    const SizedBox(width: 5),
                    _MiniPill(
                      text: "$wrong",
                      icon: "🙂",
                    ),
                    const SizedBox(width: 5),
                    _MiniPill(
                      text: UsageTimeRepository.formatSeconds(elapsedSeconds),
                      icon: "⏱️",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onSpeak,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final String icon;

  const _MiniPill({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.21),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiPlayField extends StatelessWidget {
  final List<_DragItem> items;
  final Set<String> collectedIds;
  final String? wrongItemId;
  final String? sparkleItemId;
  final Map<String, List<Color>> itemColors;
  final int shakeSeed;

  const _EmojiPlayField({
    required this.items,
    required this.collectedIds,
    required this.wrongItemId,
    required this.sparkleItemId,
    required this.itemColors,
    required this.shakeSeed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final r = AppResponsive.of(context);
        final isLandscape = r.isLandscape;

        final w = c.maxWidth;
        final h = c.maxHeight;

        final columns = isLandscape ? 4 : 2;
        final rows = isLandscape ? 2 : 4;

        final cellW = w / columns;
        final cellH = h / rows;

        final itemSize = isLandscape
            ? min(cellW * 0.72, cellH * 0.78)
            : min(cellW * 0.66, cellH * 0.74);

        return Stack(
          children: List.generate(items.length, (index) {
            final item = items[index];

            final row = index ~/ columns;
            final col = index % columns;

            final x = (col * cellW) + (cellW * 0.50);
            final y = (row * cellH) + (cellH * 0.50);

            final collected = collectedIds.contains(item.id);
            final wrong = wrongItemId == item.id;
            final sparkle = sparkleItemId == item.id;

            final colors = itemColors[item.id] ??
                const [
                  Color(0xFF7C83FD),
                  Color(0xFF5B5FEE),
                ];

            return Positioned(
              left: x - (itemSize / 2),
              top: y - (itemSize / 2),
              width: itemSize,
              height: itemSize,
              child: collected
                  ? _CollectedEmojiSpot(
                emoji: item.emoji,
                sparkle: sparkle,
              )
                  : _DraggableFloatingEmoji(
                key: ValueKey("${item.id}-$shakeSeed-$wrong"),
                item: item,
                colors: colors,
                wrong: wrong,
              ),
            );
          }),
        );
      },
    );
  }
}
class _DraggableFloatingEmoji extends StatelessWidget {
  final _DragItem item;
  final List<Color> colors;
  final bool wrong;

  const _DraggableFloatingEmoji({
    super.key,
    required this.item,
    required this.colors,
    required this.wrong,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: wrong ? 1 : 0),
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final shakeX = wrong ? sin(t * pi * 9) * (1 - t) * 12 : 0.0;
        final shakeY = wrong ? sin(t * pi * 7) * (1 - t) * 6 : 0.0;

        return Transform.translate(
          offset: Offset(shakeX, shakeY),
          child: child,
        );
      },
      child: Draggable<_DragItem>(
        data: item,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).orientation == Orientation.landscape ? 96 : 82,
            height: MediaQuery.of(context).orientation == Orientation.landscape ? 96 : 82,
            child: _FloatingEmojiObject(
              item: item,
              colors: colors,
              dragging: true,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.16,
          child: _FloatingEmojiObject(
            item: item,
            colors: colors,
          ),
        ),
        child: _FloatingEmojiObject(
          item: item,
          colors: colors,
        ),
      ),
    );
  }
}

class _FloatingEmojiObject extends StatelessWidget {
  final _DragItem item;
  final List<Color> colors;
  final bool dragging;

  const _FloatingEmojiObject({
    required this.item,
    required this.colors,
    this.dragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final delay = (item.id.length * 80) % 600;
    final duration = 1900 + ((item.id.length % 5) * 130);

    final object = AnimatedScale(
      duration: const Duration(milliseconds: 170),
      scale: dragging ? 1.14 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.36, -0.44),
            radius: 1.15,
            colors: [
              Colors.white.withValues(alpha: 0.42),
              colors.first,
              colors.last,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: dragging ? 0.38 : 0.24),
              blurRadius: dragging ? 20 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                width: 13,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Center(
              child: Text(
                item.emoji,
                style: const TextStyle(
                  fontSize: 34,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (dragging) {
      return object;
    }

    return JoyFloat(
      distance: 4.5,
      durationMs: duration,
      delayMs: delay,
      child: JoyPulse(
        minScale: 0.96,
        maxScale: 1.055,
        durationMs: 1500 + delay,
        child: JoyShine(
          borderRadius: BorderRadius.circular(999),
          child: object,
        ),
      ),
    );
  }
}

class _CollectedEmojiSpot extends StatelessWidget {
  final String emoji;
  final bool sparkle;

  const _CollectedEmojiSpot({
    required this.emoji,
    required this.sparkle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: sparkle ? 1.12 : 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.green.withOpacity(0.40),
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              sparkle ? "✨" : emoji,
              style: TextStyle(
                fontSize: sparkle ? 34 : 25,
              ),
            ),
            const Positioned(
              right: 5,
              bottom: 5,
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketZone extends StatelessWidget {
  final List<Color> gradient;
  final bool hovering;
  final bool happy;
  final int score;
  final int goal;

  const _BasketZone({
    required this.gradient,
    required this.hovering,
    required this.happy,
    required this.score,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: happy ? 1.05 : hovering ? 1.03 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hovering || happy
                ? [
              gradient.last,
              gradient.first,
            ]
                : [
              gradient.first.withOpacity(0.92),
              gradient.last.withOpacity(0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.52),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(hovering ? 0.32 : 0.20),
              blurRadius: hovering ? 20 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 18,
              top: 8,
              child: Opacity(
                opacity: 0.18,
                child: Text(
                  happy ? "✨" : "🍎",
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hovering ? "👇 Buraya bırak" : "🧺 Meyveleri Buraya Koy",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.5,
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.19),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "🍎 $score / $goal",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
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

class _FruitSuccessOverlay extends StatelessWidget {
  final List<Color> gradient;
  final String finishTimeText;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _FruitSuccessOverlay({
    required this.gradient,
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
                      "🎉",
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
                    "Tüm meyveleri sepete taşıdın.\n"
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
                  // ... (Yukarıdaki Yıldız ve Süre yazıları aynı kalıyor)
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      // 🚀 1. DEĞİŞİKLİK: YENİDEN OYNA BUTONU
                      onPressed: () {
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            onRestart(); // Reklam bitince oyunu sıfırla
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
                      // 🚀 2. DEĞİŞİKLİK: ÇIKIŞ BUTONU
                      onPressed: () {
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            onClose(); // Reklam bitince menüye dön
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

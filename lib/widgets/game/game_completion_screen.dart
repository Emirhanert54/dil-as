import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../repositories/usage_time_repository.dart';
import '../../screens/student/activities_screen.dart';
import '../common/joy_motion.dart';
import '../common/themed_background.dart';
import '../../services/ad_manager.dart';

class GameCompletionScreen extends StatefulWidget {
  final String levelTitle;

  const GameCompletionScreen({
    super.key,
    required this.levelTitle,
  });

  @override
  State<GameCompletionScreen> createState() => _GameCompletionScreenState();
}

class _GameCompletionScreenState extends State<GameCompletionScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _confettiController.play();

      final u = context.read<AppProvider>();
      u.speak(
        "Harika iş! Etkinliği tamamladın. Seninle gurur duyuyorum!",
        interrupt: true,
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  int _readElapsedSeconds(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final raw = args['elapsedSeconds'];

      if (raw is int) return raw;
      if (raw is double) return raw.toInt();

      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;
    final gradient = theme.gradient;

    final elapsedSeconds = _readElapsedSeconds(context);
    final hasTime = elapsedSeconds > 0;
    final timeText = hasTime
        ? UsageTimeRepository.formatSeconds(elapsedSeconds)
        : "Süre kaydedildi";

    return Scaffold(
      backgroundColor: theme.background,
      body: ThemedBackground(
        variantIndex: 2,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        JoyPressable(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            // 🚀 1. REKLAM EKLENTİSİ
                            AdManager.showInterstitialAd(
                              onAdClosed: () {
                                Navigator.popUntil(
                                  context,
                                      (route) => route.isFirst,
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: gradient.first.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: gradient.first,
                              size: 25,
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),

                    const Spacer(),

                    JoyEntrance(
                      delayMs: 80,
                      beginY: 24,
                      child: JoyShine(
                        borderRadius: BorderRadius.circular(36),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.first.withValues(alpha: 0.24),
                                blurRadius: 26,
                                offset: const Offset(0, 13),
                              ),
                            ],
                            border: Border.all(
                              color: gradient.first.withValues(alpha: 0.18),
                              width: 1.6,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  JoyPulse(
                                    minScale: 0.94,
                                    maxScale: 1.08,
                                    durationMs: 1400,
                                    child: Container(
                                      width: 122,
                                      height: 122,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            gradient.first.withValues(alpha: 0.18),
                                            gradient.last.withValues(alpha: 0.18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  JoyFloat(
                                    distance: 8,
                                    durationMs: 1700,
                                    child: JoyPulse(
                                      minScale: 0.96,
                                      maxScale: 1.08,
                                      durationMs: 1350,
                                      child: Container(
                                        width: 104,
                                        height: 104,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: gradient,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: gradient.first
                                                  .withValues(alpha: 0.30),
                                              blurRadius: 20,
                                              offset: const Offset(0, 9),
                                            ),
                                          ],
                                          border: Border.all(
                                            color:
                                            Colors.white.withValues(alpha: 0.50),
                                            width: 4,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            u.currentMascot.emoji,
                                            style: const TextStyle(
                                              fontSize: 54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              _ShimmerCompletionText(
                                text: "Harika İş!",
                                style: TextStyle(
                                  color: gradient.first,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.levelTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Etkinliği başarıyla tamamladın. Maskotun seninle gurur duyuyor!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _CompletionStatChip(
                                    gradient: gradient,
                                    icon: "⭐",
                                    title: "Ödül",
                                    value: "Yıldız kazandın!",
                                  ),
                                  _CompletionStatChip(
                                    gradient: gradient,
                                    icon: "⏱️",
                                    title: "Süre",
                                    value: timeText,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      gradient.first.withValues(alpha: 0.13),
                                      gradient.last.withValues(alpha: 0.13),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: gradient.first.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  "Bugün biraz daha güçlendin! Devam edersen rozetlere daha hızlı ulaşırsın.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: gradient.first,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    _CompletionActionButton(
                      label: "Yeni Etkinlik Seç",
                      icon: Icons.sports_esports_rounded,
                      gradient: gradient,
                      filled: true,
                      onTap: () {
                        context.read<AppProvider>().speak("", interrupt: true);
                        // 🚀 2. REKLAM EKLENTİSİ
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActivitiesScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    _CompletionActionButton(
                      label: "Ana Sayfaya Dön",
                      icon: Icons.home_rounded,
                      gradient: gradient,
                      filled: false,
                      onTap: () {
                        context.read<AppProvider>().speak("", interrupt: true);
                        AdManager.showInterstitialAd(
                          onAdClosed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          }
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.06,
                  numberOfParticles: 26,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.18,
                  shouldLoop: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionStatChip extends StatelessWidget {
  final List<Color> gradient;
  final String icon;
  final String title;
  final String value;

  const _CompletionStatChip({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return JoyFloat(
      distance: 3,
      durationMs: 1900,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 128,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.first.withValues(alpha: 0.18),
              gradient.last.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: gradient.first.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gradient.first,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gradient.last,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
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

class _CompletionActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final bool filled;
  final VoidCallback onTap;

  const _CompletionActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JoyPressable(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: filled ? 57 : 54,
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: filled
                ? Colors.white.withValues(alpha: 0.22)
                : gradient.first.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: filled ? 0.26 : 0.10),
              blurRadius: filled ? 15 : 10,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : gradient.first,
              size: 22,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : gradient.first,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyBackground extends StatelessWidget {
  final List<Color> gradient;

  const _PartyBackground({
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final bubbles = [
      ("🎉", 0.08, 0.14, 26.0),
      ("✨", 0.82, 0.16, 24.0),
      ("⭐", 0.12, 0.48, 22.0),
      ("🎈", 0.84, 0.44, 28.0),
      ("🌟", 0.18, 0.78, 24.0),
      ("🎊", 0.78, 0.76, 26.0),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: bubbles.map((item) {
            final emoji = item.$1;
            final leftFactor = item.$2;
            final topFactor = item.$3;
            final fontSize = item.$4;

            return Positioned(
              left: constraints.maxWidth * leftFactor,
              top: constraints.maxHeight * topFactor,
              child: JoyFloat(
                distance: 7,
                durationMs: 2000 + (fontSize.toInt() * 20),
                child: Opacity(
                  opacity: 0.34,
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ShimmerCompletionText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ShimmerCompletionText({
    required this.text,
    required this.style,
  });

  @override
  State<_ShimmerCompletionText> createState() => _ShimmerCompletionTextState();
}

class _ShimmerCompletionTextState extends State<_ShimmerCompletionText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor.withValues(alpha: 0.90),
                Colors.white,
                baseColor.withValues(alpha: 0.90),
              ],
              stops: const [0.18, 0.50, 0.82],
              begin: Alignment(-2.2 + value * 4.4, -0.4),
              end: Alignment(-1.0 + value * 4.4, 0.4),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: widget.style,
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../common/joy_motion.dart';

class GameMascotCard extends StatelessWidget {
  final String message;
  final VoidCallback onSpeak;

  const GameMascotCard({
    super.key,
    required this.message,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;
    final mascot = u.currentMascot;

    // 🚀 TABLET KONTROLÜ EKLENDİ
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final feedbackText = u.feedbackText.trim();
    final hasFeedback = feedbackText.isNotEmpty;

    final shownMessage = hasFeedback ? feedbackText : message;

    final gradient = hasFeedback
        ? [
      u.feedbackColor,
      theme.gradient.last,
    ]
        : theme.gradient;

    return JoyShine(
      borderRadius: BorderRadius.circular(isTablet ? 32 : 26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 24 : 14), // 🚀 İÇ BOŞLUK BÜYÜTÜLDÜ
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.first.withValues(alpha: 0.86),
              gradient.last.withValues(alpha: 0.86),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 32 : 26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.24),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            JoyFloat(
              distance: 5,
              durationMs: 1800,
              child: JoyPulse(
                minScale: 0.97,
                maxScale: 1.07,
                durationMs: 1400,
                child: Container(
                  width: isTablet ? 90 : 58, // 🚀 STICKER ÇEMBERİ DEVLEŞTİ
                  height: isTablet ? 90 : 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      hasFeedback ? (u.feedbackColor == Colors.green ? "🌟" : mascot.emoji) : mascot.emoji,
                      key: ValueKey(
                        hasFeedback ? "feedback-${u.feedbackColor}" : mascot.emoji,
                      ),
                      style: TextStyle(
                        fontSize: isTablet ? 54 : 32, // 🚀 EMOJI BÜYÜDÜ
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: isTablet ? 24 : 13),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.16),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: _GameShimmerText(
                  key: ValueKey(shownMessage),
                  text: shownMessage,
                  maxLines: isTablet ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 13, // 🚀 YAZI EFSANE BÜYÜDÜ VE OKUNAKLI OLDU
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: isTablet ? 16 : 8),

            JoyPressable(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                if (hasFeedback) {
                  context.read<AppProvider>().speak(shownMessage);
                } else {
                  onSpeak();
                }
              },
              child: Container(
                width: isTablet ? 68 : 44, // 🚀 SES BUTONU BÜYÜDÜ
                height: isTablet ? 68 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: isTablet ? 38 : 24, // 🚀 İKON BÜYÜDÜ
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  const _GameShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<_GameShimmerText> createState() => _GameShimmerTextState();
}

class _GameShimmerTextState extends State<_GameShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
                baseColor.withValues(alpha: 0.86),
                Colors.white,
                baseColor.withValues(alpha: 0.86),
              ],
              stops: const [0.15, 0.50, 0.85],
              begin: Alignment(-2.0 + value * 4.0, -0.4),
              end: Alignment(-0.9 + value * 4.0, 0.4),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            style: widget.style.copyWith(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
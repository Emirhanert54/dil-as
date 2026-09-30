import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../common/joy_motion.dart';

class HomeMascotHeader extends StatelessWidget {
  const HomeMascotHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final mascot = u.currentMascot;

    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape = size.width > size.height && size.shortestSide >= 600;

    final rawName = u.name.trim();
    final displayName = rawName.isEmpty || rawName == "Yükleniyor..."
        ? "Arkadaşım"
        : rawName.split(" ").first;

    final missionDone = u.dailyCompleted >= AppProvider.dailyGoal;

    final message = missionDone
        ? "Bugünkü görev tamamlandı! Harika gidiyorsun."
        : "Bugün öğrenmeye hazır mısın? ${u.dailyRemaining} etkinlik daha yapalım!";

    final speakText = "Merhaba $displayName. $message";

    final mascotSize = isTabletLandscape ? 72.0 : 62.0;
    final mascotFont = isTabletLandscape ? 40.0 : 34.0;
    final titleFont = isTabletLandscape ? 22.0 : 20.0;
    final messageFont = isTabletLandscape ? 14.0 : 13.0;
    final volumeSize = isTabletLandscape ? 50.0 : 46.0;

    return JoyEntrance(
      delayMs: 60,
      beginY: 14,
      child: JoyShine(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTabletLandscape ? 18 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              JoyFloat(
                distance: 7,
                durationMs: 1700,
                child: JoyPulse(
                  minScale: 0.96,
                  maxScale: 1.08,
                  durationMs: 1350,
                  child: Container(
                    width: mascotSize,
                    height: mascotSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.40),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      mascot.emoji,
                      style: TextStyle(
                        fontSize: mascotFont,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                    _HeaderShimmerText(
                      text: "Merhaba $displayName!",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      durationMs: 1900,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFont,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    _HeaderShimmerText(
                      text: message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      durationMs: 2400,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: messageFont,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              JoyPressable(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  context.read<AppProvider>().speak(speakText);
                },
                child: Container(
                  width: volumeSize,
                  height: volumeSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.16),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: isTabletLandscape ? 27 : 25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final int durationMs;

  const _HeaderShimmerText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.durationMs = 2200,
  });

  @override
  State<_HeaderShimmerText> createState() => _HeaderShimmerTextState();
}

class _HeaderShimmerTextState extends State<_HeaderShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
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

        return Stack(
          children: [
            Text(
              widget.text,
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
              style: widget.style.copyWith(
                color: baseColor.withValues(alpha: 0.72),
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    baseColor.withValues(alpha: 0.85),
                    Colors.white,
                    baseColor.withValues(alpha: 0.85),
                  ],
                  stops: const [0.18, 0.50, 0.82],
                  begin: Alignment(-2.2 + value * 4.4, -0.4),
                  end: Alignment(-1.0 + value * 4.4, 0.4),
                ).createShader(bounds);
              },
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                overflow: widget.overflow,
                style: widget.style.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
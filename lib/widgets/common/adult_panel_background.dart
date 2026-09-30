import 'package:flutter/material.dart';

class AdultPanelBackground extends StatelessWidget {
  final Widget child;
  final Color background;
  final List<Color> gradient;
  final bool showTopGlow;

  const AdultPanelBackground({
    super.key,
    required this.child,
    required this.background,
    required this.gradient,
    this.showTopGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final first = gradient.isNotEmpty ? gradient.first : const Color(0xFF1F2A44);
    final last = gradient.length > 1 ? gradient.last : const Color(0xFF6C63FF);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            background,
            const Color(0xFFF8FAFF),
            background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          if (showTopGlow)
            Positioned(
              top: -120,
              left: -80,
              child: _SoftGlowCircle(
                size: 260,
                color: first.withValues(alpha: 0.13),
              ),
            ),

          Positioned(
            top: 90,
            right: -90,
            child: _SoftGlowCircle(
              size: 220,
              color: last.withValues(alpha: 0.10),
            ),
          ),

          Positioned(
            bottom: -110,
            left: -70,
            child: _SoftGlowCircle(
              size: 240,
              color: first.withValues(alpha: 0.08),
            ),
          ),

          Positioned(
            bottom: 80,
            right: 24,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.045,
                child: Icon(
                  Icons.insights_rounded,
                  size: 155,
                  color: first,
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SoftGlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftGlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
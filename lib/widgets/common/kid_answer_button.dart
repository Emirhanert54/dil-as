import 'package:flutter/material.dart';

import '../common/joy_motion.dart';

class KidAnswerButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const KidAnswerButton({
    super.key,
    required this.text,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    final delay = (text.length * 70) % 450;
    final duration = 2300 + ((text.length % 4) * 140);

    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 62,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? [
                Colors.grey.shade400,
                Colors.grey.shade500,
              ]
                  : [
                gradient.first,
                gradient.last,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1.3,
            ),
            boxShadow: disabled
                ? []
                : [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (disabled) return button;

    return JoyFloat(
      distance: 2.2,
      durationMs: duration,
      delayMs: delay,
      child: button,
    );
  }
}
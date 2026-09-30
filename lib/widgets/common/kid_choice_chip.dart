import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../common/joy_motion.dart';

class KidChoiceChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const KidChoiceChip({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().currentTheme;
    final gradient = theme.gradient;
    final disabled = onTap == null;

    final delay = (text.length * 85) % 500;
    final duration = 2100 + ((text.length % 4) * 160);

    final chip = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
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
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.34),
              width: 1.2,
            ),
            boxShadow: disabled
                ? []
                : [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );

    if (disabled) return chip;

    return JoyFloat(
      distance: 2,
      durationMs: duration,
      delayMs: delay,
      child: chip,
    );
  }
}
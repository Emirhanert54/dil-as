import 'dart:async';

import 'package:flutter/material.dart';

import '../../repositories/usage_time_repository.dart';

class ElapsedTimePill extends StatefulWidget {
  final DateTime startedAt;
  final List<Color> gradient;
  final bool compact;

  const ElapsedTimePill({
    super.key,
    required this.startedAt,
    required this.gradient,
    this.compact = false,
  });

  @override
  State<ElapsedTimePill> createState() => _ElapsedTimePillState();
}

class _ElapsedTimePillState extends State<ElapsedTimePill> {
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();

    _update();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _update();
    });
  }

  void _update() {
    if (!mounted) return;

    setState(() {
      _seconds = DateTime.now().difference(widget.startedAt).inSeconds;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 9 : 11,
        vertical: widget.compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.gradient.first.withValues(alpha: 0.92),
            widget.gradient.last.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradient.first.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            UsageTimeRepository.formatSeconds(_seconds),
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.compact ? 11 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import '../../repositories/usage_time_repository.dart';

mixin MiniGameUsageTracker<T extends StatefulWidget> on State<T> {
  DateTime _miniGameStartedAt = DateTime.now();

  bool _miniGameCompletedSaved = false;
  bool _miniGameDisposeSaved = false;

  Timer? _miniGameVisibleTimer;

  int visibleMiniGameSeconds = 0;
  int completedMiniGameSeconds = 0;

  int get miniGameElapsedSeconds {
    return DateTime.now().difference(_miniGameStartedAt).inSeconds;
  }

  void resetMiniGameUsageTimer() {
    _miniGameStartedAt = DateTime.now();
    _miniGameCompletedSaved = false;
    _miniGameDisposeSaved = false;
    visibleMiniGameSeconds = 0;
    completedMiniGameSeconds = 0;
  }

  void startMiniGameVisibleTimer() {
    _miniGameVisibleTimer?.cancel();

    _miniGameVisibleTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) return;

        setState(() {
          visibleMiniGameSeconds = miniGameElapsedSeconds;
        });
      },
    );
  }

  void freezeMiniGameVisibleTimer() {
    completedMiniGameSeconds = miniGameElapsedSeconds;
    visibleMiniGameSeconds = completedMiniGameSeconds;
    _miniGameVisibleTimer?.cancel();

    if (mounted) {
      setState(() {});
    }
  }

  void stopMiniGameVisibleTimer() {
    _miniGameVisibleTimer?.cancel();
    _miniGameVisibleTimer = null;
  }

  Future<void> saveMiniGameUsage({
    required String gameKey,
    required String title,
    required bool completed,
  }) async {
    final seconds = completed && completedMiniGameSeconds > 0
        ? completedMiniGameSeconds
        : miniGameElapsedSeconds;

    if (seconds <= 0) return;

    if (completed) {
      if (_miniGameCompletedSaved) return;
      _miniGameCompletedSaved = true;
    } else {
      if (_miniGameDisposeSaved || _miniGameCompletedSaved) return;
      if (seconds < 2) return;
      _miniGameDisposeSaved = true;
    }

    try {
      debugPrint(
        "MINI GAME USAGE SAVE => key=mini_$gameKey title=$title seconds=$seconds completed=$completed",
      );

      await UsageTimeRepository.addActivityTime(
        activityKey: "mini_$gameKey",
        title: title,
        type: "miniGame",
        seconds: seconds,
        completed: completed,
      );
    } catch (e) {
      debugPrint("MINI GAME USAGE ERROR => $e");

      if (completed) {
        _miniGameCompletedSaved = false;
      } else {
        _miniGameDisposeSaved = false;
      }
    }
  }

  void saveMiniGameUsageOnDispose({
    required String gameKey,
    required String title,
  }) {
    unawaited(
      saveMiniGameUsage(
        gameKey: gameKey,
        title: title,
        completed: false,
      ),
    );
  }
}
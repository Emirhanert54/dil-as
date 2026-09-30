import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _enabled = true;
  bool _isSpeaking = false;

  double _rate = 0.45;
  double _pitch = 1.05;
  double _volume = 1.0;

  int _speechToken = 0;
  Completer<void>? _currentCompleter;

  bool get isEnabled => _enabled;
  bool get isSpeaking => _isSpeaking;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;

  Future<void> init({
    bool enabled = true,
    double rate = 0.45,
    double pitch = 1.05,
    double volume = 1.0,
  }) async {
    _enabled = enabled;
    _rate = rate;
    _pitch = pitch;
    _volume = volume;

    if (_initialized) {
      await _applySettings();
      return;
    }

    try {
      await _tts.setLanguage("tr-TR");

      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      try {
        await _tts.setQueueMode(0);
      } catch (_) {}

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _completeCurrent();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _completeCurrent();
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        _completeCurrent();
      });

      await _applySettings();
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> _applySettings() async {
    try {
      await _tts.setLanguage("tr-TR");
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
    } catch (_) {}
  }

  void _completeCurrent() {
    final completer = _currentCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Duration _safeTimeoutFor(String text) {
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final ms = 1200 + (wordCount * 420);
    return Duration(milliseconds: ms.clamp(1800, 9000));
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;

    if (!_enabled) {
      await stop();
    }
  }

  Future<void> updateSettings({
    bool? enabled,
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (enabled != null) {
      _enabled = enabled;
    }

    if (rate != null) {
      _rate = rate.clamp(0.1, 1.0);
    }

    if (pitch != null) {
      _pitch = pitch.clamp(0.5, 2.0);
    }

    if (volume != null) {
      _volume = volume.clamp(0.0, 1.0);
    }

    await init(
      enabled: _enabled,
      rate: _rate,
      pitch: _pitch,
      volume: _volume,
    );
  }

  Future<void> speak(
      String text, {
        bool interrupt = true,
        Duration delayAfterStop = const Duration(milliseconds: 120),
      }) async {
    final token = ++_speechToken;

    await _speakWithToken(
      token: token,
      text: text,
      interrupt: interrupt,
      delayAfterStop: delayAfterStop,
    );
  }

  Future<void> speakAfter(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
        bool interrupt = true,
      }) async {
    final token = ++_speechToken;

    await Future.delayed(delay);

    if (token != _speechToken) return;

    await _speakWithToken(
      token: token,
      text: text,
      interrupt: interrupt,
    );
  }

  Future<void> _speakWithToken({
    required int token,
    required String text,
    bool interrupt = true,
    Duration delayAfterStop = const Duration(milliseconds: 120),
  }) async {
    final cleanText = text.trim();

    if (!_enabled || cleanText.isEmpty) return;

    await init(
      enabled: _enabled,
      rate: _rate,
      pitch: _pitch,
      volume: _volume,
    );

    if (token != _speechToken) return;

    try {
      if (interrupt) {
        await _tts.stop();
        _completeCurrent();
        _isSpeaking = false;

        await Future.delayed(delayAfterStop);

        if (token != _speechToken) return;
      }

      final completer = Completer<void>();
      _currentCompleter = completer;
      _isSpeaking = true;

      await _tts.speak(cleanText);

      await completer.future.timeout(
        _safeTimeoutFor(cleanText),
        onTimeout: () {},
      );

      if (token == _speechToken) {
        _isSpeaking = false;
      }
    } catch (_) {
      _isSpeaking = false;
      _completeCurrent();
    }
  }

  Future<void> stop() async {
    _speechToken++;

    try {
      await _tts.stop();
    } catch (_) {}

    _completeCurrent();
    _isSpeaking = false;
  }

  Future<void> testVoice() async {
    await speak(
      "Merhaba, ben DİL-AS. Ses ayarların çalışıyor.",
      interrupt: true,
    );
  }
}
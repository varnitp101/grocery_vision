import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsPriority {
  immediate,
  normal,
  guidance,
}

class TtsService with WidgetsBindingObserver {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isAppForeground = true;
  static bool _observerAdded = false;
  double _speechRate = 0.55;
  double _speechPitch = 1.0;
  final double _speechVolume = 1.0;

  TtsService() {
    _ensureObserver();
    _init();
  }

  void _ensureObserver() {
    if (!_observerAdded) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observerAdded = true;
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.hidden ||
               state == AppLifecycleState.detached) {
      _isAppForeground = false;
      stop();
    }
  }

  /// Check whether app is currently active in the foreground
  static bool get isAppForeground => _isAppForeground;

  /// Explicitly update foreground status if controlled by root app observer
  static void setAppForeground(bool foreground) {
    _isAppForeground = foreground;
    if (!foreground) {
      try {
        _flutterTts.stop();
      } catch (_) {}
    }
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _speechRate = prefs.getDouble('tts_speech_rate') ?? 0.55;
      _speechPitch = prefs.getDouble('tts_speech_pitch') ?? 1.0;

      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_speechVolume);
      await _flutterTts.setPitch(_speechPitch);
      await _flutterTts.awaitSpeakCompletion(false);
      _isInitialized = true;
    } catch (e) {
      // Graceful fallback
      _isInitialized = true;
    }
  }

  /// Speaks text with specified priority
  Future<void> speak(String text, {TtsPriority priority = TtsPriority.normal}) async {
    if (!_isAppForeground) return;
    if (text.trim().isEmpty) return;
    await _init();
    if (!_isAppForeground) return;

    if (priority == TtsPriority.immediate) {
      await _flutterTts.stop();
    }

    try {
      if (_isAppForeground) {
        await _flutterTts.speak(text);
      }
    } catch (_) {
      // Ignored
    }
  }

  /// Stops current speech output
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  /// Adjust speech rate (0.1 to 1.0) and persist
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speech_rate', _speechRate);
  }

  /// Adjust pitch (0.5 to 2.0) and persist
  Future<void> setPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_speechPitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speech_pitch', _speechPitch);
  }

  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

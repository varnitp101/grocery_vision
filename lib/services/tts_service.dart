import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsPriority {
  immediate,
  normal,
  guidance,
}

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  double _speechRate = 0.55;
  double _speechPitch = 1.0;
  final double _speechVolume = 1.0;

  TtsService() {
    _init();
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
    if (text.trim().isEmpty) return;
    await _init();

    if (priority == TtsPriority.immediate) {
      await _flutterTts.stop();
    }

    try {
      await _flutterTts.speak(text);
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

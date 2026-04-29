import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

enum VoiceProfile { male, female, neutral }

enum VibrationLevel { low, medium, high }

class AppSettings {
  final bool aiVoiceEnabled;
  final VoiceProfile voiceProfile;
  final double speechRate;
  final double voicePitch;
  final VibrationLevel vibrationLevel;
  final String language;

  AppSettings({
    this.aiVoiceEnabled = true,
    this.voiceProfile = VoiceProfile.female,
    this.speechRate = 1.2,
    this.voicePitch = 0.7,
    this.vibrationLevel = VibrationLevel.high,
    this.language = 'English (US)',
  });

  AppSettings copyWith({
    bool? aiVoiceEnabled,
    VoiceProfile? voiceProfile,
    double? speechRate,
    double? voicePitch,
    VibrationLevel? vibrationLevel,
    String? language,
  }) {
    return AppSettings(
      aiVoiceEnabled: aiVoiceEnabled ?? this.aiVoiceEnabled,
      voiceProfile: voiceProfile ?? this.voiceProfile,
      speechRate: speechRate ?? this.speechRate,
      voicePitch: voicePitch ?? this.voicePitch,
      vibrationLevel: vibrationLevel ?? this.vibrationLevel,
      language: language ?? this.language,
    );
  }

  /// Returns pitch as a human-readable label.
  String get pitchLabel {
    if (voicePitch <= 0.33) return 'Low';
    if (voicePitch <= 0.66) return 'Medium';
    return 'High';
  }

  /// Returns vibration intensity as a 0-1 double (for persistence).
  double get vibrationIntensity {
    switch (vibrationLevel) {
      case VibrationLevel.low:
        return 0.3;
      case VibrationLevel.medium:
        return 0.6;
      case VibrationLevel.high:
        return 1.0;
    }
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(_loadSettings(_prefs));

  static AppSettings _loadSettings(SharedPreferences prefs) {
    return AppSettings(
      aiVoiceEnabled: prefs.getBool('aiVoiceEnabled') ?? true,
      voiceProfile: VoiceProfile.values[prefs.getInt('voiceProfile') ?? 1],
      speechRate: prefs.getDouble('speechRate') ?? 1.2,
      voicePitch: prefs.getDouble('voicePitch') ?? 0.7,
      vibrationLevel: VibrationLevel.values[prefs.getInt('vibrationLevel') ?? 2],
      language: prefs.getString('language') ?? 'English (US)',
    );
  }

  void toggleAiVoice(bool enabled) {
    state = state.copyWith(aiVoiceEnabled: enabled);
    _prefs.setBool('aiVoiceEnabled', enabled);
  }

  void setVoiceProfile(VoiceProfile profile) {
    // Auto-adjust pitch and rate based on voice profile
    double pitch;
    double rate;
    switch (profile) {
      case VoiceProfile.male:
        pitch = 0.3;  // Low/deep voice
        rate = 1.1;
      case VoiceProfile.female:
        pitch = 0.85; // Higher feminine voice
        rate = 1.2;
      case VoiceProfile.neutral:
        pitch = 0.55; // Balanced midrange
        rate = 1.15;
    }
    state = state.copyWith(voiceProfile: profile, voicePitch: pitch, speechRate: rate);
    _prefs.setInt('voiceProfile', profile.index);
    _prefs.setDouble('voicePitch', pitch);
    _prefs.setDouble('speechRate', rate);
  }

  void updateSpeechRate(double rate) {
    state = state.copyWith(speechRate: rate);
    _prefs.setDouble('speechRate', rate);
  }

  void updateVoicePitch(double pitch) {
    state = state.copyWith(voicePitch: pitch);
    _prefs.setDouble('voicePitch', pitch);
  }

  void setVibrationLevel(VibrationLevel level) {
    state = state.copyWith(vibrationLevel: level);
    _prefs.setInt('vibrationLevel', level.index);
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
    _prefs.setString('language', lang);
  }

  void resetToDefaults() {
    state = AppSettings();
    _prefs.setBool('aiVoiceEnabled', true);
    _prefs.setInt('voiceProfile', VoiceProfile.female.index);
    _prefs.setDouble('speechRate', 1.2);
    _prefs.setDouble('voicePitch', 0.7);
    _prefs.setInt('vibrationLevel', VibrationLevel.high.index);
    _prefs.setString('language', 'English (US)');
  }
}

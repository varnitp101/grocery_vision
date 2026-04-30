import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/settings_provider.dart';


const List<String> _supportedLanguages = [
  'English',
  'Hindi',
  'Bengali',
  'Telugu',
  'Marathi',
  'Tamil',
  'Urdu',
  'Gujarati',
  'Kannada',
  'Malayalam',
  'Odia',
  'Punjabi',
  'Assamese',
  'Maithili',
  'Sanskrit',
  'Santali',
  'Kashmiri',
  'Nepali',
  'Sindhi',
  'Dogri',
  'Konkani',
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _testVoice() async {
    final settings = ref.read(settingsProvider);
    await _tts.setSpeechRate(settings.speechRate / 2.0);
    await _tts.setPitch(settings.voicePitch + 0.5);
    await _tts.speak('Hello! This is your voice assistant. All settings are configured.');
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) => const _ResetConfirmationDialog(),
    );
  }

  void _showLanguagePicker() {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    const primaryAmber = Color(0xFFFFC107);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'SELECT LANGUAGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              Divider(color: Colors.white.withAlpha(20), height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _supportedLanguages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final lang = _supportedLanguages[index];
                    final isSelected = settings.language == lang;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setLanguage(lang);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          color: isSelected ? primaryAmber.withAlpha(20) : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    color: isSelected ? primaryAmber : Colors.white,
                                    fontSize: 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: primaryAmber, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgBlack = Color(0xFF000000);
    const highlight = Color(0xFF2A2A2A);
    const primaryAmber = Color(0xFFFFC107);

    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              decoration: BoxDecoration(
                color: bgBlack.withAlpha(240),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(25))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Accessibility\n& Voice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: primaryAmber, size: 28),
                  ),
                ],
              ),
            ),


            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [

                  _SettingsCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Voice Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Verbose descriptions',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(100),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: 'Toggle AI Voice Assistant',
                          toggled: settings.aiVoiceEnabled,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.toggleAiVoice(!settings.aiVoiceEnabled);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 64,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: settings.aiVoiceEnabled ? primaryAmber : const Color(0xFF3C4953),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                alignment: settings.aiVoiceEnabled ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Profile',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: VoiceProfile.values.map((profile) {
                              final isSelected = settings.voiceProfile == profile;
                              final label = profile.name[0].toUpperCase() + profile.name.substring(1);
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: profile == VoiceProfile.male ? 0 : 6,
                                    right: profile == VoiceProfile.neutral ? 0 : 6,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      notifier.setVoiceProfile(profile);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryAmber : highlight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryAmber : Colors.white.withAlpha(25),
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: primaryAmber.withAlpha(76), blurRadius: 15)]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : Colors.white,
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  _SettingsCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Speech Rate',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${settings.speechRate.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: primaryAmber,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _CustomSlider(
                          value: settings.speechRate,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (val) => notifier.updateSpeechRate(double.parse(val.toStringAsFixed(1))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  _SettingsCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Voice Pitch',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              settings.pitchLabel,
                              style: const TextStyle(
                                color: primaryAmber,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _CustomSlider(
                          value: settings.voicePitch,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) => notifier.updateVoicePitch(double.parse(val.toStringAsFixed(2))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vibration Intensity',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: VibrationLevel.values.map((level) {
                              final isSelected = settings.vibrationLevel == level;
                              final label = level.name[0].toUpperCase() + level.name.substring(1);
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: level == VibrationLevel.low ? 0 : 4,
                                    right: level == VibrationLevel.high ? 0 : 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      notifier.setVibrationLevel(level);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryAmber : highlight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.white.withAlpha(25),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: primaryAmber.withAlpha(128), blurRadius: 15)]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : Colors.white70,
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  _SettingsCard(
                    child: GestureDetector(
                      onTap: _showLanguagePicker,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Language',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  settings.language,
                                  style: const TextStyle(color: primaryAmber, fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: highlight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),



                  Semantics(
                    label: 'Test Voice',
                    button: true,
                    child: ElevatedButton(
                      onPressed: _testVoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                        shadowColor: primaryAmber.withAlpha(76),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'TEST VOICE',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Semantics(
                    label: 'Reset Settings to Defaults',
                    button: true,
                    child: OutlinedButton(
                      onPressed: _showResetDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                        backgroundColor: Colors.white.withAlpha(8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restart_alt_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'RESET TO DEFAULTS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: child,
    );
  }
}


class _CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CustomSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryAmber = Color(0xFFFFC107);
    final fraction = (value - min) / (max - min);

    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final thumbPosition = fraction * trackWidth;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [

              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              Container(
                height: 24,
                width: thumbPosition.clamp(0, trackWidth),
                decoration: BoxDecoration(
                  color: primaryAmber,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              Positioned(
                left: (thumbPosition - 20).clamp(0, trackWidth - 40),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: primaryAmber.withAlpha(76), blurRadius: 0, spreadRadius: 6),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 56,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackShape: const RectangularSliderTrackShape(),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class _ResetConfirmationDialog extends ConsumerWidget {
  const _ResetConfirmationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryAmber = Color(0xFFFFAA00);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryAmber, width: 6),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(230), blurRadius: 50, offset: const Offset(0, 25)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: primaryAmber.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: primaryAmber, width: 2),
              ),
              child: const Icon(Icons.warning_rounded, color: primaryAmber, size: 48),
            ),
            const SizedBox(height: 24),


            const Text(
              'Reset All',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Settings?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryAmber,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),


            Container(
              width: 64,
              height: 4,
              decoration: BoxDecoration(
                color: primaryAmber.withAlpha(76),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),


            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'This will return all voice and vibration settings to normal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),


            Semantics(
              label: 'Yes, Reset. Confirm Action',
              button: true,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref.read(settingsProvider.notifier).resetToDefaults();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'YES, RESET',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3.0),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Confirm Action',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black.withAlpha(150), letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),


            Semantics(
              label: 'Cancel',
              button: true,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 72),
                  side: BorderSide(color: Colors.white.withAlpha(76), width: 3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

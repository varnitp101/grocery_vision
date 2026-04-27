import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/settings_provider.dart';

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
    await _tts.setSpeechRate(settings.speechRate / 2.0); // TTS expects 0-1 range roughly
    await _tts.setPitch(settings.voicePitch + 0.5); // Adjust to TTS range
    await _tts.speak('Hello! This is your voice assistant. All settings are configured.');
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) => const _ResetConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgBlack = Color(0xFF000000);
    const surface = Color(0xFF121212);
    const highlight = Color(0xFF2A2A2A);
    const primaryAmber = Color(0xFFFFC107);

    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      color: surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: primaryAmber, size: 28),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 220),
                children: [
                  // ── AI Voice Assistant Toggle ──
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

                  // ── Voice Profile ──
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

                  // ── Speech Rate ──
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

                  // ── Voice Pitch ──
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

                  // ── Vibration Intensity ──
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Vibration Intensity',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              settings.vibrationLevel.name[0].toUpperCase() + settings.vibrationLevel.name.substring(1),
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 64,
                          child: Row(
                            children: VibrationLevel.values.map((level) {
                              final isSelected = settings.vibrationLevel == level;
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
                                          color: isSelected ? Colors.white : Colors.transparent,
                                          width: isSelected ? 2 : 0,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: primaryAmber.withAlpha(128), blurRadius: 15)]
                                            : null,
                                      ),
                                      child: isSelected
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(width: 3, height: 24, decoration: BoxDecoration(color: Colors.black.withAlpha(100), borderRadius: BorderRadius.circular(2))),
                                                const SizedBox(width: 4),
                                                Container(width: 3, height: 40, decoration: BoxDecoration(color: Colors.black.withAlpha(100), borderRadius: BorderRadius.circular(2))),
                                                const SizedBox(width: 4),
                                                Container(width: 3, height: 24, decoration: BoxDecoration(color: Colors.black.withAlpha(100), borderRadius: BorderRadius.circular(2))),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
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

                  // ── Language ──
                  _SettingsCard(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: language picker
                      },
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
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Fixed Bottom Buttons ──
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              bgBlack,
              bgBlack,
              bgBlack.withAlpha(220),
              bgBlack.withAlpha(0),
            ],
            stops: const [0.0, 0.7, 0.9, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TEST VOICE
            Semantics(
              label: 'Test Voice',
              button: true,
              child: ElevatedButton(
                onPressed: _testVoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  shadowColor: primaryAmber.withAlpha(76),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 32),
                    SizedBox(width: 8),
                    Text(
                      'TEST VOICE',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // RESET
            Semantics(
              label: 'Reset Settings to Defaults',
              button: true,
              child: OutlinedButton(
                onPressed: _showResetDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 80),
                  side: BorderSide(color: Colors.white.withAlpha(50)),
                  backgroundColor: surface.withAlpha(128),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'RESET TO DEFAULTS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Card ───
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFC107).withAlpha(12), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}

// ─── Custom Slider ───
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
              // Background track
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Filled track
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
              // Thumb
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
              // Invisible native slider on top for interaction
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

// ─── Reset Confirmation Dialog ───
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
            // Warning icon
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

            // Title
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

            // Divider
            Container(
              width: 64,
              height: 4,
              decoration: BoxDecoration(
                color: primaryAmber.withAlpha(76),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Body text
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

            // YES, RESET button
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
                  minimumSize: const Size(double.infinity, 88),
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

            // CANCEL button
            Semantics(
              label: 'Cancel',
              button: true,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 88),
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

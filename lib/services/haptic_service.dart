import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class HapticService {
  Future<void> detectionStable() async {
    try {
      await Haptics.vibrate(HapticsType.selection);
    } catch (_) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> captureTriggered() async {
    try {
      await Haptics.vibrate(HapticsType.medium);
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> productFound() async {
    try {
      await Haptics.vibrate(HapticsType.success);
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> failureOrRetry() async {
    try {
      await Haptics.vibrate(HapticsType.error);
    } catch (_) {
      await HapticFeedback.vibrate();
    }
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});

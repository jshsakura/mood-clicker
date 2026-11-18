import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'haptic_cue.dart';
import 'ports.dart';

/// Plays haptics via Flutter's HapticFeedback. No-op on devices without a motor (e.g. macOS).
class SystemHaptics implements HapticsPort {
  SystemHaptics({
    Future<void> Function(HapticStyle style)? fire,
    Future<void> Function(Duration)? delay,
    void Function(String)? log,
  }) : _fire = fire ?? _platformFire,
       _delay = delay ?? Future<void>.delayed,
       _log = log ?? debugPrint;

  final Future<void> Function(HapticStyle) _fire;
  final Future<void> Function(Duration) _delay;
  final void Function(String) _log;

  /// Incremented on each new cue so pending delayed steps from an older cue cancel.
  int _generation = 0;

  @override
  Future<void> play(HapticCue cue) async {
    final mine = ++_generation;
    try {
      for (final step in cue.steps) {
        if (step.delay > Duration.zero) {
          await _delay(step.delay);
          if (mine != _generation) return;
        }
        await _fire(step.style);
      }
    } catch (e) {
      _log('Haptics failed: $e');
    }
  }

  static Future<void> _platformFire(HapticStyle style) => switch (style) {
    HapticStyle.light => HapticFeedback.lightImpact(),
    HapticStyle.medium => HapticFeedback.mediumImpact(),
    HapticStyle.heavy => HapticFeedback.heavyImpact(),
    HapticStyle.selection => HapticFeedback.selectionClick(),
  };
}

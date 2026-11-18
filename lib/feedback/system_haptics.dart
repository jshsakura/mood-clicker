import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/tuning.dart';
import 'haptic_cue.dart';
import 'ports.dart';

/// Plays haptics via Flutter's HapticFeedback. No-op on devices without a motor (e.g. macOS).
class SystemHaptics implements HapticsPort {
  SystemHaptics({
    Future<void> Function(HapticStyle style)? fire,
    Future<void> Function(Duration)? delay,
    Duration Function()? clock,
    void Function(String)? log,
  }) : _fire = fire ?? _platformFire,
       _delay = delay ?? Future<void>.delayed,
       _clock = clock ?? _sharedClock,
       _log = log ?? debugPrint;

  static final Stopwatch _sharedWatch = Stopwatch()..start();
  static Duration _sharedClock() => _sharedWatch.elapsed;
  static Duration? _lastPlatformFire;

  /// Resets the global minimum gap tracker for isolated unit tests.
  @visibleForTesting
  static void resetGlobalGapForTest() {
    _lastPlatformFire = null;
  }

  final Future<void> Function(HapticStyle) _fire;
  final Future<void> Function(Duration) _delay;
  final Duration Function() _clock;
  final void Function(String) _log;

  /// Incremented on each new cue or cancel so pending delayed steps stop.
  int _generation = 0;

  @override
  void cancel() {
    _generation++;
  }

  @override
  Future<void> play(HapticCue cue, {bool priority = false}) async {
    final mine = ++_generation;
    try {
      for (var i = 0; i < cue.steps.length; i++) {
        final step = cue.steps[i];
        if (step.delay > Duration.zero) {
          await _delay(step.delay);
          if (mine != _generation) return;
        }
        final now = _clock();
        final last = _lastPlatformFire;
        final bypass = priority && i == 0;
        if (!bypass &&
            last != null &&
            now - last < FeedbackTuning.minHapticGap) {
          continue;
        }
        _lastPlatformFire = now;
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

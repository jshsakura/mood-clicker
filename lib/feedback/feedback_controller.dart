import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/tuning.dart';
import 'feedback_kind.dart';
import 'feedback_settings.dart';
import 'feedback_table.dart';
import 'ports.dart';

/// Minimum interval between haptics. Earlier triggers are dropped; sounds may overlap.
const minHapticGap = FeedbackTuning.minHapticGap;

/// Pitch jitter range: ±3% around the base pitch.
const pitchJitter = FeedbackTuning.pitchJitter;

class FeedbackController {
  FeedbackController({
    required this.haptics,
    required this.sound,
    FeedbackSettings? settings,
    Duration Function()? clock,
    Random? random,
    void Function(String message)? log,
  }) : _settings = settings ?? const FeedbackSettings(),
       _clock = clock ?? _stopwatchClock(),
       _random = random ?? Random(),
       _log = log ?? debugPrint;

  final HapticsPort haptics;
  final SoundPort sound;
  final Duration Function() _clock;
  final Random _random;
  final void Function(String) _log;

  FeedbackSettings _settings;

  /// Updated settings take effect on the next trigger; turning haptics off cancels pending steps.
  FeedbackSettings get settings => _settings;
  set settings(FeedbackSettings value) {
    _settings = value;
    if (!value.hapticsOn) {
      haptics.cancel();
    }
  }

  Duration? _lastHaptic;

  /// Triggers feedback without throwing errors to the caller.
  void trigger(FeedbackKind kind, String moodId) {
    final entry = FeedbackTable.of(kind, moodId);

    final haptic = entry.haptic;
    final isPriority = kind == FeedbackKind.full;
    if (_settings.hapticsOn &&
        haptic != null &&
        _hapticAllowed(priority: isPriority)) {
      _fire(() => haptics.play(haptic, priority: isPriority));
    }

    final soundId = entry.soundId;
    if (_settings.soundOn && soundId != null) {
      final cue = SoundCue(_settings.soundPack, soundId);
      final pitch = 1 + (_random.nextDouble() * 2 - 1) * pitchJitter;
      _fire(() => sound.play(cue, pitch: pitch));
    }
  }

  bool _hapticAllowed({bool priority = false}) {
    final now = _clock();
    final last = _lastHaptic;
    if (!priority && last != null && now - last < minHapticGap) return false;
    _lastHaptic = now;
    return true;
  }

  void _fire(Future<void> Function() play) {
    try {
      unawaited(
        play().onError((Object e, StackTrace _) => _log('Feedback failed: $e')),
      );
    } catch (e) {
      _log('Feedback failed: $e');
    }
  }

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }
}

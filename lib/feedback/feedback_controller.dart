import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/tuning.dart';
import 'feedback_kind.dart';
import 'feedback_settings.dart';
import 'feedback_table.dart';
import 'ports.dart';
import 'tap_pitch.dart';

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
       _run = TapPitchRun(random: random),
       _log = log ?? debugPrint;

  final HapticsPort haptics;
  final SoundPort sound;
  final Duration Function() _clock;
  final Random _random;
  final TapPitchRun _run;
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

  /// How much of its strength the tap haptic keeps, 1 down to 0. The release flow lowers it while
  /// the gauge approaches full. Taps made by hand never see it above 1.
  double get hapticEase => _hapticEase;
  double _hapticEase = 1;
  set hapticEase(double value) => _hapticEase = value.clamp(0.0, 1.0);

  /// True after the release flow settled: the tap sound is the pentatonic kalimba climbing, the
  /// calm rule, whatever the heavy mood normally plays.
  bool settled = false;

  /// Triggers feedback without throwing errors to the caller.
  /// When [kind] is [FeedbackKind.tap] and [fill] is given, scales intensity and sharpness.
  void trigger(FeedbackKind kind, String moodId, {double? fill}) {
    final entry = FeedbackTable.of(kind, moodId);

    var haptic = entry.haptic;
    final isPriority =
        kind == FeedbackKind.full ||
        kind == FeedbackKind.rare ||
        kind == FeedbackKind.cleanse;
    if (_settings.hapticsOn &&
        haptic != null &&
        _hapticAllowed(priority: isPriority)) {
      if (kind == FeedbackKind.tap && fill != null) {
        haptic = haptic.scaledByFill(fill);
      }
      haptic = haptic.scaledByStrength(_settings.hapticScale * _hapticEase);
      _fire(() => haptics.play(haptic!, priority: isPriority));
    }

    final soundId = entry.soundId;
    if (_settings.soundOn && soundId != null) {
      final isTap = kind == FeedbackKind.tap;
      final tapId = _settings.soundPack.tapSoundId;
      if (kind == FeedbackKind.cleanse) {
        final cue = SoundCue(SoundPack.pentatonic, SoundPack.cleanseSoundId);
        _fire(() => sound.play(cue));
      } else if (isTap && (settled || tapId != null)) {
        final rule = settled ? TapPitchRule.rise : tapPitchRuleOf(moodId);
        final voice = _run.next(rule, _clock());
        final cue = SoundCue(
          settled ? SoundPack.pentatonic : _settings.soundPack,
          settled ? SoundPack.pentatonic.tapSoundId! : tapId!,
        );
        _fire(
          () => sound.play(
            cue,
            pitch: voice.pitch,
            volume: voice.volume,
            limitVoices: true,
          ),
        );
      } else {
        final cue = SoundCue(_settings.soundPack, soundId);
        final pitch = 1 + (_random.nextDouble() * 2 - 1) * pitchJitter;
        _fire(() => sound.play(cue, pitch: pitch, limitVoices: isTap));
      }
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

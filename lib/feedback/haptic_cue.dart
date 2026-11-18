import '../domain/tuning.dart';

/// Four basic haptic primitives mapped 1:1 to Flutter HapticFeedback.
enum HapticStyle { light, medium, heavy, selection }

/// A single playback step. [delay] is the wait time after the previous step.
class HapticStep {
  const HapticStep(this.style, {this.delay = Duration.zero});

  final HapticStyle style;
  final Duration delay;
}

enum IosHapticType { transient, continuous }

/// Single iOS Core Haptics event, used when wiring the platform channel.
class IosHapticEvent {
  const IosHapticEvent(
    this.type,
    this.intensity,
    this.sharpness, {
    this.startMs = 0,
    this.durationMs = 0,
  });

  final IosHapticType type;

  /// Intensity from 0.0 to 1.0.
  final double intensity;

  /// Sharpness from 0.0 to 1.0; lower values feel heavier.
  final double sharpness;
  final int startMs;

  /// Used only for continuous events.
  final int durationMs;

  Map<String, Object> toMap() => {
    'type': type.name,
    'intensity': intensity,
    'sharpness': sharpness,
    'startMs': startMs,
    'durationMs': durationMs,
  };
}

/// Hardware primitives for Android VibrationEffect.Composition (API 30+).
enum AndroidPrimitiveType { tick, click, thud, lowTick }

/// Single Android Composition primitive with normalized scale (0.0..1.0).
class AndroidPrimitiveStep {
  const AndroidPrimitiveStep(this.type, this.scale, {this.delayMs = 0});

  final AndroidPrimitiveType type;
  final double scale;
  final int delayMs;

  Map<String, Object> toMap() => {
    'type': type.name,
    'scale': scale,
    'delayMs': delayMs,
  };
}

/// Parameters for Android VibrationEffect.createWaveform and Composition.
class AndroidHaptic {
  const AndroidHaptic(
    this.timings,
    this.amplitudes, {
    this.primitives = const [],
  });

  /// Milliseconds alternating off/on durations; the first value is initial delay.
  final List<int> timings;

  /// Amplitudes 0..255; ignored on devices without amplitude control.
  final List<int> amplitudes;

  /// Optional hardware primitives for API 30+ devices.
  final List<AndroidPrimitiveStep> primitives;

  Map<String, Object> toMap() => {
    'timings': timings,
    'amplitudes': amplitudes,
    'primitives': [for (final p in primitives) p.toMap()],
  };
}

/// A haptic cue holding three representations together:
///
/// - [steps]: Fallback played via Flutter HapticFeedback when native channels are unavailable.
/// - [ios], [android]: Precise parameters for iOS Core Haptics and Android VibrationEffect.
class HapticCue {
  const HapticCue({
    required this.steps,
    required this.ios,
    required this.android,
  });

  final List<HapticStep> steps;
  final List<IosHapticEvent> ios;
  final AndroidHaptic android;

  /// Returns a copy whose intensity and sharpness scale proportionally with [fill] (0.0..1.0).
  HapticCue scaledByFill(double fill) {
    final t = fill.clamp(0.0, 1.0);
    final iScale =
        FeedbackTuning.fillIntensityMin +
        (FeedbackTuning.fillIntensityMax - FeedbackTuning.fillIntensityMin) * t;
    final sScale =
        FeedbackTuning.fillSharpnessMin +
        (FeedbackTuning.fillSharpnessMax - FeedbackTuning.fillSharpnessMin) * t;

    return HapticCue(
      steps: steps,
      ios: [
        for (final e in ios)
          IosHapticEvent(
            e.type,
            (e.intensity * iScale).clamp(0.0, 1.0),
            (e.sharpness * sScale).clamp(0.0, 1.0),
            startMs: e.startMs,
            durationMs: e.durationMs,
          ),
      ],
      android: AndroidHaptic(
        android.timings,
        [
          for (final a in android.amplitudes)
            a == 0 ? 0 : (a * iScale).round().clamp(1, 255),
        ],
        primitives: [
          for (final p in android.primitives)
            AndroidPrimitiveStep(
              p.type,
              (p.scale * iScale).clamp(0.0, 1.0),
              delayMs: p.delayMs,
            ),
        ],
      ),
    );
  }

  Map<String, Object> toChannelMap() => {
    'ios': [for (final e in ios) e.toMap()],
    'android': android.toMap(),
  };
}

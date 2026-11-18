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
}

/// Parameters for Android VibrationEffect.createWaveform (equal-length arrays).
class AndroidHaptic {
  const AndroidHaptic(this.timings, this.amplitudes);

  /// Milliseconds alternating off/on durations; the first value is initial delay.
  final List<int> timings;

  /// Amplitudes 0..255; ignored on devices without amplitude control.
  final List<int> amplitudes;
}

/// A haptic cue holding three representations together:
///
/// - [steps]: Current approximation played via the four Flutter HapticFeedback styles.
/// - [ios], [android]: Precise parameters for future platform channels (not played yet).
class HapticCue {
  const HapticCue({
    required this.steps,
    required this.ios,
    required this.android,
  });

  final List<HapticStep> steps;
  final List<IosHapticEvent> ios;
  final AndroidHaptic android;
}

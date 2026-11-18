import 'dart:async';
import 'dart:math' as math;

import '../domain/tuning.dart';

/// Emitted when a sudden shake is detected so the screen can trigger a liquid slosh.
class SloshSignal {
  const SloshSignal({required this.intensity, required this.directionX});

  /// Normalized slosh strength from 0.0 to 1.0.
  final double intensity;

  /// Horizontal tilt impulse from -1.0 (left) to 1.0 (right).
  final double directionX;
}

/// Detects sudden acceleration spikes from accelerometer samples (m/s^2).
class ShakeDetector {
  ShakeDetector({
    Duration Function()? clock,
    this.thresholdDelta = FeedbackTuning.shakeThresholdDelta,
    this.cooldown = FeedbackTuning.shakeCooldown,
  }) : _clock = clock ?? _stopwatchClock();

  final Duration Function() _clock;
  final double thresholdDelta;
  final Duration cooldown;

  final StreamController<SloshSignal> _controller =
      StreamController<SloshSignal>.broadcast();

  Stream<SloshSignal> get onSlosh => _controller.stream;

  double? _prevX;
  double? _prevY;
  double? _prevZ;
  Duration? _lastEmit;

  /// Feeds one accelerometer reading in m/s^2.
  void addSample(double x, double y, double z) {
    final px = _prevX;
    final py = _prevY;
    final pz = _prevZ;
    _prevX = x;
    _prevY = y;
    _prevZ = z;
    if (px == null || py == null || pz == null) return;

    final dx = x - px;
    final dy = y - py;
    final dz = z - pz;
    final delta = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (delta < thresholdDelta) return;

    final now = _clock();
    final last = _lastEmit;
    if (last != null && now - last < cooldown) return;
    _lastEmit = now;

    final intensity = ((delta - thresholdDelta) / thresholdDelta + 0.5).clamp(
      0.0,
      1.0,
    );
    final dirX = (dx / delta).clamp(-1.0, 1.0);
    _controller.add(SloshSignal(intensity: intensity, directionX: dirX));
  }

  Future<void> dispose() => _controller.close();

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }
}

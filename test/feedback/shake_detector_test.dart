import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/feedback/shake_detector.dart';

void main() {
  test('steady samples do not emit a slosh signal', () async {
    var now = Duration.zero;
    final detector = ShakeDetector(clock: () => now);
    final signals = <SloshSignal>[];
    final sub = detector.onSlosh.listen(signals.add);

    detector.addSample(0.0, 9.81, 0.0);
    now += const Duration(milliseconds: 50);
    detector.addSample(0.2, 9.85, -0.1);
    await Future<void>.delayed(Duration.zero);

    expect(signals, isEmpty);
    await sub.cancel();
    await detector.dispose();
  });

  test(
    'sudden acceleration spike emits slosh signal and respects cooldown',
    () async {
      var now = const Duration(seconds: 1);
      final detector = ShakeDetector(clock: () => now);
      final signals = <SloshSignal>[];
      final sub = detector.onSlosh.listen(signals.add);

      detector.addSample(0.0, 9.81, 0.0);
      detector.addSample(18.0, 9.81, 0.0);
      await Future<void>.delayed(Duration.zero);

      expect(signals, hasLength(1));
      expect(signals.first.intensity, inInclusiveRange(0.5, 1.0));
      expect(signals.first.directionX, greaterThan(0.9));

      // Within cooldown: ignored
      now += const Duration(milliseconds: 200);
      detector.addSample(-18.0, 9.81, 0.0);
      await Future<void>.delayed(Duration.zero);
      expect(signals, hasLength(1));

      // After cooldown: emits again
      now += FeedbackTuning.shakeCooldown;
      detector.addSample(18.0, 9.81, 0.0);
      await Future<void>.delayed(Duration.zero);
      expect(signals, hasLength(2));

      await sub.cancel();
      await detector.dispose();
    },
  );
}

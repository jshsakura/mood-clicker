import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/fill_gauge.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  const step = GaugeTuning.stepPerTap;
  const decay = GaugeTuning.decayPerSecond;
  final grace = GaugeTuning.grace.inMilliseconds;
  final tapsToFill = (1 / step).round();
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  FillGauge tapTimes(FillGauge from, int times, DateTime now) {
    var gauge = from;
    for (var i = 0; i < times; i++) {
      gauge = gauge.tap(now);
    }
    return gauge;
  }

  test('starts empty', () {
    expect(const FillGauge.empty().valueAt(t0), 0);
  });

  test('one tap raises the level by one step', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(t0), closeTo(step, 1e-12));
  });

  test('holds during the grace period after the last tap', () {
    final gauge = const FillGauge.empty().tap(t0).tap(at(100));
    expect(gauge.valueAt(at(100 + grace)), closeTo(2 * step, 1e-12));
  });

  test('decays at the configured rate once the grace period ends', () {
    var gauge = const FillGauge.empty();
    for (var i = 0; i < 10; i++) {
      gauge = gauge.tap(at(i * 10));
    }
    // Ten steps, then the grace time, then one second of decay.
    expect(
      gauge.valueAt(at(90 + grace + 1000)),
      closeTo(10 * step - decay, 1e-9),
    );
  });

  test('never drops below zero', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(at(60 * 1000)), 0);
  });

  test('never exceeds one and reports full', () {
    final gauge = tapTimes(const FillGauge.empty(), tapsToFill + 20, t0);
    expect(gauge.valueAt(t0), 1);
    expect(gauge.isFullAt(t0), isTrue);
  });

  test('exactly 1 / step taps fill it despite float error', () {
    final gauge = tapTimes(const FillGauge.empty(), tapsToFill, t0);
    expect(gauge.isFullAt(t0), isTrue);
  });

  test('one tap fewer does not fill it', () {
    final gauge = tapTimes(const FillGauge.empty(), tapsToFill - 1, t0);
    expect(gauge.isFullAt(t0), isFalse);
  });

  test('a tap during decay adds to the decayed level, not the old one', () {
    final four = tapTimes(const FillGauge.empty(), 4, t0);
    final gauge = four.tap(at(grace + 400));
    final decayed = 4 * step - 0.4 * decay;
    expect(gauge.valueAt(at(grace + 400)), closeTo(decayed + step, 1e-9));
  });

  group('holding the level', () {
    // A gap of g seconds loses (g - grace) * decay, and a tap adds one step.
    // The two cancel when (g - grace) * decay == step.
    final breakEvenMs = grace + (step / decay * 1000).round();

    FillGauge tapEvery(int ms, int times) {
      var gauge = tapTimes(const FillGauge.empty(), 10, t0);
      for (var i = 1; i <= times; i++) {
        gauge = gauge.tap(at(i * ms));
      }
      return gauge;
    }

    test('taps a bit faster than break even keep the level from sinking', () {
      final ms = breakEvenMs - 25;
      final gauge = tapEvery(ms, 20);
      expect(gauge.valueAt(at(20 * ms)), greaterThan(10 * step));
    });

    test('taps slower than break even let the level sink', () {
      final ms = breakEvenMs + 150;
      final gauge = tapEvery(ms, 5);
      expect(gauge.valueAt(at(5 * ms)), lessThan(10 * step));
    });
  });

  test('a clock that moves backwards does not raise the level', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(at(-5000)), closeTo(step, 1e-12));
  });

  test('emptiesAt is when decay reaches zero', () {
    final gauge = const FillGauge.empty().tap(t0);
    final decayMs = (step / decay * 1000).round();
    final empties = gauge.emptiesAt!;
    expect(
      empties.difference(at(grace + decayMs)).inMicroseconds.abs(),
      lessThan(1000),
    );
    expect(gauge.valueAt(empties), closeTo(0, 1e-6));
    expect(const FillGauge.empty().emptiesAt, isNull);
  });

  group('justFilled', () {
    test('is false on an empty gauge and on ordinary taps', () {
      expect(const FillGauge.empty().justFilled, isFalse);
      expect(const FillGauge.empty().tap(t0).justFilled, isFalse);
    });

    test('is true only on the tap that fills the gauge', () {
      final almost = tapTimes(const FillGauge.empty(), tapsToFill - 1, t0);
      expect(almost.justFilled, isFalse);
      final filled = almost.tap(t0);
      expect(filled.isFullAt(t0), isTrue);
      expect(filled.justFilled, isTrue);
    });

    test('is false for taps while the gauge stays full', () {
      final filled = tapTimes(const FillGauge.empty(), tapsToFill, t0);
      expect(filled.tap(at(10)).justFilled, isFalse);
    });

    test(
      'fires once per fill: again only after the gauge sinks and refills',
      () {
        var gauge = tapTimes(const FillGauge.empty(), tapsToFill, t0);
        final later = at(grace + 2000);
        expect(gauge.valueAt(later), lessThan(1));

        var fires = 0;
        for (var i = 0; i < tapsToFill; i++) {
          gauge = gauge.tap(later);
          if (gauge.justFilled) fires++;
        }
        expect(fires, 1);
        expect(gauge.isFullAt(later), isTrue);
      },
    );
  });

  test('the display follow time is a plain tuning constant', () {
    expect(GaugeTuning.displayFollow, const Duration(milliseconds: 420));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/fill_gauge.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  test('starts empty', () {
    expect(const FillGauge.empty().valueAt(t0), 0);
  });

  test('one tap raises the level by one step', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(t0), closeTo(GaugeTuning.stepPerTap, 1e-12));
  });

  test('holds during the grace period after the last tap', () {
    final gauge = const FillGauge.empty().tap(t0).tap(at(100));
    expect(gauge.valueAt(at(100 + 300)), closeTo(0.08, 1e-12));
  });

  test('decays at the configured rate once the grace period ends', () {
    var gauge = const FillGauge.empty();
    for (var i = 0; i < 10; i++) {
      gauge = gauge.tap(at(i * 10));
    }
    // 0.40, then 0.3 s grace, then 0.25 per second for 1 s.
    expect(gauge.valueAt(at(90 + 300 + 1000)), closeTo(0.15, 1e-9));
  });

  test('never drops below zero', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(at(60 * 1000)), 0);
  });

  test('never exceeds one and reports full', () {
    var gauge = const FillGauge.empty();
    for (var i = 0; i < 40; i++) {
      gauge = gauge.tap(at(i));
    }
    expect(gauge.valueAt(at(39)), 1);
    expect(gauge.isFullAt(at(39)), isTrue);
  });

  test('exactly 1 / step taps fill it despite float error', () {
    final taps = (1 / GaugeTuning.stepPerTap).round();
    var gauge = const FillGauge.empty();
    for (var i = 0; i < taps; i++) {
      gauge = gauge.tap(t0);
    }
    expect(gauge.isFullAt(t0), isTrue);
  });

  test('a tap during decay adds to the decayed level, not the old one', () {
    final gauge = const FillGauge.empty()
        .tap(t0)
        .tap(t0)
        .tap(t0)
        .tap(t0) // 0.16
        .tap(at(300 + 400)); // decayed by 0.10 to 0.06, then +0.04
    expect(gauge.valueAt(at(700)), closeTo(0.10, 1e-9));
  });

  test('about five taps per second roughly holds the level', () {
    var gauge = const FillGauge.empty();
    for (var i = 0; i < 10; i++) {
      gauge = gauge.tap(t0);
    }
    final start = gauge.valueAt(t0);
    for (var i = 1; i <= 25; i++) {
      gauge = gauge.tap(at(i * 160));
    }
    expect(gauge.valueAt(at(25 * 160)), greaterThanOrEqualTo(start));
  });

  test('a clock that moves backwards does not raise the level', () {
    final gauge = const FillGauge.empty().tap(t0);
    expect(gauge.valueAt(at(-5000)), closeTo(0.04, 1e-12));
  });

  test('emptiesAt is when decay reaches zero', () {
    final gauge = const FillGauge.empty().tap(t0); // 0.04 -> 0.16 s of decay
    expect(gauge.emptiesAt, at(300 + 160));
    expect(gauge.valueAt(gauge.emptiesAt!), 0);
    expect(const FillGauge.empty().emptiesAt, isNull);
  });
}

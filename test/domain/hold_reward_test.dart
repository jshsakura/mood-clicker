import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/hold_reward.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(double seconds) =>
      t0.add(Duration(milliseconds: (seconds * 1000).round()));

  test('pays once after the hold time inside the band', () {
    var hold = const HoldReward();
    var paid = 0;
    for (var ms = 0; ms <= 4000; ms += 100) {
      final (next, earned) = hold.update(0.97, at(ms / 1000));
      hold = next;
      if (earned) paid++;
    }
    expect(paid, 1);
  });

  test('does not pay before the hold time', () {
    var hold = const HoldReward();
    final seconds = HoldTuning.duration.inMilliseconds / 1000 - 0.1;
    var paid = false;
    for (var ms = 0; ms <= seconds * 1000; ms += 100) {
      final (next, earned) = hold.update(0.97, at(ms / 1000));
      hold = next;
      paid |= earned;
    }
    expect(paid, isFalse);
  });

  test('leaving the band restarts the count', () {
    var hold = const HoldReward();
    hold = hold.update(0.97, at(0)).$1;
    hold = hold.update(0.9, at(2)).$1;
    final (_, early) = hold.update(0.97, at(3.5));
    expect(early, isFalse);
  });

  test('a full gauge is outside the band', () {
    var hold = const HoldReward();
    hold = hold.update(0.97, at(0)).$1;
    hold = hold.update(1.0, at(2)).$1;
    expect(hold.update(0.97, at(3.5)).$2, isFalse);
  });

  test('after paying it waits until the level is below the rearm level', () {
    var hold = const HoldReward();
    hold = hold.update(0.97, at(0)).$1;
    hold = hold.update(0.97, at(3.1)).$1;
    // Back in the band without having gone below the rearm level: nothing.
    hold = hold.update(0.9, at(4)).$1;
    hold = hold.update(0.97, at(5)).$1;
    expect(hold.update(0.97, at(9)).$2, isFalse);
    // Below the rearm level, then up again: paid once more.
    hold = hold.update(0.5, at(10)).$1;
    hold = hold.update(0.97, at(11)).$1;
    expect(hold.update(0.97, at(14.1)).$2, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/save_policy.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  // Monotonic time: the elapsed time of an injected Stopwatch, not the wall clock.
  const t0 = Duration.zero;
  Duration at(int ms) => Duration(milliseconds: ms);

  test('nothing is due before any tap', () {
    const policy = SavePolicy.clean();
    expect(policy.hasPending, isFalse);
    expect(policy.dueAt, isNull);
    expect(policy.shouldSave(SaveTrigger.tick, at(10000)), isFalse);
    expect(policy.shouldSave(SaveTrigger.leaveScreen, t0), isFalse);
  });

  test('first unsaved tap starts the clock, later taps do not reset it', () {
    final policy = const SavePolicy.clean()
        .afterTap(t0)
        .afterTap(at(1500))
        .afterTap(at(1900));
    expect(policy.dueAt, t0 + SaveTuning.interval);
    expect(policy.shouldSave(SaveTrigger.tick, at(1999)), isFalse);
    expect(policy.shouldSave(SaveTrigger.tick, at(2000)), isTrue);
  });

  test('a single tap is still saved within the interval', () {
    final policy = const SavePolicy.clean().afterTap(t0);
    expect(policy.shouldSave(SaveTrigger.tick, at(2000)), isTrue);
  });

  test('leaving the screen or going to the background saves pending taps', () {
    final policy = const SavePolicy.clean().afterTap(t0);
    expect(policy.shouldSave(SaveTrigger.leaveScreen, at(1)), isTrue);
    expect(policy.shouldSave(SaveTrigger.background, at(1)), isTrue);
  });

  test('after saving, the next tap starts a fresh interval', () {
    final saved = const SavePolicy.clean().afterTap(t0).afterSaveStarted();
    expect(saved.hasPending, isFalse);
    final next = saved.afterTap(at(5000));
    expect(next.dueAt, at(5000) + SaveTuning.interval);
  });

  group('taps that arrive while a save is running', () {
    test('stay pending, with their own interval', () {
      final policy = const SavePolicy.clean()
          .afterTap(t0)
          .afterSaveStarted() // the write began
          .afterTap(at(500)); // tapped while writing
      expect(policy.hasPending, isTrue);
      expect(policy.dueAt, at(500) + SaveTuning.interval);
    });

    test('a failed save puts the oldest unsaved tap back', () {
      final policy = const SavePolicy.clean()
          .afterTap(t0)
          .afterSaveStarted()
          .afterTap(at(500))
          .afterSaveFailed();
      expect(policy.dueAt, t0 + SaveTuning.interval);
    });

    test('a failed save with no newer taps is pending again', () {
      final policy = const SavePolicy.clean()
          .afterTap(t0)
          .afterSaveStarted()
          .afterSaveFailed();
      expect(policy.hasPending, isTrue);
      expect(policy.shouldSave(SaveTrigger.leaveScreen, at(1)), isTrue);
    });
  });

  test(
    'a wall clock jump cannot move the deadline: only elapsed time counts',
    () {
      // The policy never sees a DateTime, so a clock set back an hour changes nothing.
      final policy = const SavePolicy.clean().afterTap(at(1000));
      expect(policy.shouldSave(SaveTrigger.tick, at(2999)), isFalse);
      expect(policy.shouldSave(SaveTrigger.tick, at(3000)), isTrue);
    },
  );

  test('two failures in a row still retry from the oldest unsaved tap', () {
    final policy = const SavePolicy.clean()
        .afterTap(t0)
        .afterSaveStarted()
        .afterSaveFailed()
        .afterTap(at(900))
        .afterSaveStarted()
        .afterTap(at(1200))
        .afterSaveFailed();
    expect(policy.dueAt, t0 + SaveTuning.interval);
  });
}

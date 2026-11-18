import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/save_policy.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

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
    expect(policy.dueAt, t0.add(SaveTuning.interval));
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
    expect(next.dueAt, at(5000).add(SaveTuning.interval));
  });

  group('taps that arrive while a save is running', () {
    test('stay pending, with their own interval', () {
      final policy = const SavePolicy.clean()
          .afterTap(t0)
          .afterSaveStarted() // the write began
          .afterTap(at(500)); // tapped while writing
      expect(policy.hasPending, isTrue);
      expect(policy.dueAt, at(500).add(SaveTuning.interval));
    });

    test('a failed save puts the oldest unsaved tap back', () {
      final policy = const SavePolicy.clean()
          .afterTap(t0)
          .afterSaveStarted()
          .afterTap(at(500))
          .afterSaveFailed();
      expect(policy.dueAt, t0.add(SaveTuning.interval));
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
}

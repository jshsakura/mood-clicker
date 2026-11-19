import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_table.dart';
import 'package:mood_clicker/feedback/haptic_cue.dart';
import 'package:mood_clicker/feedback/system_haptics.dart';

void main() {
  late List<HapticStyle> fired;
  late List<Completer<void>> waits;
  late SystemHaptics haptics;

  late Duration now;

  setUp(() {
    fired = [];
    waits = [];
    now = const Duration(seconds: 10);
    SystemHaptics.resetGlobalGapForTest();
    haptics = SystemHaptics(
      fire: (s) async => fired.add(s),
      delay: (d) {
        final c = Completer<void>();
        waits.add(c);
        return c.future.then((_) => now += d);
      },
      clock: () => now,
    );
  });

  HapticCue cue(FeedbackKind k, String mood) =>
      FeedbackTable.of(k, mood).haptic!;

  test('a single step fires at once', () async {
    await haptics.play(cue(FeedbackKind.tap, 'angry'));
    expect(fired, [HapticStyle.heavy]);
    expect(waits, isEmpty);
  });

  test('later steps wait for their delay', () async {
    final done = haptics.play(cue(FeedbackKind.tap, 'excited'));
    await Future<void>.delayed(Duration.zero);
    expect(fired, [HapticStyle.light]);
    waits.single.complete();
    await done;
    expect(fired, [HapticStyle.light, HapticStyle.light]);
  });

  test('a newer cue cancels the steps still waiting', () async {
    final first = haptics.play(cue(FeedbackKind.tap, 'anxious'));
    await Future<void>.delayed(Duration.zero);
    expect(fired, hasLength(1));
    now += const Duration(milliseconds: 45);
    await haptics.play(cue(FeedbackKind.tap, 'angry'));
    waits.first.complete();
    await first;
    expect(fired, [HapticStyle.selection, HapticStyle.heavy]);
  });

  test('a failing platform call does not throw', () async {
    final h = SystemHaptics(
      fire: (_) async => throw StateError('no motor'),
      delay: (_) async {},
      log: (_) {},
    );
    await h.play(cue(FeedbackKind.tap, 'happy'));
  });

  test('enforces a single global minimum gap across requests', () async {
    var now = const Duration(seconds: 10);
    SystemHaptics.resetGlobalGapForTest();
    final a = SystemHaptics(
      fire: (s) async => fired.add(s),
      delay: (_) async {},
      clock: () => now,
    );
    final b = SystemHaptics(
      fire: (s) async => fired.add(s),
      delay: (_) async {},
      clock: () => now,
    );
    await a.play(cue(FeedbackKind.tap, 'happy'));
    now += const Duration(milliseconds: 20);
    await b.play(cue(FeedbackKind.select, 'happy'));
    expect(fired, hasLength(1));
    now += const Duration(milliseconds: 25);
    await b.play(cue(FeedbackKind.select, 'happy'));
    expect(fired, hasLength(2));
  });

  test('cancel stops scheduled next steps', () async {
    final first = haptics.play(cue(FeedbackKind.tap, 'excited'));
    await Future<void>.delayed(Duration.zero);
    expect(fired, hasLength(1));
    haptics.cancel();
    waits.single.complete();
    await first;
    expect(fired, hasLength(1));
  });
}

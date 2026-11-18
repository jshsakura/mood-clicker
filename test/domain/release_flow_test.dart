import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/release_flow.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  final t0 = DateTime(2026, 11, 19, 12);
  DateTime after(Duration d) => t0.add(d);

  group('release', () {
    test('starts in release with nothing approaching and touch free', () {
      final frame = const ReleaseFlow.start().frameAt(t0);
      expect(frame.phase, ReleasePhase.release);
      expect(frame.approaching, isFalse);
      expect(frame.approach, 0);
      expect(frame.touchLocked, isFalse);
    });

    test('below the threshold is not approaching, at it is', () {
      final below = const ReleaseFlow.start().withLevel(0.849, t0);
      final at = const ReleaseFlow.start().withLevel(
        ReleaseTuning.approachAt,
        t0,
      );
      expect(below.frameAt(t0).approaching, isFalse);
      expect(at.frameAt(t0).approaching, isTrue);
      expect(at.frameAt(t0).phase, ReleasePhase.release);
    });

    test('approach grows from 0 at the threshold to 1 just before full', () {
      final mid = const ReleaseFlow.start().withLevel(0.925, t0).frameAt(t0);
      expect(mid.approach, closeTo(0.5, 1e-9));
      final near = const ReleaseFlow.start().withLevel(0.99, t0).frameAt(t0);
      expect(near.approach, closeTo(0.9333, 1e-3));
      expect(near.phase, ReleasePhase.release);
    });
  });

  group('cleanse', () {
    final full = const ReleaseFlow.start().withLevel(1, t0);

    test('starts the moment the level is full and locks touch', () {
      final frame = full.frameAt(t0);
      expect(frame.phase, ReleasePhase.cleanse);
      expect(frame.touchLocked, isTrue);
      expect(frame.cleanse, 0);
    });

    test('progress follows the time and ends at the cleanse length', () {
      final half = full.frameAt(after(ReleaseTuning.cleanse ~/ 2));
      expect(half.phase, ReleasePhase.cleanse);
      expect(half.cleanse, closeTo(0.5, 1e-9));
      final last = full.frameAt(
        after(ReleaseTuning.cleanse - const Duration(milliseconds: 1)),
      );
      expect(last.phase, ReleasePhase.cleanse);
      expect(last.touchLocked, isTrue);
    });

    test('level changes during the cleanse do not stop or restart it', () {
      final moved = full.withLevel(0, after(const Duration(seconds: 1)));
      expect(
        moved.frameAt(after(const Duration(seconds: 1))).phase,
        ReleasePhase.cleanse,
      );
      expect(
        moved.frameAt(after(ReleaseTuning.cleanse)).phase,
        ReleasePhase.settle,
      );
    });

    test('a clock that moves back reads as the start, not a negative time', () {
      final frame = full.frameAt(t0.subtract(const Duration(seconds: 5)));
      expect(frame.cleanse, 0);
      expect(frame.phase, ReleasePhase.cleanse);
    });
  });

  group('settle', () {
    final full = const ReleaseFlow.start().withLevel(1, t0);
    DateTime settleAt(Duration d) => after(ReleaseTuning.cleanse + d);

    test('opens touch right after the cleanse, with the quiet beat first', () {
      final frame = full.frameAt(settleAt(Duration.zero));
      expect(frame.phase, ReleasePhase.settle);
      expect(frame.touchLocked, isFalse);
      expect(frame.cleanse, 1);
      expect(frame.quiet, isTrue);
    });

    test('the quiet beat ends and the breathing starts after stillness', () {
      expect(full.frameAt(settleAt(ReleaseTuning.stillness)).quiet, isFalse);
      expect(
        full
            .frameAt(
              settleAt(
                ReleaseTuning.stillness - const Duration(milliseconds: 1),
              ),
            )
            .quiet,
        isTrue,
      );
    });

    test('the dawn light dissolves over the crossfade and stays dissolved', () {
      expect(full.frameAt(settleAt(Duration.zero)).blend, 0);
      expect(
        full.frameAt(settleAt(ReleaseTuning.crossfade ~/ 2)).blend,
        closeTo(0.5, 1e-9),
      );
      expect(full.frameAt(settleAt(const Duration(minutes: 5))).blend, 1);
    });

    test('the settled time counts from the start of the settle', () {
      expect(
        full.frameAt(settleAt(const Duration(seconds: 4))).settled,
        const Duration(seconds: 4),
      );
      expect(
        full.frameAt(after(const Duration(seconds: 1))).settled,
        Duration.zero,
      );
    });

    test(
      'stays settled while the level is high, and a full level does not restart',
      () {
        final later = settleAt(const Duration(seconds: 10));
        final still = full.withLevel(1, later);
        expect(still.frameAt(later).phase, ReleasePhase.settle);
        final high = full.withLevel(0.85, later);
        expect(high.frameAt(later).phase, ReleasePhase.settle);
      },
    );

    test('returns to release once the level falls below the re-arm line', () {
      final later = settleAt(const Duration(seconds: 10));
      final back = full.withLevel(FillTuning.rearm - 0.01, later);
      final frame = back.frameAt(later);
      expect(frame.phase, ReleasePhase.release);
      expect(frame.touchLocked, isFalse);
      // And a new full level starts a new cleanse.
      final again = back.withLevel(1, later);
      expect(again.frameAt(later).phase, ReleasePhase.cleanse);
    });

    test(
      'a low level during the cleanse is ignored, only the settle may end',
      () {
        final low = full.withLevel(0, after(const Duration(seconds: 1)));
        final early = low.frameAt(after(const Duration(seconds: 2)));
        expect(early.phase, ReleasePhase.cleanse);
      },
    );
  });
}

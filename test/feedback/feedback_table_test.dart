import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/feedback/feedback_table.dart';

void main() {
  group('FeedbackTable completeness', () {
    for (final kind in FeedbackKind.values) {
      for (final mood in feedbackMoodIds) {
        test('defines ${kind.name} for $mood', () {
          expect(FeedbackTable.has(kind, mood), isTrue);
        });
      }
    }

    test('has no entries beyond kind x mood', () {
      expect(
        FeedbackTable.size,
        FeedbackKind.values.length * feedbackMoodIds.length,
      );
    });

    test('uses the five mood ids of the spec', () {
      expect(feedbackMoodIds, ['happy', 'excited', 'angry', 'sad', 'anxious']);
    });
  });

  group('FeedbackTable values', () {
    test('every moods tap has a haptic and a sound of its own', () {
      final sounds = <String>{};
      for (final mood in feedbackMoodIds) {
        final e = FeedbackTable.of(FeedbackKind.tap, mood);
        expect(e.haptic, isNotNull, reason: mood);
        expect(e.soundId, isNotNull, reason: mood);
        sounds.add(e.soundId!);
      }
      expect(sounds.length, feedbackMoodIds.length);
    });

    test('drop is nearly silent: a weak haptic and no sound', () {
      for (final mood in feedbackMoodIds) {
        final e = FeedbackTable.of(FeedbackKind.drop, mood);
        expect(e.soundId, isNull);
        expect(e.haptic, isNotNull);
        expect(e.haptic!.ios.first.intensity, lessThanOrEqualTo(0.3));
      }
    });

    test('platform values stay in range and line up', () {
      for (final kind in FeedbackKind.values) {
        for (final mood in feedbackMoodIds) {
          final h = FeedbackTable.of(kind, mood).haptic;
          if (h == null) continue;
          final where = '${kind.name}/$mood';
          expect(h.steps, isNotEmpty, reason: where);
          expect(h.ios, isNotEmpty, reason: where);
          for (final e in h.ios) {
            expect(e.intensity, inInclusiveRange(0.0, 1.0), reason: where);
            expect(e.sharpness, inInclusiveRange(0.0, 1.0), reason: where);
            expect(e.startMs, greaterThanOrEqualTo(0), reason: where);
          }
          expect(
            h.android.timings.length,
            h.android.amplitudes.length,
            reason: where,
          );
          for (final a in h.android.amplitudes) {
            expect(a, inInclusiveRange(0, 255), reason: where);
          }
        }
      }
    });

    test('anxious trembles with three quick pulses', () {
      final h = FeedbackTable.of(FeedbackKind.tap, 'anxious').haptic!;
      expect(h.steps.length, 3);
      expect(h.ios.length, 3);
    });

    test('unknown mood ids stay silent instead of throwing', () {
      final e = FeedbackTable.of(FeedbackKind.tap, 'nope');
      expect(e.haptic, isNull);
      expect(e.soundId, isNull);
      expect(FeedbackTable.has(FeedbackKind.tap, 'nope'), isFalse);
    });
  });

  group('sound files', () {
    test(
      'every sound id has a file in the basic pack, the cleanse in the pentatonic one',
      () {
        final ids = {
          for (final kind in FeedbackKind.values)
            for (final mood in feedbackMoodIds)
              ?FeedbackTable.of(kind, mood).soundId,
        };
        for (final id in ids) {
          final pack = id == SoundPack.cleanseSoundId ? 'pentatonic' : 'basic';
          final exists = [
            'ogg',
            'wav',
          ].any((ext) => File('assets/sounds/$pack/$id.$ext').existsSync());
          expect(exists, isTrue, reason: id);
        }
      },
    );
  });
}

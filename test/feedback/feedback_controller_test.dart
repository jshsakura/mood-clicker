import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/feedback/feedback_table.dart';
import 'package:mood_clicker/feedback/soloud_sound.dart';

import 'fakes.dart';

/// Deterministic Random returning preset values (0.0 for lowest, near 1.0 for highest pitch).
class _FixedRandom implements Random {
  _FixedRandom(this.values);
  final List<double> values;
  int _i = 0;

  @override
  double nextDouble() => values[_i++ % values.length];

  @override
  bool nextBool() => nextDouble() >= 0.5;

  @override
  int nextInt(int max) => (nextDouble() * max).floor();
}

void main() {
  late FakeHaptics haptics;
  late FakeSound sound;
  late Duration now;

  /// The sounds of these tests are the basic pack's, so the pack is named here and not left to
  /// the default.
  FeedbackController make({
    FeedbackSettings settings = const FeedbackSettings(
      soundPack: SoundPack.basic,
    ),
    Random? random,
  }) {
    return FeedbackController(
      haptics: haptics,
      sound: sound,
      settings: settings,
      clock: () => now,
      random: random ?? Random(1),
    );
  }

  setUp(() {
    haptics = FakeHaptics();
    sound = FakeSound();
    now = const Duration(seconds: 10);
  });

  group('plays what the table says', () {
    test('sends the tables haptic cue and sound id', () {
      make().trigger(FeedbackKind.tap, 'angry');
      final entry = FeedbackTable.of(FeedbackKind.tap, 'angry');
      expect(haptics.played, [entry.haptic]);
      expect(sound.played.single.cue.id, entry.soundId);
      expect(sound.played.single.cue.pack, SoundPack.basic);
    });

    test('uses the chosen sound pack', () {
      make(
        settings: const FeedbackSettings(soundPack: SoundPack.soft),
      ).trigger(FeedbackKind.select, 'happy');
      expect(sound.played.single.cue.pack, SoundPack.soft);
    });

    test('drop gives a haptic and no sound', () {
      make().trigger(FeedbackKind.drop, 'sad');
      expect(haptics.played, hasLength(1));
      expect(sound.played, isEmpty);
    });
  });

  group('haptic throttle', () {
    test('skips a haptic that comes less than 40ms after the last one', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      now += const Duration(milliseconds: 39);
      c.trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(1));
    });

    test('lets a haptic through at exactly 40ms', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      now += const Duration(milliseconds: 40);
      c.trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(2));
    });

    test('measures from the last haptic that played, not the skipped one', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy'); // t=0 plays
      now += const Duration(milliseconds: 30);
      c.trigger(FeedbackKind.tap, 'happy'); // t=30 skipped
      now += const Duration(milliseconds: 15);
      c.trigger(FeedbackKind.tap, 'happy'); // t=45 plays
      expect(haptics.played, hasLength(2));
    });

    test('still plays the sound when the haptic is skipped', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      c.trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(1));
      expect(sound.played, hasLength(2));
    });

    test('a kind with no haptic does not start the clock', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'unknown');
      c.trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(1));
    });
  });

  group('settings', () {
    test('haptics off mutes only the haptic', () {
      make(
        settings: const FeedbackSettings(hapticsOn: false),
      ).trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, isEmpty);
      expect(sound.played, hasLength(1));
    });

    test('sound off mutes only the sound', () {
      make(
        settings: const FeedbackSettings(soundOn: false),
      ).trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(1));
      expect(sound.played, isEmpty);
    });

    test('new settings apply to the next trigger', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      now += const Duration(seconds: 1);
      c.settings = c.settings.copyWith(hapticsOn: false, soundOn: false);
      c.trigger(FeedbackKind.tap, 'happy');
      expect(haptics.played, hasLength(1));
      expect(sound.played, hasLength(1));
    });
  });

  group('pitch jitter', () {
    test('stays within 3 percent of the original pitch', () {
      final c = make(random: Random(7));
      for (var i = 0; i < 500; i++) {
        now += const Duration(milliseconds: 50);
        c.trigger(FeedbackKind.tap, 'happy');
      }
      for (final p in sound.played) {
        expect(p.pitch, inInclusiveRange(0.97, 1.03));
      }
    });

    test('reaches both ends of the range', () {
      make(random: _FixedRandom([0.0, 0.999999]))
        ..trigger(FeedbackKind.tap, 'happy')
        ..trigger(FeedbackKind.tap, 'happy');
      expect(sound.played[0].pitch, closeTo(0.97, 1e-9));
      expect(sound.played[1].pitch, closeTo(1.03, 1e-4));
    });

    test('is not the same every time', () {
      final c = make(random: Random(3));
      for (var i = 0; i < 20; i++) {
        c.trigger(FeedbackKind.tap, 'happy');
      }
      expect(sound.played.map((p) => p.pitch).toSet().length, greaterThan(10));
    });
  });

  group('priority and cancel', () {
    test('full haptic wins when tap and full arrive at the same moment', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      c.trigger(FeedbackKind.full, 'happy');
      expect(
        haptics.played.last,
        FeedbackTable.of(FeedbackKind.full, 'happy').haptic,
      );
    });

    test('haptics off cancels scheduled next haptic step', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'excited');
      c.settings = c.settings.copyWith(hapticsOn: false);
      expect(haptics.cancelCount, 1);
    });

    test('uses FeedbackTuning.minHapticGap for global throttle', () {
      expect(minHapticGap, FeedbackTuning.minHapticGap);
    });

    test('tap scales haptic intensity and sharpness with fill', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy', fill: 0.0);
      now += const Duration(milliseconds: 50);
      c.trigger(FeedbackKind.tap, 'happy', fill: 1.0);
      expect(
        haptics.played[0].ios.first.intensity,
        lessThan(haptics.played[1].ios.first.intensity),
      );
    });

    test('rare haptic plays with priority even right after tap', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      c.trigger(FeedbackKind.rare, 'happy');
      expect(
        haptics.played.last,
        FeedbackTable.of(FeedbackKind.rare, 'happy').haptic,
      );
    });
  });

  group('audio session and sound packs', () {
    test('iOS audio session uses ambient without explicit mixWithOthers', () {
      expect(
        SoloudSound.audioSessionConfig.avAudioSessionCategory,
        AVAudioSessionCategory.ambient,
      );
      expect(
        SoloudSound.audioSessionConfig.avAudioSessionCategoryOptions,
        isNull,
      );
    });

    test('soft pack is hidden from available packs until files exist', () {
      expect(SoundPack.available, [SoundPack.basic, SoundPack.pentatonic]);
      expect(SoundPack.available, isNot(contains(SoundPack.soft)));
    });
  });

  group('failures never reach the caller', () {
    test('a haptic port that throws does not stop the sound', () {
      final c = FeedbackController(
        haptics: _ThrowingHaptics(),
        sound: sound,
        clock: () => now,
        random: Random(1),
        log: (_) {},
      );
      expect(() => c.trigger(FeedbackKind.tap, 'happy'), returnsNormally);
      expect(sound.played, hasLength(1));
    });
  });
}

class _ThrowingHaptics extends FakeHaptics {
  @override
  Future<void> play(cue, {bool priority = false}) =>
      throw StateError('no motor');
}

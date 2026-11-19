import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/feedback/tap_pitch.dart';
import 'package:mood_clicker/feedback/voice_limiter.dart';

import 'fakes.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  group('the rule of each mood', () {
    test('happy and excited climb, the heavy moods get a small mistake', () {
      expect(tapPitchRuleOf('happy'), TapPitchRule.rise);
      expect(tapPitchRuleOf('excited'), TapPitchRule.rise);
      for (final mood in ['angry', 'sad', 'anxious']) {
        expect(tapPitchRuleOf(mood), TapPitchRule.microRandom, reason: mood);
      }
    });

    test('every mood has a rule and an unknown one climbs', () {
      for (final mood in feedbackMoodIdsForTest) {
        expect(tapPitchRuleByMood, contains(mood));
      }
      expect(tapPitchRuleOf('unknown'), TapPitchRule.rise);
    });
  });

  group('the rising run', () {
    test('taps 1 to 7 follow the table and then start over', () {
      final run = TapPitchRun(random: Random(1));
      final got = [
        for (var i = 0; i < 7; i++)
          run.next(TapPitchRule.rise, ms(i * 100)).pitch,
      ];
      expect(got, [
        ...FeedbackTuning.risePitches,
        FeedbackTuning.risePitches.first,
      ]);
      expect(got.sublist(0, 6), [1.0, 1.122, 1.260, 1.498, 1.682, 2.0]);
    });

    test('a rest of more than 0.8 seconds starts a new run', () {
      final run = TapPitchRun();
      run.next(TapPitchRule.rise, ms(0));
      run.next(TapPitchRule.rise, ms(100));
      expect(run.next(TapPitchRule.rise, ms(200)).pitch, 1.260);
      expect(run.next(TapPitchRule.rise, ms(200 + 801)).pitch, 1.0);
    });

    test('a rest of exactly 0.8 seconds goes on climbing', () {
      final run = TapPitchRun();
      run.next(TapPitchRule.rise, ms(0));
      expect(run.next(TapPitchRule.rise, ms(800)).pitch, 1.122);
    });

    test('the rise keeps the full volume', () {
      final run = TapPitchRun();
      expect(run.next(TapPitchRule.rise, ms(0)).volume, 1.0);
    });
  });

  group('the micro random rule', () {
    test('stays inside the ranges for a thousand taps', () {
      final run = TapPitchRun(random: Random(7));
      var low = 9.0;
      var high = 0.0;
      for (var i = 0; i < 1000; i++) {
        final voice = run.next(TapPitchRule.microRandom, ms(i));
        expect(
          voice.pitch,
          inInclusiveRange(
            FeedbackTuning.microPitchMin,
            FeedbackTuning.microPitchMax,
          ),
        );
        expect(
          voice.volume,
          inInclusiveRange(
            FeedbackTuning.microVolumeMin,
            FeedbackTuning.microVolumeMax,
          ),
        );
        low = min(low, voice.pitch);
        high = max(high, voice.pitch);
      }
      expect(low, lessThan(0.95));
      expect(high, greaterThan(1.05));
    });

    test('the same seed gives the same taps', () {
      List<TapVoice> take() {
        final run = TapPitchRun(random: Random(42));
        return [
          for (var i = 0; i < 5; i++) run.next(TapPitchRule.microRandom, ms(i)),
        ];
      }

      expect(take(), take());
    });
  });

  group('the pentatonic pack in the controller', () {
    late FakeHaptics haptics;
    late FakeSound sound;
    var now = Duration.zero;

    FeedbackController make() {
      now = Duration.zero;
      haptics = FakeHaptics();
      sound = FakeSound();
      return FeedbackController(
        haptics: haptics,
        sound: sound,
        settings: const FeedbackSettings(soundPack: SoundPack.pentatonic),
        clock: () => now,
        random: Random(3),
      );
    }

    test('every mood plays the one kalimba note', () {
      final c = make();
      for (final mood in feedbackMoodIdsForTest) {
        c.trigger(FeedbackKind.tap, mood);
      }
      expect(sound.played.map((p) => p.cue.id).toSet(), {'kalimba'});
      expect(sound.played.map((p) => p.cue.pack).toSet(), {
        SoundPack.pentatonic,
      });
    });

    test('a happy burst climbs and an angry one does not', () {
      final c = make();
      for (var i = 0; i < 4; i++) {
        now = ms(i * 100);
        c.trigger(FeedbackKind.tap, 'happy');
      }
      expect(sound.played.map((p) => p.pitch), [1.0, 1.122, 1.260, 1.498]);
      sound.played.clear();
      for (var i = 0; i < 20; i++) {
        now = ms(1000 + i * 100);
        c.trigger(FeedbackKind.tap, 'angry');
      }
      for (final p in sound.played) {
        expect(p.pitch, inInclusiveRange(0.94, 1.06));
        expect(p.volume, inInclusiveRange(0.85, 1.0));
      }
      expect(sound.played.map((p) => p.pitch).toSet().length, greaterThan(10));
    });

    test('taps ask for the voice limit and the full sound falls back', () {
      final c = make();
      c.trigger(FeedbackKind.tap, 'happy');
      c.trigger(FeedbackKind.full, 'happy');
      expect(sound.played[0].limited, isTrue);
      expect(sound.played[1].limited, isFalse);
      expect(sound.played[1].cue.pack, SoundPack.pentatonic);
    });

    test('sound off or haptics off still follow their settings', () {
      final c = make();
      c.settings = const FeedbackSettings(
        soundPack: SoundPack.pentatonic,
        soundOn: false,
        hapticsOn: false,
      );
      c.trigger(FeedbackKind.tap, 'happy');
      expect(sound.played, isEmpty);
      expect(haptics.played, isEmpty);
    });

    test('the basic pack keeps its own sounds and its jitter', () {
      final c = make();
      c.settings = const FeedbackSettings(soundPack: SoundPack.basic);
      c.trigger(FeedbackKind.tap, 'happy');
      expect(sound.played.single.cue.id, isNot('kalimba'));
      expect(sound.played.single.pitch, inInclusiveRange(0.97, 1.03));
      expect(sound.played.single.limited, isTrue);
    });
  });

  group('the release flow in the controller', () {
    late FakeHaptics haptics;
    late FakeSound sound;
    late FeedbackController controller;

    setUp(() {
      haptics = FakeHaptics();
      sound = FakeSound();
      controller = FeedbackController(
        haptics: haptics,
        sound: sound,
        settings: const FeedbackSettings(soundPack: SoundPack.basic),
        clock: () => Duration.zero,
        random: Random(2),
      );
    });

    test('the cleanse plays the pentatonic cleansing sound in any pack', () {
      controller.trigger(FeedbackKind.cleanse, 'angry');
      expect(sound.played.single.cue.pack, SoundPack.pentatonic);
      expect(sound.played.single.cue.id, SoundPack.cleanseSoundId);
      expect(sound.played.single.limited, isFalse);
    });

    test('the ease scales the tap haptic and clamps to 0 to 1', () {
      controller.trigger(FeedbackKind.tap, 'angry');
      controller.hapticEase = 0.5;
      controller.trigger(FeedbackKind.tap, 'angry');
      expect(haptics.played, hasLength(1));
      expect(controller.hapticEase, 0.5);
      controller.hapticEase = 7;
      expect(controller.hapticEase, 1.0);
      controller.hapticEase = -1;
      expect(controller.hapticEase, 0.0);
    });

    test('settled swaps the heavy mood to the climbing kalimba', () {
      controller.settled = true;
      for (var i = 0; i < 3; i++) {
        controller.trigger(FeedbackKind.tap, 'angry');
      }
      expect(sound.played.map((p) => p.cue.id), everyElement('kalimba'));
      expect(
        sound.played.map((p) => p.cue.pack),
        everyElement(SoundPack.pentatonic),
      );
      expect(sound.played.map((p) => p.pitch), [1.0, 1.122, 1.260]);
    });
  });

  group('the cap of ringing voices', () {
    test('a sixth sound fades the oldest one out', () {
      final cut = <int>[];
      final limiter = VoiceLimiter<int>(
        max: FeedbackTuning.maxTapVoices,
        isAlive: (_) => true,
        fadeOut: cut.add,
      );
      for (var voice = 1; voice <= 5; voice++) {
        limiter.admit(voice);
      }
      expect(cut, isEmpty);
      limiter.admit(6);
      expect(cut, [1]);
      limiter.admit(7);
      expect(cut, [1, 2]);
    });

    test('voices that ended on their own do not count', () {
      final ended = <int>{};
      final cut = <int>[];
      final limiter = VoiceLimiter<int>(
        max: 5,
        isAlive: (v) => !ended.contains(v),
        fadeOut: cut.add,
      );
      for (var voice = 1; voice <= 5; voice++) {
        limiter.admit(voice);
      }
      ended.addAll([1, 2]);
      limiter.admit(6);
      expect(cut, isEmpty);
    });

    test('ten taps a second for two seconds never hold more than five', () {
      final ringing = <int>[];
      final limiter = VoiceLimiter<int>(
        max: FeedbackTuning.maxTapVoices,
        isAlive: ringing.contains,
        fadeOut: ringing.remove,
      );
      for (var i = 0; i < 20; i++) {
        ringing.add(i);
        limiter.admit(i);
        expect(ringing.length, lessThanOrEqualTo(5));
      }
    });

    test('the cap is inside the range the owner asked for', () {
      expect(FeedbackTuning.maxTapVoices, inInclusiveRange(4, 6));
      expect(FeedbackTuning.voiceFade, ms(20));
    });
  });
}

const feedbackMoodIdsForTest = ['happy', 'excited', 'angry', 'sad', 'anxious'];

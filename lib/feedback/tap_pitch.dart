import 'dart:math';

import '../domain/tuning.dart';

/// How the tap sound of a mood changes from one tap to the next.
enum TapPitchRule {
  /// Each tap of a run is one step higher up the pentatonic scale, so a burst sounds like a
  /// tune climbing.
  rise,

  /// Each tap gets a small random speed and volume.
  microRandom,
}

/// The rule of each mood, by mood id. Moods that are not listed use [TapPitchRule.rise].
const Map<String, TapPitchRule> tapPitchRuleByMood = {
  'happy': TapPitchRule.rise,
  'excited': TapPitchRule.rise,
  'angry': TapPitchRule.microRandom,
  'sad': TapPitchRule.microRandom,
  'anxious': TapPitchRule.microRandom,
};

TapPitchRule tapPitchRuleOf(String moodId) =>
    tapPitchRuleByMood[moodId] ?? TapPitchRule.rise;

/// The speed and volume of one tap sound.
typedef TapVoice = ({double pitch, double volume});

/// Follows a run of taps and hands out the [TapVoice] of the next one.
class TapPitchRun {
  TapPitchRun({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _step = 0;
  Duration? _last;

  /// The voice of a tap at [now] under [rule].
  TapVoice next(TapPitchRule rule, Duration now) {
    switch (rule) {
      case TapPitchRule.rise:
        final last = _last;
        if (last == null || now - last > FeedbackTuning.riseReset) _step = 0;
        _last = now;
        final pitch = FeedbackTuning.risePitches[_step];
        _step = (_step + 1) % FeedbackTuning.risePitches.length;
        return (pitch: pitch, volume: 1.0);
      case TapPitchRule.microRandom:
        _step = 0;
        _last = null;
        return (
          pitch: _between(
            FeedbackTuning.microPitchMin,
            FeedbackTuning.microPitchMax,
          ),
          volume: _between(
            FeedbackTuning.microVolumeMin,
            FeedbackTuning.microVolumeMax,
          ),
        );
    }
  }

  double _between(double low, double high) =>
      low + _random.nextDouble() * (high - low);
}

import 'package:mood_clicker/feedback/haptic_cue.dart';
import 'package:mood_clicker/feedback/ports.dart';

class FakeHaptics implements HapticsPort {
  final List<HapticCue> played = [];
  int cancelCount = 0;

  @override
  Future<void> play(HapticCue cue, {bool priority = false}) async =>
      played.add(cue);

  @override
  void cancel() => cancelCount++;
}

class PlayedSound {
  const PlayedSound(
    this.cue,
    this.pitch, {
    this.volume = 1.0,
    this.limited = false,
  });
  final SoundCue cue;
  final double pitch;
  final double volume;
  final bool limited;
}

class FakeSound implements SoundPort {
  final List<PlayedSound> played = [];

  @override
  Future<void> play(
    SoundCue cue, {
    double pitch = 1.0,
    double volume = 1.0,
    bool limitVoices = false,
  }) async =>
      played.add(PlayedSound(cue, pitch, volume: volume, limited: limitVoices));
}

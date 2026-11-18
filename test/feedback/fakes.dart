import 'package:mood_clicker/feedback/haptic_cue.dart';
import 'package:mood_clicker/feedback/ports.dart';

class FakeHaptics implements HapticsPort {
  final List<HapticCue> played = [];

  @override
  Future<void> play(HapticCue cue) async => played.add(cue);
}

class PlayedSound {
  const PlayedSound(this.cue, this.pitch);
  final SoundCue cue;
  final double pitch;
}

class FakeSound implements SoundPort {
  final List<PlayedSound> played = [];

  @override
  Future<void> play(SoundCue cue, {double pitch = 1.0}) async =>
      played.add(PlayedSound(cue, pitch));
}

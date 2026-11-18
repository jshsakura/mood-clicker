import 'feedback_settings.dart';
import 'haptic_cue.dart';

/// A sound cue resolved to `assets/sounds/<pack>/<id>.ogg` or `.wav`.
class SoundCue {
  const SoundCue(this.pack, this.id);

  final SoundPack pack;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is SoundCue && other.pack == pack && other.id == id;

  @override
  int get hashCode => Object.hash(pack, id);

  @override
  String toString() => 'SoundCue(${pack.name}/$id)';
}

abstract interface class HapticsPort {
  Future<void> play(HapticCue cue, {bool priority = false});
  void cancel();
}

abstract interface class SoundPort {
  /// [pitch] defaults to 1.0 (original pitch) and [volume] to full. A sound with [limitVoices]
  /// counts against the cap of ringing tap sounds: past it the oldest one fades out.
  Future<void> play(
    SoundCue cue, {
    double pitch = 1.0,
    double volume = 1.0,
    bool limitVoices = false,
  });
}

import 'feedback_settings.dart';
import 'haptic_cue.dart';

/// 소리 하나. 묶음과 id 로 파일이 정해진다: `assets/sounds/<묶음>/<id>.ogg` 또는 `.wav`
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
  Future<void> play(HapticCue cue);
}

abstract interface class SoundPort {
  /// [pitch] 는 1.0 이 원래 음 높이다.
  Future<void> play(SoundCue cue, {double pitch = 1.0});
}

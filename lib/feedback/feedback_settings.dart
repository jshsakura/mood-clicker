/// 소리 묶음. 파일은 assets/sounds/<이름>/ 아래에 둔다.
enum SoundPack { basic, soft }

class FeedbackSettings {
  const FeedbackSettings({
    this.hapticsOn = true,
    this.soundOn = true,
    this.soundPack = SoundPack.basic,
  });

  final bool hapticsOn;
  final bool soundOn;
  final SoundPack soundPack;

  FeedbackSettings copyWith({
    bool? hapticsOn,
    bool? soundOn,
    SoundPack? soundPack,
  }) {
    return FeedbackSettings(
      hapticsOn: hapticsOn ?? this.hapticsOn,
      soundOn: soundOn ?? this.soundOn,
      soundPack: soundPack ?? this.soundPack,
    );
  }
}

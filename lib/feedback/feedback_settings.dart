/// Sound pack selection. Audio files live under `assets/sounds/<pack>/`.
enum SoundPack {
  basic,
  soft,

  /// One kalimba note that the tap sound moves up and down the pentatonic scale.
  pentatonic;

  /// The pack until the person picks another.
  static const SoundPack defaultPack = SoundPack.pentatonic;

  /// Packs with bundled audio files ready to show in Settings.
  static const List<SoundPack> available = [
    SoundPack.basic,
    SoundPack.pentatonic,
  ];

  /// The sound id of every tap in this pack, or null when the pack has one sound per cue.
  /// The cleansing sound lives in the pentatonic pack, so it plays whatever pack is chosen.
  static const String cleanseSoundId = 'cleanse';

  /// The short chord of the hold reward. It lives in the pentatonic pack too.
  static const String holdSoundId = 'chime';

  String? get tapSoundId => this == pentatonic ? 'kalimba' : null;
}

class FeedbackSettings {
  const FeedbackSettings({
    this.hapticsOn = true,
    this.soundOn = true,
    this.soundPack = SoundPack.defaultPack,
    this.hapticScale = 1,
  });

  /// How strong the haptics are, 1 being the cue as designed.
  final double hapticScale;
  final bool hapticsOn;
  final bool soundOn;
  final SoundPack soundPack;

  FeedbackSettings copyWith({
    bool? hapticsOn,
    bool? soundOn,
    SoundPack? soundPack,
    double? hapticScale,
  }) {
    return FeedbackSettings(
      hapticsOn: hapticsOn ?? this.hapticsOn,
      soundOn: soundOn ?? this.soundOn,
      soundPack: soundPack ?? this.soundPack,
      hapticScale: hapticScale ?? this.hapticScale,
    );
  }
}

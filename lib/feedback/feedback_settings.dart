/// Sound pack selection. Audio files live under `assets/sounds/<pack>/`.
enum SoundPack {
  basic,
  soft;

  /// Packs with bundled audio files ready to show in Settings.
  static const List<SoundPack> available = [SoundPack.basic];
}

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

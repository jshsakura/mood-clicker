import 'tuning.dart';

/// The settings that turn the hand-feel effects on and off. Immutable.
/// The tap screen reads these; the settings screen changes them.
class FeelSettings {
  const FeelSettings({
    this.screenShake = true,
    this.cheerPhrases = true,
    this.largeText = false,
    this.tiltSpill = true,
  });

  /// The screen shakes when the gauge becomes full.
  final bool screenShake;

  /// Cheer phrases pop up where the user taps.
  final bool cheerPhrases;

  /// Text is [FillTuning.largeTextScale] times bigger.
  final bool largeText;

  /// Tilting the phone tilts the water and can spill it.
  final bool tiltSpill;

  double get textScale => largeText ? FillTuning.largeTextScale : 1;

  FeelSettings copyWith({
    bool? screenShake,
    bool? cheerPhrases,
    bool? largeText,
    bool? tiltSpill,
  }) => FeelSettings(
    screenShake: screenShake ?? this.screenShake,
    cheerPhrases: cheerPhrases ?? this.cheerPhrases,
    largeText: largeText ?? this.largeText,
    tiltSpill: tiltSpill ?? this.tiltSpill,
  );

  Map<String, Object?> toJson() => {
    'screenShake': screenShake,
    'cheerPhrases': cheerPhrases,
    'largeText': largeText,
    'tiltSpill': tiltSpill,
  };

  /// Never throws. A missing or wrongly typed value keeps its default.
  factory FeelSettings.fromJson(Object? raw) {
    if (raw is! Map) return const FeelSettings();
    bool read(String key, bool fallback) {
      final value = raw[key];
      return value is bool ? value : fallback;
    }

    const defaults = FeelSettings();
    return FeelSettings(
      screenShake: read('screenShake', defaults.screenShake),
      cheerPhrases: read('cheerPhrases', defaults.cheerPhrases),
      largeText: read('largeText', defaults.largeText),
      tiltSpill: read('tiltSpill', defaults.tiltSpill),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeelSettings &&
      other.screenShake == screenShake &&
      other.cheerPhrases == cheerPhrases &&
      other.largeText == largeText &&
      other.tiltSpill == tiltSpill;

  @override
  int get hashCode =>
      Object.hash(screenShake, cheerPhrases, largeText, tiltSpill);
}

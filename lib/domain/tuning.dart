/// Numbers for the fill gauge. Judge the feel on a real device and adjust only here.
abstract final class GaugeTuning {
  /// How much one tap raises the level.
  static const double stepPerTap = 0.025;

  /// How long the level holds after the last tap.
  static const Duration grace = Duration(milliseconds: 300);

  /// How much the level falls per second once the grace time is over.
  static const double decayPerSecond = 0.2;

  /// How long the on-screen gauge takes to catch up with the real level (exponential smoothing).
  /// For display only: the domain never uses it, and the screen does the smoothing.
  static const Duration displayFollow = Duration(milliseconds: 220);
}

/// Numbers for save batching.
abstract final class SaveTuning {
  /// How often to write to disk while the user keeps tapping.
  static const Duration interval = Duration(seconds: 2);
}

/// Numbers for the cheer phrases that pop up where the user taps. The screen draws them;
/// the domain picks the phrase and decides whether a spot is free.
abstract final class CheerTuning {
  /// How long one phrase stays on screen.
  static const Duration lifetime = Duration(milliseconds: 800);

  /// When a new phrase appears, the previous one keeps this share of its lifetime,
  /// and the one before that keeps [olderLifetimeShare].
  static const double previousLifetimeShare = 0.6;
  static const double olderLifetimeShare = 0.35;

  /// Font size per gauge stage.
  static const double fontSizeLow = 38;
  static const double fontSizeHigh = 44;
  static const double fontSizeFull = 52;

  /// Phrase box: width = characters * size * [widthPerSize] + [boxPadding],
  /// height = size * [heightPerSize]. The box is where the phrase is drawn now.
  static const double widthPerSize = 0.95;
  static const double boxPadding = 12;
  static const double heightPerSize = 1.2;

  /// How far a phrase floats up over its lifetime. A visible phrase blocks the spot it is at
  /// now, so the rise is applied to its box as it goes, not reserved in advance.
  static const double riseDistance = 46;

  /// A phrase blocks other phrases only while it is in the first this share of its lifetime.
  static const double blockingShare = 0.7;

  /// Every tap shows a phrase. If the tap spot is taken, the nearest free spot on a grid is used:
  /// [spotStepX] left and right, [spotStepY] up and down, 5 columns by 9 rows = 45 spots.
  static const double spotStepX = 100;
  static const double spotStepY = 70;
  static const int spotColumns = 5;
  static const int spotRows = 9;

  /// Phrases are dealt from a shuffled deck. When a deck runs out, the next one is shuffled so
  /// that the last this many phrases of the old deck stay out of the first this many of the new
  /// one. For a small bundle the number is half of its size.
  static const int deckTailSize = 50;

  /// A phrase file larger than this is refused (bytes).
  static const int maxFileBytes = 1024 * 1024;

  /// Longer phrases get a warning when a phrase file is loaded.
  static const int maxPhraseLength = 12;
}

/// Numbers for haptic and sound feedback.
abstract final class FeedbackTuning {
  /// Minimum interval between actual platform haptic calls across all requests.
  static const Duration minHapticGap = Duration(milliseconds: 40);

  /// Pitch jitter range around the original pitch (1.0 +/- this value).
  static const double pitchJitter = 0.03;
}

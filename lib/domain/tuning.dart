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

  /// At most this many phrases are visible at once.
  static const int maxVisible = 8;

  /// When a new phrase appears, the previous one keeps this share of its lifetime,
  /// and the one before that keeps [olderLifetimeShare].
  static const double previousLifetimeShare = 0.6;
  static const double olderLifetimeShare = 0.35;

  /// Font size per gauge stage.
  static const double fontSizeLow = 38;
  static const double fontSizeHigh = 44;
  static const double fontSizeFull = 52;

  /// Phrase box: width = characters * size * [widthPerSize] + [boxPadding],
  /// height = size * [heightPerSize]. The box also covers the [riseDistance] the phrase
  /// floats up, so a rising phrase still blocks its own track.
  static const double widthPerSize = 0.95;
  static const double boxPadding = 16;
  static const double heightPerSize = 1.25;
  static const double riseDistance = 46;

  /// The full-gauge phrase looks for a free spot on a grid around the tap:
  /// [spotStepX] left and right, [spotStepY] up and down, 3 columns by 5 rows = 15 spots.
  static const double spotStepX = 120;
  static const double spotStepY = 90;
  static const int spotColumns = 3;
  static const int spotRows = 5;

  /// A phrase shown within the last this many picks is not picked again.
  static const int recentWindow = 8;

  /// A bundle this small or smaller only avoids the phrase picked just before.
  static const int smallBundle = 8;

  /// Longer phrases get a warning when a phrase file is loaded.
  static const int maxPhraseLength = 12;
}

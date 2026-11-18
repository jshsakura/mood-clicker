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
  /// How long one ordinary phrase stays on screen. The complete and rare phrases stay longer.
  static const Duration lifetime = Duration(milliseconds: 950);
  static const Duration completeLifetime = Duration(milliseconds: 1700);
  static const Duration rareLifetime = Duration(milliseconds: 1400);

  /// When a new phrase appears, the previous one keeps this share of its lifetime,
  /// and the one before that keeps [olderLifetimeShare].
  static const double previousLifetimeShare = 0.85;
  static const double olderLifetimeShare = 0.7;

  /// Font size grows with the fill: base + level * perFill. The complete phrase has its own size.
  /// A phrase is shrunk until it fits in [maxWidthShare] of the screen width.
  static const double fontSizeBase = 30;
  static const double fontSizePerFill = 30;
  static const double fontSizeComplete = 76;
  static const double maxWidthShare = 0.6;

  /// A tap this far or less from the screen center may show its phrase on either side. A tap
  /// farther out shows it only on its own side.
  static const double sideDeadZone = 60;

  /// The chance that a phrase is a rare one. The screen draws it as a black pill with white text,
  /// five stars above and eight short lines turning slowly. Flat shapes, no glow.
  static const double rareChance = 0.025;
  static const int rareStars = 5;
  static const int rareRays = 8;

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
/// Numbers for the water. The screen runs the spring and draws it; the domain only keeps the
/// numbers in one place.
abstract final class FillTuning {
  /// The surface is this many columns of springs.
  static const int columns = 40;
  static const double spring = 8;
  static const double spread = 900;
  static const double damping = 1.6;

  /// A tap pushes the columns around it, with a gaussian of a random width in this range
  /// (in columns). Tapping inside the water makes it rise, tapping above it presses it down.
  static const double kick = 260;
  static const double kickWidthMin = 1.6;
  static const double kickWidthMax = 3;

  /// A tap also sloshes the water toward the side opposite to where it was pressed.
  static const double slosh = 70;

  /// While nothing is touched, a small random wobble comes this often.
  static const Duration idleWobble = Duration(milliseconds: 500);

  /// The surface tilts with the phone. Past this angle the water spills.
  static const double tiltLimitRadians = 0.5;

  /// Spill rate per radian beyond the limit, as fill level per second.
  static const double spillPerRadianPerSecond = 1.5;
}

/// Numbers for the moment the gauge becomes full.
abstract final class CompleteTuning {
  static const Duration shakeDuration = Duration(milliseconds: 420);
  static const double shakeAmplitude = 9;

  /// The stamp starts this many times its size and lands within [stampLand].
  static const double stampStartScale = 2.6;
  static const Duration stampLand = Duration(milliseconds: 160);
  static const Duration stampHold = Duration(milliseconds: 1900);
  static const Duration stampFade = Duration(milliseconds: 500);

  /// The water is struck this many times harder than an ordinary tap.
  static const double waterKickScale = 2.2;
}

abstract final class FeedbackTuning {
  /// Minimum interval between actual platform haptic calls across all requests.
  static const Duration minHapticGap = Duration(milliseconds: 40);

  /// Pitch jitter range around the original pitch (1.0 +/- this value).
  static const double pitchJitter = 0.03;
}

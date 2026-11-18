/// Numbers for the fill gauge. Judge the feel on a real device and adjust only here.
abstract final class GaugeTuning {
  /// How much one tap raises the level.
  static const double stepPerTap = 1 / 60;

  /// How long the level holds after the last tap.
  static const Duration grace = Duration(seconds: 1);

  /// How much the level falls per second once the grace time is over.
  static const double decayPerSecond = 0.07;

  /// How long the on-screen gauge takes to catch up with the real level (exponential smoothing).
  /// For display only: the domain never uses it, and the screen does the smoothing.
  static const Duration displayFollow = Duration(milliseconds: 420);
}

/// Limits for the note of the day.
abstract final class NoteTuning {
  /// The longest note, counted in characters as a person sees them.
  static const int maxLength = 40;

  /// A preset id is lowercase letters, digits and underscores, at most this long.
  static const int maxPresetIdLength = 32;
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

  /// Font size of an ordinary phrase: base + level^exponent * span. About 18 at the start, 35 at
  /// half, 60 when nearly full. A rare phrase is [fontSizeRareBonus] bigger and the complete
  /// phrase has its own size. A phrase is shrunk until it fits in [maxWidthShare] of the width.
  static const double fontSizeBase = 18;
  static const double fontSizeSpan = 42;
  static const double fontSizeExponent = 1.3;
  static const double fontSizeRareBonus = 6;
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

  /// A base sentence does not come again within the last this many bases shown (across moods
  /// and stages). For a bundle with fewer bases the window is half of them.
  static const int recentBases = 60;

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
  static const int columns = 60;
  static const double spring = 8;
  static const double spread = 1800;
  static const double damping = 1.1;

  /// A tap pushes the columns around it, with a gaussian of a random width in this range
  /// (in columns). Tapping inside the water makes it rise, tapping above it presses it down.
  static const double kick = 260;
  static const double kickWidthMin = 2.4;
  static const double kickWidthMax = 4.4;

  /// A tap also sloshes the water toward the side opposite to where it was pressed.
  static const double slosh = 70;

  /// While nothing is touched, a small random wobble comes this often.
  static const Duration idleWobble = Duration(milliseconds: 500);

  /// One more wave behind the front one: it copies the front wave shifted by [backShiftColumns],
  /// scaled by [backScale], [backDelay] late, drawn [backRise] px higher in the surface color.
  /// The curve is smoothed with Catmull-Rom splines.
  static const int backShiftColumns = 3;
  static const double backScale = 0.75;
  static const Duration backDelay = Duration(milliseconds: 200);
  static const double backRise = 5;

  /// A tap within [dropletReach] px of the surface throws [dropletsMin] to [dropletsMax] droplets
  /// (twice as many when the gauge becomes full), at most [dropletsLimit] at once.
  static const double dropletReach = 220;
  static const int dropletsMin = 2;
  static const int dropletsMax = 5;
  static const int dropletsWhenComplete = 2; // multiplier
  static const int dropletsLimit = 40;

  /// A droplet leaves going up at [dropletUpMin] to [dropletUpMax] px/s, sideways by up to
  /// +-[dropletSide] px/s, with a radius of [dropletRadiusMin] to [dropletRadiusMax] px, and then
  /// falls under [dropletGravity] px/s^2.
  static const double dropletUpMin = 220;
  static const double dropletUpMax = 500;
  static const double dropletSide = 90;
  static const double dropletRadiusMin = 2;
  static const double dropletRadiusMax = 5;
  static const double dropletGravity = 1400;

  /// A droplet that lands on the water makes a small wave in that column of strength
  /// [splashBase] + radius * [splashPerRadius].
  static const double splashBase = 30;
  static const double splashPerRadius = 8;

  /// The phone can tilt the surface up to this far either way.
  static const double tiltLimitDegrees = 85;

  /// While the level is falling, the surface ripples: each frame, for the height lost in px (at
  /// most [drainMaxPx]), [drainColumns] random columns are pushed by
  /// (random - 0.5) * lostPx * [drainJiggle]. If the phone is tilted, the water also leans toward
  /// the low side by lostPx * [drainTiltPull].
  static const double drainMaxPx = 6;
  static const int drainColumns = 3;
  static const double drainJiggle = 160;
  static const double drainTiltPull = 14;

  /// The slope of the surface is tan(tilt) with the tilt limited to this many radians.
  static const double slopeLimitRadians = 1.48;

  /// The surface is measured at this many places across the width when the water area is
  /// worked out.
  static const int areaSamples = 40;

  /// Water spills like out of a cup. A tilted cup holds less: the most it can hold is the water
  /// area when the high edge just touches the top of the screen. Only the part of the level over
  /// that capacity spills. Every second it spills [spillRate] times the excess, at least
  /// [pourMin] of the level, and never more than the excess itself.
  static const double spillRate = 1.2;
  static const double pourMin = 0.08;

  /// A full gauge shakes the screen and shows the big phrase once. It can do that again only
  /// after the level has fallen below this.
  static const double rearm = 0.8;

  /// A tap on a gauge that is already full pushes the water this much of the usual strength.
  static const double fullKick = 0.3;

  /// Settings that can turn the effects off, and the larger text scale.
  static const double largeTextScale = 1.18;
}

/// Numbers for the moment the gauge becomes full. There is no stamp on the tap screen.
abstract final class CompleteTuning {
  static const Duration shakeDuration = Duration(milliseconds: 420);
  static const double shakeAmplitude = 9;

  /// The water is struck this many times harder than an ordinary tap.
  static const double waterKickScale = 2.2;
}

abstract final class FeedbackTuning {
  /// Minimum interval between actual platform haptic calls across all requests.
  static const Duration minHapticGap = Duration(milliseconds: 40);

  /// Pitch jitter range around the original pitch (1.0 +/- this value).
  static const double pitchJitter = 0.03;

  /// Fill-proportional tap haptic scaling bounds (iOS Core Haptics & Android scale).
  static const double fillIntensityMin = 0.35;
  static const double fillIntensityMax = 1.0;
  static const double fillSharpnessMin = 0.25;
  static const double fillSharpnessMax = 0.95;

  /// Sudden acceleration delta (m/s^2) required to emit a liquid slosh signal.
  static const double shakeThresholdDelta = 14.0;

  /// Minimum interval between emitted slosh signals.
  static const Duration shakeCooldown = Duration(milliseconds: 450);
}

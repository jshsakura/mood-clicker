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

  /// Phrases on screen at once. The oldest goes first.
  static const int maxOnScreen = 8;

  /// Font size of an ordinary phrase: base + level^exponent * span, rounded. About 18 at the
  /// start, 35 at half, 60 when nearly full. A rare phrase is [fontSizeRareBonus] bigger and the
  /// complete phrase has its own size. A phrase is shrunk until its text fits in
  /// [maxWidthShare] of the width ([maxWidthShareComplete] for the complete phrase).
  static const double fontSizeBase = 18;
  static const double fontSizeSpan = 42;
  static const double fontSizeExponent = 1.3;
  static const double fontSizeRareBonus = 6;
  static const double fontSizeComplete = 76;
  static const double maxWidthShare = 0.6;
  static const double maxWidthShareComplete = 0.9;

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

  /// The phrase appears this far above the finger, so the finger does not hide it.
  static const double liftAboveFinger = 50;

  /// Phrases stay between these heights of an 844 px tall screen (kept as shares for other heights).
  static const double referenceHeight = 844;
  static const double spotTop = 150;
  static const double spotBottom = 700;

  /// The complete phrase goes to this height of an 844 px tall screen, in the middle.
  static const double completeY = 360;

  /// A phrase turns by a whole number of degrees between -[tiltDegrees] and [tiltDegrees]; the
  /// complete phrase always leans [completeTiltDegrees].
  static const int tiltDegrees = 4;
  static const int completeTiltDegrees = -4;

  /// How far a phrase floats up over its lifetime. A visible phrase blocks the spot it is at
  /// now, so the rise is applied to its box as it goes, not reserved in advance.
  static const double riseDistance = 46;

  /// A phrase blocks other phrases only while it is in the first this share of its lifetime.
  static const double blockingShare = 0.7;

  /// A phrase pops in over the first [popInShare] of its life (a small overshoot), grows a little
  /// more until it goes, stays fully visible until [fadeStart] and fades out after that.
  static const double popInShare = 0.35;
  static const double fadeStart = 0.6;

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

  /// No droplets when the surface is within this many px of the bottom: the screen is empty.
  static const double dropletFloorMargin = 6;
  static const int dropletsMin = 2;
  static const int dropletsMax = 5;

  /// The tap strength that scales the droplet count tops out here, and the launch speed tops out
  /// at [dropletUpPowerCap]. Strength is 1 for a tap, 2.2 when the gauge fills, 0.3 when it is full.
  static const double dropletsPowerCap = 2;
  static const double dropletUpPowerCap = 1.6;
  static const int dropletsLimit = 40;

  /// A droplet leaves going up at [dropletUpMin] to [dropletUpMax] px/s, sideways by up to
  /// +-[dropletSide] px/s, with a radius of [dropletRadiusMin] to [dropletRadiusMax] px, and then
  /// falls under [dropletGravity] px/s^2.
  static const double dropletSpawnSpread =
      24; // px, total width a droplet can start across
  static const double dropletUpMin = 220;
  static const double dropletUpMax = 500;
  static const double dropletSide = 90;
  static const double dropletBorder = 1.5;
  static const double dropletRadiusMin = 2;
  static const double dropletRadiusMax = 5;
  static const double dropletGravity = 1400;

  /// A droplet that lands on the water makes a small wave in that column of strength
  /// [splashBase] + radius * [splashPerRadius].
  static const double splashBase = 30;
  static const double splashPerRadius = 8;

  /// The phone can tilt the surface up to this far either way.
  static const double tiltLimitDegrees = 85;

  /// A phone lying flat has gravity almost only through the screen, so its sideways readings are
  /// noise. The share of gravity that lies in the screen plane (0 flat, 1 upright) scales the tilt:
  /// below [flatBelow] the surface is level and nothing spills, above [flatFull] the tilt counts in
  /// full, and in between it eases in with a smoothstep. Standard gravity is [gravity] m/s^2.
  static const double flatBelow = 0.15;
  static const double flatFull = 0.4;
  static const double gravity = 9.80665;

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

  /// What the spilling looks like: water running over the low edge. The strength of the picture is
  /// the spill rate (level per second) over [runoffFullRate], at most 1. At full strength
  /// [runoffPerSecond] drops leave the edge each second, and the stream along the edge is
  /// [runoffStreamMin] to [runoffStreamMax] px wide. Drops start [runoffInset] px inside the edge and
  /// fly out at up to [runoffOut] px/s, then fall. At most [runoffLimit] fly at once.
  static const double runoffFullRate = 0.1;
  static const double runoffPerSecond = 45;
  static const double runoffStreamMin = 6;
  static const double runoffStreamMax = 16;
  static const double runoffInset = 10;
  static const double runoffOut = 160;
  static const double runoffRadiusMin = 3;
  static const double runoffRadiusMax = 6.5;
  static const int runoffLimit = 40;

  /// The spill picture eases toward the real spill instead of following it frame by frame: the
  /// stream strength rises with time constant [spillAttack] and dies away with [spillRelease]
  /// seconds, so a spill that stutters at capacity fades rather than blinks.
  static const double spillAttack = 0.12;
  static const double spillRelease = 0.5;

  /// Below this strength, with no spill left, the stream is off.
  static const double spillFloor = 0.02;

  /// The edge the water runs over is chosen with hysteresis. A side is taken once the tilt passes
  /// [sideOnDegrees]. It is kept until the tilt falls inside [sideOffDegrees] (no side, so no
  /// stream) or passes [sideOnDegrees] the other way, so noise around level never flips it.
  static const double sideOnDegrees = 4;
  static const double sideOffDegrees = 2;

  /// A full gauge shakes the screen and shows the big phrase once. It can do that again only
  /// after the level has fallen below this.
  static const double rearm = 0.8;

  /// A tap on a gauge that is already full pushes the water this much of the usual strength.
  static const double fullKick = 0.3;

  /// Settings that can turn the effects off, and the larger text scale.
  static const double largeTextScale = 1.18;

  /// A touch that starts within [edgeGuard] px of the left or right edge may be the system back
  /// gesture. It counts as a tap only when it lifts after moving less than [edgeTapSlop] px; a
  /// drag or a cancelled touch counts for nothing.
  static const double edgeGuard = 20;
  static const double edgeTapSlop = 18;

  /// The hint in the middle of the tap screen goes away after this many taps today.
  static const int hintUntilCount = 130;
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

  /// The playback speed of the 1st, 2nd, ... tap in a run, on the pentatonic sound (do re mi sol la
  /// and the do an octave up). After the last one the run starts again.
  static const List<double> risePitches = [
    1.0,
    1.122,
    1.260,
    1.498,
    1.682,
    2.0,
  ];

  /// A run ends when the hand rests this long. The next tap is the first of a new run.
  static const Duration riseReset = Duration(milliseconds: 800);

  /// The playback speed and volume of a tap that follows the micro random rule: a small, fresh
  /// mistake on every tap, like a hand.
  static const double microPitchMin = 0.94;
  static const double microPitchMax = 1.06;
  static const double microVolumeMin = 0.85;
  static const double microVolumeMax = 1.0;

  /// The most tap sounds that ring at once. A newer tap beyond it fades the oldest one out.
  static const int maxTapVoices = 5;

  /// How long the oldest sound fades out when it is cut.
  static const Duration voiceFade = Duration(milliseconds: 20);

  /// Fill-proportional tap haptic scaling bounds (iOS Core Haptics & Android scale).
  static const double fillIntensityMin = 0.35;
  static const double fillIntensityMax = 1.0;
  static const double fillSharpnessMin = 0.25;
  static const double fillSharpnessMax = 0.95;

  /// Haptic intensity factor of the weak and strong settings. Normal is 1.
  static const double hapticWeakScale = 0.6;
  static const double hapticStrongScale = 1.4;

  /// Sudden acceleration delta (m/s^2) required to emit a liquid slosh signal.
  static const double shakeThresholdDelta = 14.0;

  /// Minimum interval between emitted slosh signals.
  static const Duration shakeCooldown = Duration(milliseconds: 450);
}

/// Numbers for the release flow of the heavy moods (angry, sad, anxious): when the gauge is full the
/// screen does not celebrate. It lets the water go, washes the screen with dawn light and settles into
/// one line. Judge the feel on a real device and adjust only here.
abstract final class ReleaseTuning {
  /// From this level the gauge counts as approaching full.
  static const double approachAt = 0.85;

  /// The cleanse that starts the moment the gauge is full. Tapping is never locked.
  static const Duration cleanse = Duration(milliseconds: 2500);

  /// How long the dawn light takes to dissolve into the settled screen.
  static const Duration crossfade = Duration(seconds: 3);

  /// How long the one line after the settle stays on screen.
  static const Duration settleLineHold = Duration(seconds: 4);

  /// The tap haptic gets weaker from the start of the approach until the gauge is full. This is the
  /// share of its strength that is left at a full gauge.
  static const double approachHapticFloor = 0.4;

  /// While the gauge approaches full, waves and droplets gather to the middle of the water: a tap
  /// lands this share of the way to the middle, and droplets drift toward it at this speed (px/s^2).
  static const double gatherPull = 0.6;
  static const double gatherDrift = 120;
}

/// Numbers for the reward of holding the gauge just below full.
abstract final class HoldTuning {
  /// The reward band starts here: from this level up to, but not including, full.
  static const double from = 0.95;

  /// How long the level must stay in the band, without a break, for the reward.
  static const Duration duration = Duration(seconds: 3);

  /// After a reward the next one waits until the level has fallen below this.
  static const double rearm = 0.85;
}

/// What the water a tilted phone spills does to the taps.
abstract final class SpillTuning {
  /// Whether spilled water also takes taps off the saved record of the day. False keeps the
  /// record whole: the number on the tap screen goes down, the saved count does not.
  static const bool takesFromRecord = false;

  /// While the finger is busy the water only looks like it spills: the stream runs over the
  /// edge, but the level and the number stay. The real spill starts this long after the last
  /// tap, so mashing a full phone in the hand never eats taps.
  static const Duration tapGrace = Duration(milliseconds: 600);
}

/// Numbers for the one-time hint beside the how-to button.
abstract final class HowToTuning {
  /// How long the first-visit bubble stays.
  static const Duration bubbleDuration = Duration(seconds: 2);

  /// The id the bubble is remembered under.
  static const String bubbleHintId = 'howToBubble';
}

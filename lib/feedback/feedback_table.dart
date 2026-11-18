import 'feedback_kind.dart';
import 'haptic_cue.dart';

/// Mood IDs used by feedback. Matched by string independently from the domain layer.
const feedbackMoodIds = ['happy', 'excited', 'angry', 'sad', 'anxious'];

/// Feedback entry for a (kind, mood) pair. Null fields mean no haptic or no sound.
class FeedbackEntry {
  const FeedbackEntry({this.haptic, this.soundId});

  final HapticCue? haptic;

  /// Sound asset base name (without extension). The pack is chosen in settings.
  final String? soundId;

  static const silent = FeedbackEntry();
}

// ---------------------------------------------------------------------------
// Haptic values from docs/RESEARCH.md 8.1 (draft). Tune here on physical devices.
// steps are the current approximation; ios and android are for platform channels.
// ---------------------------------------------------------------------------

const _happy = HapticCue(
  steps: [HapticStep(HapticStyle.light)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.55, 0.85)],
  android: AndroidHaptic(
    [0, 15],
    [0, 140],
    primitives: [AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.65)],
  ),
);

const _excited = HapticCue(
  steps: [
    HapticStep(HapticStyle.light),
    HapticStep(HapticStyle.light, delay: Duration(milliseconds: 45)),
  ],
  ios: [
    IosHapticEvent(IosHapticType.transient, 0.45, 0.75),
    IosHapticEvent(IosHapticType.transient, 0.65, 0.75, startMs: 45),
  ],
  android: AndroidHaptic(
    [0, 12, 35, 15],
    [0, 110, 0, 165],
    primitives: [
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.50),
      AndroidPrimitiveStep(AndroidPrimitiveType.click, 0.70, delayMs: 35),
    ],
  ),
);

const _angry = HapticCue(
  steps: [HapticStep(HapticStyle.heavy)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.95, 0.25)],
  android: AndroidHaptic(
    [0, 32],
    [0, 245],
    primitives: [AndroidPrimitiveStep(AndroidPrimitiveType.thud, 0.95)],
  ),
);

const _sad = HapticCue(
  steps: [HapticStep(HapticStyle.medium)],
  ios: [IosHapticEvent(IosHapticType.continuous, 0.45, 0.15, durationMs: 80)],
  android: AndroidHaptic([0, 30, 50], [0, 110, 65]),
);

const _anxious = HapticCue(
  steps: [
    HapticStep(HapticStyle.selection),
    HapticStep(HapticStyle.selection, delay: Duration(milliseconds: 22)),
    HapticStep(HapticStyle.selection, delay: Duration(milliseconds: 22)),
  ],
  ios: [
    IosHapticEvent(IosHapticType.transient, 0.35, 0.90),
    IosHapticEvent(IosHapticType.transient, 0.35, 0.90, startMs: 22),
    IosHapticEvent(IosHapticType.transient, 0.35, 0.90, startMs: 44),
  ],
  android: AndroidHaptic(
    [0, 10, 14, 10, 14, 10],
    [0, 95, 0, 95, 0, 95],
    primitives: [
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.40),
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.40, delayMs: 14),
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.40, delayMs: 14),
    ],
  ),
);

const _full = HapticCue(
  steps: [
    HapticStep(HapticStyle.heavy),
    HapticStep(HapticStyle.heavy, delay: Duration(milliseconds: 120)),
  ],
  ios: [
    IosHapticEvent(IosHapticType.continuous, 0.90, 0.45, durationMs: 220),
    IosHapticEvent(IosHapticType.transient, 1.0, 0.80, startMs: 230),
  ],
  android: AndroidHaptic(
    [0, 140, 30, 60],
    [0, 220, 0, 255],
    primitives: [
      AndroidPrimitiveStep(AndroidPrimitiveType.thud, 0.85),
      AndroidPrimitiveStep(AndroidPrimitiveType.click, 1.0, delayMs: 60),
    ],
  ),
);

// Two slow, soft swells with a breath between them: a "doo-oong", never a hit.
const _cleanse = HapticCue(
  steps: [
    HapticStep(HapticStyle.medium),
    HapticStep(HapticStyle.medium, delay: Duration(milliseconds: 700)),
  ],
  ios: [
    IosHapticEvent(IosHapticType.continuous, 0.35, 0.10, durationMs: 420),
    IosHapticEvent(
      IosHapticType.continuous,
      0.45,
      0.10,
      startMs: 700,
      durationMs: 520,
    ),
  ],
  android: AndroidHaptic([0, 420, 280, 520], [0, 90, 0, 120]),
);

const _rare = HapticCue(
  steps: [
    HapticStep(HapticStyle.light),
    HapticStep(HapticStyle.light, delay: Duration(milliseconds: 55)),
  ],
  ios: [
    IosHapticEvent(IosHapticType.transient, 0.50, 0.80),
    IosHapticEvent(IosHapticType.transient, 0.55, 0.85, startMs: 55),
  ],
  android: AndroidHaptic(
    [0, 12, 43, 12],
    [0, 120, 0, 130],
    primitives: [
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.55),
      AndroidPrimitiveStep(AndroidPrimitiveType.tick, 0.60, delayMs: 43),
    ],
  ),
);

const _select = HapticCue(
  steps: [HapticStep(HapticStyle.selection)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.45, 0.65)],
  android: AndroidHaptic([0, 12], [0, 115]),
);

// Very light haptic; approximated with the lightest built-in style (selection).
const _drop = HapticCue(
  steps: [HapticStep(HapticStyle.selection)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.25, 0.20)],
  android: AndroidHaptic([0, 15], [0, 60]),
);

// Sound IDs. Files live at assets/sounds/<pack>/<id>.ogg (or .wav).
const _tapHappy = FeedbackEntry(haptic: _happy, soundId: 'tap_happy');
const _tapExcited = FeedbackEntry(haptic: _excited, soundId: 'tap_excited');
const _tapAngry = FeedbackEntry(haptic: _angry, soundId: 'tap_angry');
const _tapSad = FeedbackEntry(haptic: _sad, soundId: 'tap_sad');
const _tapAnxious = FeedbackEntry(haptic: _anxious, soundId: 'tap_anxious');
const _fullAll = FeedbackEntry(haptic: _full, soundId: 'full');
const _cleanseAll = FeedbackEntry(haptic: _cleanse, soundId: 'cleanse');
const _selectAll = FeedbackEntry(haptic: _select, soundId: 'select');
const _dropAll = FeedbackEntry(haptic: _drop);
const _rareAll = FeedbackEntry(haptic: _rare);

/// Lookup table for all feedback cues. Edit only here to adjust mappings.
/// Every kind and mood combination must be present; enforced by tests.
abstract final class FeedbackTable {
  static const _entries = <FeedbackKind, Map<String, FeedbackEntry>>{
    FeedbackKind.tap: {
      'happy': _tapHappy,
      'excited': _tapExcited,
      'angry': _tapAngry,
      'sad': _tapSad,
      'anxious': _tapAnxious,
    },
    FeedbackKind.full: {
      'happy': _fullAll,
      'excited': _fullAll,
      'angry': _fullAll,
      'sad': _fullAll,
      'anxious': _fullAll,
    },
    FeedbackKind.cleanse: {
      'happy': _cleanseAll,
      'excited': _cleanseAll,
      'angry': _cleanseAll,
      'sad': _cleanseAll,
      'anxious': _cleanseAll,
    },
    FeedbackKind.select: {
      'happy': _selectAll,
      'excited': _selectAll,
      'angry': _selectAll,
      'sad': _selectAll,
      'anxious': _selectAll,
    },
    FeedbackKind.drop: {
      'happy': _dropAll,
      'excited': _dropAll,
      'angry': _dropAll,
      'sad': _dropAll,
      'anxious': _dropAll,
    },
    FeedbackKind.rare: {
      'happy': _rareAll,
      'excited': _rareAll,
      'angry': _rareAll,
      'sad': _rareAll,
      'anxious': _rareAll,
    },
  };

  static bool has(FeedbackKind kind, String moodId) =>
      _entries[kind]?.containsKey(moodId) ?? false;

  /// Returns a silent entry for unknown mood IDs so the UI never crashes.
  static FeedbackEntry of(FeedbackKind kind, String moodId) =>
      _entries[kind]?[moodId] ?? FeedbackEntry.silent;

  static int get size =>
      _entries.values.fold(0, (sum, byMood) => sum + byMood.length);
}

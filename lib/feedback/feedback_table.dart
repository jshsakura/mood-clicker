import 'feedback_kind.dart';
import 'haptic_cue.dart';

/// 반응에 쓰는 기분 id. 도메인과 따로 문자열로만 맞춘다.
const feedbackMoodIds = ['happy', 'excited', 'angry', 'sad', 'anxious'];

/// (kind, 기분) 하나의 반응. 진동이나 소리가 없으면 null 이다.
class FeedbackEntry {
  const FeedbackEntry({this.haptic, this.soundId});

  final HapticCue? haptic;

  /// 소리 파일 이름(확장자 없이). 묶음은 설정이 정한다.
  final String? soundId;

  static const silent = FeedbackEntry();
}

// ---------------------------------------------------------------------------
// 진동 값. 출처: docs/RESEARCH.md 8.1 (조사 초안). 실기기에서 손맛을 보고 여기만 고친다.
// steps 는 지금 실제로 내는 근사, ios 와 android 는 나중에 플랫폼 채널이 쓸 값이다.
// ---------------------------------------------------------------------------

const _happy = HapticCue(
  steps: [HapticStep(HapticStyle.light)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.55, 0.85)],
  android: AndroidHaptic([0, 15], [0, 140]),
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
  android: AndroidHaptic([0, 12, 35, 15], [0, 110, 0, 165]),
);

const _angry = HapticCue(
  steps: [HapticStep(HapticStyle.heavy)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.95, 0.25)],
  android: AndroidHaptic([0, 32], [0, 245]),
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
  android: AndroidHaptic([0, 10, 14, 10, 14, 10], [0, 95, 0, 95, 0, 95]),
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
  android: AndroidHaptic([0, 140, 30, 60], [0, 220, 0, 255]),
);

const _select = HapticCue(
  steps: [HapticStep(HapticStyle.selection)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.45, 0.65)],
  android: AndroidHaptic([0, 12], [0, 115]),
);

// 아주 약한 진동. 가장 약한 기본 진동(selection)으로 근사한다.
const _drop = HapticCue(
  steps: [HapticStep(HapticStyle.selection)],
  ios: [IosHapticEvent(IosHapticType.transient, 0.25, 0.20)],
  android: AndroidHaptic([0, 15], [0, 60]),
);

// 소리 id. 파일은 assets/sounds/<묶음>/<id>.ogg (또는 .wav).
const _tapHappy = FeedbackEntry(haptic: _happy, soundId: 'tap_happy');
const _tapExcited = FeedbackEntry(haptic: _excited, soundId: 'tap_excited');
const _tapAngry = FeedbackEntry(haptic: _angry, soundId: 'tap_angry');
const _tapSad = FeedbackEntry(haptic: _sad, soundId: 'tap_sad');
const _tapAnxious = FeedbackEntry(haptic: _anxious, soundId: 'tap_anxious');
const _fullAll = FeedbackEntry(haptic: _full, soundId: 'full');
const _selectAll = FeedbackEntry(haptic: _select, soundId: 'select');
const _dropAll = FeedbackEntry(haptic: _drop);

/// 모든 반응의 표. 바꿀 곳은 여기 한 군데다.
/// 모든 kind 와 기분 조합이 빠짐없이 있어야 하고, 테스트가 강제한다.
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
  };

  static bool has(FeedbackKind kind, String moodId) =>
      _entries[kind]?.containsKey(moodId) ?? false;

  /// 표에 없는 기분 id 는 조용한 반응을 돌려준다. 반응 때문에 화면이 죽지 않게 한다.
  static FeedbackEntry of(FeedbackKind kind, String moodId) =>
      _entries[kind]?[moodId] ?? FeedbackEntry.silent;

  static int get size =>
      _entries.values.fold(0, (sum, byMood) => sum + byMood.length);
}

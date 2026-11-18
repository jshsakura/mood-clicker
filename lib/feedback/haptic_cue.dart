/// 실제로 부를 수 있는 기본 진동 네 가지. Flutter 의 HapticFeedback 과 일대일이다.
enum HapticStyle { light, medium, heavy, selection }

/// 지금 단계의 실제 재생 한 단계. [delay] 는 앞 단계가 끝난 뒤 기다리는 시간이다.
class HapticStep {
  const HapticStep(this.style, {this.delay = Duration.zero});

  final HapticStyle style;
  final Duration delay;
}

enum IosHapticType { transient, continuous }

/// iOS Core Haptics 이벤트 하나. 플랫폼 채널을 만들 때 그대로 쓴다.
class IosHapticEvent {
  const IosHapticEvent(
    this.type,
    this.intensity,
    this.sharpness, {
    this.startMs = 0,
    this.durationMs = 0,
  });

  final IosHapticType type;

  /// 세기 0.0~1.0.
  final double intensity;

  /// 날카로움 0.0~1.0. 낮을수록 묵직하다.
  final double sharpness;
  final int startMs;

  /// continuous 일 때만 쓴다.
  final int durationMs;
}

/// 안드로이드 VibrationEffect.createWaveform 에 넘길 값. 같은 길이의 두 배열이다.
class AndroidHaptic {
  const AndroidHaptic(this.timings, this.amplitudes);

  /// 밀리초. 쉬는 시간과 진동 시간이 번갈아 온다. 첫 값은 시작 전 대기다.
  final List<int> timings;

  /// 0~255. 진폭 조절이 안 되는 기기에서는 쓰지 않는다.
  final List<int> amplitudes;
}

/// 진동 신호 하나. 세 가지 표현을 한 자리에 담는다.
///
/// - [steps]: 지금 실제로 재생하는 근사. HapticFeedback 기본 네 가지로 낸다.
/// - [ios], [android]: 플랫폼 채널을 만들 때 쓸 정밀한 값. 지금은 재생하지 않는다.
class HapticCue {
  const HapticCue({
    required this.steps,
    required this.ios,
    required this.android,
  });

  final List<HapticStep> steps;
  final List<IosHapticEvent> ios;
  final AndroidHaptic android;
}

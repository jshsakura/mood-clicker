/// 채움 게이지의 숫자. 손맛은 실기기에서 보고 여기서만 조정한다.
abstract final class GaugeTuning {
  /// 한 번 두드릴 때 오르는 양.
  static const double stepPerTap = 0.04;

  /// 마지막 두드림 뒤 그대로 머무는 시간.
  static const Duration grace = Duration(milliseconds: 300);

  /// 유예가 끝난 뒤 초당 떨어지는 양.
  static const double decayPerSecond = 0.25;
}

/// 저장 배치의 숫자.
abstract final class SaveTuning {
  /// 두드리는 동안 디스크에 쓰는 간격.
  static const Duration interval = Duration(seconds: 2);
}

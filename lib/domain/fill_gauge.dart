import 'tuning.dart';

/// 두드림의 세기를 0~1 로 나타내는 불변 값. 시계는 읽지 않고 시각을 인자로 받는다.
class FillGauge {
  const FillGauge.empty() : _level = 0, _lastTapAt = null;

  const FillGauge._(this._level, this._lastTapAt);

  /// 마지막 두드림 직후의 채움.
  final double _level;
  final DateTime? _lastTapAt;

  static const double _epsilon = 1e-9;

  double valueAt(DateTime now) {
    final last = _lastTapAt;
    if (last == null) return 0;
    final elapsed = now.difference(last);
    if (elapsed <= GaugeTuning.grace) return _level;
    final decaySeconds =
        (elapsed - GaugeTuning.grace).inMicroseconds /
        Duration.microsecondsPerSecond;
    final value = _level - decaySeconds * GaugeTuning.decayPerSecond;
    if (value < _epsilon) return 0;
    return value > 1 ? 1 : value;
  }

  bool isFullAt(DateTime now) => valueAt(now) >= 1 - _epsilon;

  FillGauge tap(DateTime now) {
    final last = _lastTapAt;
    final at = (last != null && now.isBefore(last)) ? last : now;
    final next = valueAt(at) + GaugeTuning.stepPerTap;
    return FillGauge._(next > 1 ? 1 : next, at);
  }

  /// 두드림이 멈춘 채로 0 이 되는 시각. 비어 있으면 null.
  DateTime? get emptiesAt {
    final last = _lastTapAt;
    if (last == null || _level <= 0) return null;
    final decayMicros =
        (_level / GaugeTuning.decayPerSecond * Duration.microsecondsPerSecond)
            .round();
    return last.add(GaugeTuning.grace + Duration(microseconds: decayMicros));
  }
}

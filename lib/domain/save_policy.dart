import 'tuning.dart';

enum SaveTrigger { tick, leaveScreen, background }

/// 언제 디스크에 쓸지 정하는 불변 값.
///
/// 화면은 두드릴 때 `afterTap`, 쓰기를 시작하는 순간 `afterSaveStarted`, 쓰기가 실패하면
/// `afterSaveFailed` 를 부른다. 쓰는 동안 들어온 두드림은 다음 저장 대상으로 남는다.
class SavePolicy {
  const SavePolicy.clean() : _pendingSince = null, _inFlightSince = null;

  const SavePolicy._(this._pendingSince, this._inFlightSince);

  /// 쓰지 않은 두드림 중 가장 오래된 것의 시각.
  final DateTime? _pendingSince;

  /// 지금 쓰고 있는 묶음의 가장 오래된 두드림 시각. 실패하면 되돌린다.
  final DateTime? _inFlightSince;

  bool get hasPending => _pendingSince != null;

  /// 쓰지 않은 두드림이 있을 때, 늦어도 이 시각에는 써야 한다.
  DateTime? get dueAt => _pendingSince?.add(SaveTuning.interval);

  SavePolicy afterTap(DateTime now) =>
      SavePolicy._(_pendingSince ?? now, _inFlightSince);

  /// 저장할 내용을 떠낸 직후, 쓰기를 기다리기 전에 부른다.
  /// 그 뒤에 들어오는 두드림은 이 쓰기에 들어 있지 않으므로 새로 센다.
  SavePolicy afterSaveStarted() => SavePolicy._(null, _pendingSince);

  /// 쓰기가 실패했다. 가장 오래된 두드림 시각으로 되돌려 곧 다시 쓰게 한다.
  SavePolicy afterSaveFailed() {
    final inFlight = _inFlightSince;
    final pending = _pendingSince;
    final since = switch ((inFlight, pending)) {
      (null, _) => pending,
      (_, null) => inFlight,
      (final a?, final b?) => a.isBefore(b) ? a : b,
    };
    return SavePolicy._(since, null);
  }

  bool shouldSave(SaveTrigger trigger, DateTime now) {
    final due = dueAt;
    if (due == null) return false;
    return switch (trigger) {
      SaveTrigger.tick => !now.isBefore(due),
      SaveTrigger.leaveScreen || SaveTrigger.background => true,
    };
  }
}

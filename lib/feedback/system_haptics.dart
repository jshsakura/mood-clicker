import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'haptic_cue.dart';
import 'ports.dart';

/// Flutter 기본 HapticFeedback 으로 진동을 낸다. 맥처럼 진동이 없는 곳에서는 아무 일도 없다.
class SystemHaptics implements HapticsPort {
  SystemHaptics({
    Future<void> Function(HapticStyle style)? fire,
    Future<void> Function(Duration)? delay,
    void Function(String)? log,
  }) : _fire = fire ?? _platformFire,
       _delay = delay ?? Future<void>.delayed,
       _log = log ?? debugPrint;

  final Future<void> Function(HapticStyle) _fire;
  final Future<void> Function(Duration) _delay;
  final void Function(String) _log;

  /// 새 신호가 오면 올라간다. 기다리던 앞 신호의 남은 단계는 이 값이 달라진 것을 보고 멈춘다.
  int _generation = 0;

  @override
  Future<void> play(HapticCue cue) async {
    final mine = ++_generation;
    try {
      for (final step in cue.steps) {
        if (step.delay > Duration.zero) {
          await _delay(step.delay);
          if (mine != _generation) return;
        }
        await _fire(step.style);
      }
    } catch (e) {
      _log('진동 실패: $e');
    }
  }

  static Future<void> _platformFire(HapticStyle style) => switch (style) {
    HapticStyle.light => HapticFeedback.lightImpact(),
    HapticStyle.medium => HapticFeedback.mediumImpact(),
    HapticStyle.heavy => HapticFeedback.heavyImpact(),
    HapticStyle.selection => HapticFeedback.selectionClick(),
  };
}

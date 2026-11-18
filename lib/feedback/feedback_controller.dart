import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'feedback_kind.dart';
import 'feedback_settings.dart';
import 'feedback_table.dart';
import 'ports.dart';

/// 진동 사이 최소 간격. 이보다 빨리 오는 진동은 거른다. 소리는 겹쳐도 된다.
const minHapticGap = Duration(milliseconds: 40);

/// 음 높이를 흔드는 폭. 원래 높이의 ±3%.
const pitchJitter = 0.03;

class FeedbackController {
  FeedbackController({
    required this.haptics,
    required this.sound,
    this.settings = const FeedbackSettings(),
    Duration Function()? clock,
    Random? random,
    void Function(String message)? log,
  }) : _clock = clock ?? _stopwatchClock(),
       _random = random ?? Random(),
       _log = log ?? debugPrint;

  final HapticsPort haptics;
  final SoundPort sound;
  final Duration Function() _clock;
  final Random _random;
  final void Function(String) _log;

  /// 설정을 바꾸면 다음 반응부터 적용된다.
  FeedbackSettings settings;

  Duration? _lastHaptic;

  /// 반응을 낸다. 어떤 실패도 부른 쪽으로 던지지 않는다.
  void trigger(FeedbackKind kind, String moodId) {
    final entry = FeedbackTable.of(kind, moodId);

    final haptic = entry.haptic;
    if (settings.hapticsOn && haptic != null && _hapticAllowed()) {
      _fire(() => haptics.play(haptic));
    }

    final soundId = entry.soundId;
    if (settings.soundOn && soundId != null) {
      final cue = SoundCue(settings.soundPack, soundId);
      final pitch = 1 + (_random.nextDouble() * 2 - 1) * pitchJitter;
      _fire(() => sound.play(cue, pitch: pitch));
    }
  }

  bool _hapticAllowed() {
    final now = _clock();
    final last = _lastHaptic;
    if (last != null && now - last < minHapticGap) return false;
    _lastHaptic = now;
    return true;
  }

  void _fire(Future<void> Function() play) {
    try {
      unawaited(play().onError((Object e, StackTrace _) => _log('반응 실패: $e')));
    } catch (e) {
      _log('반응 실패: $e');
    }
  }

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }
}

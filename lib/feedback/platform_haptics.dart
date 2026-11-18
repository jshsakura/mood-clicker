import 'package:flutter/services.dart';

import 'haptic_cue.dart';
import 'ports.dart';
import 'system_haptics.dart';

/// Plays rich haptics via the native platform channel (iOS Core Haptics and Android
/// VibrationEffect / Composition), falling back to [SystemHaptics] when unsupported.
class PlatformHaptics implements HapticsPort {
  PlatformHaptics({MethodChannel? channel, HapticsPort? fallback})
    : _channel = channel ?? const MethodChannel('mood_clicker/haptics'),
      _fallback = fallback ?? SystemHaptics();

  final MethodChannel _channel;
  final HapticsPort _fallback;

  @override
  Future<void> play(HapticCue cue, {bool priority = false}) async {
    try {
      final handled = await _channel.invokeMethod<bool>(
        'play',
        cue.toChannelMap(),
      );
      if (handled == true) return;
    } on MissingPluginException {
      // Fall back on desktop or test environments without native channels.
    } on PlatformException {
      // Fall back to basic system haptics on native error.
    }
    await _fallback.play(cue, priority: priority);
  }

  @override
  void cancel() => _fallback.cancel();
}

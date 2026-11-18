import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'feedback_kind.dart';
import 'feedback_table.dart';
import 'ports.dart';
import 'sound_bank.dart';
import 'voice_limiter.dart';
import '../domain/tuning.dart';
import 'feedback_settings.dart';

/// Plays sounds via flutter_soloud, supporting overlapping cues and iOS mute switch respect.
///
/// If initialization or asset loading fails, audio is silently disabled so the app keeps running.
class SoloudSound implements SoundPort {
  SoloudSound({void Function(String)? log}) : _log = log ?? debugPrint {
    _bank = SoundBank<AudioSource>(
      load: (path) => SoLoud.instance.loadAsset(path),
      log: _log,
    );
  }

  final void Function(String) _log;
  late final SoundBank<AudioSource> _bank;
  bool _ready = false;
  final VoiceLimiter<SoundHandle> _voices = VoiceLimiter<SoundHandle>(
    max: FeedbackTuning.maxTapVoices,
    isAlive: (voice) => SoLoud.instance.getIsValidVoiceHandle(voice),
    fadeOut: (voice) {
      SoLoud.instance.fadeVolume(voice, 0, FeedbackTuning.voiceFade);
      SoLoud.instance.scheduleStop(voice, FeedbackTuning.voiceFade);
    },
  );

  /// Per Apple's AVAudioSession.Category.ambient docs, ambient mixes with other
  /// audio automatically and respects the hardware mute switch; setting
  /// mixWithOthers explicitly is redundant.
  static const audioSessionConfig = AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.ambient,
  );

  /// Preloads all sounds in the table across all packs. Call once after startup.
  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(audioSessionConfig);
      await SoLoud.instance.init();
      _ready = true;
    } catch (e) {
      _log('Failed to start sound engine; continuing without sound: $e');
      return;
    }
    await _bank.preload(_allCues());
  }

  @override
  Future<void> play(
    SoundCue cue, {
    double pitch = 1.0,
    double volume = 1.0,
    bool limitVoices = false,
  }) async {
    if (!_ready) return;
    final source = _bank.sourceForWithFallback(cue);
    if (source == null) return;
    try {
      final soloud = SoLoud.instance;
      final handle = soloud.play(source, volume: volume, paused: true);
      soloud.setRelativePlaySpeed(handle, pitch);
      soloud.setPause(handle, false);
      if (limitVoices) _voices.admit(handle);
    } catch (e) {
      _log('Sound playback failed: $e');
    }
  }

  static Iterable<SoundCue> _allCues() sync* {
    final ids = <String>{
      for (final kind in FeedbackKind.values)
        for (final mood in feedbackMoodIds)
          ?FeedbackTable.of(kind, mood).soundId,
    };
    for (final pack in SoundPack.available) {
      final tapId = pack.tapSoundId;
      if (tapId != null) yield SoundCue(pack, tapId);
      // A pack with one tap sound still falls back to the basic pack for its other cues.
      if (tapId != null) continue;
      for (final id in ids) {
        yield SoundCue(pack, id);
      }
    }
  }
}

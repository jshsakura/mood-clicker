import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'feedback_kind.dart';
import 'feedback_table.dart';
import 'ports.dart';
import 'sound_bank.dart';
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

  /// Preloads all sounds in the table across all packs. Call once after startup.
  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      // ambient: stays silent when the iOS mute switch is on and mixes with other apps.
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
        ),
      );
      await SoLoud.instance.init();
      _ready = true;
    } catch (e) {
      _log('Failed to start sound engine; continuing without sound: $e');
      return;
    }
    await _bank.preload(_allCues());
  }

  @override
  Future<void> play(SoundCue cue, {double pitch = 1.0}) async {
    if (!_ready) return;
    final source = _bank.sourceFor(cue);
    if (source == null) return;
    try {
      final soloud = SoLoud.instance;
      final handle = soloud.play(source, paused: true);
      soloud.setRelativePlaySpeed(handle, pitch);
      soloud.setPause(handle, false);
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
    for (final pack in SoundPack.values) {
      for (final id in ids) {
        yield SoundCue(pack, id);
      }
    }
  }
}

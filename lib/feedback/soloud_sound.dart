import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'feedback_kind.dart';
import 'feedback_table.dart';
import 'ports.dart';
import 'sound_bank.dart';
import 'feedback_settings.dart';

/// flutter_soloud 로 소리를 낸다. 짧은 소리를 겹쳐 낼 수 있고, 아이폰 무음 스위치를 존중한다.
///
/// 시작에 실패하거나 파일이 없으면 소리만 조용히 빠지고 앱은 그대로 돈다.
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

  /// 표에 나오는 모든 소리를 모든 묶음에서 미리 불러 둔다. 앱을 켠 뒤 한 번만 부른다.
  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      // ambient: 무음 스위치를 켜면 소리가 나지 않고, 다른 앱의 음악도 끊지 않는다.
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
      _log('소리 엔진을 켜지 못해 소리 없이 진행합니다: $e');
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
      _log('소리 재생 실패: $e');
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

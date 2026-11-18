import 'package:flutter/foundation.dart';

import 'ports.dart';

typedef SoundLoader<T> = Future<T> Function(String assetPath);

/// 소리 파일을 미리 불러 두는 곳. 재생 엔진과 상관없이 "없으면 조용히 건너뛴다" 를 맡는다.
///
/// 파일은 `assets/sounds/<묶음>/<id>.ogg` 를 먼저 찾고, 없으면 `.wav` 를 찾는다.
/// 둘 다 없으면 그 소리는 건너뛰고, 로그는 전체에서 한 번만 남긴다.
class SoundBank<T extends Object> {
  SoundBank({required this.load, void Function(String)? log})
    : _log = log ?? debugPrint;

  static const extensions = ['ogg', 'wav'];

  final SoundLoader<T> load;
  final void Function(String) _log;
  final Map<SoundCue, T> _sources = {};
  final Set<SoundCue> _missing = {};
  bool _logged = false;

  int get missingCount => _missing.length;

  static String pathFor(SoundCue cue, String extension) =>
      'assets/sounds/${cue.pack.name}/${cue.id}.$extension';

  Future<void> preload(Iterable<SoundCue> cues) async {
    for (final cue in cues) {
      if (_sources.containsKey(cue)) continue;
      final source = await _loadFirst(cue);
      if (source == null) {
        _missing.add(cue);
      } else {
        _missing.remove(cue);
        _sources[cue] = source;
      }
    }
    if (_missing.isNotEmpty && !_logged) {
      _logged = true;
      _log(
        '소리 파일 ${_missing.length}개를 찾지 못해 그 소리는 건너뜁니다. '
        '예: ${pathFor(_missing.first, extensions.first)}',
      );
    }
  }

  /// 불러 둔 소리. 없으면 null 이다.
  T? sourceFor(SoundCue cue) => _sources[cue];

  Future<T?> _loadFirst(SoundCue cue) async {
    for (final ext in extensions) {
      try {
        return await load(pathFor(cue, ext));
      } catch (_) {
        // 이 확장자 파일이 없다. 다음을 찾는다.
      }
    }
    return null;
  }
}

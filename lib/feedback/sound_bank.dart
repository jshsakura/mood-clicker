import 'package:flutter/foundation.dart';

import 'feedback_settings.dart';
import 'ports.dart';

typedef SoundLoader<T> = Future<T> Function(String assetPath);

/// Preloads sound assets and silently skips missing files regardless of playback engine.
///
/// Looks up `assets/sounds/<pack>/<id>.ogg` first, then `.wav`.
/// Missing cues are skipped and logged once overall.
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
        'Skipped ${_missing.length} missing sound file(s), '
        'e.g. ${pathFor(_missing.first, extensions.first)}',
      );
    }
  }

  /// Returns the preloaded sound source, or null if unavailable.
  T? sourceFor(SoundCue cue) => _sources[cue];

  /// Returns the source for [cue], falling back to [fallback] pack when missing.
  T? sourceForWithFallback(
    SoundCue cue, {
    SoundPack fallback = SoundPack.basic,
  }) =>
      _sources[cue] ??
      (cue.pack == fallback ? null : _sources[SoundCue(fallback, cue.id)]);

  Future<T?> _loadFirst(SoundCue cue) async {
    for (final ext in extensions) {
      try {
        return await load(pathFor(cue, ext));
      } catch (_) {
        // File not found for this extension; try the next one.
      }
    }
    return null;
  }
}

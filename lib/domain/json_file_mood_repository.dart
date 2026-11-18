import 'dart:convert';
import 'dart:io';

import 'day_key.dart';
import 'day_record.dart';
import 'mood.dart';
import 'mood_journal.dart';
import 'mood_repository.dart';

/// Stores the journal in one JSON file. The file is injected.
class JsonFileMoodRepository implements MoodRepository {
  JsonFileMoodRepository(this.file);

  final File file;

  /// Version 2 puts each day's moods under `moods` so a day can also carry a note. Version 1
  /// files (a day is just its moods) are still read.
  static const int _version = 2;
  static const int _oldestReadable = 1;

  /// Makes every temp file name unique in this process, across all repositories.
  static int _nextTemp = 0;

  /// Chains writes one after another so two saves never share the temp file.
  Future<void> _tail = Future.value();

  @override
  Future<LoadResult> load() async {
    try {
      if (!await file.exists()) return Loaded(MoodJournal.empty());
      final text = utf8.decode(await file.readAsBytes());
      return Loaded(_decode(jsonDecode(text)));
    } on FormatException catch (e) {
      return LoadFailed(await _keepAside(e.message));
    } on FileSystemException catch (e) {
      return LoadFailed(e.message);
    }
  }

  /// Copies an unreadable file to `.unreadable`, then `.unreadable.2`, `.unreadable.3` and so on,
  /// so every different damaged original survives even if the caller carries on with an empty
  /// journal and saves. A copy with the same bytes already kept is not made again.
  Future<String> _keepAside(String reason) async {
    try {
      final bytes = await file.readAsBytes();
      for (var n = 1; ; n++) {
        final backup = File(
          n == 1 ? '${file.path}.unreadable' : '${file.path}.unreadable.$n',
        );
        if (!await backup.exists()) {
          await backup.writeAsBytes(bytes, flush: true);
          return reason;
        }
        if (_sameBytes(await backup.readAsBytes(), bytes)) return reason;
      }
    } on FileSystemException catch (e) {
      return '$reason (could not keep the original aside: ${e.message})';
    }
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<bool> save(MoodJournal journal) {
    final done = _tail.then((_) => _write(journal));
    _tail = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  @override
  Future<void> clear() {
    final done = _tail.then((_) async {
      if (await file.exists()) await file.delete();
      // Copies kept aside from an unreadable file hold the old records too.
      final prefix = '${file.path}.unreadable';
      if (await file.parent.exists()) {
        await for (final entry in file.parent.list()) {
          if (entry is File && entry.path.startsWith(prefix)) {
            await entry.delete();
          }
        }
      }
    });
    _tail = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  Future<bool> _write(MoodJournal journal) async {
    final text = jsonEncode(_encode(journal));
    if (text == await _currentText()) return false;
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.$pid.${_nextTemp++}.tmp');
    try {
      await temp.writeAsString(text, flush: true);
      await temp.rename(file.path);
    } on Object {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
    return true;
  }

  /// The current file text. Null when the file is missing or unreadable.
  Future<String?> _currentText() async {
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// The same journal always encodes to the same text: days and moods go in a fixed order.
  Map<String, Object?> _encode(MoodJournal journal) => {
    'version': _version,
    'days': {
      for (final record in journal.days)
        record.day.toString(): {
          'moods': {
            for (final mood in Mood.values)
              if (record.tallies[mood] case final tally?)
                mood.id: {
                  'count': tally.count,
                  'lastTapAt': tally.lastTapAt.toUtc().toIso8601String(),
                  'order': tally.lastOrder,
                },
          },
          if (record.note != null) 'note': record.note,
          if (record.notePresetId != null) 'presetId': record.notePresetId,
        },
    },
  };

  MoodJournal _decode(Object? root) {
    final map = _asMap(root, 'file root');
    final version = map['version'];
    if (version is! int || version < _oldestReadable || version > _version) {
      throw FormatException('unsupported version: $version');
    }
    final days = _asMap(map['days'], 'days');
    return MoodJournal([
      for (final MapEntry(:key, :value) in days.entries)
        _decodeDay(key, value, version),
    ]);
  }

  DayRecord _decodeDay(String key, Object? value, int version) {
    final day =
        DayKey.tryParse(key) ?? (throw FormatException('bad day key: $key'));
    final entry = _asMap(value, key);
    final moods = version == 1 ? entry : _asMap(entry['moods'], '$key/moods');
    final raws = <Mood, ({int count, DateTime at, int? order})>{};
    for (final MapEntry(key: moodId, value: raw) in moods.entries) {
      final mood =
          Mood.byId(moodId) ?? (throw FormatException('unknown mood: $moodId'));
      final tally = _asMap(raw, '$key/$moodId');
      final count = tally['count'];
      if (count is! int || count < 1) {
        throw FormatException('bad count at $key/$moodId');
      }
      final at = tally['lastTapAt'];
      final parsed = at is String ? DateTime.tryParse(at) : null;
      if (parsed == null) {
        throw FormatException('bad timestamp at $key/$moodId');
      }
      final order = tally['order'];
      if (order != null && (order is! int || order < 1)) {
        throw FormatException('bad order at $key/$moodId');
      }
      raws[mood] = (count: count, at: parsed, order: order as int?);
    }
    final (note, presetId) = version == 1
        ? (null, null)
        : _decodeNote(key, entry);
    return DayRecord(day, _withOrder(raws), note: note, notePresetId: presetId);
  }

  (String?, String?) _decodeNote(String key, Map<String, Object?> entry) {
    final note = entry['note'];
    final presetId = entry['presetId'];
    if (note != null && note is! String) {
      throw FormatException('bad note at $key');
    }
    if (presetId != null && presetId is! String) {
      throw FormatException('bad preset id at $key');
    }
    try {
      return (
        DayRecord.cleanNote(note as String?),
        DayRecord.checkPresetId(presetId as String?),
      );
    } on ArgumentError {
      throw FormatException('invalid note or preset id at $key');
    }
  }

  /// Uses the saved tap order. A file from before tap order existed has none, so the order is
  /// rebuilt from the timestamps (ties by `Mood` declaration order).
  Map<Mood, MoodTally> _withOrder(
    Map<Mood, ({int count, DateTime at, int? order})> raws,
  ) {
    final saved = raws.values.every((r) => r.order != null);
    final byTime = raws.keys.toList()
      ..sort((a, b) {
        final byAt = raws[a]!.at.compareTo(raws[b]!.at);
        return byAt != 0 ? byAt : a.index.compareTo(b.index);
      });
    return {
      for (final mood in raws.keys)
        mood: MoodTally(
          count: raws[mood]!.count,
          lastTapAt: raws[mood]!.at,
          lastOrder: saved ? raws[mood]!.order! : byTime.indexOf(mood) + 1,
        ),
    };
  }

  Map<String, Object?> _asMap(Object? value, String where) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('$where is not an object');
  }
}

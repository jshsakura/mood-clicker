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

  static const int _version = 1;

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

  /// Copies an unreadable file to `.unreadable`. If the caller carries on with an
  /// empty journal and saves, the original still survives. An existing copy is kept as is.
  Future<String> _keepAside(String reason) async {
    final backup = File('${file.path}.unreadable');
    try {
      if (!await backup.exists()) await file.copy(backup.path);
      return reason;
    } on FileSystemException catch (e) {
      return '$reason (could not keep the original aside: ${e.message})';
    }
  }

  @override
  Future<bool> save(MoodJournal journal) {
    final done = _tail.then((_) => _write(journal));
    _tail = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  Future<bool> _write(MoodJournal journal) async {
    final text = jsonEncode(_encode(journal));
    if (text == await _currentText()) return false;
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
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
          for (final mood in Mood.values)
            if (record.tallies[mood] case final tally?)
              mood.id: {
                'count': tally.count,
                'lastTapAt': tally.lastTapAt.toUtc().toIso8601String(),
              },
        },
    },
  };

  MoodJournal _decode(Object? root) {
    final map = _asMap(root, 'file root');
    if (map['version'] != _version) {
      throw FormatException('unsupported version: ${map['version']}');
    }
    final days = _asMap(map['days'], 'days');
    return MoodJournal([
      for (final MapEntry(:key, :value) in days.entries) _decodeDay(key, value),
    ]);
  }

  DayRecord _decodeDay(String key, Object? value) {
    final day =
        DayKey.tryParse(key) ?? (throw FormatException('bad day key: $key'));
    final tallies = <Mood, MoodTally>{};
    for (final MapEntry(key: moodId, value: raw) in _asMap(
      value,
      key,
    ).entries) {
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
      tallies[mood] = MoodTally(count: count, lastTapAt: parsed);
    }
    return DayRecord(day, tallies);
  }

  Map<String, Object?> _asMap(Object? value, String where) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('$where is not an object');
  }
}

import 'dart:convert';
import 'dart:io';

import 'day_key.dart';
import 'day_record.dart';
import 'mood.dart';
import 'mood_journal.dart';
import 'mood_repository.dart';

/// JSON 파일 한 개에 저장한다. 경로는 주입받는다.
class JsonFileMoodRepository implements MoodRepository {
  JsonFileMoodRepository(this.file);

  final File file;

  static const int _version = 1;

  /// 쓰기를 차례로 잇는 줄. 같은 임시 파일을 두 쓰기가 함께 쓰지 못하게 한다.
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

  /// 읽을 수 없는 파일을 `.unreadable` 로 복사해 둔다. 호출자가 비어 있는 기록으로
  /// 이어 가서 저장해도 원본이 사라지지 않게 한다. 이미 복사본이 있으면 처음 것을 그대로 둔다.
  Future<String> _keepAside(String reason) async {
    final backup = File('${file.path}.unreadable');
    try {
      if (!await backup.exists()) await file.copy(backup.path);
      return reason;
    } on FileSystemException catch (e) {
      return '$reason (원본을 따로 보관하지 못했습니다: ${e.message})';
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

  /// 지금 파일의 내용. 없거나 읽을 수 없으면 null.
  Future<String?> _currentText() async {
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// 같은 기록은 늘 같은 글자로 만든다. 날짜와 기분을 정해진 순서로 쓴다.
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
    final map = _asMap(root, '파일 최상위');
    if (map['version'] != _version) {
      throw FormatException('지원하지 않는 버전입니다: ${map['version']}');
    }
    final days = _asMap(map['days'], 'days');
    return MoodJournal([
      for (final MapEntry(:key, :value) in days.entries) _decodeDay(key, value),
    ]);
  }

  DayRecord _decodeDay(String key, Object? value) {
    final day =
        DayKey.tryParse(key) ?? (throw FormatException('날짜 키가 잘못됐습니다: $key'));
    final tallies = <Mood, MoodTally>{};
    for (final MapEntry(key: moodId, value: raw) in _asMap(
      value,
      key,
    ).entries) {
      final mood =
          Mood.byId(moodId) ?? (throw FormatException('모르는 기분입니다: $moodId'));
      final tally = _asMap(raw, '$key/$moodId');
      final count = tally['count'];
      if (count is! int || count < 1) {
        throw FormatException('$key/$moodId 의 횟수가 잘못됐습니다');
      }
      final at = tally['lastTapAt'];
      final parsed = at is String ? DateTime.tryParse(at) : null;
      if (parsed == null) {
        throw FormatException('$key/$moodId 의 시각이 잘못됐습니다');
      }
      tallies[mood] = MoodTally(count: count, lastTapAt: parsed);
    }
    return DayRecord(day, tallies);
  }

  Map<String, Object?> _asMap(Object? value, String where) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('$where 가 객체가 아닙니다');
  }
}

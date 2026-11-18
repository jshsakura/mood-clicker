import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/json_file_mood_repository.dart';
import 'package:mood_clicker/settings/records_port.dart';

void main() {
  late Directory tmp;
  late File file;
  late List<String> shared;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('records');
    file = File('${tmp.path}/mood_journal.json');
    shared = [];
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  DeviceRecordsPort port() => DeviceRecordsPort(
    journalFile: () async => file,
    shareFiles: (paths) async => shared.addAll(paths),
  );

  test('an empty app has no record today and nothing to export', () async {
    final empty = port();
    expect(await empty.hasRecordToday(), isFalse);
    expect(await empty.exportJournal(), isNull);
    expect(shared, isEmpty);
  });

  test('a journal with a tap today counts as recorded', () async {
    final repository = JsonFileMoodRepository(file);
    final now = DateTime.now();
    final journal = MoodJournal.empty().withTap(Mood.happy, now);
    await repository.save(journal);
    expect(await port().hasRecordToday(), isTrue);
  });

  test('export shares the journal file path', () async {
    final repository = JsonFileMoodRepository(file);
    await repository.save(
      MoodJournal.empty().withTap(Mood.sad, DateTime.now()),
    );
    final path = await port().exportJournal();
    expect(path, file.path);
    expect(shared, [file.path]);
    expect(await File(file.path).exists(), isTrue);
  });

  test('deleteAll removes the journal file', () async {
    final repository = JsonFileMoodRepository(file);
    await repository.save(
      MoodJournal.empty().withTap(Mood.sad, DateTime.now()),
    );
    await port().deleteAll();
    expect(await file.exists(), isFalse);
  });
}

/// Records export and wipe for the settings screen, behind a port so tests
/// inject fakes.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/day_key.dart';
import '../domain/json_file_mood_repository.dart';
import '../domain/mood_repository.dart';

abstract interface class RecordsPort {
  /// Whether today already has a record; the reminder skips such days.
  Future<bool> hasRecordToday();

  /// Shares the journal file and returns its path, or returns null when
  /// there is nothing to export yet.
  Future<String?> exportJournal();

  /// Removes every record after the confirm sheet.
  Future<void> deleteAll();
}

/// The journal file of this app. Every reader and writer, now and in the
/// screen work, must go through here so they agree on the location.
Future<File> moodJournalFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/mood_journal.json');
}

/// Shares paths through the system share sheet.
Future<void> shareThroughSheet(List<String> paths) async {
  await SharePlus.instance.share(
    ShareParams(files: [for (final path in paths) XFile(path)]),
  );
}

class DeviceRecordsPort implements RecordsPort {
  DeviceRecordsPort({
    this.journalFile = moodJournalFile,
    this.shareFiles = shareThroughSheet,
  });

  final Future<File> Function() journalFile;
  final Future<void> Function(List<String> paths) shareFiles;

  @override
  Future<bool> hasRecordToday() async {
    final file = await journalFile();
    final result = await JsonFileMoodRepository(file).load();
    if (result is! Loaded) {
      return false;
    }
    final today = result.journal.dayOf(DayKey.of(DateTime.now()));
    return today.total > 0;
  }

  @override
  Future<String?> exportJournal() async {
    final file = await journalFile();
    if (!await file.exists()) {
      return null;
    }
    await shareFiles([file.path]);
    return file.path;
  }

  @override
  Future<void> deleteAll() async {
    final file = await journalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

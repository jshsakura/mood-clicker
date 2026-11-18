/// Records export and wipe for the settings screen, behind a port so tests
/// inject fakes.
library;

import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../app/journal_store.dart' as app_journal;
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

/// Shares paths through the system share sheet.
Future<void> shareThroughSheet(List<String> paths) async {
  await SharePlus.instance.share(
    ShareParams(files: [for (final path in paths) XFile(path)]),
  );
}

class DeviceRecordsPort implements RecordsPort {
  DeviceRecordsPort({
    this.journalFile = defaultJournalFile,
    this.shareFiles = shareThroughSheet,
    this.store,
  });

  /// The live journal. When given, deleting goes through it so memory, disk and the calendar
  /// empty together.
  final app_journal.JournalStore? store;

  /// Resolves to the app's one journal file from lib/app/journal_store.dart.
  static Future<File> defaultJournalFile() => app_journal.journalFile();

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
    final live = store;
    if (live != null) return live.deleteAll();
    final file = await journalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Records export and wipe for the settings screen, behind a port so tests
/// inject fakes.
library;

import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../app/journal_store.dart' as app_journal;
import '../domain/day_key.dart';
import '../domain/json_file_mood_repository.dart';
import '../domain/mood_repository.dart';

/// How an export ended, so the screen tells the three apart.
enum ExportOutcome {
  /// There is no journal file yet.
  nothing,

  /// The share sheet was used.
  shared,

  /// The user closed the share sheet without sharing.
  cancelled,
}

abstract interface class RecordsPort {
  /// Whether today already has a record; the reminder skips such days.
  Future<bool> hasRecordToday();

  /// Shares the journal file, and says whether there was nothing to share,
  /// the file was shared, or the user cancelled.
  Future<ExportOutcome> exportJournal();

  /// Removes every record after the confirm sheet.
  Future<void> deleteAll();
}

/// Shares paths through the system share sheet.
/// Returns true only when the share finished.
Future<bool> shareThroughSheet(List<String> paths) async {
  final result = await SharePlus.instance.share(
    ShareParams(files: [for (final path in paths) XFile(path)]),
  );
  return shareFinished(result);
}

/// Only a finished share counts. A device that cannot say, or has no share sheet, did not share.
bool shareFinished(ShareResult result) =>
    result.status == ShareResultStatus.success;

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
  final Future<bool> Function(List<String> paths) shareFiles;

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
  Future<ExportOutcome> exportJournal() async {
    final file = await journalFile();
    if (!await file.exists()) {
      return ExportOutcome.nothing;
    }
    final done = await shareFiles([file.path]);
    return done ? ExportOutcome.shared : ExportOutcome.cancelled;
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

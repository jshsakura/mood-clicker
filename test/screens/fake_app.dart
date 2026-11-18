import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mood_clicker/app/app_services.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/cheer_picker.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/app_localizations_ko.g.dart';

import '../domain/cheer_fixtures.dart';
import '../feedback/fakes.dart';

/// The Korean strings, so tests read labels from the translations instead of typing them.
final ko = AppLocalizationsKo();

class MemoryRepository implements MoodRepository {
  MemoryRepository({this.loadResult});

  LoadResult? loadResult;
  final List<MoodJournal> saved = [];

  @override
  Future<LoadResult> load() async => loadResult ?? Loaded(MoodJournal.empty());

  @override
  Future<bool> save(MoodJournal journal) async {
    saved.add(journal);
    return true;
  }
}

class MemoryDeckStore implements CheerDeckStore {
  CheerDeckSnapshot snapshot = const CheerDeckSnapshot.empty();

  @override
  Future<CheerDeckSnapshot> load() async => snapshot;

  @override
  Future<bool> save(CheerDeckSnapshot value) async {
    snapshot = value;
    return true;
  }
}

/// App services made of fakes. [clock] is the app time; move it with [advance].
class TestApp {
  TestApp({
    MemoryRepository? repository,
    FeelSettings feel = const FeelSettings(),
    DateTime? start,
    this.settingsBuilder,
  }) : repository = repository ?? MemoryRepository(),
       clock = start ?? DateTime(2026, 11, 18, 12),
       haptics = FakeHaptics(),
       sound = FakeSound(),
       feel = ValueNotifier(feel),
       tiltEvents = StreamController<double>.broadcast() {
    journal = JournalStore(this.repository);
    final store = MemoryDeckStore();
    services = AppServices(
      journal: journal,
      feedback: FeedbackController(
        haptics: haptics,
        sound: sound,
        clock: () => Duration(microseconds: clock.microsecondsSinceEpoch),
      ),
      loadCheers: (_) async => bookOf(20),
      cheerPicker: CheerPicker(Random(1)),
      deckStore: store,
      feel: this.feel,
      tilt: () => tiltEvents.stream,
      settingsBuilder: settingsBuilder,
      now: () => clock,
    );
  }

  final MemoryRepository repository;
  final FakeHaptics haptics;
  final FakeSound sound;
  final ValueNotifier<FeelSettings> feel;
  final StreamController<double> tiltEvents;
  final WidgetBuilder? settingsBuilder;
  late final JournalStore journal;
  late final AppServices services;
  DateTime clock;

  void advance(Duration by) => clock = clock.add(by);

  Widget wrap(
    Widget home, {
    AppPalette? palette,
    Locale locale = const Locale('ko'),
  }) => AppScope(
    services: services,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette ?? lightPalette),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

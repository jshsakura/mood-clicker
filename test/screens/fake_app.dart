import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mood_clicker/app/app_services.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_picker.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/l10n/app_localizations_ko.g.dart';

import '../domain/cheer_fixtures.dart';
import '../feedback/fakes.dart';
import '../surfaces/fakes.dart';
import 'package:mood_clicker/surfaces/native_surfaces.dart';

/// The Korean strings, so tests read labels from the translations instead of typing them.
final ko = AppLocalizationsKo();

/// The three fake ports of the native surfaces, so a test can look at what was sent.
class FakeSurfaces {
  final publisher = FakeWidgetPublisher();
  final shortcuts = FakeIconShortcuts();
  final links = FakeLaunchLinks();

  NativeSurfaces build() => NativeSurfaces(
    widget: publisher,
    shortcuts: shortcuts,
    links: links,
    onLaunchMood: (_) {},
  );
}

class MemoryRepository implements MoodRepository {
  MemoryRepository({this.loadResult, this.gate});

  /// When set, [save] throws it. A test that wants a failing disk sets one.
  Object? saveError;

  /// When set, [clear] throws it. A test that wants a file that cannot be removed sets one.
  Object? clearError;

  /// When given, [save] waits for it before it finishes.
  Future<void>? saveGate;

  LoadResult? loadResult;

  /// When given, [load] waits for it. A test that wants the loading screen to stay gives one.
  final Future<void>? gate;
  final List<MoodJournal> saved = [];

  @override
  Future<LoadResult> load() async {
    await gate;
    return loadResult ?? Loaded(MoodJournal.empty());
  }

  @override
  Future<bool> save(MoodJournal journal) async {
    await saveGate;
    if (saveError case final error?) throw error;
    saved.add(journal);
    return true;
  }

  @override
  Future<void> clear() async {
    if (clearError case final error?) throw error;
    saved.clear();
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
    this.fakeSurfaces,
    CheerBook? book,
    FeedbackController? feedback,
    ValueNotifier<LocaleChoice>? language,
    ValueNotifier<ThemeChoice>? theme,
    ValueNotifier<FeelSettings>? feelNotifier,
    ValueNotifier<bool>? mapView,
  }) : repository = repository ?? MemoryRepository(),
       clock = start ?? DateTime(2026, 11, 18, 12),
       haptics = FakeHaptics(),
       sound = FakeSound(),
       feel = feelNotifier ?? ValueNotifier(feel),
       tiltEvents = StreamController<double>.broadcast() {
    journal = JournalStore(this.repository);
    final store = MemoryDeckStore();
    services = AppServices(
      journal: journal,
      feedback:
          feedback ??
          FeedbackController(
            haptics: haptics,
            sound: sound,
            clock: () => Duration(microseconds: clock.microsecondsSinceEpoch),
          ),
      loadCheers: (_) async => book ?? bookOf(20),
      cheerPicker: CheerPicker(Random(1)),
      deckStore: store,
      feel: this.feel,
      tilt: () => tiltEvents.stream,
      theme: theme ?? ValueNotifier(const ThemeChoice.named('light')),
      language: language,
      mapView: mapView,
      settingsBuilder: settingsBuilder,
      surfaces: fakeSurfaces?.build(),
      now: () => clock,
    );
  }

  final MemoryRepository repository;
  final FakeHaptics haptics;
  final FakeSound sound;
  final ValueNotifier<FeelSettings> feel;
  final StreamController<double> tiltEvents;
  final WidgetBuilder? settingsBuilder;

  /// Fakes for the home widget and shortcuts. Null leaves the surfaces out.
  final FakeSurfaces? fakeSurfaces;
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

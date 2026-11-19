import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/surfaces/mood_links.dart';
import 'package:mood_clicker/surfaces/native_surfaces.dart';
import 'package:mood_clicker/surfaces/surfaces_ports.dart';
import 'package:mood_clicker/surfaces/widget_snapshot.dart';

import 'fakes.dart';

void main() {
  final noon = DateTime(2030, 3, 4, 12);
  late FakeWidgetPublisher widget;
  late FakeIconShortcuts shortcuts;
  late FakeLaunchLinks links;
  late List<Mood> launched;

  NativeSurfaces build({Uri? initial}) {
    widget = FakeWidgetPublisher();
    shortcuts = FakeIconShortcuts();
    links = FakeLaunchLinks(initial: initial);
    launched = [];
    return NativeSurfaces(
      widget: widget,
      shortcuts: shortcuts,
      links: links,
      onLaunchMood: launched.add,
    );
  }

  DayRecord today(int taps) {
    var r = DayRecord.empty(DayKey.of(noon));
    for (var i = 0; i < taps; i++) {
      r = r.withTap(Mood.happy, noon);
    }
    return r;
  }

  test('the widget is published from the day record', () async {
    final s = build();
    await s.publishToday(today(2));
    expect(widget.published.single.count, 2);
    expect(widget.published.single.mood, Mood.happy);
  });

  test('an unchanged snapshot is not published again', () async {
    final s = build();
    await s.publishToday(today(2));
    await s.publishToday(today(2));
    expect(widget.published.length, 1);
    await s.publishToday(today(3));
    expect(widget.published.length, 2);
  });

  test('a failed publish is tried again next time', () async {
    build();
    final failing = _FailingOnce();
    final surfaces = NativeSurfaces(
      widget: failing,
      shortcuts: shortcuts,
      links: links,
      onLaunchMood: launched.add,
    );
    await expectLater(surfaces.publishToday(today(1)), throwsStateError);
    await surfaces.publishToday(today(1));
    expect(failing.calls, 2);
  });

  test('the link that launched the app goes to the mood', () async {
    final s = build(initial: tapUri(Mood.angry));
    await s.start();
    expect(launched, [Mood.angry]);
  });

  test('a link without a mood or without a launch does nothing', () async {
    final s = build(initial: tapUri(null));
    await s.start();
    expect(launched, isEmpty);
  });

  test('links while the app runs go to the mood', () async {
    final s = build();
    await s.start();
    links.controller.add(tapUri(Mood.sad));
    links.controller.add(null);
    links.controller.add(Uri.parse('https://example.com'));
    await Future<void>.delayed(Duration.zero);
    expect(launched, [Mood.sad]);
    await s.dispose();
    links.controller.add(tapUri(Mood.happy));
    await Future<void>.delayed(Duration.zero);
    expect(launched, [Mood.sad]);
  });

  test(
    'a selected shortcut goes to the mood and unknown ones are ignored',
    () async {
      final s = build();
      await s.start();
      shortcuts.handler!(shortcutTypeFor(Mood.anxious));
      shortcuts.handler!('nonsense');
      expect(launched, [Mood.anxious]);
    },
  );

  test('shortcuts hold four moods with their translated names', () async {
    final s = build();
    final ko = await AppLocalizations.delegate.load(const Locale('ko'));
    await s.registerShortcuts(ko, MoodJournal.empty(), noon);
    final entries = shortcuts.registered.single;
    expect(
      entries.map((e) => e.type),
      [Mood.happy, Mood.excited, Mood.angry, Mood.sad].map(shortcutTypeFor),
    );
    expect(entries.first.title, ko.moodSelect_moodHappy);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await s.registerShortcuts(en, MoodJournal.empty(), noon);
    expect(shortcuts.registered.last.first.title, 'Happy');
  });

  test('shortcuts follow what was picked in the last 14 days', () async {
    final s = build();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final journal = MoodJournal.empty()
        .withTap(Mood.anxious, noon)
        .withTap(Mood.anxious, noon)
        .withTap(Mood.sad, noon);
    await s.registerShortcuts(en, journal, noon);
    expect(shortcuts.registered.single.map((e) => e.title), [
      'Anxious',
      'Sad',
      'Happy',
      'Excited',
    ]);
  });

  test('registering again after a change replaces the shortcuts', () async {
    final s = build();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await s.registerShortcuts(en, MoodJournal.empty(), noon);
    await s.registerShortcuts(
      en,
      MoodJournal.empty().withTap(Mood.anxious, noon),
      noon,
    );
    expect(shortcuts.registered, hasLength(2));
    expect(shortcuts.registered.last.first.title, 'Anxious');
  });
}

class _FailingOnce implements WidgetPublisher {
  int calls = 0;

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    calls++;
    if (calls == 1) throw StateError('native side not ready');
  }
}

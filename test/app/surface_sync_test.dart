import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/app.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';
import 'package:mood_clicker/surfaces/mood_links.dart';

import '../screens/fake_app.dart';

Future<TestApp> start(
  WidgetTester tester, {
  MoodJournal? journal,
  Uri? launch,
}) async {
  final surfaces = FakeSurfaces()..links.initial = launch;
  final app = TestApp(fakeSurfaces: surfaces);
  if (journal != null) app.repository.loadResult = Loaded(journal);
  await tester.pumpWidget(MoodClickerApp(services: app.services));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return app;
}

void main() {
  testWidgets(
    'the widget gets the record of today once the journal is loaded',
    (tester) async {
      final surfaces = FakeSurfaces();
      final app = TestApp(fakeSurfaces: surfaces);
      app.repository.loadResult = Loaded(
        MoodJournal.empty()
            .withTap(Mood.sad, app.clock)
            .withTap(Mood.sad, app.clock),
      );
      await tester.pumpWidget(MoodClickerApp(services: app.services));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(surfaces.publisher.published, isNotEmpty);
      final last = surfaces.publisher.published.last;
      expect(last.mood, Mood.sad);
      expect(last.count, 2);
    },
  );

  testWidgets('a new tap updates the widget', (tester) async {
    final app = await start(tester);
    app.journal.recordTap(Mood.happy, app.clock);
    await tester.pump();
    // The fake publisher sits in the surfaces made by TestApp.
    final published = app.fakeSurfaces!.publisher.published;
    expect(published.last.mood, Mood.happy);
    expect(published.last.count, 1);
  });

  testWidgets('the icon shortcuts are registered after loading, four of them', (
    tester,
  ) async {
    final app = await start(tester);
    final registered = app.fakeSurfaces!.shortcuts.registered;
    expect(registered, isNotEmpty);
    expect(registered.last, hasLength(4));
  });

  testWidgets('the shortcuts follow the language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final app = await start(tester);
    final ko = app.fakeSurfaces!.shortcuts.registered.last.first.title;
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    await tester.pump();
    await tester.pump();
    final en = app.fakeSurfaces!.shortcuts.registered.last.first.title;
    expect(en, isNot(ko));
  });

  testWidgets(
    'the shortcut order follows what was tapped most in the last days',
    (tester) async {
      final app = await start(tester);
      for (var i = 0; i < 3; i++) {
        app.journal.recordTap(Mood.anxious, app.clock);
      }
      await tester.pump();
      final first = app.fakeSurfaces!.shortcuts.registered.last.first;
      expect(first.type, shortcutTypeFor(Mood.anxious));
    },
  );

  testWidgets(
    'a shortcut opens the tap screen of that mood on top of the picker',
    (tester) async {
      final app = await start(tester);
      app.fakeSurfaces!.shortcuts.handler!(shortcutTypeFor(Mood.angry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<TapScreen>(find.byType(TapScreen)).mood, Mood.angry);
    },
  );

  testWidgets(
    'a second shortcut replaces the open tap screen, not stacks on it',
    (tester) async {
      final app = await start(tester);
      final handler = app.fakeSurfaces!.shortcuts.handler!;
      handler(shortcutTypeFor(Mood.angry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      handler(shortcutTypeFor(Mood.sad));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TapScreen), findsOneWidget);
      expect(tester.widget<TapScreen>(find.byType(TapScreen)).mood, Mood.sad);
    },
  );

  testWidgets('a launch before the journal is loaded waits for it', (
    tester,
  ) async {
    final app = TestApp(fakeSurfaces: FakeSurfaces());
    await tester.pumpWidget(MoodClickerApp(services: app.services));
    // Before the loading screen is done.
    app.fakeSurfaces!.shortcuts.handler?.call(shortcutTypeFor(Mood.excited));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MoodSelectScreen, skipOffstage: false), findsOneWidget);
    expect(tester.widget<TapScreen>(find.byType(TapScreen)).mood, Mood.excited);
  });

  testWidgets(
    'a widget link that started the app opens that mood after loading',
    (tester) async {
      final surfaces = FakeSurfaces()..links.initial = tapUri(Mood.sad);
      final app = TestApp(fakeSurfaces: surfaces);
      await tester.pumpWidget(MoodClickerApp(services: app.services));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.widget<TapScreen>(find.byType(TapScreen)).mood, Mood.sad);
    },
  );
}

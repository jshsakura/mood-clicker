import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/map/map_rules.dart';
import 'package:mood_clicker/design/parts/how_to_button.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';
import 'package:mood_clicker/screens/loading_screen.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';

import 'fake_app.dart';

void main() {
  testWidgets('shows the five moods with today counts', (tester) async {
    final app = TestApp();
    app.journal.load(
      MoodJournal.empty()
          .withTap(Mood.sad, app.clock)
          .withTap(Mood.sad, app.clock),
    );
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    for (final name in [
      ko.moodSelect_moodHappy,
      ko.moodSelect_moodExcited,
      ko.moodSelect_moodAngry,
      ko.moodSelect_moodSad,
      ko.moodSelect_moodAnxious,
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text(ko.tap_todayCount(2)), findsOneWidget);
  });

  testWidgets(
    'a banner opens its tap screen at once and plays the select cue',
    (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
      await tester.tap(find.text(ko.moodSelect_moodAngry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final screen = tester.widget<TapScreen>(find.byType(TapScreen));
      expect(screen.mood, Mood.angry);
      expect(app.sound.played, isNotEmpty);
    },
  );

  testWidgets(
    'the settings button shows only when a settings screen is given',
    (tester) async {
      final without = TestApp();
      await tester.pumpWidget(without.wrap(const MoodSelectScreen()));
      expect(find.bySemanticsLabel(ko.settings_title), findsNothing);
      final withIt = TestApp(
        settingsBuilder: (_) => const Scaffold(body: Text('settings page')),
      );
      await tester.pumpWidget(withIt.wrap(const MoodSelectScreen()));
      await tester.tap(find.bySemanticsLabel(ko.settings_title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('settings page'), findsOneWidget);
    },
  );

  testWidgets(
    'loading shows the wordmark, then the mood picker with the loaded journal',
    (tester) async {
      final app = TestApp();
      app.repository.loadResult = Loaded(
        MoodJournal.empty().withTap(Mood.happy, app.clock),
      );
      await tester.pumpWidget(app.wrap(const LoadingScreen()));
      expect(find.textContaining('Unknown'), findsOneWidget);
      expect(find.text(ko.loading_message), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(MoodSelectScreen), findsOneWidget);
      expect(find.text(ko.tap_todayCount(1)), findsOneWidget);
    },
  );

  testWidgets('an unreadable journal is announced, never silently replaced', (
    tester,
  ) async {
    final app = TestApp();
    app.repository.loadResult = const LoadFailed('broken');
    await tester.pumpWidget(app.wrap(const LoadingScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(ko.loading_brokenTitle), findsOneWidget);
    await tester.tap(find.text(ko.loading_startNew));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MoodSelectScreen), findsOneWidget);
    expect(app.repository.saved, isEmpty);
  });

  testWidgets('the settings button opens from the keyboard', (tester) async {
    final app = TestApp(
      settingsBuilder: (_) => const Scaffold(body: Text('settings page')),
    );
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    // The header order is help, map (when available), calendar, settings.
    for (var i = 0; i < (MapRules.available ? 4 : 3); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('settings page'), findsOneWidget);
  });

  testWidgets('the title sits under the date line', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    expect(find.text(ko.moodSelect_title), findsOneWidget);
  });

  testWidgets('the how-to button opens the play sheet, not the crisis sheet', (
    tester,
  ) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    expect(find.byType(HowToButton), findsOneWidget);
    expect(find.bySemanticsLabel(ko.settings_mindCareHelp), findsNothing);
    await tester.tap(find.bySemanticsLabel(ko.howTo_label));
    await tester.pumpAndSettle();
    expect(find.text(ko.howTo_title), findsWidgets);
    expect(find.text(ko.howTo_fill), findsOneWidget);
    expect(find.text(ko.settings_mindCareTitle), findsNothing);
  });

  testWidgets('the grab bar on top closes the play sheet for assistive tech', (
    tester,
  ) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    await tester.tap(find.bySemanticsLabel(ko.howTo_label));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(ko.settings_close).first);
    await tester.pumpAndSettle();
    expect(find.text(ko.howTo_fill), findsNothing);
  });

  testWidgets('the play sheet closes by dragging it down', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
    await tester.tap(find.bySemanticsLabel(ko.howTo_label));
    await tester.pumpAndSettle();
    await tester.drag(find.text(ko.howTo_fill), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text(ko.howTo_fill), findsNothing);
  });
}

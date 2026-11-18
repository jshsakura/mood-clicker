import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/screens/calendar_screen.dart';
import 'package:mood_clicker/screens/day_detail_screen.dart';
import 'package:mood_clicker/screens/mood_labels.dart';

import 'fake_app.dart';

void main() {
  testWidgets('shows the month title and a face on each day with taps', (
    tester,
  ) async {
    final app = TestApp();
    app.journal.load(
      MoodJournal.empty()
          .withTap(Mood.happy, app.clock)
          .withTap(Mood.happy, app.clock)
          .withTap(Mood.sad, app.clock)
          .withTap(Mood.angry, DateTime(2026, 11, 3, 9)),
    );
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.text(moodEmoji(Mood.happy)), findsOneWidget);
    expect(find.text(moodEmoji(Mood.angry)), findsOneWidget);
    expect(find.text(moodEmoji(Mood.sad)), findsNothing);
  });

  testWidgets('the main mood of a day is the one tapped most', (tester) async {
    final app = TestApp();
    app.journal.load(
      MoodJournal.empty()
          .withTap(Mood.sad, app.clock)
          .withTap(Mood.happy, app.clock)
          .withTap(Mood.happy, app.clock),
    );
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.text(moodEmoji(Mood.happy)), findsOneWidget);
    expect(find.text(moodEmoji(Mood.sad)), findsNothing);
  });

  testWidgets('a day without taps stays empty', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    for (final mood in Mood.values) {
      expect(find.text(moodEmoji(mood)), findsNothing);
    }
  });

  testWidgets(
    'the previous month opens, and the next month is closed in the current one',
    (tester) async {
      final app = TestApp();
      app.journal.load(
        MoodJournal.empty().withTap(Mood.excited, DateTime(2026, 10, 20, 9)),
      );
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      expect(find.text(moodEmoji(Mood.excited)), findsNothing);
      await tester.tap(find.bySemanticsLabel(ko.calendar_prevMonth));
      await tester.pump();
      expect(find.text(moodEmoji(Mood.excited)), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pump();
      expect(find.text(moodEmoji(Mood.excited)), findsNothing);
      // Already on the current month: the next button does nothing.
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pump();
      expect(find.text(moodEmoji(Mood.excited)), findsNothing);
    },
  );

  testWidgets('a day opens its detail with counts, both sides and the note', (
    tester,
  ) async {
    final app = TestApp();
    app.journal.load(
      MoodJournal.empty()
          .withTap(Mood.happy, app.clock)
          .withTap(Mood.happy, app.clock)
          .withTap(Mood.sad, app.clock),
    );
    await app.journal.setNote(
      app.journal.journal.days.single.day,
      note: 'a note',
    );
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text(moodEmoji(Mood.happy)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(
      find.text(ko.dayDetail_moodCount(ko.moodSelect_moodHappy, 2)),
      findsOneWidget,
    );
    expect(
      find.text(ko.dayDetail_moodCount(ko.moodSelect_moodSad, 1)),
      findsOneWidget,
    );
    expect(find.text(ko.dayDetail_happySide), findsOneWidget);
    expect(find.text(ko.dayDetail_sadSide), findsOneWidget);
    expect(find.text('a note'), findsOneWidget);
  });

  testWidgets('a day in the future cannot be opened', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayDetailScreen), findsNothing);
  });

  testWidgets('an empty day tells there is nothing', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(ko.dayDetail_empty), findsOneWidget);
  });

  testWidgets('back returns to the picker', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.bySemanticsLabel(ko.common_back), findsOneWidget);
  });

  testWidgets('the bars are black and gray, with colors only in faces', (
    tester,
  ) async {
    final app = TestApp();
    app.journal.load(MoodJournal.empty().withTap(Mood.happy, app.clock));
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text(moodEmoji(Mood.happy)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.constraints?.maxHeight == 10)
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(bars, isNotEmpty);
    expect(bars, everyElement(lightPalette.ink));
  });
}

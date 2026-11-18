import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/pressable_surface.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/screens/calendar_screen.dart';
import 'package:mood_clicker/screens/day_detail_screen.dart';
import 'package:mood_clicker/screens/mood_labels.dart';

import 'fake_app.dart';

void main() {
  Color? shadeOf(WidgetTester tester, String day) => tester
      .widget<PressableSurface>(
        find.ancestor(
          of: find.text(day),
          matching: find.byType(PressableSurface),
        ),
      )
      .color;

  MoodJournal tapped(Mood mood, DateTime at, int times) {
    var journal = MoodJournal.empty();
    for (var i = 0; i < times; i++) {
      journal = journal.withTap(mood, at);
    }
    return journal;
  }

  testWidgets('a day with taps is gray, darker the more it was tapped', (
    tester,
  ) async {
    final app = TestApp();
    var journal = tapped(Mood.happy, DateTime(2026, 11, 3, 9), 5);
    for (var i = 0; i < 30; i++) {
      journal = journal.withTap(Mood.happy, DateTime(2026, 11, 4, 9));
    }
    for (var i = 0; i < 70; i++) {
      journal = journal.withTap(Mood.happy, DateTime(2026, 11, 5, 9));
    }
    app.journal.load(journal);
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    final empty = shadeOf(tester, '2');
    final light = shadeOf(tester, '3');
    final mid = shadeOf(tester, '4');
    final dark = shadeOf(tester, '5');
    expect(empty, lightPalette.ground);
    expect({light, mid, dark}.length, 3);
    double luma(Color? c) => c!.computeLuminance();
    expect(luma(light), greaterThan(luma(mid)));
    expect(luma(mid), greaterThan(luma(dark)));
  });

  testWidgets('the grid has no faces and no color: every shade is gray', (
    tester,
  ) async {
    final app = TestApp();
    var journal = MoodJournal.empty();
    for (final mood in Mood.values) {
      journal = journal.withTap(mood, DateTime(2026, 11, 3 + mood.index, 9));
    }
    app.journal.load(journal);
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    for (final mood in Mood.values) {
      expect(find.text(moodEmoji(mood)), findsNothing);
      final color = shadeOf(tester, '${3 + mood.index}')!;
      final hsl = HSLColor.fromColor(color);
      expect(
        hsl.saturation,
        lessThan(0.15),
        reason: '${mood.id} must not be colored',
      );
    }
  });

  testWidgets('a low mood is not drawn differently from a high one', (
    tester,
  ) async {
    final app = TestApp();
    var journal = MoodJournal.empty();
    for (var i = 0; i < 20; i++) {
      journal = journal
          .withTap(Mood.sad, DateTime(2026, 11, 3, 9))
          .withTap(Mood.happy, DateTime(2026, 11, 4, 9));
    }
    app.journal.load(journal);
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(shadeOf(tester, '3'), shadeOf(tester, '4'));
  });

  testWidgets('a day without taps stays empty', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    for (final mood in Mood.values) {
      expect(find.text(moodEmoji(mood)), findsNothing);
    }
    expect(shadeOf(tester, '10'), lightPalette.ground);
  });

  testWidgets(
    'the previous month opens, and the next month is closed in the current one',
    (tester) async {
      final app = TestApp();
      app.journal.load(tapped(Mood.excited, DateTime(2026, 10, 20, 9), 30));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      await tester.tap(find.bySemanticsLabel(ko.calendar_prevMonth));
      await tester.pump();
      expect(shadeOf(tester, '20'), isNot(lightPalette.ground));
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pump();
      expect(find.text('30'), findsOneWidget);
      // Already on the current month: the next button does nothing.
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pump();
      expect(find.text('30'), findsOneWidget);
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
    await tester.tap(find.text('18'));
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
    expect(find.text(moodEmoji(Mood.happy)), findsWidgets);
    expect(find.text(ko.dayDetail_note), findsOneWidget);
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
    await tester.tap(find.text('18'));
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

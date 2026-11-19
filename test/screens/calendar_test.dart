import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/day_shade.dart';
import 'package:mood_clicker/design/parts/mood_face.dart';
import 'package:mood_clicker/design/parts/month_flow_bars.dart';
import 'package:mood_clicker/design/parts/pressable_surface.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/screens/calendar_screen.dart';
import 'package:mood_clicker/screens/day_detail_screen.dart';

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

  testWidgets(
    'the grid has no faces, and each mood tints its day in its own color',
    (tester) async {
      final app = TestApp();
      var journal = MoodJournal.empty();
      for (final mood in Mood.values) {
        for (var i = 0; i < 20; i++) {
          journal = journal.withTap(
            mood,
            DateTime(2026, 11, 3 + mood.index, 9),
          );
        }
      }
      app.journal.load(journal);
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      expect(
        find.descendant(
          of: find.byType(TableCalendar),
          matching: find.byType(MoodFace),
        ),
        findsNothing,
      );
      final seen = <Color>{};
      for (final mood in Mood.values) {
        final color = shadeOf(tester, '${3 + mood.index}')!;
        expect(color, DayShade.fill(lightPalette, 20, 20, mood));
        seen.add(color);
      }
      expect(seen.length, Mood.values.length);
    },
  );

  testWidgets('a day without taps stays empty', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.byType(MoodFace), findsNothing);
    expect(shadeOf(tester, '10'), lightPalette.ground);
  });

  testWidgets(
    'the previous month opens, and the next month is closed in the current one',
    (tester) async {
      final app = TestApp();
      app.journal.load(tapped(Mood.excited, DateTime(2026, 10, 20, 9), 30));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      await tester.tap(find.bySemanticsLabel(ko.calendar_prevMonth));
      await tester.pumpAndSettle();
      expect(shadeOf(tester, '20'), isNot(lightPalette.ground));
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pumpAndSettle();
      expect(find.text('30').first, findsOneWidget);
      // Already on the current month: the next button does nothing.
      await tester.tap(find.bySemanticsLabel(ko.calendar_nextMonth));
      await tester.pumpAndSettle();
      expect(find.text('30').first, findsOneWidget);
    },
  );

  testWidgets(
    'the arrows sit in the top row on round surfaces and the month flow bars render',
    (tester) async {
      final app = TestApp();
      app.journal.load(tapped(Mood.happy, DateTime(2026, 11, 3, 9), 5));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      final prevButton = find.bySemanticsLabel(ko.calendar_prevMonth);
      final nextButton = find.bySemanticsLabel(ko.calendar_nextMonth);
      expect(prevButton, findsOneWidget);
      expect(nextButton, findsOneWidget);
      // Like the sketch: the same round surface as the back button, no fill of their own.
      for (final button in [prevButton, nextButton]) {
        final surface = tester.widget<PressableSurface>(
          find.ancestor(of: button, matching: find.byType(PressableSurface)),
        );
        expect(surface.color, isNull);
      }
      final back = tester.getTopLeft(find.bySemanticsLabel(ko.common_back));
      final prev = tester.getTopLeft(prevButton);
      final month = tester.getTopLeft(
        find.text(DateFormat.MMMM('ko').format(DateTime(2026, 11))),
      );
      expect(prev.dy, back.dy, reason: 'one row with the back button');
      expect(month.dy, greaterThan(prev.dy), reason: 'the month is below it');
      expect(find.text(ko.calendar_monthFlow), findsOneWidget);
      expect(find.byType(MonthFlowBars), findsOneWidget);
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
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(
      find.bySemanticsLabel(ko.dayDetail_moodCount(ko.moodSelect_moodHappy, 2)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(ko.dayDetail_moodCount(ko.moodSelect_moodSad, 1)),
      findsOneWidget,
    );
    expect(find.text(ko.dayDetail_happySide), findsOneWidget);
    expect(find.text(ko.dayDetail_sadSide), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DayDetailScreen),
        matching: find.text('"a note"'),
      ),
      findsOneWidget,
    );
    expect(find.byType(MoodFace), findsWidgets);
    expect(find.text(ko.dayDetail_weekReview), findsOneWidget);
  });

  testWidgets('a day in the future cannot be opened', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('30').last);
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailScreen), findsNothing);
  });

  testWidgets('an empty day tells there is nothing', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('5').first);
    await tester.pump();
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DayDetailScreen),
        matching: find.text(ko.dayDetail_empty),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back returns to the picker', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.bySemanticsLabel(ko.common_back), findsOneWidget);
  });

  testWidgets('the mood bars of the detail are drawn in the mood colors', (
    tester,
  ) async {
    final app = TestApp();
    app.journal.load(MoodJournal.empty().withTap(Mood.happy, app.clock));
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.constraints?.maxHeight == 12 && c.decoration != null)
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(bars, isNotEmpty);
    expect(
      bars,
      everyElement(
        anyOf([for (final mood in Mood.values) lightPalette.moodColor(mood)]),
      ),
    );
  });

  testWidgets('today button shows on past months and jumps back', (
    tester,
  ) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.text(ko.calendar_today), findsNothing);
    await tester.tap(find.bySemanticsLabel(ko.calendar_prevMonth));
    await tester.pumpAndSettle();
    expect(find.text(ko.calendar_today), findsOneWidget);
    await tester.tap(find.text(ko.calendar_today));
    await tester.pumpAndSettle();
    expect(find.text(ko.calendar_today), findsNothing);
  });

  testWidgets('empty month shows an empty month notice', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    expect(find.text(ko.calendar_emptyMonth), findsOneWidget);
  });

  testWidgets('day detail shows edit note button next to note', (tester) async {
    final app = TestApp();
    app.journal.load(MoodJournal.empty().withTap(Mood.happy, app.clock));
    await app.journal.setNote(
      app.journal.journal.days.single.day,
      note: 'hello',
    );
    await tester.pumpWidget(app.wrap(const CalendarScreen()));
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text(ko.dayDetail_editNote), findsOneWidget);
  });

  group('the note on the card', () {
    MoodJournal withNote({String? presetId, required String note}) =>
        MoodJournal.empty()
            .withTap(Mood.happy, DateTime(2026, 11, 18, 9))
            .withNote(
              DayKey.of(DateTime(2026, 11, 18)),
              note: note,
              presetId: presetId,
            );

    testWidgets('a ready-made sentence shows in the language of the app', (
      tester,
    ) async {
      final app = TestApp();
      app.journal.load(
        withNote(presetId: 'thanks', note: 'Something to be thankful for'),
      );
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      expect(find.text(ko.calendar_noteQuote(ko.note_presetThanks)), findsOne);
      expect(find.textContaining('thankful'), findsNothing);
    });

    testWidgets('words the user wrote are shown as they are', (tester) async {
      final app = TestApp();
      app.journal.load(withNote(note: 'my own words'));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      expect(find.text(ko.calendar_noteQuote('my own words')), findsOne);
    });

    testWidgets('a long note shows two lines and then an ellipsis', (
      tester,
    ) async {
      final app = TestApp();
      app.journal.load(withNote(note: List.filled(8, 'word').join(' ')));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      final text = tester.widget<Text>(find.textContaining('word word'));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('the day detail follows the language too', (tester) async {
      final app = TestApp();
      app.journal.load(withNote(presetId: 'calm', note: 'Felt calm'));
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      expect(find.textContaining(ko.note_presetCalm), findsOneWidget);
      expect(find.textContaining('Felt calm'), findsNothing);
    });
  });

  group('month arrows', () {
    Future<void> pumpAt(WidgetTester tester, DateTime start) async {
      final app = TestApp(start: start);
      await tester.pumpWidget(app.wrap(const CalendarScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('the arrows are focusable buttons a screen reader can tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAt(tester, DateTime(2026, 11, 18, 12));
      expect(
        find.ancestor(
          of: find.bySemanticsLabel(ko.calendar_prevMonth),
          matching: find.byType(PressableSurface),
        ),
        findsOneWidget,
      );
      tester.semantics.tap(find.semantics.byLabel(ko.calendar_prevMonth));
      await tester.pumpAndSettle();
      expect(find.text(ko.calendar_nextMonth), findsNothing);
      expect(find.textContaining('10'), findsWidgets);
      handle.dispose();
    });

    testWidgets('Tab reaches the previous arrow and Enter moves the month', (
      tester,
    ) async {
      await pumpAt(tester, DateTime(2026, 11, 18, 12));
      final prev = find.ancestor(
        of: find.bySemanticsLabel(ko.calendar_prevMonth),
        matching: find.byType(PressableSurface),
      );
      var reached = false;
      for (var i = 0; i < 8 && !reached; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        reached =
            focus?.context != null &&
            find
                .descendant(
                  of: prev,
                  matching: find.byElementPredicate(
                    (e) => identical(e, focus!.context),
                  ),
                )
                .evaluate()
                .isNotEmpty;
      }
      expect(reached, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat.MMMM('ko').format(DateTime(2026, 10))),
        findsOneWidget,
      );
    });

    testWidgets('previous month is off in January 2020 and does not assert', (
      tester,
    ) async {
      await pumpAt(tester, DateTime(2020, 1, 15, 12));
      final prev = tester.widget<PressableSurface>(
        find.ancestor(
          of: find.bySemanticsLabel(ko.calendar_prevMonth),
          matching: find.byType(PressableSurface),
        ),
      );
      expect(prev.onTap, isNull);
      await tester.tap(
        find.bySemanticsLabel(ko.calendar_prevMonth),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

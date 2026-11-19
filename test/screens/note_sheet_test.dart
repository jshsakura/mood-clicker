import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/l10n/date_labels.dart';
import 'package:mood_clicker/screens/tap/note_sheet.dart';

import 'fake_app.dart';

/// A stand-in for the day detail screen: it opens the sheet and shows whether it is still there.
class _Detail extends StatelessWidget {
  const _Detail({required this.day, this.afterComplete = false});

  final DayKey day;
  final bool afterComplete;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('detail'),
          TextButton(
            onPressed: () =>
                showNoteSheet(context, day, afterComplete: afterComplete),
            child: const Text('open'),
          ),
        ],
      ),
    ),
  );
}

Future<TestApp> openSheet(
  WidgetTester tester, {
  bool afterComplete = false,
  String? existing,
  DateTime? on,
}) async {
  final app = TestApp();
  final when = on ?? app.clock;
  app.journal.recordTap(Mood.happy, when);
  final day = DayKey.of(when);
  if (existing != null) await app.journal.setNote(day, note: existing);
  await tester.pumpWidget(
    app.wrap(_Detail(day: day, afterComplete: afterComplete)),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return app;
}

FilledButton saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  testWidgets('an empty input cannot be saved and the sheet stays', (
    tester,
  ) async {
    final app = await openSheet(tester);
    expect(saveButton(tester).onPressed, isNull);
    await tester.tap(find.text(ko.note_save), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(ko.note_title), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
    expect(app.repository.saved, isEmpty);
    await tester.enterText(find.byType(TextField), 'ok');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a disk error keeps the sheet and the draft and says so', (
    tester,
  ) async {
    final app = await openSheet(tester);
    final day = DayKey.of(app.clock);
    app.repository.saveError = const FileSystemException('disk full');
    await tester.enterText(find.byType(TextField), 'my line');
    await tester.pump();
    await tester.tap(find.text(ko.note_save));
    await tester.pumpAndSettle();
    // The store reports the failed write to the framework; the test takes it.
    expect(tester.takeException(), isA<FileSystemException>());
    expect(find.text(ko.note_title), findsOneWidget);
    expect(find.text('my line'), findsOneWidget);
    expect(find.text(ko.note_saveFailed), findsOneWidget);
    // The memory holds no line the disk does not hold.
    expect(app.journal.journal.dayOf(day).note, isNull);
    // Trying again after the disk works closes the sheet and keeps the note.
    app.repository.saveError = null;
    await tester.tap(find.text(ko.note_save));
    await tester.pumpAndSettle();
    expect(find.text(ko.note_title), findsNothing);
    expect(app.journal.journal.dayOf(day).note, 'my line');
  });

  testWidgets(
    'closing the sheet while it saves does not close the screen below',
    (tester) async {
      final app = await openSheet(tester);
      final gate = Completer<void>();
      app.repository.saveGate = gate.future;
      await tester.enterText(find.byType(TextField), 'slow one');
      await tester.pump();
      await tester.tap(find.text(ko.note_save));
      await tester.pump();
      // The sheet cannot be dismissed by back or by the barrier while it saves.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text(ko.note_title), findsOneWidget);
      // Even when the sheet is removed some other way, the late callback pops nothing more.
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text(ko.note_title), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    },
  );

  testWidgets('the reason line shows only when the gauge was just filled', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text(ko.note_reason), findsNothing);
    expect(find.text(ko.note_privacy), findsOneWidget);
  });

  testWidgets('the reason line shows after the gauge was filled', (
    tester,
  ) async {
    await openSheet(tester, afterComplete: true);
    expect(find.text(ko.note_reason), findsOneWidget);
    expect(find.text(ko.note_privacy), findsOneWidget);
  });

  testWidgets('the sheet opens with the line already on the day and edits it', (
    tester,
  ) async {
    final app = await openSheet(tester, existing: 'first');
    expect(find.text('first'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'second');
    await tester.pump();
    await tester.tap(find.text(ko.note_save));
    await tester.pumpAndSettle();
    expect(app.journal.journal.dayOf(DayKey.of(app.clock)).note, 'second');
  });

  testWidgets(
    '320x568, 1.5x text and a 330 px keyboard: the buttons are reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 330);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });
      final app = await openSheet(tester, afterComplete: true);
      expect(tester.takeException(), isNull);
      final save = tester.getRect(find.byType(FilledButton));
      expect(save.bottom, lessThanOrEqualTo(568 - 330));
      expect(save.top, greaterThanOrEqualTo(0));
      // With the keyboard open: type, save with a real tap.
      await tester.enterText(find.byType(TextField), 'tiny phone');
      await tester.pump();
      await tester.tap(find.text(ko.note_save));
      await tester.pumpAndSettle();
      expect(
        app.journal.journal.dayOf(DayKey.of(app.clock)).note,
        'tiny phone',
      );
      expect(find.text(ko.note_title), findsNothing);
    },
  );

  testWidgets('the body scrolls when the keyboard leaves little room', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 330);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await openSheet(tester);
    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('while it saves the field and the sentences are locked', (
    tester,
  ) async {
    final app = await openSheet(tester);
    final gate = Completer<void>();
    app.repository.saveGate = gate.future;
    await tester.enterText(find.byType(TextField), 'slow one');
    await tester.pump();
    await tester.tap(find.text(ko.note_save));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.text(ko.note_presetProud), warnIfMissed: false);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'slow one');
    gate.complete();
    await tester.pumpAndSettle();
    expect(app.journal.journal.dayOf(DayKey.of(app.clock)).note, 'slow one');
  });

  testWidgets('a day that is not today is named by its date', (tester) async {
    final past = DateTime(2026, 11, 10, 12);
    await openSheet(tester, on: past);
    expect(find.text(ko.note_title), findsNothing);
    expect(
      find.text(ko.note_titleOn(dayTitle(const Locale('ko'), past))),
      findsOneWidget,
    );
  });

  testWidgets('today keeps the plain title', (tester) async {
    await openSheet(tester);
    expect(find.text(ko.note_title), findsOneWidget);
  });
}

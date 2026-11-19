import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/month_flow_bars.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';

const _taps = [10, 0, 40, 25, 5];
const List<Mood?> _moods = [
  Mood.happy,
  null,
  Mood.angry,
  Mood.sad,
  Mood.anxious,
];

String _label(int day) => 'Nov $day, ${_taps[day - 1]} taps';

Widget _host({
  required List<int> picked,
  int? lastDay,
  VoidCallback? onOutside,
}) {
  return MaterialApp(
    theme: buildTheme(lightPalette),
    home: Scaffold(
      body: Column(
        children: [
          GestureDetector(
            key: const Key('outside'),
            behavior: HitTestBehavior.opaque,
            onTap: onOutside,
            child: const SizedBox(width: 300, height: 100),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MonthFlowBars(
              taps: _taps,
              moods: _moods,
              picked: picked.isEmpty ? null : picked.last,
              lastDay: lastDay,
              onPick: picked.add,
              label: _label,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  Finder barOf(int day) => find.bySemanticsLabel(_label(day));

  testWidgets('pressing a bar opens a bubble with its date and taps', (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(_host(picked: picked));
    expect(find.text(_label(3)), findsNothing);
    await tester.tap(barOf(3));
    await tester.pump();
    expect(find.text(_label(3)), findsOneWidget);
    expect(picked, [3]);
  });

  testWidgets('pressing and holding a bar opens the bubble too', (
    tester,
  ) async {
    await tester.pumpWidget(_host(picked: []));
    await tester.longPress(barOf(4));
    await tester.pump();
    expect(find.text(_label(4)), findsOneWidget);
  });

  testWidgets('another bar moves the bubble, one bubble at a time', (
    tester,
  ) async {
    await tester.pumpWidget(_host(picked: []));
    await tester.tap(barOf(3));
    await tester.pump();
    await tester.tap(barOf(5));
    await tester.pump();
    expect(find.text(_label(3)), findsNothing);
    expect(find.text(_label(5)), findsOneWidget);
  });

  testWidgets('a press anywhere else closes the bubble', (tester) async {
    await tester.pumpWidget(_host(picked: []));
    await tester.tap(barOf(3));
    await tester.pump();
    expect(find.text(_label(3)), findsOneWidget);
    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(find.text(_label(3)), findsNothing);
  });

  testWidgets('the bubble stays inside the bars at both ends', (tester) async {
    await tester.pumpWidget(_host(picked: []));
    final bars = tester.getRect(find.byType(MonthFlowBars));
    for (final day in [1, 5]) {
      await tester.tap(barOf(day));
      await tester.pump();
      final bubble = tester.getRect(find.text(_label(day)));
      expect(bubble.left, greaterThanOrEqualTo(bars.left));
      expect(bubble.right, lessThanOrEqualTo(bars.right));
    }
  });

  testWidgets('each bar has the date and taps as its accessible name', (
    tester,
  ) async {
    await tester.pumpWidget(_host(picked: []));
    final handle = tester.ensureSemantics();
    for (var day = 1; day <= _taps.length; day++) {
      expect(find.bySemanticsLabel(_label(day)), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('a day after the last one cannot be pressed', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(_host(picked: picked, lastDay: 3));
    await tester.tap(barOf(5));
    await tester.pump();
    expect(picked, isEmpty);
    expect(find.text(_label(5)), findsNothing);
  });

  testWidgets('a bar is drawn in the color of its mood', (tester) async {
    await tester.pumpWidget(_host(picked: [3]));
    final colors = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(MonthFlowBars),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => (b.decoration as BoxDecoration).color)
        .whereType<Color>()
        .toList();
    expect(colors, contains(lightPalette.moodAngry));
    expect(colors, contains(lightPalette.moodSad));
    expect(colors, contains(lightPalette.line), reason: 'a day without taps');
  });
}

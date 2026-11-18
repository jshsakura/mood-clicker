import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/app_services.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/screens/calendar_screen.dart';
import 'package:mood_clicker/screens/day_detail_screen.dart';
import 'package:mood_clicker/screens/loading_screen.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';

import '../domain/cheer_fixtures.dart';
import '../screens/fake_app.dart';

/// A fixed week of taps, so every shot draws the same thing.
MoodJournal sampleJournal(DateTime today) {
  var journal = MoodJournal.empty();
  void tap(int dayOffset, Mood mood, int times) {
    final at = today.subtract(Duration(days: dayOffset));
    for (var i = 0; i < times; i++) {
      journal = journal.withTap(mood, at);
    }
  }

  tap(0, Mood.happy, 42);
  tap(0, Mood.excited, 12);
  tap(0, Mood.anxious, 5);
  tap(1, Mood.sad, 30);
  tap(2, Mood.angry, 18);
  tap(3, Mood.happy, 25);
  tap(5, Mood.anxious, 40);
  tap(8, Mood.excited, 22);
  tap(9, Mood.sad, 9);
  tap(12, Mood.happy, 60);
  return journal;
}

/// English phrases that fit the layout. The shot is about the screen, not the real phrase pack.
CheerBook shotBook() {
  const phrases = ['Nice!', 'Keep going', 'You got it', 'Yes'];
  return CheerBook.parse(
    fileOf({
      for (final mood in Mood.values)
        mood.id: {for (final stage in CheerStage.values) stage.id: phrases},
    }),
  ).book;
}

TestApp shotApp({bool holdLoading = false}) {
  final app = TestApp(
    book: shotBook(),
    repository: holdLoading
        ? MemoryRepository(gate: Completer<void>().future)
        : null,
  );
  app.journal.load(sampleJournal(app.clock));
  return app;
}

/// The widget a shot shows: [child] inside an [AppScope] with fake services.
Widget scoped(TestApp app, Widget child) =>
    AppScope(services: app.services, child: child);

final shotScreens =
    <
      ({
        String name,
        Widget Function(TestApp) build,
        Future<void> Function(WidgetTester, TestApp)? act,
      })
    >[
      (
        name: 'loading',
        build: (_) => const LoadingScreen(),
        act: (tester, app) async {},
      ),
      (name: 'mood_select', build: (_) => const MoodSelectScreen(), act: null),
      (name: 'calendar', build: (_) => const CalendarScreen(), act: null),
      (
        name: 'day_detail',
        build: (app) => DayDetailScreen(day: DayKey.of(app.clock)),
        act: null,
      ),
      (
        name: 'tap',
        build: (_) => TapScreen(mood: Mood.happy, random: Random(3)),
        act: (tester, app) async {
          for (var i = 0; i < 36; i++) {
            final x = i.isEven ? 90.0 : 300.0;
            await tester.tapAt(Offset(x, 520 + (i % 5) * 20));
            // Real frame times, so the water follows the way it does on a phone.
            for (var frame = 0; frame < 7; frame++) {
              app.advance(const Duration(milliseconds: 17));
              await tester.pump(const Duration(milliseconds: 17));
            }
          }
        },
      ),
    ];

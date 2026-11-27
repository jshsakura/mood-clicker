import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app/journal_store.dart';
import '../domain/day_key.dart';
import '../domain/mood.dart';
import 'map_server.dart';

/// Sends today's counts to the shared map while "share my mood on the map" is on, and deletes
/// what was sent when it is turned off.
///
/// It waits [delay] after the journal last changed, so one tapping run is one send. Each mood that
/// changed since the last send goes out with the cell the phone is in now. A failed send is tried
/// again on the next change.
class MapSharer {
  MapSharer({
    required this.journal,
    required this.contribute,
    required this.server,
    required this.currentCell,
    DateTime Function()? now,
    this.delay = const Duration(seconds: 4),
  }) : _now = now ?? DateTime.now;

  final JournalStore journal;
  final ValueListenable<bool> contribute;
  final MapServer server;

  /// The H3 cell of the phone as a number, or null without a position. The position itself
  /// never leaves this call.
  final Future<int?> Function() currentCell;
  final Duration delay;
  final DateTime Function() _now;

  Timer? _timer;
  final Map<Mood, int> _sent = {};
  DayKey? _sentDay;
  bool _wasOn = false;

  void start() {
    _wasOn = contribute.value;
    journal.addListener(_schedule);
    contribute.addListener(_onSwitch);
    _schedule();
  }

  void stop() {
    _timer?.cancel();
    journal.removeListener(_schedule);
    contribute.removeListener(_onSwitch);
  }

  void _schedule() {
    if (!contribute.value) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(send()));
  }

  void _onSwitch() {
    final on = contribute.value;
    if (on == _wasOn) return;
    _wasOn = on;
    if (on) {
      _schedule();
      return;
    }
    _timer?.cancel();
    _sent.clear();
    unawaited(_guard(server.deleteMyData));
  }

  /// Sends what changed today. Public so tests and app resume can call it at once.
  Future<void> send() async {
    if (!contribute.value || !journal.isLoaded) return;
    final day = DayKey.of(_now());
    if (_sentDay != day) {
      _sent.clear();
      _sentDay = day;
    }
    final record = journal.journal.dayOf(day);
    final changed = [
      for (final mood in Mood.values)
        if (record.countOf(mood) > 0 && _sent[mood] != record.countOf(mood))
          mood,
    ];
    if (changed.isEmpty) return;
    final cell = await currentCell();
    if (cell == null) return;
    for (final mood in changed) {
      final taps = record.countOf(mood);
      final ok = await _guard(
        () => server.putDrop(day: day, cell: cell, mood: mood, taps: taps),
      );
      if (!ok) return;
      _sent[mood] = taps;
    }
  }

  Future<bool> _guard(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'map'),
      );
      return false;
    }
  }
}

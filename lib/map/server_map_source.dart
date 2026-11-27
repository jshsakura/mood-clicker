import 'package:flutter/foundation.dart';

import '../domain/day_key.dart';
import '../domain/mood.dart';
import 'map_rules.dart';
import 'map_server.dart';
import 'map_source.dart';

/// The map from the shared server. A cell carries no word: words are not collected.
class ServerMapSource implements MapSource {
  ServerMapSource(this.server, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MapServer server;
  final DateTime Function() _now;

  @override
  Future<MapSnapshot> load(MapRange range, List<H3CellId> cells) async {
    final today = _now();
    final first = range == MapRange.week
        ? today.subtract(const Duration(days: 6))
        : today;
    try {
      final rows = await server.load(
        from: DayKey.of(first),
        to: DayKey.of(today),
        cells: [for (final id in cells) int.parse(id.value, radix: 16)],
      );
      return MapSnapshot(cells: [for (final row in rows) cellOf(row)]);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'map'),
      );
      return MapSnapshot(cells: const []);
    }
  }

  /// The face is the mood with the most taps; the happy share counts taps on the happy side.
  @visibleForTesting
  static MapCell cellOf(ServerCell row) {
    var top = Mood.values.first;
    var total = 0;
    var happy = 0;
    for (final mood in Mood.values) {
      final n = row.taps[mood] ?? 0;
      total += n;
      if (mood.side == MoodSide.happy) happy += n;
      if (n > (row.taps[top] ?? 0)) top = mood;
    }
    return MapCell(
      id: H3CellId(row.cell.toRadixString(16).padLeft(15, '0')),
      mood: top,
      people: row.people,
      taps: total,
      happyShare: total == 0 ? 0 : happy / total,
    );
  }
}

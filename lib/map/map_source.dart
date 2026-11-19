/// Where the map data comes from. The port speaks blocks and counts only; there is no place in it
/// for an exact position, in either direction. A real source (planned: Supabase with anonymous sign-in,
/// Postgres and H3 blocks) keys everything by H3 cell id, and the position never leaves the
/// device finer than that id.
library;

import 'package:flutter/foundation.dart';

import 'map_rules.dart';

abstract interface class MapSource {
  Future<MapSnapshot> load(MapRange range);
}

/// Made-up data on the device, until a server exists. Includes a few blocks under the minimum
/// on purpose, so the hiding rule shows up in the picture.
class SampleMapSource implements MapSource {
  const SampleMapSource();

  static final H3CellId _viewer = _id(0);

  /// Made-up block ids that pass the H3 header check.
  static H3CellId _id(int n) =>
      H3CellId('87${n.toRadixString(16).padLeft(13, '0')}');

  static const List<(int, int, int, int, int, MapWord)> _rows = [
    // east km, north km, people, taps, happy percent, word
    (-1, 2, 23, 3100, 72, MapWord.smiled),
    (1, 1, 9, 640, 38, MapWord.rest),
    (0, 0, 31, 5200, 80, MapWord.ateWell),
    (1, -1, 12, 980, 30, MapWord.betterThanExpected),
    (-2, -1, 7, 410, 58, MapWord.tomorrowToo),
    (0, -3, 18, 2300, 66, MapWord.thankful),
    (2, 3, 6, 260, 55, MapWord.smiled),
    (-2, 0, 8, 720, 44, MapWord.rest),
    (2, -2, 3, 90, 60, MapWord.thankful),
    (-1, -3, 4, 120, 20, MapWord.rest),
  ];

  @visibleForTesting
  static List<(int, int, int, int, int, MapWord)> get rowsForTest => _rows;

  @override
  Future<MapSnapshot> load(MapRange range) async {
    final factor = range == MapRange.week ? 4 : 1;
    return MapSnapshot(
      viewer: _viewer,
      cells: [
        for (final (i, (east, north, people, taps, happy, word))
            in _rows.indexed)
          MapCell(
            id: _id(i),
            eastKm: east.toDouble(),
            northKm: north.toDouble(),
            people: people * factor,
            taps: taps * factor,
            happyShare: happy / 100,
            word: word,
          ),
      ],
    );
  }
}

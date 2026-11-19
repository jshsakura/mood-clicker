/// Where the map data comes from. The port speaks blocks and counts only; there is no place in it
/// for an exact position, in either direction: the screen asks for blocks by H3 id and gets
/// counts per id. A real source (planned: a SupabaseMapSource with anonymous sign-in, Postgres
/// and H3 blocks) plugs into this same port without a change to the screen. The position never
/// leaves the device finer than a block id.
library;

import 'package:flutter/foundation.dart';

import '../domain/mood.dart';
import 'map_rules.dart';

abstract interface class MapSource {
  /// What is known about [cells] for [range]. Blocks with no data are left out.
  Future<MapSnapshot> load(MapRange range, List<H3CellId> cells);
}

/// Made-up data on the device, until a server exists. It makes believable blocks for whatever
/// blocks are asked for, and the same id always gets the same block, so the map looks the same
/// wherever and whenever it is opened. A share of the blocks fall under the minimum on purpose,
/// so the hiding rule shows up in the picture.
class SampleMapSource implements MapSource {
  const SampleMapSource();

  /// Out of every [_present] + [_absent] blocks, [_present] have data.
  static const int _present = 7;
  static const int _absent = 3;

  @override
  Future<MapSnapshot> load(MapRange range, List<H3CellId> cells) async {
    final factor = range == MapRange.week ? 4 : 1;
    return MapSnapshot(cells: [for (final id in cells) ?_cellOf(id, factor)]);
  }

  /// FNV-1a over the id text: the same on every device and run, unlike hashCode.
  @visibleForTesting
  static int seedOf(H3CellId id) {
    var hash = 0x811c9dc5;
    for (final unit in id.value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static MapCell? _cellOf(H3CellId id, int factor) {
    final seed = seedOf(id);
    if (seed % (_present + _absent) >= _present) return null;
    final people = 2 + (seed >> 4) % 38;
    final taps = people * (20 + (seed >> 10) % 120);
    final happy = (seed >> 16) % 101 / 100;
    return MapCell(
      id: id,
      mood: _moodOf(happy, seed >> 8),
      people: people * factor,
      taps: taps * factor,
      happyShare: happy,
      word: MapWord.values[(seed >> 20) % MapWord.values.length],
    );
  }

  /// The face of a block follows its mood of the day: a happy side block shows one of the happy
  /// moods, the others one of the sad side moods.
  static Mood _moodOf(double happyShare, int pick) {
    final side = happyShare >= 0.5 ? MoodSide.happy : MoodSide.sad;
    final moods = [
      for (final mood in Mood.values)
        if (mood.side == side) mood,
    ];
    return moods[pick % moods.length];
  }
}

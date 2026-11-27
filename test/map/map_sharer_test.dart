import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/map/map_server.dart';
import 'package:mood_clicker/map/map_sharer.dart';

import '../screens/fake_app.dart';

class _FakeServer implements MapServer {
  final List<(Mood, int, int)> puts = [];
  int deletes = 0;
  bool fail = false;

  @override
  Future<void> putDrop({
    required DayKey day,
    required int cell,
    required Mood mood,
    required int taps,
  }) async {
    if (fail) throw const MapServerError(503, 'put_mood_drop');
    puts.add((mood, taps, cell));
  }

  @override
  Future<List<ServerCell>> load({
    required DayKey from,
    required DayKey to,
    required List<int> cells,
  }) async => const [];

  @override
  Future<void> deleteMyData() async => deletes++;
}

void main() {
  final clock = DateTime(2026, 11, 27, 12);

  ({
    JournalStore journal,
    ValueNotifier<bool> on,
    _FakeServer server,
    MapSharer sharer,
  })
  setUpSharer({bool on = true, int? cell = 99}) {
    final journal = JournalStore(MemoryRepository());
    final contribute = ValueNotifier(on);
    final server = _FakeServer();
    final sharer = MapSharer(
      journal: journal,
      contribute: contribute,
      server: server,
      currentCell: () async => cell,
      now: () => clock,
      delay: const Duration(hours: 1),
    );
    return (journal: journal, on: contribute, server: server, sharer: sharer);
  }

  test(
    'sends each mood of today once, and again only when it changed',
    () async {
      final s = setUpSharer();
      s.journal.load(
        MoodJournal.empty()
            .withTap(Mood.sad, clock)
            .withTap(Mood.sad, clock)
            .withTap(Mood.happy, clock),
      );
      await s.sharer.send();
      expect(
        s.server.puts,
        containsAll([(Mood.sad, 2, 99), (Mood.happy, 1, 99)]),
      );
      await s.sharer.send();
      expect(s.server.puts, hasLength(2));
      s.journal.load(s.journal.journal.withTap(Mood.sad, clock));
      await s.sharer.send();
      expect(s.server.puts.last, (Mood.sad, 3, 99));
    },
  );

  test('sends nothing while the switch is off', () async {
    final s = setUpSharer(on: false);
    s.journal.load(MoodJournal.empty().withTap(Mood.sad, clock));
    await s.sharer.send();
    expect(s.server.puts, isEmpty);
  });

  test('sends nothing without a position', () async {
    final s = setUpSharer(cell: null);
    s.journal.load(MoodJournal.empty().withTap(Mood.sad, clock));
    await s.sharer.send();
    expect(s.server.puts, isEmpty);
  });

  test('a failed send goes out on the next try', () async {
    final s = setUpSharer();
    s.journal.load(MoodJournal.empty().withTap(Mood.sad, clock));
    s.server.fail = true;
    await s.sharer.send();
    s.server.fail = false;
    await s.sharer.send();
    expect(s.server.puts, [(Mood.sad, 1, 99)]);
  });

  test('turning the switch off deletes what was sent', () async {
    final s = setUpSharer();
    s.sharer.start();
    s.on.value = false;
    await Future<void>.delayed(Duration.zero);
    expect(s.server.deletes, 1);
    s.sharer.stop();
  });
}

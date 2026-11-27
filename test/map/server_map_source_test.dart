import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/map/map_server.dart';
import 'package:mood_clicker/map/server_map_source.dart';

void main() {
  test('a server cell shows its top mood, its happy share and no word', () {
    final cell = ServerMapSource.cellOf(
      const ServerCell(
        cell: 0x87283082bffffff,
        people: 6,
        taps: {
          Mood.happy: 4,
          Mood.excited: 2,
          Mood.angry: 9,
          Mood.sad: 1,
          Mood.anxious: 0,
        },
      ),
    );
    expect(cell.id.value, '87283082bffffff');
    expect(cell.mood, Mood.angry);
    expect(cell.people, 6);
    expect(cell.taps, 16);
    expect(cell.happyShare, closeTo(6 / 16, 1e-9));
    expect(cell.word, isNull);
  });
}

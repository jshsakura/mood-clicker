import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/map/map_rules.dart';
import 'package:mood_clicker/map/map_source.dart';

H3CellId _id(int n) => H3CellId('87${n.toRadixString(16).padLeft(13, '0')}');

MapCell cell(int row, int people, {double happy = 0.5}) => MapCell(
  id: _id(row),
  eastKm: 0,
  northKm: 0,
  people: people,
  taps: people * 10,
  happyShare: happy,
  word: MapWord.smiled,
);

void main() {
  group('H3 block ids', () {
    test('a resolution 7 cell id is accepted', () {
      expect(H3CellId.isValid('871fb4660ffffff'), isTrue);
      expect(H3CellId('871fb4660ffffff').value, '871fb4660ffffff');
    });

    test('ids of another resolution, mode or shape are refused', () {
      for (final bad in [
        '8928308280fffff', // resolution 9
        '881fb4660ffffff', // resolution 8
        '971fb4660ffffff', // not a cell
        '871fb4660fffff', // too short
        '871FB4660FFFFFF', // upper case
        '0.50,0.50', // a position is not an id
        '',
      ]) {
        expect(H3CellId.isValid(bad), isFalse, reason: bad);
        expect(() => H3CellId(bad), throwsFormatException);
      }
    });

    test('the block size is H3 resolution 7', () {
      expect(MapRules.h3Resolution, 7);
    });
  });

  group('hiding small places', () {
    test('the minimum is five people', () => expect(MapRules.minPeople, 5));

    test('a block with fewer than five people is dropped', () {
      final snap = MapSnapshot(
        viewer: _id(0),
        cells: [cell(0, 4), cell(1, 5), cell(2, 1), cell(3, 99)],
      );
      expect([for (final c in snap.cells) c.people], [5, 99]);
    });

    test('totals count the shown blocks only', () {
      final snap = MapSnapshot(viewer: _id(0), cells: [cell(0, 4), cell(1, 6)]);
      expect(snap.people, 6);
      expect(snap.taps, 60);
    });

    test('nothing shown means no share', () {
      final snap = MapSnapshot(viewer: _id(0), cells: [cell(0, 2)]);
      expect(snap.cells, isEmpty);
      expect(snap.happyShare, isNull);
    });

    test('the share is weighted by people', () {
      final snap = MapSnapshot(
        viewer: _id(0),
        cells: [cell(0, 5, happy: 1), cell(1, 15, happy: 0)],
      );
      expect(snap.happyShare, closeTo(0.25, 1e-9));
    });

    test('the sample source never returns a small block', () async {
      for (final range in MapRange.values) {
        final snap = await const SampleMapSource().load(range);
        expect(snap.cells, isNotEmpty);
        expect(snap.cells.every((c) => c.people >= MapRules.minPeople), isTrue);
      }
    });

    test('the sample source does include small blocks that get hidden', () {
      // Guards the sample data: if it had none, the rule would show nothing in the picture.
      final raw = SampleMapSource.rowsForTest;
      expect(raw.any((r) => r.$3 < MapRules.minPeople), isTrue);
    });

    test('the ratio shows by default, like the weather of a place', () {
      expect(MapRules.showMoodRatio, isTrue);
    });
  });

  group('ratio policy', () {
    test('the constants start as the owner asked', () {
      expect(MapRules.showMoodRatio, isTrue);
      expect(MapRules.ratioStyle, RatioStyle.percent);
      expect(MapRules.hideRatioAfterHeavyMood, isFalse);
      const policy = RatioPolicy();
      expect(policy.show, MapRules.showMoodRatio);
      expect(policy.style, MapRules.ratioStyle);
      expect(policy.hideAfterHeavyMood, MapRules.hideRatioAfterHeavyMood);
    });

    test('every combination of show and hide-after-heavy', () {
      for (final show in [true, false]) {
        for (final hide in [true, false]) {
          for (final mood in [null, ...Mood.values]) {
            final policy = RatioPolicy(show: show, hideAfterHeavyMood: hide);
            final heavy = mood?.side == MoodSide.sad;
            expect(
              policy.visible(mood),
              show && !(hide && heavy),
              reason: '$show $hide ${mood?.id}',
            );
          }
        }
      }
    });

    test('the last recorded mood is the one with the latest serial', () {
      final day = DayRecord(DayKey.of(DateTime(2026, 11, 18)), {
        Mood.happy: MoodTally(
          count: 3,
          lastTapAt: DateTime(2026, 11, 18, 9),
          lastOrder: 3,
        ),
        Mood.sad: MoodTally(
          count: 2,
          lastTapAt: DateTime(2026, 11, 18, 8),
          lastOrder: 5,
        ),
      });
      expect(lastRecordedMood(day), Mood.sad);
      expect(
        lastRecordedMood(DayRecord.empty(DayKey.of(DateTime(2026, 11, 18)))),
        isNull,
      );
    });
  });

  group('no exact position through the port', () {
    test('the port and its data speak blocks, not coordinates', () {
      final text = File('lib/map/map_source.dart').readAsStringSync();
      final data = File('lib/map/map_rules.dart').readAsStringSync();
      final port = RegExp(
        r'abstract interface class MapSource \{[^}]*\}',
      ).firstMatch(text)!.group(0)!;
      expect(port, isNot(contains('double')));
      expect(port, isNot(contains('longitude')));
      expect(port, isNot(contains('lat')));
      // No latitude or longitude is accepted anywhere in the map data.
      expect(data, isNot(contains('latitude')));
      expect(data, isNot(contains('longitude')));
      final cellClass = data.substring(
        data.indexOf('class MapCell'),
        data.indexOf('class MapSnapshot'),
      );
      expect(cellClass, isNot(contains('double lat')));
      expect(cellClass, isNot(contains('latitude')));
      expect(cellClass, isNot(contains('longitude')));
    });

    test('a snapshot carries blocks and counts only', () async {
      final snap = await const SampleMapSource().load(MapRange.today);
      for (final c in snap.cells) {
        expect(H3CellId.isValid(c.id.value), isTrue);
      }
    });
  });
}

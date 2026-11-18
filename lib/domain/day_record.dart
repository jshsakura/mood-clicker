import 'package:characters/characters.dart';

import 'day_key.dart';
import 'mood.dart';
import 'tuning.dart';

class MoodTally {
  const MoodTally({
    required this.count,
    required this.lastTapAt,
    required this.lastOrder,
  });

  final int count;

  /// When the last tap happened by the device clock. Informational only.
  final DateTime lastTapAt;

  /// The serial number of the last tap within its day: 1 for the first tap of the day, counting up
  /// across all moods. "Later" always means a higher serial, so a clock set back cannot reorder taps.
  final int lastOrder;
}

/// One day of records. Updating returns a new object.
class DayRecord {
  DayRecord(
    this.day,
    Map<Mood, MoodTally> tallies, {
    this.note,
    this.notePresetId,
  }) : tallies = Map.unmodifiable(tallies);

  DayRecord.empty(DayKey day) : this(day, const {});

  final DayKey day;
  final Map<Mood, MoodTally> tallies;

  /// The user's line for the day. At most [NoteTuning.maxLength] characters, on this device only.
  final String? note;

  /// The id of the ready-made sentence the user picked. This is the only part of the note that
  /// may ever leave the device (for the map). The sentences themselves live in the translations.
  final String? notePresetId;

  static final RegExp _presetPattern = RegExp(r'^[a-z0-9_]+$');

  /// The note trimmed, or null when it is blank. Throws [ArgumentError] when it is longer than
  /// [NoteTuning.maxLength] characters or has a line break or other control character.
  static String? cleanNote(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.runes.any((r) => r < 0x20 || r == 0x7f)) {
      throw ArgumentError.value(
        raw,
        'note',
        'a note is one line of plain text',
      );
    }
    if (text.characters.length > NoteTuning.maxLength) {
      throw ArgumentError.value(
        raw,
        'note',
        'at most ${NoteTuning.maxLength} characters',
      );
    }
    return text;
  }

  /// Throws [ArgumentError] unless the id is a short lowercase id. Null is allowed.
  static String? checkPresetId(String? id) {
    if (id == null) return null;
    if (id.length > NoteTuning.maxPresetIdLength ||
        !_presetPattern.hasMatch(id)) {
      throw ArgumentError.value(id, 'presetId', 'not a valid preset id');
    }
    return id;
  }

  /// Replaces the note and the preset id together. Call with no arguments to clear both.
  /// If the user edits the text of a picked preset, the caller passes no [presetId].
  DayRecord withNote({String? note, String? presetId}) => DayRecord(
    day,
    tallies,
    note: cleanNote(note),
    notePresetId: checkPresetId(presetId),
  );

  /// Takes [count] taps off a mood: water the phone spilled. The count never goes below zero, and
  /// a mood with no taps left disappears from the record. Tap order and the note stay as they are.
  DayRecord withTapsRemoved(Mood mood, int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
    final old = tallies[mood];
    if (old == null || count == 0) return this;
    final left = old.count - count;
    final next = {...tallies};
    if (left <= 0) {
      next.remove(mood);
    } else {
      next[mood] = MoodTally(
        count: left,
        lastTapAt: old.lastTapAt,
        lastOrder: old.lastOrder,
      );
    }
    return DayRecord(day, next, note: note, notePresetId: notePresetId);
  }

  /// Whether to show the note window when the user leaves the tap screen: only on a day the gauge
  /// was filled during this visit, and only while there is no note yet.
  bool shouldAskNote({required bool filledThisVisit}) =>
      filledThisVisit && note == null && notePresetId == null;

  int countOf(Mood mood) => tallies[mood]?.count ?? 0;

  int get total => tallies.values.fold(0, (sum, t) => sum + t.count);

  int get happyTotal => _totalOf(MoodSide.happy);

  int get sadTotal => _totalOf(MoodSide.sad);

  int _totalOf(MoodSide side) => tallies.entries
      .where((e) => e.key.side == side)
      .fold(0, (sum, e) => sum + e.value.count);

  /// The mood with the most taps. A tie goes to the one tapped last, judged by tap order and not by
  /// the clock. Null when there are no records.
  Mood? get dominantMood {
    Mood? best;
    for (final mood in Mood.values) {
      final tally = tallies[mood];
      if (tally == null) continue;
      final current = best == null ? null : tallies[best];
      if (current == null || _beats(tally, current)) best = mood;
    }
    return best;
  }

  static bool _beats(MoodTally a, MoodTally b) =>
      a.count > b.count || (a.count == b.count && a.lastOrder > b.lastOrder);

  DayRecord withTap(Mood mood, DateTime at) {
    if (DayKey.of(at) != day) {
      throw ArgumentError.value(
        at,
        'at',
        'a tap on another day cannot go into the record of $day',
      );
    }
    final old = tallies[mood];
    final last = (old != null && old.lastTapAt.isAfter(at))
        ? old.lastTapAt
        : at;
    final order =
        tallies.values.fold(0, (m, t) => t.lastOrder > m ? t.lastOrder : m) + 1;
    return DayRecord(
      day,
      {
        ...tallies,
        mood: MoodTally(
          count: (old?.count ?? 0) + 1,
          lastTapAt: last,
          lastOrder: order,
        ),
      },
      note: note,
      notePresetId: notePresetId,
    );
  }
}

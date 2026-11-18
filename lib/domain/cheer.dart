import 'dart:convert';
import 'dart:math';

import 'fill_gauge.dart';
import 'mood.dart';
import 'tuning.dart';

/// Which phrase bundle fits the gauge: 0 to 0.5, 0.5 to 1, or full.
enum CheerStage {
  low('low'),
  high('high'),
  full('full');

  const CheerStage(this.id);
  final String id;

  double get fontSize => switch (this) {
    CheerStage.low => CheerTuning.fontSizeLow,
    CheerStage.high => CheerTuning.fontSizeHigh,
    CheerStage.full => CheerTuning.fontSizeFull,
  };

  static CheerStage of(FillGauge gauge, DateTime now) {
    if (gauge.isFullAt(now)) return CheerStage.full;
    return gauge.valueAt(now) < 0.5 ? CheerStage.low : CheerStage.high;
  }
}

/// Cheer phrases for one language: a bundle per mood and stage.
class CheerBook {
  CheerBook._(this._bundles);

  final Map<(Mood, CheerStage), List<String>> _bundles;

  List<String> bundle(Mood mood, CheerStage stage) =>
      _bundles[(mood, stage)] ?? const [];

  /// Parses `{"version":1,"moods":{"happy":{"low":[...],"high":[...],"full":[...]}}}`.
  /// Throws [FormatException] for a wrong version, an unknown mood id, a missing or empty
  /// bundle, or an entry that is not a non-empty string. Phrases longer than
  /// [CheerTuning.maxPhraseLength] only produce a warning.
  static CheerParse parse(String text) {
    final root = jsonDecode(text);
    if (root is! Map || root['version'] != 1) {
      throw const FormatException('unsupported cheer file version');
    }
    final moods = root['moods'];
    if (moods is! Map) throw const FormatException('moods is not an object');

    for (final id in moods.keys) {
      if (Mood.byId('$id') == null) {
        throw FormatException('unknown mood id: $id');
      }
    }
    final bundles = <(Mood, CheerStage), List<String>>{};
    final warnings = <String>[];
    for (final mood in Mood.values) {
      final entry = moods[mood.id];
      if (entry is! Map) throw FormatException('missing mood: ${mood.id}');
      for (final stage in CheerStage.values) {
        final phrases = _phrases(entry[stage.id], '${mood.id}/${stage.id}');
        for (final phrase in phrases) {
          if (phrase.runes.length > CheerTuning.maxPhraseLength) {
            warnings.add(
              '${mood.id}/${stage.id}: "$phrase" is longer than '
              '${CheerTuning.maxPhraseLength} characters',
            );
          }
        }
        bundles[(mood, stage)] = List.unmodifiable(phrases);
      }
    }
    return CheerParse(CheerBook._(bundles), List.unmodifiable(warnings));
  }

  static List<String> _phrases(Object? raw, String where) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException('empty or missing bundle: $where');
    }
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty)
          item
        else
          throw FormatException('bad phrase in $where'),
    ];
  }
}

class CheerParse {
  const CheerParse(this.book, this.warnings);
  final CheerBook book;
  final List<String> warnings;
}

/// Picks one phrase per tap. A phrase picked within the last
/// [CheerTuning.recentWindow] picks is not picked again; a bundle of
/// [CheerTuning.smallBundle] phrases or fewer only avoids the phrase picked just before.
class CheerPicker {
  CheerPicker(this._random);

  final Random _random;
  final List<String> _recent = [];

  String pick(CheerBook book, Mood mood, CheerStage stage) {
    final bundle = book.bundle(mood, stage);
    if (bundle.isEmpty) {
      throw StateError('no phrases for ${mood.id}/${stage.id}');
    }
    final avoid = bundle.length <= CheerTuning.smallBundle
        ? _recent.reversed.take(1).toSet()
        : _recent.toSet();
    var candidates = [
      for (final phrase in bundle)
        if (!avoid.contains(phrase)) phrase,
    ];
    if (candidates.isEmpty) candidates = bundle;
    final chosen = candidates[_random.nextInt(candidates.length)];
    _recent.add(chosen);
    if (_recent.length > CheerTuning.recentWindow) {
      _recent.removeAt(0);
    }
    return chosen;
  }
}

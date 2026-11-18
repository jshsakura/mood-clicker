import 'dart:convert';
import 'dart:isolate';

import 'fill_gauge.dart';
import 'mood.dart';
import 'tuning.dart';

/// Which phrase bundle fits the gauge: 0 to 0.5, 0.5 to 1, full, or the single moment it fills.
/// How a phrase is shown. Decides its lifetime and look.
enum CheerKind {
  normal,
  rare,
  complete;

  Duration get lifetime => switch (this) {
    CheerKind.normal => CheerTuning.lifetime,
    CheerKind.rare => CheerTuning.rareLifetime,
    CheerKind.complete => CheerTuning.completeLifetime,
  };
}

enum CheerStage {
  low('low'),
  high('high'),
  full('full'),

  /// The one tap that takes the gauge from not full to full. Optional in a phrase file: without
  /// it the full bundle is used.
  complete('complete'),

  /// A rare phrase. Optional in a phrase file: without it a rare draw uses the high bundle.
  rare('rare');

  const CheerStage(this.id);
  final String id;

  static CheerStage of(FillGauge gauge, DateTime now) {
    if (gauge.justFilled) return CheerStage.complete;
    if (gauge.isFullAt(now)) return CheerStage.full;
    // A small tolerance so that 30 taps of 1/60 count as half despite float rounding.
    return gauge.valueAt(now) < 0.5 - 1e-9 ? CheerStage.low : CheerStage.high;
  }
}

/// Cheer phrases for one language: a bundle per mood and stage.
class CheerBook {
  CheerBook._(this._bundles, this._bases);

  final Map<(Mood, CheerStage), List<String>> _bundles;
  final Map<(Mood, CheerStage), List<String?>> _bases;

  /// The stage whose bundle is really used. `complete` falls back to `full` and `rare` to `high`
  /// when this mood has no such bundle.
  CheerStage effectiveStage(Mood mood, CheerStage stage) {
    if (_bundles.containsKey((mood, stage))) return stage;
    return stage == CheerStage.rare ? CheerStage.high : CheerStage.full;
  }

  List<String> bundle(Mood mood, CheerStage stage) =>
      _bundles[(mood, effectiveStage(mood, stage))] ?? const [];

  /// The base sentence id of each phrase of a bundle (same order as [bundle]), or null for a
  /// phrase written as a plain string. Variants of one base sentence share an id, so a caller can
  /// avoid showing two variants of the same base one after another.
  List<String?> bases(Mood mood, CheerStage stage) =>
      _bases[(mood, effectiveStage(mood, stage))] ?? const [];

  /// Parses `{"version":1,"moods":{"happy":{"low":[...],"high":[...],"full":[...],"complete":[...],"rare":[...]}}}`.
  /// `complete` and `rare` are optional. Throws [FormatException] for a file over [CheerTuning.maxFileBytes],
  /// a wrong version, an unknown mood id, a missing or empty bundle, or an entry that is not a
  /// non-empty string. Phrases longer than [CheerTuning.maxPhraseLength] and phrases repeated
  /// inside one bundle only produce a warning.
  static CheerParse parse(String text) {
    if (utf8.encode(text).length > CheerTuning.maxFileBytes) {
      throw const FormatException('cheer file is larger than the size cap');
    }
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
    final bases = <(Mood, CheerStage), List<String?>>{};
    final warnings = <String>[];
    for (final mood in Mood.values) {
      final entry = moods[mood.id];
      if (entry is! Map) throw FormatException('missing mood: ${mood.id}');
      for (final stage in CheerStage.values) {
        final optional =
            stage == CheerStage.complete || stage == CheerStage.rare;
        if (optional && entry[stage.id] == null) continue;
        final where = '${mood.id}/${stage.id}';
        final items = _items(entry[stage.id], where);
        final phrases = [for (final item in items) item.text];
        warnings.addAll(_warningsFor(where, phrases));
        bundles[(mood, stage)] = List.unmodifiable(phrases);
        bases[(mood, stage)] = List.unmodifiable([
          for (final item in items) item.base,
        ]);
      }
    }
    return CheerParse(CheerBook._(bundles, bases), List.unmodifiable(warnings));
  }

  /// Parses on another isolate so a large file does not block the first frames.
  /// A bad file throws [FormatException], like [parse].
  static Future<CheerParse> parseInBackground(String text) =>
      Isolate.run(() => parse(text));

  static Iterable<String> _warningsFor(
    String where,
    List<String> phrases,
  ) sync* {
    final seen = <String>{};
    final repeated = <String>{};
    for (final phrase in phrases) {
      if (phrase.runes.length > CheerTuning.maxPhraseLength) {
        yield '$where: "$phrase" is longer than '
            '${CheerTuning.maxPhraseLength} characters';
      }
      if (!seen.add(phrase) && repeated.add(phrase)) {
        yield '$where: "$phrase" is repeated';
      }
    }
  }

  /// An entry is a plain string, or `{"t": "text", "b": "base id"}` where `b` is optional.
  static List<({String text, String? base})> _items(Object? raw, String where) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException('empty or missing bundle: $where');
    }
    return [for (final item in raw) _item(item, where)];
  }

  static ({String text, String? base}) _item(Object? item, String where) {
    if (item is String && item.trim().isNotEmpty) {
      return (text: item, base: null);
    }
    if (item is Map) {
      final text = item['t'];
      final base = item['b'];
      final baseOk = base == null || (base is String && base.trim().isNotEmpty);
      if (text is String && text.trim().isNotEmpty && baseOk) {
        return (text: text, base: base as String?);
      }
    }
    throw FormatException('bad phrase in $where');
  }
}

class CheerParse {
  const CheerParse(this.book, this.warnings);
  final CheerBook book;
  final List<String> warnings;
}

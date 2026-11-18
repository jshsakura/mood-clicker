import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'cheer.dart';
import 'mood.dart';
import 'tuning.dart';

/// One shuffled pass over a bundle. `order` holds indexes into the bundle.
class _Deck {
  const _Deck(this.fingerprint, this.order, this.position);

  final String fingerprint;
  final List<int> order;
  final int position;

  bool get isUsedUp => position >= order.length;

  _Deck advanced() => _Deck(fingerprint, order, position + 1);

  Map<String, Object?> toJson() => {
    'fp': fingerprint,
    'order': order,
    'pos': position,
  };

  /// Null unless the data is a real deck: a permutation of 0..n-1 and a position inside it.
  static _Deck? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final fp = raw['fp'];
    final order = raw['order'];
    final pos = raw['pos'];
    if (fp is! String || order is! List || order.isEmpty || pos is! int) {
      return null;
    }
    if (pos < 0 || pos > order.length) return null;
    final seen = <int>{};
    for (final item in order) {
      if (item is! int || item < 0 || item >= order.length || !seen.add(item)) {
        return null;
      }
    }
    return _Deck(fp, List.unmodifiable(order.cast<int>()), pos);
  }
}

/// Where each bundle's deck stands. An immutable value that can be saved and restored.
class CheerDeckSnapshot {
  const CheerDeckSnapshot._(this._decks);

  const CheerDeckSnapshot.empty() : _decks = const {};

  final Map<String, _Deck> _decks;

  Map<String, Object?> toJson() => {
    'version': 1,
    'decks': {for (final e in _decks.entries) e.key: e.value.toJson()},
  };

  /// Never throws. Anything that does not look right is dropped, so a damaged file only costs a
  /// fresh shuffle.
  factory CheerDeckSnapshot.fromJson(Object? raw) {
    if (raw is! Map || raw['version'] != 1) {
      return const CheerDeckSnapshot.empty();
    }
    final decks = raw['decks'];
    if (decks is! Map) return const CheerDeckSnapshot.empty();
    final out = <String, _Deck>{};
    for (final MapEntry(:key, :value) in decks.entries) {
      if (key is! String || !_isKnownKey(key)) continue;
      final deck = _Deck.fromJson(value);
      if (deck != null) out[key] = deck;
    }
    return CheerDeckSnapshot._(Map.unmodifiable(out));
  }

  static bool _isKnownKey(String key) {
    final parts = key.split('/');
    return parts.length == 2 &&
        Mood.byId(parts[0]) != null &&
        CheerStage.values.any((s) => s.id == parts[1]);
  }
}

/// Deals one phrase per tap from a shuffled deck per mood and stage. No phrase comes twice until
/// the whole bundle has been used. When a deck runs out it is reshuffled, and the last
/// [CheerTuning.deckTailSize] phrases of the old deck (half the bundle for a small one) stay out
/// of the first that many of the new deck. The position can be saved and restored.
class CheerPicker {
  CheerPicker(
    this._random, {
    CheerDeckSnapshot saved = const CheerDeckSnapshot.empty(),
  }) : _decks = {...saved._decks};

  /// Opens a picker with the position saved in [store]. A missing or damaged file gives a fresh
  /// one.
  static Future<CheerPicker> open(Random random, CheerDeckStore store) async =>
      CheerPicker(random, saved: await store.load());

  final Random _random;
  final Map<String, _Deck> _decks;
  int _revision = 0;
  int _savedRevision = 0;

  /// True when picks have been made since the position was last saved.
  bool get isDirty => _revision != _savedRevision;

  CheerDeckSnapshot snapshot() =>
      CheerDeckSnapshot._(Map.unmodifiable({..._decks}));

  Map<String, Object?> snapshotJson() => snapshot().toJson();

  static CheerDeckSnapshot snapshotFromJson(Object? raw) =>
      CheerDeckSnapshot.fromJson(raw);

  /// Saves the position if it changed. Returns true when something was written. A failed save
  /// is silent: the picker keeps working and stays dirty for the next try.
  Future<bool> persist(CheerDeckStore store) async {
    if (!isDirty) return false;
    final revision = _revision;
    final saved = await store.save(snapshot());
    if (saved && revision == _revision) _savedRevision = revision;
    return saved;
  }

  String pick(CheerBook book, Mood mood, CheerStage stage) {
    final used = book.effectiveStage(mood, stage);
    final bundle = book.bundle(mood, used);
    if (bundle.isEmpty) {
      throw StateError('no phrases for ${mood.id}/${used.id}');
    }
    final key = '${mood.id}/${used.id}';
    final fingerprint = book.fingerprint(mood, used);
    var deck = _decks[key];
    if (deck == null || deck.fingerprint != fingerprint || deck.isUsedUp) {
      final matching = deck != null && deck.fingerprint == fingerprint;
      deck = _newDeck(bundle.length, fingerprint, matching ? deck : null);
    }
    final chosen = bundle[deck.order[deck.position]];
    _decks[key] = deck.advanced();
    _revision++;
    return chosen;
  }

  _Deck _newDeck(int size, String fingerprint, _Deck? previous) {
    final keep = min(CheerTuning.deckTailSize, size ~/ 2);
    final tail = previous == null || keep == 0
        ? const <int>[]
        : previous.order.sublist(previous.order.length - keep);
    final tailSet = tail.toSet();
    final rest = [
      for (var i = 0; i < size; i++)
        if (!tailSet.contains(i)) i,
    ]..shuffle(_random);
    // The first `keep` places come from phrases the old deck did not end with. Everything after
    // them, including the old tail, is shuffled together.
    final head = rest.take(keep).toList();
    final later = [...rest.skip(keep), ...tail]..shuffle(_random);
    return _Deck(fingerprint, List.unmodifiable([...head, ...later]), 0);
  }
}

/// Keeps the deck positions between app runs.
abstract interface class CheerDeckStore {
  /// Never throws. A missing or damaged store gives an empty snapshot.
  Future<CheerDeckSnapshot> load();

  /// Never throws. Returns false when nothing could be written.
  Future<bool> save(CheerDeckSnapshot snapshot);
}

/// Stores the positions in one JSON file. The file is injected.
class JsonFileCheerDeckStore implements CheerDeckStore {
  JsonFileCheerDeckStore(this.file);

  final File file;

  static int _nextTemp = 0;

  @override
  Future<CheerDeckSnapshot> load() async {
    try {
      if (!await file.exists()) return const CheerDeckSnapshot.empty();
      final text = utf8.decode(await file.readAsBytes());
      return CheerDeckSnapshot.fromJson(jsonDecode(text));
    } on FormatException {
      return const CheerDeckSnapshot.empty();
    } on FileSystemException {
      return const CheerDeckSnapshot.empty();
    }
  }

  @override
  Future<bool> save(CheerDeckSnapshot snapshot) async {
    final temp = File('${file.path}.$pid.${_nextTemp++}.tmp');
    try {
      await file.parent.create(recursive: true);
      await temp.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
      await temp.rename(file.path);
      return true;
    } on FileSystemException {
      try {
        if (await temp.exists()) await temp.delete();
      } on FileSystemException {
        // Nothing more to clean up.
      }
      return false;
    }
  }
}

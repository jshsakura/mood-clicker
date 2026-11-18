import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'cheer.dart';
import 'mood.dart';
import 'tuning.dart';

/// The base sentences shown most recently, oldest first, across every mood and stage. An
/// immutable value that can be saved and restored.
class CheerDeckSnapshot {
  const CheerDeckSnapshot._(this._recent);

  const CheerDeckSnapshot.empty() : _recent = const [];

  final List<String> _recent;

  Map<String, Object?> toJson() => {'version': 2, 'recent': _recent};

  /// Never throws. Anything that does not look right is dropped, so a damaged file (or an old
  /// one) only costs a fresh start.
  factory CheerDeckSnapshot.fromJson(Object? raw) {
    if (raw is! Map || raw['version'] != 2) {
      return const CheerDeckSnapshot.empty();
    }
    final recent = raw['recent'];
    if (recent is! List) return const CheerDeckSnapshot.empty();
    final out = [
      for (final item in recent)
        if (item is String && item.isNotEmpty) item,
    ];
    final from = max(0, out.length - CheerTuning.recentBases);
    return CheerDeckSnapshot._(List.unmodifiable(out.sublist(from)));
  }
}

/// Deals one phrase per tap. A bundle is a set of base sentences, each with its variants
/// ("good", "good~~", "good!!" are one base). A tap picks a base, then one of its variants at
/// random, so variants of one sentence never show up as different sentences.
///
/// A base does not come again within the last [CheerTuning.recentBases] bases shown, or within
/// half the bundle's bases when that is fewer. The memory is shared by every mood and stage and
/// can be saved and restored, so it lasts across app runs. A phrase written as a plain string is
/// its own base.
class CheerPicker {
  CheerPicker(
    this._random, {
    CheerDeckSnapshot saved = const CheerDeckSnapshot.empty(),
  }) : _recent = [...saved._recent];

  /// Opens a picker with the memory saved in [store]. A missing or damaged file gives a fresh
  /// one.
  static Future<CheerPicker> open(Random random, CheerDeckStore store) async =>
      CheerPicker(random, saved: await store.load());

  final Random _random;
  final List<String> _recent;
  int _revision = 0;
  int _savedRevision = 0;

  /// True when picks have been made since the memory was last saved.
  bool get isDirty => _revision != _savedRevision;

  CheerDeckSnapshot snapshot() =>
      CheerDeckSnapshot._(List.unmodifiable([..._recent]));

  Map<String, Object?> snapshotJson() => snapshot().toJson();

  static CheerDeckSnapshot snapshotFromJson(Object? raw) =>
      CheerDeckSnapshot.fromJson(raw);

  /// Saves the memory if it changed. Returns true when something was written. A failed save
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
    final bases = book.bases(mood, used);
    // Variants of one base, in the order the bundle lists them.
    final groups = <String, List<String>>{};
    for (var i = 0; i < bundle.length; i++) {
      final base = i < bases.length ? bases[i] : null;
      (groups[base ?? bundle[i]] ??= []).add(bundle[i]);
    }
    final keys = groups.keys.toList();
    final keep = min(CheerTuning.recentBases, keys.length ~/ 2);
    final blocked = keep == 0
        ? const <String>{}
        : _recent.sublist(max(0, _recent.length - keep)).toSet();
    final fresh = [
      for (final key in keys)
        if (!blocked.contains(key)) key,
    ];
    final from = fresh.isEmpty ? keys : fresh;
    final key = from[_random.nextInt(from.length)];
    _recent.add(key);
    if (_recent.length > CheerTuning.recentBases) {
      _recent.removeRange(0, _recent.length - CheerTuning.recentBases);
    }
    _revision++;
    final variants = groups[key]!;
    return variants[_random.nextInt(variants.length)];
  }

  /// Decides what one tap shows. The complete stage is always the complete phrase. Any other tap
  /// is a rare phrase with [CheerTuning.rareChance], else an ordinary one of that stage.
  CheerDraw draw(CheerBook book, Mood mood, CheerStage stage) {
    if (stage == CheerStage.complete) {
      return CheerDraw(pick(book, mood, stage), CheerKind.complete);
    }
    if (_random.nextDouble() < CheerTuning.rareChance) {
      return CheerDraw(pick(book, mood, CheerStage.rare), CheerKind.rare);
    }
    return CheerDraw(pick(book, mood, stage), CheerKind.normal);
  }
}

/// One tap's phrase and how to show it.
class CheerDraw {
  const CheerDraw(this.phrase, this.kind);
  final String phrase;
  final CheerKind kind;
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

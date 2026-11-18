import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which one-time hints were already shown, so each shows once.
abstract interface class SeenHints {
  bool seen(String id);

  /// Marks [id] as shown. A failed write is ignored: the hint may show once more.
  Future<void> markSeen(String id);
}

class SharedPreferencesSeenHints implements SeenHints {
  SharedPreferencesSeenHints(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String id) => 'hint.$id';

  @override
  bool seen(String id) => _prefs.getBool(_key(id)) ?? false;

  @override
  Future<void> markSeen(String id) async {
    try {
      await _prefs.setBool(_key(id), true);
    } on Object {
      // The hint is a courtesy: losing the mark only repeats it.
    }
  }
}

/// Keeps the marks in memory. For tests and for runs without storage.
class MemorySeenHints implements SeenHints {
  final Set<String> _ids = {};

  @override
  bool seen(String id) => _ids.contains(id);

  @override
  Future<void> markSeen(String id) async => _ids.add(id);
}

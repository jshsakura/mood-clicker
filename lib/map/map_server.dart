/// The shared map server: the four database functions of supabase/migrations, reached over plain
/// HTTP. Only a day, an H3 cell, a mood and a tap count go out. The session is an anonymous
/// account, made the first time something is sent, and only its refresh token is kept.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/day_key.dart';
import '../domain/mood.dart';

/// Where the server is. Both values come from --dart-define at build time and never sit in the
/// repository. Without them the map keeps its sample data and nothing is sent.
class MapServerConfig {
  const MapServerConfig({required this.url, required this.key});

  static const MapServerConfig fromEnvironment = MapServerConfig(
    url: String.fromEnvironment('MAP_URL'),
    key: String.fromEnvironment('MAP_KEY'),
  );

  final String url;

  /// The publishable key. It is public by design; the database functions are the guard.
  final String key;

  bool get isSet => url.isNotEmpty && key.isNotEmpty;
}

/// The tap sums of one cell, as the server returns them.
class ServerCell {
  const ServerCell({
    required this.cell,
    required this.people,
    required this.taps,
  });

  final int cell;
  final int people;
  final Map<Mood, int> taps;
}

abstract interface class MapServer {
  /// Replaces the caller's count for [mood] on [day].
  Future<void> putDrop({
    required DayKey day,
    required int cell,
    required Mood mood,
    required int taps,
  });

  /// Sums for [cells] from [from] to [to]. Cells with too few people are left out by the server.
  Future<List<ServerCell>> load({
    required DayKey from,
    required DayKey to,
    required List<int> cells,
  });

  /// Removes the caller's rows and account. Does nothing when this phone never sent anything.
  Future<void> deleteMyData();
}

class MapServerError implements Exception {
  const MapServerError(this.status, this.what);

  final int status;
  final String what;

  @override
  String toString() => 'MapServerError($status, $what)';
}

/// Keeps the refresh token of the anonymous account between launches.
abstract interface class MapSessionStore {
  Future<String?> read();
  Future<void> write(String? refreshToken);
}

class PrefsMapSessionStore implements MapSessionStore {
  const PrefsMapSessionStore(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'map.refreshToken';

  @override
  Future<String?> read() async => _prefs.getString(_key);

  @override
  Future<void> write(String? refreshToken) async {
    if (refreshToken == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, refreshToken);
    }
  }
}

class SupabaseMapServer implements MapServer {
  SupabaseMapServer({
    required this.config,
    required this.client,
    required this.sessions,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MapServerConfig config;
  final http.Client client;
  final MapSessionStore sessions;
  final DateTime Function() _now;

  /// A token is renewed this long before it runs out.
  static const Duration renewEarly = Duration(minutes: 1);

  String? _access;
  DateTime _accessUntil = DateTime.fromMillisecondsSinceEpoch(0);

  Uri _uri(String path) => Uri.parse('${config.url}$path');

  Map<String, String> get _plain => {
    'apikey': config.key,
    'Content-Type': 'application/json',
  };

  /// A live access token: the one in memory, a refreshed one, or a new anonymous account.
  Future<String> _token() async {
    final access = _access;
    if (access != null && _now().isBefore(_accessUntil)) return access;
    final refresh = await sessions.read();
    if (refresh != null) {
      final renewed = await _auth('/auth/v1/token?grant_type=refresh_token', {
        'refresh_token': refresh,
      });
      if (renewed != null) return renewed;
    }
    final made = await _auth('/auth/v1/signup', const {});
    if (made == null) throw const MapServerError(0, 'anonymous sign-in');
    return made;
  }

  Future<String?> _auth(String path, Map<String, Object> body) async {
    final res = await client.post(
      _uri(path),
      headers: _plain,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final seconds = data['expires_in'] as int?;
    if (access == null || refresh == null || seconds == null) return null;
    _access = access;
    _accessUntil = _now().add(Duration(seconds: seconds) - renewEarly);
    await sessions.write(refresh);
    return access;
  }

  Future<http.Response> _rpc(
    String name,
    Map<String, Object> body, {
    required bool signedIn,
  }) async {
    Future<http.Response> send() async => client.post(
      _uri('/rest/v1/rpc/$name'),
      headers: {
        ..._plain,
        if (signedIn) 'Authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode(body),
    );
    var res = await send();
    if (signedIn && res.statusCode == 401) {
      // The token ran out early or the account was purged: start over once.
      _access = null;
      res = await send();
    }
    if (res.statusCode >= 300) throw MapServerError(res.statusCode, name);
    return res;
  }

  @override
  Future<void> putDrop({
    required DayKey day,
    required int cell,
    required Mood mood,
    required int taps,
  }) async {
    await _rpc('put_mood_drop', {
      'p_day': '$day',
      'p_cell': cell,
      'p_mood': mood.id,
      'p_taps': taps,
    }, signedIn: true);
  }

  @override
  Future<List<ServerCell>> load({
    required DayKey from,
    required DayKey to,
    required List<int> cells,
  }) async {
    if (cells.isEmpty) return const [];
    final res = await _rpc('mood_map', {
      'p_from': '$from',
      'p_to': '$to',
      'p_cells': cells,
    }, signedIn: false);
    final rows = jsonDecode(res.body) as List<dynamic>;
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        ServerCell(
          cell: row['cell'] as int,
          people: row['people'] as int,
          taps: {for (final mood in Mood.values) mood: row[mood.id] as int},
        ),
    ];
  }

  @override
  Future<void> deleteMyData() async {
    if (await sessions.read() == null && _access == null) return;
    await _rpc('delete_my_data', const {}, signedIn: true);
    _access = null;
    await sessions.write(null);
  }
}

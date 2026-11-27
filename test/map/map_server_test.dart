import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/map/map_server.dart';

class MemorySessions implements MapSessionStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String? refreshToken) async => token = refreshToken;
}

const _config = MapServerConfig(
  url: 'https://map.example.com',
  key: 'sb_publishable_AAAA0000',
);

/// A fake server that records each request and answers like the real functions.
class _Server {
  final List<http.Request> calls = [];
  int signups = 0;
  int refreshes = 0;
  int failNextRpcWith = 0;

  late final client = MockClient((req) async {
    calls.add(req);
    final path = req.url.path;
    if (path == '/auth/v1/signup') {
      signups++;
      return _session('access-$signups', 'refresh-$signups');
    }
    if (path == '/auth/v1/token') {
      refreshes++;
      return _session('access-r$refreshes', 'refresh-r$refreshes');
    }
    if (failNextRpcWith != 0) {
      final status = failNextRpcWith;
      failNextRpcWith = 0;
      return http.Response('{}', status);
    }
    if (path == '/rest/v1/rpc/mood_map') {
      return http.Response(
        jsonEncode([
          {
            'cell': 0x87283082bffffff,
            'people': 6,
            'happy': 4,
            'excited': 0,
            'angry': 9,
            'sad': 1,
            'anxious': 0,
          },
        ]),
        200,
      );
    }
    return http.Response('', 204);
  });

  static http.Response _session(String access, String refresh) => http.Response(
    jsonEncode({
      'access_token': access,
      'refresh_token': refresh,
      'expires_in': 3600,
    }),
    200,
  );

  Iterable<http.Request> rpc(String name) =>
      calls.where((r) => r.url.path == '/rest/v1/rpc/$name');
}

void main() {
  final day = DayKey.of(DateTime(2026, 11, 27, 9));

  test(
    'the first send makes one anonymous account and keeps only the refresh token',
    () async {
      final fake = _Server();
      final sessions = MemorySessions();
      final server = SupabaseMapServer(
        config: _config,
        client: fake.client,
        sessions: sessions,
      );
      await server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 7);
      await server.putDrop(day: day, cell: 42, mood: Mood.happy, taps: 3);
      expect(fake.signups, 1);
      expect(sessions.token, 'refresh-1');
      final put = fake.rpc('put_mood_drop').first;
      expect(put.headers['authorization'], 'Bearer access-1');
      expect(put.headers['apikey'], _config.key);
      expect(jsonDecode(put.body), {
        'p_day': '2026-11-27',
        'p_cell': 42,
        'p_mood': 'sad',
        'p_taps': 7,
      });
    },
  );

  test(
    'a later launch renews the stored account instead of making a new one',
    () async {
      final fake = _Server();
      final sessions = MemorySessions()..token = 'refresh-old';
      final server = SupabaseMapServer(
        config: _config,
        client: fake.client,
        sessions: sessions,
      );
      await server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 1);
      expect(fake.signups, 0);
      expect(fake.refreshes, 1);
      expect(sessions.token, 'refresh-r1');
    },
  );

  test('an expired token is renewed before the next send', () async {
    final fake = _Server();
    var now = DateTime(2026, 11, 27, 9);
    final server = SupabaseMapServer(
      config: _config,
      client: fake.client,
      sessions: MemorySessions(),
      now: () => now,
    );
    await server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 1);
    now = now.add(const Duration(hours: 1));
    await server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 2);
    expect(fake.signups, 1);
    expect(fake.refreshes, 1);
  });

  test('reading the map needs no account and parses the sums', () async {
    final fake = _Server();
    final server = SupabaseMapServer(
      config: _config,
      client: fake.client,
      sessions: MemorySessions(),
    );
    final cells = await server.load(from: day, to: day, cells: [1, 2]);
    expect(fake.signups, 0);
    expect(fake.rpc('mood_map').single.headers['authorization'], isNull);
    expect(cells.single.people, 6);
    expect(cells.single.taps[Mood.angry], 9);
  });

  test('a refused call throws, so the sender tries again later', () async {
    final fake = _Server()..failNextRpcWith = 500;
    final server = SupabaseMapServer(
      config: _config,
      client: fake.client,
      sessions: MemorySessions(),
    );
    await expectLater(
      server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 1),
      throwsA(isA<MapServerError>()),
    );
  });

  test('deleting calls the server and forgets the account', () async {
    final fake = _Server();
    final sessions = MemorySessions();
    final server = SupabaseMapServer(
      config: _config,
      client: fake.client,
      sessions: sessions,
    );
    await server.putDrop(day: day, cell: 42, mood: Mood.sad, taps: 1);
    await server.deleteMyData();
    expect(fake.rpc('delete_my_data'), hasLength(1));
    expect(sessions.token, isNull);
  });

  test('deleting with no account sends nothing', () async {
    final fake = _Server();
    final server = SupabaseMapServer(
      config: _config,
      client: fake.client,
      sessions: MemorySessions(),
    );
    await server.deleteMyData();
    expect(fake.calls, isEmpty);
  });

  test('a build without a server address is not set', () {
    expect(const MapServerConfig(url: '', key: 'k').isSet, isFalse);
    expect(_config.isSet, isTrue);
  });
}

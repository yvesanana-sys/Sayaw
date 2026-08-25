import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart' show CachePolicy;
import 'package:sayaw/data/sources/plex/plex_api_client.dart';
import 'package:sayaw/data/sources/plex/plex_identity.dart';
import 'package:sayaw/data/sources/plex/plex_importer.dart';

import '../fakes/fake_http.dart';
import '../fakes/fake_secret_store.dart';
import 'db_harness.dart';

const _identity = PlexIdentity(clientIdentifier: 'sayaw-test-uuid');
const _serverHost = '192-168-1-10.plex.direct';
const _serverUri = 'https://$_serverHost:32400';

/// One track as the server describes it: artist two levels up, album one, and
/// the playable part nested under Media.
Map<String, dynamic> _track({
  required String ratingKey,
  String title = 'Kiss of Fire',
  String artist = 'Georgia Gibbs',
  String album = 'Ballroom Classics',
  int updatedAt = 1600000000,
  int durationMs = 178000,
}) =>
    {
      'ratingKey': ratingKey,
      'title': title,
      'grandparentTitle': artist,
      'parentTitle': album,
      'year': 1952,
      'duration': durationMs,
      'Media': [
        {
          'id': 900,
          'bitrate': 1005,
          'audioCodec': 'flac',
          'Part': [
            {'id': 555, 'updatedAt': updatedAt, 'file': '/music/$ratingKey.flac'},
          ],
        },
      ],
    };

Map<String, dynamic> _container(Object? payload) => {'MediaContainer': payload};

void main() {
  late SayawDatabase db;
  late FakeHttpAdapter http;
  late PlexApiClient plex;
  late PlexImporter importer;

  Future<String> connect({bool owned = true}) async {
    final id = await plex.connect(PlexServer(
      machineIdentifier: 'server-uuid',
      name: 'Home Server',
      accessToken: 'server-token',
      owned: owned,
      connections: const [],
    ));
    // A remembered address, so nothing has to race to reach the server.
    await db.sourceAccountDao.rememberConnection(id, Uri.parse(_serverUri));
    http.on('GET $_serverHost/identity', FakeResponse({'size': 0}));
    return id;
  }

  void onSections(List<Map<String, dynamic>> directories) => http.on(
        'GET $_serverHost/library/sections',
        FakeResponse(_container({'Directory': directories})),
      );

  void onTracks(List<Map<String, dynamic>> tracks, {int? total}) => http.on(
        'GET $_serverHost/library/sections/1/all',
        FakeResponse(_container({
          'totalSize': total ?? tracks.length,
          'size': tracks.length,
          'Metadata': tracks,
        })),
      );

  setUp(() {
    db = openTestDatabase();
    http = FakeHttpAdapter();
    plex = PlexApiClient(
      dio: fakeDio(http),
      identity: _identity,
      secrets: FakeSecretStore(),
      accounts: db.sourceAccountDao,
      probeTimeout: const Duration(milliseconds: 50),
    );
    importer = PlexImporter(db: db, plex: plex, pageSize: 2);
  });

  group('finding the music', () {
    test('only music libraries come back', () async {
      final id = await connect();
      onSections([
        {'key': '1', 'type': 'artist', 'title': 'Music'},
        {'key': '2', 'type': 'movie', 'title': 'Films'},
        {'key': '3', 'type': 'show', 'title': 'TV'},
      ]);

      final sections = await plex.musicSections(id);

      expect([for (final s in sections) s.title], ['Music']);
      expect(sections.single.key, '1');
    });
  });

  group('importing a library', () {
    test('a track arrives with everything the deck screen draws', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);

      final report = await importer.importSection(id, '1');

      expect(report.added, 1);
      final track = (await db.select(db.tracks).get()).single;
      expect(track.title, 'Kiss of Fire');
      expect(track.artist, 'Georgia Gibbs');
      expect(track.album, 'Ballroom Classics');
      expect(track.year, 1952);
      expect(track.durationMs, const Duration(milliseconds: 178000));
      expect(track.codec, 'flac');
      expect(track.bitrateKbps, 1005);
    });

    test('and everything the resolver needs to play it', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);

      await importer.importSection(id, '1');

      final track = (await db.select(db.tracks).get()).single;
      expect(track.sourceType, SourceType.plex);
      expect(track.accountId, id);
      expect(track.sourceId, '100');

      // The part and its timestamp are what a direct-play URL is built from.
      expect(track.sourcePartId, '555');
      expect(track.sourceUpdatedAt, 1600000000);
    });

    test('an imported track is searchable immediately', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);

      await importer.importSection(id, '1');

      expect([for (final t in await db.trackDao.search('georgia')) t.title],
          ['Kiss of Fire']);
    });

    test('a library larger than one page is fetched in pages', () async {
      final id = await connect();

      // pageSize is 2 and the server holds 3, so this is two requests.
      http.onSequence('GET $_serverHost/library/sections/1/all', [
        FakeResponse(_container({
          'totalSize': 3,
          'Metadata': [_track(ratingKey: 'a'), _track(ratingKey: 'b')],
        })),
        FakeResponse(_container({
          'totalSize': 3,
          'Metadata': [_track(ratingKey: 'c')],
        })),
      ]);

      final report = await importer.importSection(id, '1');

      expect(report.added, 3);
      expect(report.total, 3);
      expect(await db.select(db.tracks).get(), hasLength(3));
      expect(http.callsTo('GET $_serverHost/library/sections/1/all'), 2);
    });

    test('each page asks for the next slice, not the same one again', () async {
      final id = await connect();
      http.onSequence('GET $_serverHost/library/sections/1/all', [
        FakeResponse(_container({
          'totalSize': 3,
          'Metadata': [_track(ratingKey: 'a'), _track(ratingKey: 'b')],
        })),
        FakeResponse(_container({
          'totalSize': 3,
          'Metadata': [_track(ratingKey: 'c')],
        })),
      ]);

      await importer.importSection(id, '1');

      final pages = [
        for (final r in http.requests)
          if (r.uri.path.endsWith('/all')) r.header('X-Plex-Container-Start'),
      ];
      expect(pages, ['0', '2']);
    });

    test('progress is reported against the size the server gave', () async {
      final id = await connect();
      onTracks([_track(ratingKey: 'a'), _track(ratingKey: 'b')], total: 2);

      final seen = <String>[];
      await importer.importSection(id, '1',
          onProgress: (imported, total) => seen.add('$imported/$total'));

      expect(seen, ['2/2']);
    });

    test('a server that is not connected is a programming error', () async {
      expect(() => importer.importSection('no-such-account', '1'),
          throwsArgumentError);
    });
  });

  group('importing again', () {
    test('a track the server has not touched is not rewritten', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);
      await importer.importSection(id, '1');

      final report = await importer.importSection(id, '1');

      expect(report.unchanged, 1);
      expect(report.added, 0);
      expect(report.updated, 0);
    });

    test('a track whose file changed is read again', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);
      await importer.importSection(id, '1');

      // Someone retagged it on the server; Plex bumps the part's updatedAt.
      onTracks([
        _track(ratingKey: '100', title: 'Kiss of Fire (remaster)', updatedAt: 1700000000),
      ]);
      final report = await importer.importSection(id, '1');

      expect(report.updated, 1);
      expect((await db.select(db.tracks).get()).single.title,
          'Kiss of Fire (remaster)');
    });

    test('a re-import keeps the row, so playlists pointing at it survive',
        () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);
      await withClock(Clock.fixed(DateTime.utc(2026, 1)),
          () => importer.importSection(id, '1'));

      final before = (await db.select(db.tracks).get()).single;
      onTracks([_track(ratingKey: '100', updatedAt: 1700000000)]);
      await withClock(Clock.fixed(DateTime.utc(2026, 6)),
          () => importer.importSection(id, '1'));

      final after = (await db.select(db.tracks).get()).single;
      expect(after.id, before.id);
      expect(after.addedAt, DateTime.utc(2026, 1));
      expect(after.updatedAt, DateTime.utc(2026, 6));
    });

    test('an afternoon of preparing a set survives a re-import', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);
      await importer.importSection(id, '1');

      final track = (await db.select(db.tracks).get()).single;
      await (db.update(db.tracks)..where((t) => t.id.equals(track.id))).write(
        const TracksCompanion(
          cueInMs: Value(Duration(milliseconds: 1200)),
          gainDb: Value(-3.5),
        ),
      );

      onTracks([_track(ratingKey: '100', updatedAt: 1700000000)]);
      await importer.importSection(id, '1');

      final after = (await db.trackDao.byId(track.id))!;
      expect(after.cueInMs, const Duration(milliseconds: 1200));
      expect(after.gainDb, -3.5);
    });
  });

  group('what may be written to disk', () {
    test('your own server is cacheable', () async {
      final id = await connect();
      onTracks([_track(ratingKey: '100')]);

      await importer.importSection(id, '1');

      expect((await db.select(db.tracks).get()).single.cachePolicy,
          CachePolicy.allow);
    });

    test('a library shared with you is not', () async {
      // ARCHITECTURE §2.5: a shared library degrades to unavailable offline
      // rather than being cached, and this is where that is recorded.
      final id = await connect(owned: false);
      onTracks([_track(ratingKey: '100')]);

      await importer.importSection(id, '1');

      expect((await db.select(db.tracks).get()).single.cachePolicy,
          CachePolicy.forbid);
    });

    test('ownership is remembered on the account, not guessed later', () async {
      final id = await connect(owned: false);

      expect((await db.sourceAccountDao.byId(id))!.isOwned, isFalse);
    });
  });
}

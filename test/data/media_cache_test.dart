import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/cache/file_media_cache.dart';
import 'package:sayaw/data/cache/media_downloader.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart';

import '../fakes/fake_http.dart';
import '../fakes/fake_sources.dart';
import 'db_harness.dart';

const _serverHost = 'plex.local';
const _partPath = '/library/parts/555/1600000000/file';

/// Something recognisable to assert on, and long enough that a resumed
/// download has a meaningful tail.
final _audio = List<int>.generate(120, (i) => i % 256);

void main() {
  late SayawDatabase db;
  late FakeHttpAdapter http;
  late FakeTidalClient tidal;
  late MediaResolver resolver;
  late MediaDownloader downloader;
  late FileMediaCache cache;
  late Directory cacheDir;

  setUp(() async {
    db = openTestDatabase();
    http = FakeHttpAdapter();
    tidal = FakeTidalClient();
    cacheDir = Directory.systemTemp.createTempSync('sayaw-cache');
    addTearDown(() => cacheDir.deleteSync(recursive: true));

    cache = FileMediaCache(db);
    resolver = MediaResolver(
      plex: FakePlexClient(connection: 'https://$_serverHost:32400'),
      tidal: tidal,
      cache: cache,
      networkMode: () => NetworkMode.online,
    );
    downloader = MediaDownloader(
      db: db,
      resolver: resolver,
      dio: fakeDio(http),
      directory: cacheDir,
    );

    await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
          id: 'plex',
          provider: SourceProvider.plex,
          displayName: 'Home Server',
          machineIdentifier: const Value('server-uuid'),
          keychainRef: 'plex:server-uuid',
          isOwned: const Value(true),
          createdAt: clock.now(),
        ));
  });

  Future<Track> plexTrack({
    String id = 'p1',
    bool owned = true,
  }) async {
    if (!owned) {
      await (db.update(db.sourceAccounts)..where((a) => a.id.equals('plex')))
          .write(const SourceAccountsCompanion(isOwned: Value(false)));
    }
    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.plex,
      accountId: const Value('plex'),
      sourceId: Value(id),
      sourcePartId: const Value('555'),
      sourceUpdatedAt: const Value(1600000000),
      title: 'Track $id',
      addedAt: clock.now(),
      updatedAt: clock.now(),
    ));
    return (await db.trackDao.byId(id))!;
  }

  void serveWholeFile([List<int>? body]) => http.on(
        'GET $_serverHost$_partPath',
        FakeResponse.bytes(body ?? _audio,
            headers: {'content-length': '${(body ?? _audio).length}'}),
      );

  group('downloading', () {
    test('the bytes land on disk and the row says so', () async {
      final track = await plexTrack();
      serveWholeFile();

      final entry = await downloader.download(track);

      expect(entry.state, CacheState.complete);
      expect(entry.byteSize, _audio.length);
      expect(File(entry.cachePath!).readAsBytesSync(), _audio);
    });

    test('the row records that policy authorised it', () async {
      final track = await plexTrack();
      serveWholeFile();

      final entry = await downloader.download(track);

      // The single gate on media bytes being on disk at all.
      expect(entry.policyAllowsPersist, isTrue);
    });

    test('the request carries the token the resolver put on it', () async {
      final track = await plexTrack();
      serveWholeFile();

      await downloader.download(track);

      expect(http.requests.last.header('X-Plex-Token'), 'plex-token-plex');
    });

    test('progress is reported against the length the server gave', () async {
      final track = await plexTrack();
      serveWholeFile();

      final seen = <String>[];
      await downloader.download(track,
          onProgress: (received, total) => seen.add('$received/$total'));

      expect(seen.last, '${_audio.length}/${_audio.length}');
    });

    test('a failure leaves the row marked failed, not half complete',
        () async {
      final track = await plexTrack();
      http.on('GET $_serverHost$_partPath', FakeResponse.refused());

      await expectLater(downloader.download(track), throwsA(isA<Object>()));

      final entry = await db.cacheDao.byTrack(track.id);
      expect(entry!.state, CacheState.failed);
    });

    test('nothing appears under the finished name until it is finished',
        () async {
      final track = await plexTrack();
      http.on('GET $_serverHost$_partPath', FakeResponse.refused());

      await expectLater(downloader.download(track), throwsA(isA<Object>()));

      // A track that plays for ten seconds and stops is worse on a dance floor
      // than one that never appears.
      expect(File('${cacheDir.path}/${track.id}').existsSync(), isFalse);
    });
  });

  group('resuming', () {
    test('an interrupted download picks up from where it stopped', () async {
      final track = await plexTrack();
      File('${cacheDir.path}/${track.id}.part')
          .writeAsBytesSync(_audio.sublist(0, 50));

      http.on(
        'GET $_serverHost$_partPath',
        FakeResponse.bytes(_audio.sublist(50), status: 206, headers: {
          'content-range': 'bytes 50-119/${_audio.length}',
          'content-length': '${_audio.length - 50}',
        }),
      );

      final entry = await downloader.download(track);

      expect(http.requests.last.header('range'), 'bytes=50-');
      expect(File(entry.cachePath!).readAsBytesSync(), _audio);
    });

    test('progress counts the bytes already on disk', () async {
      final track = await plexTrack();
      File('${cacheDir.path}/${track.id}.part')
          .writeAsBytesSync(_audio.sublist(0, 50));
      http.on(
        'GET $_serverHost$_partPath',
        FakeResponse.bytes(_audio.sublist(50), status: 206, headers: {
          'content-range': 'bytes 50-119/${_audio.length}',
        }),
      );

      final seen = <String>[];
      await downloader.download(track,
          onProgress: (received, total) => seen.add('$received/$total'));

      // Not 70/70: the bar would jump backwards on resume.
      expect(seen.last, '120/120');
    });

    test('a server that ignores the range starts the file again', () async {
      final track = await plexTrack();
      File('${cacheDir.path}/${track.id}.part')
          .writeAsBytesSync(_audio.sublist(0, 50));

      // 200 rather than 206: what is on disk is no longer a prefix of what is
      // coming, so appending would produce a corrupt file.
      serveWholeFile();

      final entry = await downloader.download(track);

      expect(File(entry.cachePath!).readAsBytesSync(), _audio);
    });
  });

  group('what may be written at all', () {
    test('a shared Plex library is refused', () async {
      final track = await plexTrack(owned: false);
      serveWholeFile();

      await expectLater(
        downloader.download(track),
        throwsA(isA<DownloadRefused>()),
      );
      expect(cacheDir.listSync(), isEmpty);
    });

    test('TIDAL without an offline entitlement is refused', () async {
      // ARCHITECTURE §2.5: persisting decrypted TIDAL audio without the grant
      // is a terms violation, so it is refused by construction rather than by
      // everyone remembering.
      await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
            id: 'tidal',
            provider: SourceProvider.tidal,
            displayName: 'TIDAL',
            keychainRef: 'tidal',
            createdAt: clock.now(),
          ));
      await db.trackDao.upsert(TracksCompanion.insert(
        id: 't1',
        sourceType: SourceType.tidal,
        accountId: const Value('tidal'),
        sourceId: const Value('t1'),
        title: 'Streamed',
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));

      await expectLater(
        downloader.download((await db.trackDao.byId('t1'))!),
        throwsA(isA<DownloadRefused>().having(
            (e) => e.reason, 'reason', contains('not kept on disk'))),
      );
    });

    test('TIDAL with the entitlement granted is allowed', () async {
      tidal.offlineEntitled = true;
      await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
            id: 'tidal',
            provider: SourceProvider.tidal,
            displayName: 'TIDAL',
            keychainRef: 'tidal',
            createdAt: clock.now(),
          ));
      await db.trackDao.upsert(TracksCompanion.insert(
        id: 't1',
        sourceType: SourceType.tidal,
        accountId: const Value('tidal'),
        sourceId: const Value('t1'),
        title: 'Streamed',
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
      http.on('GET audio.tidal.com/t1.flac',
          FakeResponse.bytes(_audio, headers: {'content-length': '120'}));

      final entry = await downloader.download((await db.trackDao.byId('t1'))!);
      expect(entry.state, CacheState.complete);
    });

    test('a local file is already where it needs to be', () async {
      await db.trackDao.upsert(TracksCompanion.insert(
        id: 'l1',
        sourceType: SourceType.local,
        localPath: Value('${cacheDir.path}/already-here.flac'),
        title: 'Local',
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
      File('${cacheDir.path}/already-here.flac').writeAsBytesSync(_audio);

      await expectLater(
        downloader.download((await db.trackDao.byId('l1'))!),
        throwsA(isA<DownloadRefused>()),
      );
    });
  });

  group('reading the cache back', () {
    test('a finished download is what the resolver plays', () async {
      final track = await plexTrack();
      serveWholeFile();
      await downloader.download(track);

      final media = await resolver.resolve(PlexSource(
        accountId: 'plex',
        machineIdentifier: 'server-uuid',
        ratingKey: track.id,
      ));

      expect(media.uri.scheme, 'file');
      expect(media.uri.toFilePath(), '${cacheDir.path}/${track.id}');
    });

    test('playing a cached track moves it down the eviction queue', () async {
      final track = await plexTrack();
      serveWholeFile();
      await withClock(Clock.fixed(DateTime.utc(2026, 1)),
          () => downloader.download(track));

      await withClock(
        Clock.fixed(DateTime.utc(2026, 6)),
        () => cache.completeFileFor(PlexSource(
          accountId: 'plex',
          machineIdentifier: 'server-uuid',
          ratingKey: track.id,
        )),
      );

      expect((await db.cacheDao.byTrack(track.id))!.lastAccessedAt,
          DateTime.utc(2026, 6));
    });

    test('a row whose file somebody deleted is not offered', () async {
      final track = await plexTrack();
      serveWholeFile();
      final entry = await downloader.download(track);
      File(entry.cachePath!).deleteSync();

      // An operator clearing space, or a cache directory on a volume that is
      // not mounted. Trust the disk over the row.
      expect(
        await cache.completeFileFor(PlexSource(
          accountId: 'plex',
          machineIdentifier: 'server-uuid',
          ratingKey: track.id,
        )),
        isNull,
      );
    });

    test('an unfinished download is not offered', () async {
      final track = await plexTrack();
      await db.cacheDao.begin(track.id, policyAllowsPersist: true);
      await db.cacheDao.progress(track.id,
          path: '${cacheDir.path}/${track.id}.part', received: 50, total: 120);

      expect(
        await cache.completeFileFor(PlexSource(
          accountId: 'plex',
          machineIdentifier: 'server-uuid',
          ratingKey: track.id,
        )),
        isNull,
      );
    });

    test('a track nobody has cached is simply absent', () async {
      await plexTrack();

      expect(
        await cache.completeFileFor(const PlexSource(
          accountId: 'plex',
          machineIdentifier: 'server-uuid',
          ratingKey: 'p1',
        )),
        isNull,
      );
    });
  });

  group('making room', () {
    Future<void> cacheTrack(String id, {required DateTime playedAt}) async {
      final track = await plexTrack(id: id);
      http.on(
        'GET $_serverHost$_partPath',
        FakeResponse.bytes(_audio, headers: {'content-length': '120'}),
      );
      await downloader.download(track);
      await withClock(Clock.fixed(playedAt), () => db.cacheDao.touch(id));
    }

    test('the least recently played goes first', () async {
      await cacheTrack('old', playedAt: DateTime.utc(2026, 1));
      await cacheTrack('newer', playedAt: DateTime.utc(2026, 6));

      final removed = await downloader.evictTo(_audio.length);

      expect(removed, 1);
      expect([for (final t in await db.select(db.cacheEntries).get()) t.trackId],
          ['newer']);
    });

    test('the bytes go with the row', () async {
      await cacheTrack('old', playedAt: DateTime.utc(2026, 1));

      await downloader.evictTo(0);

      expect(File('${cacheDir.path}/old').existsSync(), isFalse);
    });

    test("tonight's set is pinned and is not touched", () async {
      await cacheTrack('pinned', playedAt: DateTime.utc(2026, 1));
      await cacheTrack('spare', playedAt: DateTime.utc(2026, 6));
      await db.cacheDao.setPinned('pinned', true);

      await downloader.evictTo(0);

      expect([for (final t in await db.select(db.cacheEntries).get()) t.trackId],
          ['pinned']);
    });

    test('a cache already under the limit is left alone', () async {
      await cacheTrack('keep', playedAt: DateTime.utc(2026, 1));

      expect(await downloader.evictTo(_audio.length * 10), 0);
      expect(await db.select(db.cacheEntries).get(), hasLength(1));
    });

    test('an entry whose licence ran out is dropped', () async {
      final track = await plexTrack();
      serveWholeFile();
      await downloader.download(track);
      await db.cacheDao.complete(track.id,
          path: '${cacheDir.path}/${track.id}',
          byteSize: 120,
          expiresAt: DateTime.utc(2000));

      expect(await downloader.evictExpired(), 1);
      expect(await db.select(db.cacheEntries).get(), isEmpty);
    });
  });
}

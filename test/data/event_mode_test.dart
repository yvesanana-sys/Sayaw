import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart' show AnnounceMode;
import 'package:sayaw/data/cache/file_media_cache.dart';
import 'package:sayaw/data/cache/media_downloader.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/event_mode.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/playlist_repository.dart';

import '../fakes/fake_clip_factory.dart';
import '../fakes/fake_deck.dart';
import '../fakes/fake_http.dart';
import '../fakes/fake_sources.dart';
import 'db_harness.dart';

const _serverHost = 'plex.local';
const _partPath = '/library/parts/555/1600000000/file';
final _audio = List<int>.generate(64, (i) => i);

void main() {
  late SayawDatabase db;
  late FakeHttpAdapter http;
  late FakeTidalClient tidal;
  late FakeClipFactory clips;
  late MediaResolver resolver;
  late MediaDownloader downloader;
  late EventPreflight preflight;
  late Directory music;
  late Directory cacheDir;
  late String set;

  setUp(() async {
    db = openTestDatabase();
    http = FakeHttpAdapter();
    tidal = FakeTidalClient();
    clips = FakeClipFactory();
    music = Directory.systemTemp.createTempSync('sayaw-event-music');
    cacheDir = Directory.systemTemp.createTempSync('sayaw-event-cache');
    addTearDown(() => music.deleteSync(recursive: true));
    addTearDown(() => cacheDir.deleteSync(recursive: true));

    resolver = MediaResolver(
      plex: FakePlexClient(connection: 'https://$_serverHost:32400'),
      tidal: tidal,
      cache: FileMediaCache(db),
      networkMode: () => NetworkMode.online,
    );
    downloader = MediaDownloader(
      db: db,
      resolver: resolver,
      dio: fakeDio(http),
      directory: cacheDir,
    );
    preflight = EventPreflight(
      db: db,
      repository: PlaylistRepository(db: db, resolver: resolver),
      downloader: downloader,
      announcements: AnnouncementEngine(
        voiceDeck: FakeDeck('voice'),
        cacheDirectory: cacheDir.path,
        settings: const TtsVoiceSettings(),
        clipFactory: clips,
      ),
    );

    set = await db.playlistDao.createPlaylist(name: 'Saturday Social');
    await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
          id: 'plex',
          provider: SourceProvider.plex,
          displayName: 'Home Server',
          machineIdentifier: const Value('server-uuid'),
          keychainRef: 'plex:server-uuid',
          isOwned: const Value(true),
          createdAt: clock.now(),
        ));

    http.on(
      'GET $_serverHost$_partPath',
      FakeResponse.bytes(_audio, headers: {'content-length': '${_audio.length}'}),
    );
  });

  Future<void> addLocal(String id, {bool onDisk = true, String? danceTypeId}) async {
    if (onDisk) File('${music.path}/$id.flac').writeAsStringSync('audio');
    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.local,
      localPath: Value('${music.path}/$id.flac'),
      title: 'Track $id',
      addedAt: clock.now(),
      updatedAt: clock.now(),
    ));
    await db.playlistDao.appendTrack(
        playlistId: set, trackId: id, danceTypeId: danceTypeId, id: 'item-$id');
  }

  Future<void> addPlex(String id, {bool owned = true}) async {
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
    await db.playlistDao
        .appendTrack(playlistId: set, trackId: id, id: 'item-$id');
  }

  Future<void> addTidal(String id) async {
    await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
          id: 'tidal',
          provider: SourceProvider.tidal,
          displayName: 'TIDAL',
          keychainRef: 'tidal',
          createdAt: clock.now(),
        ));
    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.tidal,
      accountId: const Value('tidal'),
      sourceId: Value(id),
      title: 'Track $id',
      addedAt: clock.now(),
      updatedAt: clock.now(),
    ));
    await db.playlistDao
        .appendTrack(playlistId: set, trackId: id, id: 'item-$id');
  }

  Future<void> addDanceTypes() async {
    await db.into(db.danceTypes).insert(
        DanceTypesCompanion.insert(id: 'tango', name: 'Tango', slug: 'tango'));
    await db.into(db.danceTypes).insert(
        DanceTypesCompanion.insert(id: 'waltz', name: 'Waltz', slug: 'waltz'));
  }

  PreflightOutcome outcomeOf(PreflightReport report, String itemId) =>
      report.items.firstWhere((i) => i.itemId == itemId).outcome;

  group('what the set needs', () {
    test('local files are ready with nothing downloaded', () async {
      await addLocal('a');
      await addLocal('b');

      final report = await preflight.prepare(set);

      expect(report.readyOffline, isTrue);
      expect(report.readyCount, 2);
      expect(cacheDir.listSync(), isEmpty);
    });

    test('a Plex track is downloaded and pinned', () async {
      await addPlex('p');

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-p'), PreflightOutcome.readyOffline);
      final entry = await db.cacheDao.byTrack('p');
      expect(entry!.state, CacheState.complete);

      // Pinned so an eviction triggered by anything else between now and the
      // last dance cannot take tonight's music.
      expect(entry.pinned, isTrue);
      expect(File(entry.cachePath!).readAsBytesSync(), _audio);
    });

    test('a track already on disk is not downloaded again', () async {
      await addPlex('p');
      await preflight.prepare(set);
      final requests = http.callsTo('GET $_serverHost$_partPath');

      await preflight.prepare(set);

      expect(http.callsTo('GET $_serverHost$_partPath'), requests);
    });

    test('a row whose file was deleted to make space is fetched again',
        () async {
      // The row still says `complete`. Trusting it would report a track as
      // ready for tonight with nothing on disk to play.
      await addPlex('p');
      await preflight.prepare(set);
      File((await db.cacheDao.byTrack('p'))!.cachePath!).deleteSync();

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-p'), PreflightOutcome.readyOffline);
      expect(File((await db.cacheDao.byTrack('p'))!.cachePath!).existsSync(),
          isTrue);
    });

    test("last event's pins are cleared before this one's are set", () async {
      await addPlex('p');
      await preflight.prepare(set);

      // A track from a set that is over. Leaving it pinned would slowly turn
      // the cache into a museum.
      await db.into(db.tracks).insert(TracksCompanion.insert(
            id: 'last-week',
            sourceType: SourceType.local,
            localPath: Value('${music.path}/last-week.flac'),
            title: 'Last week',
            addedAt: clock.now(),
            updatedAt: clock.now(),
          ));
      await db.cacheDao.begin('last-week', policyAllowsPersist: true);
      await db.cacheDao
          .complete('last-week', path: '/cache/last-week', byteSize: 10);
      await db.cacheDao.setPinned('last-week', true);

      await preflight.prepare(set);

      expect((await db.cacheDao.byTrack('last-week'))!.pinned, isFalse);
      expect((await db.cacheDao.byTrack('p'))!.pinned, isTrue);
    });
  });

  group('what the set cannot have', () {
    test('a shared Plex library is streaming only', () async {
      await addPlex('p', owned: false);

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-p'), PreflightOutcome.streamingOnly);
      expect(await db.cacheDao.byTrack('p'), isNull);
      expect(cacheDir.listSync(), isEmpty);
    });

    test('TIDAL without an offline entitlement is streaming only', () async {
      await addTidal('t');

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-t'), PreflightOutcome.streamingOnly);
      expect(report.items.single.detail, contains('skipped without'));
    });

    test('a missing file is named so it can be found', () async {
      await addLocal('gone', onDisk: false);

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-gone'), PreflightOutcome.missingFile);
      expect(report.items.single.title, 'Track gone');
      expect(report.items.single.detail, contains('missing'));
    });

    test('a download that fails is reported, and the set carries on', () async {
      await addLocal('a');
      await addPlex('p');
      http.on('GET $_serverHost$_partPath', FakeResponse.refused());

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'item-a'), PreflightOutcome.readyOffline);
      expect(outcomeOf(report, 'item-p'), PreflightOutcome.notDownloaded);
      expect(report.readyOffline, isFalse);
    });

    test('a row the engine cannot play is listed as such', () async {
      await addLocal('a');
      await db.into(db.playlistItems).insert(PlaylistItemsCompanion.insert(
            id: 'gap',
            playlistId: set,
            position: 9.0,
            itemType: const Value(PlaylistItemType.silence),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ));

      final report = await preflight.prepare(set);

      expect(outcomeOf(report, 'gap'), PreflightOutcome.notPlayable);
    });
  });

  group('announcements', () {
    test('every one in the set is rendered up front', () async {
      await addDanceTypes();
      await addLocal('a', danceTypeId: 'tango');
      await addLocal('b', danceTypeId: 'waltz');

      final report = await preflight.prepare(set);

      expect(report.announcementsRendered, 2);
      expect(report.announcementsMissing, 0);
      expect(clips.rendered, ['Next dance: Tango', 'Next dance: Waltz']);
    });

    test('a set with forty Cha-Chas renders Cha-Cha once', () async {
      await addDanceTypes();
      for (final id in ['a', 'b', 'c']) {
        await addLocal(id, danceTypeId: 'tango');
      }

      final report = await preflight.prepare(set);

      // Counted three times — every row has one — but synthesised once.
      expect(report.announcementsRendered, 3);
      expect(clips.rendered, ['Next dance: Tango']);
    });

    test('a set with announcements turned off renders nothing', () async {
      await addDanceTypes();
      await addLocal('a', danceTypeId: 'tango');
      await (db.update(db.playlists)..where((p) => p.id.equals(set)))
          .write(const PlaylistsCompanion(announceMode: Value(AnnounceMode.off)));

      final report = await preflight.prepare(set);

      expect(report.announcementsRendered, 0);
      expect(clips.rendered, isEmpty);
    });

    test('a mute speech engine is counted, not thrown', () async {
      await addDanceTypes();
      await addLocal('a', danceTypeId: 'tango');
      clips.failRender = true;

      final report = await preflight.prepare(set);

      expect(report.announcementsMissing, 1);
      expect(report.announcementsRendered, 0);

      // The tracks are still ready; only the voice is missing.
      expect(report.readyOffline, isTrue);
    });

    test('a row with no dance type asks for nothing', () async {
      await addLocal('a');

      final report = await preflight.prepare(set);

      expect(report.announcementsRendered, 0);
      expect(report.announcementsMissing, 0);
    });
  });

  group('the report', () {
    test('counts what is ready against what is in the set', () async {
      await addLocal('a');
      await addLocal('gone', onDisk: false);
      await addPlex('p');

      final report = await preflight.prepare(set);

      expect(report.total, 3);
      expect(report.readyCount, 2);
      expect(report.countOf(PreflightOutcome.missingFile), 1);
      expect(report.readyOffline, isFalse);
    });

    test('an empty set is trivially ready', () async {
      final report = await preflight.prepare(set);

      expect(report.total, 0);
      expect(report.readyOffline, isTrue);
    });

    test('progress names the step and what it is working on', () async {
      await addDanceTypes();
      await addLocal('a', danceTypeId: 'tango');

      final steps = <String>[];
      await preflight.prepare(
        set,
        onProgress: (p) => steps.add('${p.step.name}:${p.title ?? ''}'),
      );

      expect(steps.first, 'resolving:');
      expect(steps, contains('downloading:Track a'));
      expect(steps, contains('announcing:Track a'));
    });
  });
}

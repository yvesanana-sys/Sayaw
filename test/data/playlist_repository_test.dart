import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/fade_curves.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/playlist_repository.dart';

import '../fakes/fake_sources.dart';
import 'db_harness.dart';

void main() {
  late SayawDatabase db;
  late PlaylistRepository repo;
  late FakeTidalClient tidal;
  late FakeMediaCache cache;
  late NetworkMode network;
  late Directory music;
  late String set;

  setUp(() async {
    db = openTestDatabase();
    tidal = FakeTidalClient();
    cache = FakeMediaCache();
    network = NetworkMode.online;
    music = Directory.systemTemp.createTempSync('sayaw-music');
    addTearDown(() => music.deleteSync(recursive: true));

    repo = PlaylistRepository(
      db: db,
      resolver: MediaResolver(
        plex: FakePlexClient(),
        tidal: tidal,
        cache: cache,
        networkMode: () => network,
      ),
    );

    set = await db.playlistDao.createPlaylist(name: 'Saturday Social');
    await _addDanceTypes(db);
  });

  group('merging playlist defaults with row overrides', () {
    test('a row with no overrides inherits everything', () async {
      final playlist = (await db.playlistDao.byId(set))!;
      final item = _item(playlistId: set);

      final spec = PlaylistRepository.specFor(playlist, item);
      expect(spec.crossfade, playlist.crossfadeMs);
      expect(spec.fadeInCurve, playlist.fadeInCurve);
      expect(spec.announceMode, playlist.announceMode);
      expect(spec.duckLevel, playlist.duckLevel);
    });

    test('a row that sets a value wins over the playlist', () async {
      final playlist = (await db.playlistDao.byId(set))!;
      final item = _item(
        playlistId: set,
        crossfadeMs: const Duration(milliseconds: 900),
        fadeInCurve: FadeCurve.exponential,
        fadeOutCurve: FadeCurve.logarithmic,
        announceMode: AnnounceMode.duckOver,
        pauseAfter: true,
      );

      final spec = PlaylistRepository.specFor(playlist, item);
      expect(spec.crossfade, const Duration(milliseconds: 900));
      expect(spec.fadeInCurve, FadeCurve.exponential);
      expect(spec.fadeOutCurve, FadeCurve.logarithmic);
      expect(spec.announceMode, AnnounceMode.duckOver);
      expect(spec.pauseAfter, isTrue);
    });

    test('the duck envelope stays a property of the set, not the song',
        () async {
      final playlist = (await db.playlistDao.byId(set))!;
      await (db.update(db.playlists)..where((p) => p.id.equals(set))).write(
        const PlaylistsCompanion(
          duckLevel: Value(0.35),
          duckFadeMs: Value(Duration(milliseconds: 750)),
        ),
      );

      final updated = (await db.playlistDao.byId(set))!;
      final spec =
          PlaylistRepository.specFor(updated, _item(playlistId: set));

      expect(spec.duckLevel, 0.35);
      expect(spec.duckFade, const Duration(milliseconds: 750));
      expect(playlist.duckLevel, isNot(0.35));
    });
  });

  group('what the voice says', () {
    test('the dance type template is filled in', () async {
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');
      final row = (await db.playlistDao.itemsOf(set)).single;

      expect(PlaylistRepository.announcementTextFor(row), 'Next dance: Tango');
    });

    test('{next} names the dance after this one', () async {
      await _setTemplate(db, 'tango', 'Tango now, {next} next');
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');
      await _appendLocal(db, set, music, 'b', danceTypeId: 'waltz');

      final queue = await repo.buildQueue(set);
      expect(queue.entries.first.announcementText, 'Tango now, Waltz next');
    });

    test('{next} on the last row leaves nothing dangling', () async {
      await _setTemplate(db, 'tango', 'Tango, then {next}.');
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');

      final queue = await repo.buildQueue(set);
      expect(queue.entries.single.announcementText, 'Tango, then.');
    });

    test('an explicit line on the row wins over the template', () async {
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');
      await _override(db, 'item-a',
          const PlaylistItemsCompanion(
              announcementText: Value('Take your partners for the {name}')));

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(PlaylistRepository.announcementTextFor(row),
          'Take your partners for the Tango');
    });

    test('a blank override falls back to the template', () async {
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');
      await _override(db, 'item-a',
          const PlaylistItemsCompanion(announcementText: Value('   ')));

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(PlaylistRepository.announcementTextFor(row), 'Next dance: Tango');
    });

    test('a row with no dance type and no override says nothing', () async {
      await _appendLocal(db, set, music, 'a');
      final row = (await db.playlistDao.itemsOf(set)).single;

      expect(PlaylistRepository.announcementTextFor(row), isNull);
    });

    test('a recorded MC clip on the row beats the dance type clip', () async {
      await (db.update(db.danceTypes)..where((d) => d.id.equals('tango')))
          .write(const DanceTypesCompanion(
              customClipPath: Value('/clips/tango.m4a')));
      await _appendLocal(db, set, music, 'a', danceTypeId: 'tango');

      var queue = await repo.buildQueue(set);
      expect(queue.entries.single.announcementClipPath, '/clips/tango.m4a');

      await _override(db, 'item-a',
          const PlaylistItemsCompanion(
              announcementClipPath: Value('/clips/mc-intro.m4a')));

      queue = await repo.buildQueue(set);
      expect(queue.entries.single.announcementClipPath, '/clips/mc-intro.m4a');
    });
  });

  group('rebuilding the source from its columns', () {
    test('a local track keeps its path', () async {
      await _appendLocal(db, set, music, 'a');
      final track = (await db.trackDao.byId('a'))!;

      final source = PlaylistRepository.sourceFor(track);
      expect(source, isA<LocalSource>());
      expect((source as LocalSource).path, '${music.path}/a.flac');
    });

    test('a Plex track carries the server it came from', () async {
      await _addPlexAccount(db);
      await _appendPlex(db, set, 'p');

      final track = (await db.trackDao.byId('p'))!;
      final account = (await db.select(db.sourceAccounts).get()).single;

      final source =
          PlaylistRepository.sourceFor(track, account: account) as PlexSource;
      expect(source.machineIdentifier, 'server-uuid');
      expect(source.ratingKey, 'p');
      expect(source.partId, '55');
    });

    test('a remote track whose account has been disconnected is unavailable',
        () async {
      await _addPlexAccount(db);
      await _appendPlex(db, set, 'p');
      final track = (await db.trackDao.byId('p'))!;

      expect(() => PlaylistRepository.sourceFor(track),
          throwsA(isA<UnavailableOffline>()));
    });
  });

  group('building a queue', () {
    test('entries come back in set order', () async {
      await _appendLocal(db, set, music, 'a');
      await _appendLocal(db, set, music, 'b');
      await db.playlistDao.move(playlistId: set, oldIndex: 1, newIndex: 0);

      final queue = await repo.buildQueue(set);
      expect([for (final e in queue.entries) e.title], ['Track b', 'Track a']);
      expect(queue.isCompletelyPlayable, isTrue);
    });

    test('the two gain trims add up, and the two cue points compose', () async {
      await _appendLocal(db, set, music, 'a');
      await (db.update(db.tracks)..where((t) => t.id.equals('a'))).write(
        const TracksCompanion(
          gainDb: Value(-4.0),
          cueInMs: Value(Duration(milliseconds: 500)),
          cueOutMs: Value(Duration(minutes: 3)),
        ),
      );
      await _override(
        db,
        'item-a',
        const PlaylistItemsCompanion(
          gainOffsetDb: Value(1.5),
          startOffsetMs: Value(Duration(milliseconds: 250)),
          targetDurationMs: Value(Duration(seconds: 105)),
        ),
      );

      final entry = (await repo.buildQueue(set)).entries.single;
      expect(entry.media.gainDb, -2.5);
      expect(entry.media.cueIn, const Duration(milliseconds: 750));
      expect(entry.media.cueOut, const Duration(minutes: 3));
      expect(entry.targetDuration, const Duration(seconds: 105));
    });

    test('a row-level end offset overrides the track cue-out', () async {
      await _appendLocal(db, set, music, 'a');
      await (db.update(db.tracks)..where((t) => t.id.equals('a'))).write(
        const TracksCompanion(cueOutMs: Value(Duration(minutes: 3))),
      );
      await _override(db, 'item-a',
          const PlaylistItemsCompanion(
              endOffsetMs: Value(Duration(seconds: 90))));

      final entry = (await repo.buildQueue(set)).entries.single;
      expect(entry.media.cueOut, const Duration(seconds: 90));
    });

    test('a missing file is reported, and the rest of the set still loads',
        () async {
      await _appendLocal(db, set, music, 'a');
      await _appendLocal(db, set, music, 'gone');
      File('${music.path}/gone.flac').deleteSync();

      final queue = await repo.buildQueue(set);
      expect([for (final e in queue.entries) e.title], ['Track a']);
      expect(queue.unavailable.single.itemId, 'item-gone');
      expect(queue.unavailable.single.title, 'Track gone');
      expect(queue.unavailable.single.reason, contains('missing'));
      expect(queue.isCompletelyPlayable, isFalse);
    });

    test('a Plex track with the server unreachable is reported, not thrown',
        () async {
      await _addPlexAccount(db);
      await _appendLocal(db, set, music, 'a');
      await _appendPlex(db, set, 'p');
      network = NetworkMode.localOnly;

      final queue = await repo.buildQueue(set);
      expect([for (final e in queue.entries) e.title], ['Track a']);
      expect(queue.unavailable.single.reason, contains('not cached'));
    });

    test('the same Plex track plays from the cache with no network at all',
        () async {
      await _addPlexAccount(db);
      await _appendPlex(db, set, 'p');
      cache.files['plex:p'] = '/cache/plex-p.flac';
      network = NetworkMode.localOnly;

      final queue = await repo.buildQueue(set);
      expect(queue.entries.single.media.uri, Uri.file('/cache/plex-p.flac'));
    });

    test('a TIDAL row carries its expiry so it can be refreshed later',
        () async {
      await _addTidalAccount(db);
      await _appendTidal(db, set, 't');

      final entry = (await repo.buildQueue(set)).entries.single;
      expect(entry.media.expiresAt, DateTime.utc(2026, 8, 25, 23));
      // The track's own trim and TIDAL's ReplayGain compose.
      expect(entry.media.gainDb, -1.5);
    });

    test('rows the engine cannot play yet are listed, not dropped in silence',
        () async {
      await _appendLocal(db, set, music, 'a');
      await db.into(db.playlistItems).insert(PlaylistItemsCompanion.insert(
            id: 'gap',
            playlistId: set,
            position: 5.0,
            itemType: const Value(PlaylistItemType.silence),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ));

      final queue = await repo.buildQueue(set);
      expect(queue.entries, hasLength(1));
      expect(queue.unavailable.single.itemId, 'gap');
      expect(queue.unavailable.single.reason, contains('silence'));
    });

    test('an unknown playlist is a programming error, not an empty queue', () {
      expect(() => repo.buildQueue('no-such-set'), throwsArgumentError);
    });
  });

  group('refreshing a row whose URL is about to expire', () {
    setUp(() async {
      await _addTidalAccount(db);
      await _appendTidal(db, set, 't');
    });

    test('the media comes back freshly signed', () async {
      final entry = (await repo.buildQueue(set)).entries.single;
      tidal.signature = '?sig=second';

      final fresh = await repo.refreshEntry(entry);

      expect(fresh.media.uri.toString(), endsWith('?sig=second'));
      expect(entry.media.uri.toString(), isNot(contains('sig')),
          reason: 'the original entry should not be mutated');
    });

    test('the new expiry comes with it', () async {
      final entry = (await repo.buildQueue(set)).entries.single;
      tidal.expiresAt = DateTime.utc(2026, 8, 26, 3);

      final fresh = await repo.refreshEntry(entry);

      expect(fresh.media.expiresAt, DateTime.utc(2026, 8, 26, 3));
    });

    test('everything the set decided about the row survives', () async {
      // A URL dying at the ninety-minute mark says nothing about the
      // crossfade or the announcement the operator chose for that row.
      await _override(
        db,
        'item-t',
        const PlaylistItemsCompanion(
          crossfadeMs: Value(Duration(seconds: 9)),
          announcementText: Value('Next up, a Tango'),
        ),
      );

      final entry = (await repo.buildQueue(set)).entries.single;
      final fresh = await repo.refreshEntry(entry);

      expect(fresh.itemId, entry.itemId);
      expect(fresh.spec.crossfade, const Duration(seconds: 9));
      expect(fresh.announcementText, 'Next up, a Tango');
      expect(fresh.title, entry.title);
      expect(fresh.targetDuration, entry.targetDuration);
    });

    test('the trims and cue points resolve on the original terms', () async {
      // The refresh must not quietly drop the row's offsets: a track that
      // came back playing from 0:00 instead of 0:12 would be audible.
      await (db.update(db.tracks)..where((t) => t.id.equals('t'))).write(
        const TracksCompanion(
          gainDb: Value(-4.0),
          cueInMs: Value(Duration(milliseconds: 500)),
        ),
      );
      await _override(
        db,
        'item-t',
        const PlaylistItemsCompanion(
          gainOffsetDb: Value(1.5),
          startOffsetMs: Value(Duration(milliseconds: 250)),
          endOffsetMs: Value(Duration(seconds: 90)),
        ),
      );

      final entry = (await repo.buildQueue(set)).entries.single;
      final fresh = await repo.refreshEntry(entry);

      expect(fresh.media.gainDb, entry.media.gainDb);
      expect(fresh.media.cueIn, const Duration(milliseconds: 750));
      expect(fresh.media.cueOut, const Duration(seconds: 90));
    });

    test('a row deleted mid-set is an error, not a silently empty entry',
        () async {
      // Someone editing the set while it plays. The engine catches this and
      // keeps the URL it already has rather than stopping the music.
      final entry = (await repo.buildQueue(set)).entries.single;
      await (db.delete(db.playlistItems)..where((i) => i.id.equals('item-t')))
          .go();

      expect(() => repo.refreshEntry(entry), throwsStateError);
    });
  });

  group('the shape of a set', () {
    test('every row inherits the set-wide per-song cap', () async {
      // "Two minutes of each track" is one setting on the night, not forty
      // identical overrides on forty rows.
      await _appendLocal(db, set, music, 'a');
      await _appendLocal(db, set, music, 'b');
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: const Duration(minutes: 2));

      final resolved = await repo.buildQueue(set);

      expect(
        [for (final entry in resolved.entries) entry.targetDuration],
        [const Duration(minutes: 2), const Duration(minutes: 2)],
      );
    });

    test("a row's own cap wins over the set's", () async {
      // A competition round in the middle of a social set.
      await _appendLocal(db, set, music, 'a');
      await _appendLocal(db, set, music, 'b');
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: const Duration(minutes: 2));
      await (db.update(db.playlistItems)
            ..where((i) => i.id.equals('item-b')))
          .write(const PlaylistItemsCompanion(
              targetDurationMs: Value(Duration(seconds: 105))));

      final resolved = await repo.buildQueue(set);

      expect(
        [for (final entry in resolved.entries) entry.targetDuration],
        [const Duration(minutes: 2), const Duration(seconds: 105)],
      );
    });

    test('no cap anywhere plays each track to its end', () async {
      await _appendLocal(db, set, music, 'a');

      final resolved = await repo.buildQueue(set);

      expect(resolved.entries.single.targetDuration, isNull);
    });

    test('the shape can be cleared again', () async {
      await db.playlistDao.setShape(set,
          songLimit: 5, targetDuration: const Duration(minutes: 2));
      expect((await db.playlistDao.byId(set))!.songLimit, 5);

      await db.playlistDao
          .setShape(set, songLimit: null, targetDuration: null);

      final playlist = (await db.playlistDao.byId(set))!;
      expect(playlist.songLimit, isNull);
      expect(playlist.targetDurationMs, isNull);
    });
  });
}


// ---------------------------------------------------------------------------

Future<void> _addDanceTypes(SayawDatabase db) async {
  await db.into(db.danceTypes).insert(
      DanceTypesCompanion.insert(id: 'tango', name: 'Tango', slug: 'tango'));
  await db.into(db.danceTypes).insert(
      DanceTypesCompanion.insert(id: 'waltz', name: 'Waltz', slug: 'waltz'));
}

Future<void> _setTemplate(SayawDatabase db, String id, String template) =>
    (db.update(db.danceTypes)..where((d) => d.id.equals(id)))
        .write(DanceTypesCompanion(ttsTemplate: Value(template)));

Future<void> _override(
        SayawDatabase db, String itemId, PlaylistItemsCompanion values) =>
    (db.update(db.playlistItems)..where((i) => i.id.equals(itemId)))
        .write(values);

Future<void> _appendLocal(
  SayawDatabase db,
  String playlistId,
  Directory music,
  String id, {
  String? danceTypeId,
}) async {
  File('${music.path}/$id.flac').writeAsStringSync('not really audio');
  await db.trackDao.upsert(TracksCompanion.insert(
    id: id,
    sourceType: SourceType.local,
    localPath: Value('${music.path}/$id.flac'),
    title: 'Track $id',
    addedAt: clock.now(),
    updatedAt: clock.now(),
  ));
  await db.playlistDao.appendTrack(
    playlistId: playlistId,
    trackId: id,
    danceTypeId: danceTypeId,
    id: 'item-$id',
  );
}

Future<void> _addPlexAccount(SayawDatabase db) =>
    db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
          id: 'plex',
          provider: SourceProvider.plex,
          displayName: 'Home Server',
          machineIdentifier: const Value('server-uuid'),
          keychainRef: 'keychain-plex',
          createdAt: clock.now(),
        ));

Future<void> _addTidalAccount(SayawDatabase db) =>
    db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
          id: 'tidal',
          provider: SourceProvider.tidal,
          displayName: 'TIDAL',
          keychainRef: 'keychain-tidal',
          createdAt: clock.now(),
        ));

Future<void> _appendPlex(SayawDatabase db, String playlistId, String id) async {
  await db.trackDao.upsert(TracksCompanion.insert(
    id: id,
    sourceType: SourceType.plex,
    accountId: const Value('plex'),
    sourceId: Value(id),
    sourcePartId: const Value('55'),
    title: 'Track $id',
    addedAt: clock.now(),
    updatedAt: clock.now(),
  ));
  await db.playlistDao
      .appendTrack(playlistId: playlistId, trackId: id, id: 'item-$id');
}

Future<void> _appendTidal(SayawDatabase db, String playlistId, String id) async {
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
      .appendTrack(playlistId: playlistId, trackId: id, id: 'item-$id');
}

PlaylistItem _item({
  required String playlistId,
  Duration? crossfadeMs,
  FadeCurve? fadeInCurve,
  FadeCurve? fadeOutCurve,
  AnnounceMode? announceMode,
  bool pauseAfter = false,
}) =>
    PlaylistItem(
      id: 'item',
      playlistId: playlistId,
      position: 1.0,
      itemType: PlaylistItemType.track,
      crossfadeMs: crossfadeMs,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      announceMode: announceMode,
      startOffsetMs: Duration.zero,
      gainOffsetDb: 0.0,
      pauseAfter: pauseAfter,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

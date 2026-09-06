import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';

import 'db_harness.dart';

void main() {
  late SayawDatabase db;
  late String set;

  setUp(() async {
    db = openTestDatabase();
    set = await db.playlistDao.createPlaylist(name: 'Saturday Social');
  });

  group('building a set', () {
    test('appended rows land in the order they were added', () async {
      await _appendTracks(db, set, ['a', 'b', 'c']);

      expect(await _positions(db, set), [1.0, 2.0, 3.0]);
      expect(await _titles(db, set), ['Track a', 'Track b', 'Track c']);
    });

    test('a row carries its track and dance type with it', () async {
      await db.into(db.danceTypes).insert(DanceTypesCompanion.insert(
            id: 'tango',
            name: 'Tango',
            slug: 'tango',
          ));
      await _appendTracks(db, set, ['a'], danceTypeId: 'tango');

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(row.track!.title, 'Track a');
      expect(row.danceType!.name, 'Tango');
      expect(row.item.itemType, PlaylistItemType.track);
    });

    test('a row without a track still comes back', () async {
      final now = clock.now();
      await db.into(db.playlistItems).insert(PlaylistItemsCompanion.insert(
            id: 'gap',
            playlistId: set,
            position: 1.0,
            itemType: const Value(PlaylistItemType.silence),
            silenceMs: const Value(Duration(seconds: 30)),
            createdAt: now,
            updatedAt: now,
          ));

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(row.track, isNull);
      expect(row.item.silenceMs, const Duration(seconds: 30));
    });

    test('the list updates live as rows are added', () async {
      // `emitsThrough` rather than a count: adding a track writes to `tracks`
      // and to `playlist_items`, and the join watches both, so the number of
      // emissions on the way is drift's business rather than this test's.
      final arrived = expectLater(
        db.playlistDao.watchItems(set),
        emitsThrough(hasLength(1)),
      );

      await _appendTracks(db, set, ['a']);
      await arrived;
    });
  });

  group('one row on its own', () {
    test('it comes back with its track and dance type joined', () async {
      await db.into(db.danceTypes).insert(DanceTypesCompanion.insert(
            id: 'tango',
            name: 'Tango',
            slug: 'tango',
          ));
      await _appendTracks(db, set, ['a'], danceTypeId: 'tango');
      final id = (await db.playlistDao.itemsOf(set)).single.item.id;

      final row = await db.playlistDao.rowById(id);

      expect(row!.track!.title, 'Track a');
      expect(row.danceType!.name, 'Tango');
    });

    test('it picks out the right row from a set of them', () async {
      await _appendTracks(db, set, ['a', 'b', 'c']);
      final rows = await db.playlistDao.itemsOf(set);

      final row = await db.playlistDao.rowById(rows[1].item.id);

      expect(row!.track!.title, 'Track b');
    });

    test('a row that has been deleted is null, not a throw', () async {
      // The set can be edited while it is playing, so this is a state the
      // engine's refresh has to survive rather than a programming error.
      expect(await db.playlistDao.rowById('no-such-item'), isNull);
    });
  });

  group('reordering', () {
    setUp(() => _appendTracks(db, set, ['a', 'b', 'c', 'd']));

    test('dragging a row to the front puts it there', () async {
      await db.playlistDao.move(playlistId: set, oldIndex: 2, newIndex: 0);
      expect(await _titles(db, set),
          ['Track c', 'Track a', 'Track b', 'Track d']);
    });

    test('dragging a row to the end puts it there', () async {
      await db.playlistDao.move(playlistId: set, oldIndex: 0, newIndex: 3);
      expect(await _titles(db, set),
          ['Track b', 'Track c', 'Track d', 'Track a']);
    });

    test('dragging a row into the middle puts it between its neighbours',
        () async {
      final position =
          await db.playlistDao.move(playlistId: set, oldIndex: 3, newIndex: 1);

      expect(await _titles(db, set),
          ['Track a', 'Track d', 'Track b', 'Track c']);
      expect(position, 1.5);
    });

    test('dropping a row where it already was changes nothing', () async {
      final before = await _positions(db, set);
      await db.playlistDao.move(playlistId: set, oldIndex: 1, newIndex: 1);
      expect(await _positions(db, set), before);
    });

    test('moving one row of four hundred writes one row', () async {
      // The whole reason `position` is a REAL. This write happens mid-set,
      // against the same file the engine is reading to preload the next track.
      await withClock(Clock.fixed(DateTime.utc(2026, 8, 25, 22)), () async {
        await db.playlistDao.move(playlistId: set, oldIndex: 3, newIndex: 1);
      });

      final touched = await (db.select(db.playlistItems)
            ..where((i) => i.updatedAt.equals(
                DateTime.utc(2026, 8, 25, 22).millisecondsSinceEpoch)))
          .get();

      expect(touched.map((i) => i.trackId), ['d']);
    });
  });

  group('when the gaps run out', () {
    test('a set is spread back out and the move still lands', () async {
      await _appendTracks(db, set, ['a', 'b', 'c']);

      // Roughly fifty consecutive insertions at the same point get here.
      await _setPosition(db, 'item-b', 1.0 + 1e-7);
      await _setPosition(db, 'item-a', 1.0);

      final position =
          await db.playlistDao.move(playlistId: set, oldIndex: 2, newIndex: 1);

      expect(await _titles(db, set), ['Track a', 'Track c', 'Track b']);
      expect(await _positions(db, set), [1.0, 1.5, 2.0]);
      expect(position, 1.5);
    });

    test('renormalising cannot collide with a row it has not moved yet',
        () async {
      await _appendTracks(db, set, ['a', 'b']);

      // `a` has to become 1.0, which is exactly where `b` still is. Written
      // naively that trips the unique index on (playlist_id, position).
      await _setPosition(db, 'item-a', 0.5);
      await _setPosition(db, 'item-b', 1.0);

      await db.playlistDao.renormalizePositions(set);

      expect(await _positions(db, set), [1.0, 2.0]);
      expect(await _titles(db, set), ['Track a', 'Track b']);
    });

    test('renormalising a set that has drifted below zero still works',
        () async {
      // Repeatedly dragging rows to the front walks positions negative.
      await _appendTracks(db, set, ['a', 'b']);
      await _setPosition(db, 'item-a', -4.0);
      await _setPosition(db, 'item-b', -3.0);

      await db.playlistDao.renormalizePositions(set);
      expect(await _positions(db, set), [1.0, 2.0]);
      expect(await _titles(db, set), ['Track a', 'Track b']);
    });

    test('renormalising an empty set is a no-op', () async {
      await db.playlistDao.renormalizePositions(set);
      expect(await _positions(db, set), isEmpty);
    });
  });

  group('removing things', () {
    test('a removed row leaves the rest in order', () async {
      await _appendTracks(db, set, ['a', 'b', 'c']);
      await db.playlistDao.removeItem('item-b');

      expect(await _titles(db, set), ['Track a', 'Track c']);
    });

    test('deleting a playlist takes its rows with it', () async {
      await _appendTracks(db, set, ['a', 'b']);
      await (db.delete(db.playlists)..where((p) => p.id.equals(set))).go();

      expect(await db.select(db.playlistItems).get(), isEmpty);
      // The tracks themselves survive: they belong to the library, not the set.
      expect(await db.select(db.tracks).get(), hasLength(2));
    });

    test('deleting a track removes the rows that pointed at it', () async {
      await _appendTracks(db, set, ['a', 'b']);
      await db.trackDao.deleteById('a');

      expect(await _titles(db, set), ['Track b']);
    });
  });

  group('tagging a row with a sound', () {
    test('the row comes back carrying the cue', () async {
      await _appendTracks(db, set, ['a']);
      final cue = await db.soundCueDao
          .add(label: 'Take your partners', filePath: '/clips/partners.wav');

      await db.playlistDao.tagSoundCue(itemId: 'item-a', cueId: cue);

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(row.item.soundCueId, cue);
      expect(row.soundCue!.label, 'Take your partners');
      expect(row.soundCue!.filePath, '/clips/partners.wav');
    });

    test('one recording can announce as many rows as the night needs',
        () async {
      await _appendTracks(db, set, ['a', 'b']);
      final cue =
          await db.soundCueDao.add(label: 'Rotate', filePath: '/clips/r.wav');

      await db.playlistDao.tagSoundCue(itemId: 'item-a', cueId: cue);
      await db.playlistDao.tagSoundCue(itemId: 'item-b', cueId: cue);

      final rows = await db.playlistDao.itemsOf(set);
      expect([for (final row in rows) row.soundCue?.label],
          ['Rotate', 'Rotate']);
    });

    test('clearing the tag leaves the row in the set', () async {
      await _appendTracks(db, set, ['a']);
      final cue =
          await db.soundCueDao.add(label: 'Rotate', filePath: '/clips/r.wav');
      await db.playlistDao.tagSoundCue(itemId: 'item-a', cueId: cue);

      await db.playlistDao.tagSoundCue(itemId: 'item-a', cueId: null);

      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(row.item.soundCueId, isNull);
      expect(row.soundCue, isNull);
      expect(row.track!.title, 'Track a');
    });

    test('deleting the sound quiets the row rather than dropping it',
        () async {
      await _appendTracks(db, set, ['a']);
      final cue =
          await db.soundCueDao.add(label: 'Rotate', filePath: '/clips/r.wav');
      await db.playlistDao.tagSoundCue(itemId: 'item-a', cueId: cue);

      await db.soundCueDao.remove(cue);

      // ON DELETE SET NULL, not CASCADE: removing a whistle from the bar must
      // never take a song out of the set with it.
      final row = (await db.playlistDao.itemsOf(set)).single;
      expect(row.item.soundCueId, isNull);
      expect(row.track!.title, 'Track a');
    });
  });

  group('what will still play with the network gone', () {
    setUp(() async {
      await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
            id: 'plex',
            provider: SourceProvider.plex,
            displayName: 'Home Server',
            keychainRef: 'keychain-plex',
            createdAt: clock.now(),
          ));
    });

    test('local files, cached remotes and spoken rows; nothing else', () async {
      await _appendTracks(db, set, ['local']);
      await _appendRemote(db, set, 'uncached');
      await _appendRemote(db, set, 'cached');
      await _appendRemote(db, set, 'stale');
      await _appendSilence(db, set, 'gap');

      await _cache(db, 'cached', CacheState.complete);
      await _cache(db, 'stale', CacheState.complete,
          expiresAt: DateTime.utc(2000));

      expect(await db.playlistDao.offlineAvailability(set), {
        'item-local': true,
        'item-uncached': false,
        'item-cached': true,
        'item-stale': false,
        'gap': true,
      });
    });

    test('a download still in flight does not count', () async {
      await _appendRemote(db, set, 'partial');
      await _cache(db, 'partial', CacheState.partial);

      expect(await db.playlistDao.offlineAvailability(set),
          {'item-partial': false});
    });

    test('a cache entry that has not expired yet counts', () async {
      await _appendRemote(db, set, 'fresh');
      await _cache(db, 'fresh', CacheState.complete,
          expiresAt: DateTime.utc(2100));

      expect(
          await db.playlistDao.offlineAvailability(set), {'item-fresh': true});
    });
  });
}

// ---------------------------------------------------------------------------

Future<void> _appendTracks(
  SayawDatabase db,
  String playlistId,
  List<String> ids, {
  String? danceTypeId,
}) async {
  for (final id in ids) {
    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.local,
      localPath: Value('/music/$id.flac'),
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
}

Future<void> _appendRemote(
    SayawDatabase db, String playlistId, String id) async {
  await db.trackDao.upsert(TracksCompanion.insert(
    id: id,
    sourceType: SourceType.plex,
    accountId: const Value('plex'),
    sourceId: Value(id),
    title: 'Track $id',
    addedAt: clock.now(),
    updatedAt: clock.now(),
  ));
  await db.playlistDao
      .appendTrack(playlistId: playlistId, trackId: id, id: 'item-$id');
}

Future<void> _appendSilence(
    SayawDatabase db, String playlistId, String id) async {
  final last = await _positions(db, playlistId);
  await db.into(db.playlistItems).insert(PlaylistItemsCompanion.insert(
        id: id,
        playlistId: playlistId,
        position: last.isEmpty ? 1.0 : last.last + 1.0,
        itemType: const Value(PlaylistItemType.silence),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ));
}

Future<void> _cache(
  SayawDatabase db,
  String trackId,
  CacheState state, {
  DateTime? expiresAt,
}) =>
    db.into(db.cacheEntries).insert(CacheEntriesCompanion.insert(
          trackId: trackId,
          state: Value(state),
          expiresAt: Value(expiresAt),
          createdAt: clock.now(),
        ));

Future<void> _setPosition(SayawDatabase db, String itemId, double position) =>
    (db.update(db.playlistItems)..where((i) => i.id.equals(itemId)))
        .write(PlaylistItemsCompanion(position: Value(position)));

Future<List<double>> _positions(SayawDatabase db, String playlistId) async =>
    [for (final row in await db.playlistDao.itemsOf(playlistId)) row.item.position];

Future<List<String>> _titles(SayawDatabase db, String playlistId) async => [
      for (final row in await db.playlistDao.itemsOf(playlistId))
        row.track?.title ?? '(no track)',
    ];

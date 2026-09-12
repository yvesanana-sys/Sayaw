import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/db/track_dao.dart';
import 'package:sayaw/data/media_resolver.dart' show CachePolicy;

import 'db_harness.dart';

void main() {
  group('storing a track', () {
    test('millisecond columns survive the round trip as Dart types', () async {
      final db = openTestDatabase();
      final added = DateTime.utc(2026, 8, 25, 21, 30, 15, 250);

      await db.trackDao.upsert(TracksCompanion.insert(
        id: 'kiss-of-fire',
        sourceType: SourceType.local,
        localPath: const Value('/music/kiss-of-fire.flac'),
        title: 'Kiss of Fire',
        artist: const Value('Georgia Gibbs'),
        durationMs: const Value(Duration(minutes: 2, seconds: 58)),
        cueInMs: const Value(Duration(milliseconds: 400)),
        cueOutMs: const Value(Duration(minutes: 2, seconds: 50)),
        gainDb: const Value(-3.5),
        addedAt: added,
        updatedAt: added,
      ));

      final track = await db.trackDao.byId('kiss-of-fire');
      expect(track!.durationMs, const Duration(minutes: 2, seconds: 58));
      expect(track.cueInMs, const Duration(milliseconds: 400));
      expect(track.cueOutMs, const Duration(minutes: 2, seconds: 50));
      expect(track.gainDb, -3.5);

      // The schema stores milliseconds; drift's own DateTime columns would have
      // truncated the 250 ms away.
      expect(track.addedAt, added);
    });

    test('cache policy is stored in the schema spelling, not the Dart one',
        () async {
      final db = openTestDatabase();
      await db.trackDao.upsert(_local('a').copyWith(
        cachePolicy: const Value(CachePolicy.sessionOnly),
      ));

      final raw = await db
          .customSelect("SELECT cache_policy FROM tracks WHERE id = 'a'")
          .getSingle();
      expect(raw.read<String>('cache_policy'), 'session_only');
      expect((await db.trackDao.byId('a'))!.cachePolicy, CachePolicy.sessionOnly);
    });

    test('upserting the same id updates rather than duplicating', () async {
      final db = openTestDatabase();
      await db.trackDao.upsert(_local('a'));
      await db.trackDao.upsert(_local('a').copyWith(title: const Value('Renamed')));

      expect((await db.select(db.tracks).get()), hasLength(1));
      expect((await db.trackDao.byId('a'))!.title, 'Renamed');
    });
  });

  group('searching the library', () {
    late SayawDatabase db;

    setUp(() async {
      db = openTestDatabase();
      await db.trackDao.upsertAll([
        _local('1').copyWith(
          title: const Value('Kiss of Fire'),
          artist: const Value('Georgia Gibbs'),
          album: const Value('Ballroom Classics'),
        ),
        _local('2').copyWith(
          title: const Value('Sway'),
          artist: const Value('Dean Martin'),
          album: const Value('Dino: The Essential'),
        ),
        _local('3').copyWith(
          title: const Value('Kiss the Rain'),
          artist: const Value('Yiruma'),
        ),
      ]);
    });

    test('matches on title, artist and album alike', () async {
      expect(await _titles(db, 'georgia'), ['Kiss of Fire']);
      expect(await _titles(db, 'dino'), ['Sway']);
      expect((await _titles(db, 'kiss'))..sort(),
          ['Kiss of Fire', 'Kiss the Rain']);
    });

    test('the last word is a prefix, so results narrow while typing', () async {
      expect(await _titles(db, 'swa'), ['Sway']);
      expect(await _titles(db, 'georgia gib'), ['Kiss of Fire']);
    });

    test('earlier words are whole words, not prefixes', () async {
      // 'kis rain' should find nothing: only the final token is a prefix.
      expect(await _titles(db, 'kis rain'), isEmpty);
      expect(await _titles(db, 'kiss rain'), ['Kiss the Rain']);
    });

    test('an edited track is findable under its new title, not its old one',
        () async {
      await db.trackDao.upsert(
          _local('2').copyWith(title: const Value('Sway (Mambo Version)')));

      expect(await _titles(db, 'mambo'), ['Sway (Mambo Version)']);
      expect(await _titles(db, 'sway'), ['Sway (Mambo Version)']);
    });

    test('a deleted track disappears from the index', () async {
      await db.trackDao.deleteById('2');
      expect(await _titles(db, 'sway'), isEmpty);
    });

    test('a live search reflects a track added after it started', () async {
      final found = expectLater(
        db.trackDao.watchSearch('bachata'),
        emitsThrough(isA<List<Track>>()
            .having((r) => [for (final t in r) t.title], 'titles',
                ['Bachata Rosa'])),
      );

      await db.trackDao
          .upsert(_local('4').copyWith(title: const Value('Bachata Rosa')));
      await found;
    });

    test('punctuation an operator types is matched, not parsed', () async {
      await db.trackDao
          .upsert(_local('5').copyWith(title: const Value('Sway (12" Mix)')));

      // Unquoted, a `"` opens a phrase and raises a syntax error on the way
      // out; `*` is a prefix operator with nothing in front of it.
      expect(await _titles(db, '12" mix'), ['Sway (12" Mix)']);
      expect(await _titles(db, 'sway * mix'), ['Sway (12" Mix)']);

      // `AND` is a word here, not an operator, so it is searched for — no
      // track contains it. Left as an operator it would silently mean
      // something else, which is worse than finding nothing.
      expect(await _titles(db, 'sway AND mix'), isEmpty);
    });

    test('a query with nothing searchable in it returns nothing', () async {
      expect(await db.trackDao.search('   '), isEmpty);
      expect(await db.trackDao.search('!?*'), isEmpty);
      expect(await db.trackDao.watchSearch('  ').first, isEmpty);
    });

    test('the limit is honoured', () async {
      expect(await db.trackDao.search('kiss', limit: 1), hasLength(1));
    });
  });

  group('every id a search would list', () {
    late SayawDatabase db;

    setUp(() async {
      db = openTestDatabase();
      // Out of order on purpose, and named the way a folder for a night is.
      await db.trackDao.upsertAll([
        _local('c').copyWith(title: const Value('03_(Rumba)_Fields of Gold')),
        _local('a').copyWith(title: const Value('01_(Waltz)_Rilassamento')),
        _local('b').copyWith(title: const Value('02_(Waltz)_Appassionata')),
      ]);
    });

    test('an empty query is the whole library, in title order', () async {
      // Files numbered to play in order arrive in it — not newest first,
      // which is the folder backwards.
      expect(await db.trackDao.idsMatching(''), ['a', 'b', 'c']);
    });

    test('a query is every match, uncapped, still in title order', () async {
      expect(await db.trackDao.idsMatching('waltz'), ['a', 'b']);
    });

    test('a query with nothing to search on is nothing', () async {
      // What the list on screen shows for it, and this answers the same.
      expect(await db.trackDao.idsMatching('!!!'), isEmpty);
    });
  });

  group('emptying the library', () {
    test('every row that pointed at a track goes with it', () async {
      final db = openTestDatabase();
      await db.trackDao.upsertAll([_local('a'), _local('b')]);
      final set = await db.playlistDao.createPlaylist(name: 'Social');
      await db.playlistDao.appendTracks(playlistId: set, trackIds: ['a', 'b']);
      expect(await db.trackDao.count(), 2);

      final removed = await db.trackDao.deleteAll();

      expect(removed, 2);
      expect(await db.trackDao.count(), 0);
      expect(await db.playlistDao.itemsOf(set), isEmpty,
          reason: 'the set empties with the library');
      expect(await db.playlistDao.byId(set), isNotNull,
          reason: 'the set itself is kept, empty');
      // And the search index went with the rows.
      expect(await db.trackDao.search('Track'), isEmpty);
    });
  });

  group('ftsQuery', () {
    test('quotes every token and prefixes only the last', () {
      expect(ftsQuery('viennese waltz'), '"viennese" "waltz"*');
      expect(ftsQuery('waltz'), '"waltz"*');
    });

    test('drops punctuation and collapses whitespace', () {
      expect(ftsQuery('  sway,   dean-martin '), '"sway" "dean" "martin"*');
    });

    test('keeps letters and digits from any script', () {
      expect(ftsQuery('Café 2step'), '"Café" "2step"*');
    });

    test('is null when there is nothing to search for', () {
      expect(ftsQuery(''), isNull);
      expect(ftsQuery('   '), isNull);
      expect(ftsQuery('-- "" *'), isNull);
    });
  });
}

TracksCompanion _local(String id) => TracksCompanion.insert(
      id: id,
      sourceType: SourceType.local,
      localPath: Value('/music/$id.flac'),
      title: 'Track $id',
      addedAt: clock.now(),
      updatedAt: clock.now(),
    );

Future<List<String>> _titles(SayawDatabase db, String query) async =>
    [for (final track in await db.trackDao.search(query)) track.title];

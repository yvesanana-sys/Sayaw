import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/set_ordering.dart';

import 'db_harness.dart';

/// Rows are built through a real database rather than by hand.
///
/// `Track` is generated and gains required fields as the schema grows, so a
/// hand-built one is a fixture that breaks for reasons that have nothing to do
/// with what is being tested. This also exercises the join the ordering
/// actually reads.
class _Fixture {
  _Fixture(this.db);

  final SayawDatabase db;
  String set = '';

  Future<void> open() async {
    set = await db.playlistDao.createPlaylist(name: 'Saturday Social');
  }

  /// One row, with whatever tempo evidence the test wants it to have.
  Future<void> add(
    String id, {
    double? bpm,
    double? danceMin,
    double? danceMax,
  }) async {
    String? danceTypeId;

    if (danceMin != null || danceMax != null) {
      danceTypeId = 'dance-$id';
      await db.into(db.danceTypes).insert(DanceTypesCompanion.insert(
            id: danceTypeId,
            name: 'Dance $id',
            slug: 'dance-$id',
            bpmMin: Value(danceMin),
            bpmMax: Value(danceMax),
          ));
    }

    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.local,
      localPath: Value('/music/$id.flac'),
      title: 'Track $id',
      bpm: Value(bpm),
      addedAt: clock.now(),
      updatedAt: clock.now(),
    ));

    await db.playlistDao.appendTrack(
      playlistId: set,
      trackId: id,
      danceTypeId: danceTypeId,
      id: 'item-$id',
    );
  }

  Future<List<PlaylistRow>> rows() => db.playlistDao.itemsOf(set);

  /// The one row for [id], for the single-row assertions.
  Future<PlaylistRow> row(String id) async =>
      (await rows()).firstWhere((r) => r.item.id == 'item-$id');
}

List<String> _order(OrderedSet set) =>
    [for (final id in set.itemIds) id.replaceFirst('item-', '')];

void main() {
  late SayawDatabase db;
  late _Fixture fx;

  setUp(() async {
    db = openTestDatabase();
    fx = _Fixture(db);
    await fx.open();
  });

  group('what a row counts as', () {
    test("the file's own tag wins", () async {
      await fx.add('a', bpm: 128, danceMin: 80, danceMax: 90);

      expect(effectiveBpm(await fx.row('a')), 128);
      expect(tempoSourceOf(await fx.row('a')), TempoSource.tagged);
    });

    test('a dance type stands in for a missing tag', () async {
      // A Waltz with no BPM tag is still a Waltz, and the middle of its range
      // is a better guess than nothing.
      await fx.add('a', danceMin: 84, danceMax: 90);

      expect(effectiveBpm(await fx.row('a')), 87);
      expect(tempoSourceOf(await fx.row('a')), TempoSource.danceType);
    });

    test('half a range is better than none', () async {
      await fx.add('low', danceMin: 84);
      await fx.add('high', danceMax: 90);

      expect(effectiveBpm(await fx.row('low')), 84);
      expect(effectiveBpm(await fx.row('high')), 90);
    });

    test('a zero tag is absence, not a very slow track', () async {
      // The value a tagger writes for "not analysed". Read literally it would
      // sort to the front of every set.
      await fx.add('a', bpm: 0, danceMin: 84, danceMax: 90);

      expect(effectiveBpm(await fx.row('a')), 87,
          reason: 'falls through to the dance type');
      expect(tempoSourceOf(await fx.row('a')), TempoSource.danceType);
    });

    test('nothing at all is unknown', () async {
      await fx.add('a');

      expect(effectiveBpm(await fx.row('a')), isNull);
      expect(tempoSourceOf(await fx.row('a')), TempoSource.unknown);
    });
  });

  group('putting a set in order', () {
    test('slowest first', () async {
      await fx.add('fast', bpm: 180);
      await fx.add('slow', bpm: 84);
      await fx.add('middling', bpm: 120);

      final ordered = orderByTempo(await fx.rows());

      expect(_order(ordered), ['slow', 'middling', 'fast']);
      expect(ordered.isExact, isTrue);
    });

    test('fastest first, for winding a night down', () async {
      await fx.add('slow', bpm: 84);
      await fx.add('fast', bpm: 180);

      final ordered =
          orderByTempo(await fx.rows(), order: TempoOrder.descending);

      expect(_order(ordered), ['fast', 'slow']);
    });

    test('two tracks at the same tempo keep the order they were put in',
        () async {
      // `List.sort` is not stable, so this is the property most likely to be
      // quietly wrong: an operator's deliberate pairing scrambled by a sort
      // that had no opinion either way.
      await fx.add('first', bpm: 120);
      await fx.add('second', bpm: 120);
      await fx.add('third', bpm: 120);
      await fx.add('slow', bpm: 84);

      final ordered = orderByTempo(await fx.rows());

      expect(_order(ordered), ['slow', 'first', 'second', 'third']);
    });

    test('tags and dance types sort against each other', () async {
      await fx.add('tagged-fast', bpm: 140);
      await fx.add('waltz', danceMin: 84, danceMax: 90);
      await fx.add('tagged-slow', bpm: 60);

      final ordered = orderByTempo(await fx.rows());

      expect(_order(ordered), ['tagged-slow', 'waltz', 'tagged-fast']);
      expect(ordered.guessed, ['item-waltz']);
      expect(ordered.isExact, isFalse);
    });

    test('rows with no tempo go last, in the order they were already in',
        () async {
      // Not scattered through the set, which would break the one property the
      // ordering exists for, and not dropped, which would change the set
      // behind the operator's back.
      await fx.add('mystery-b');
      await fx.add('fast', bpm: 180);
      await fx.add('mystery-a');
      await fx.add('slow', bpm: 84);

      final ordered = orderByTempo(await fx.rows());

      expect(_order(ordered), ['slow', 'fast', 'mystery-b', 'mystery-a']);
      expect(ordered.withoutTempo, ['item-mystery-b', 'item-mystery-a']);
    });

    test('every row comes back out', () async {
      // The invariant that matters most: a generator that loses rows is the
      // worst thing to find at a venue.
      await fx.add('a', bpm: 100);
      await fx.add('b');
      await fx.add('c', danceMin: 84, danceMax: 90);
      await fx.add('d', bpm: 60);

      final rows = await fx.rows();
      final ordered = orderByTempo(rows);

      expect(ordered.total, 4);
      expect(ordered.itemIds.toSet(), {for (final row in rows) row.item.id});
    });

    test('an empty set is an empty set', () {
      final ordered = orderByTempo([]);

      expect(ordered.itemIds, isEmpty);
      expect(ordered.isExact, isTrue);
    });

    test('a set nothing is known about is left exactly as it was', () async {
      await fx.add('a');
      await fx.add('b');
      await fx.add('c');

      final ordered = orderByTempo(await fx.rows());

      expect(_order(ordered), ['a', 'b', 'c']);
      expect(ordered.withoutTempo, hasLength(3));
    });
  });

  group('writing the order back', () {
    Future<void> append(List<String> ids) async {
      for (final id in ids) {
        await fx.add(id);
      }
    }

    Future<List<String>> order() async => [
          for (final row in await fx.rows())
            row.item.id.replaceFirst('item-', ''),
        ];

    test('the set comes back in exactly the order asked for', () async {
      await append(['a', 'b', 'c', 'd']);

      await db.playlistDao
          .applyOrder(fx.set, ['item-d', 'item-b', 'item-a', 'item-c']);

      expect(await order(), ['d', 'b', 'a', 'c']);
    });

    test('reversing a set does not trip the unique position index', () async {
      // Writing 1..n straight over rows already sitting on those numbers
      // collides part way through; everything is shifted clear first.
      await append(['a', 'b', 'c', 'd', 'e']);

      await db.playlistDao.applyOrder(
        fx.set,
        ['item-e', 'item-d', 'item-c', 'item-b', 'item-a'],
      );

      expect(await order(), ['e', 'd', 'c', 'b', 'a']);
    });

    test('positions come out as plain 1, 2, 3', () async {
      await append(['a', 'b', 'c']);

      await db.playlistDao.applyOrder(fx.set, ['item-c', 'item-b', 'item-a']);

      expect(
        [for (final row in await fx.rows()) row.item.position],
        [1.0, 2.0, 3.0],
      );
    });

    test('a row the caller forgot keeps its place at the end', () async {
      await append(['a', 'b', 'c']);

      await db.playlistDao.applyOrder(fx.set, ['item-c', 'item-a']);

      expect(await order(), ['c', 'a', 'b']);
    });

    test('an id from another set is ignored rather than obeyed', () async {
      await append(['a', 'b']);
      final other = await db.playlistDao.createPlaylist(name: 'Sunday');

      await db.playlistDao.applyOrder(fx.set, ['item-b', 'not-mine', 'item-a']);

      expect(await order(), ['b', 'a']);
      expect(await db.playlistDao.itemsOf(other), isEmpty);
    });

    test('an empty set is not something to write', () async {
      await db.playlistDao.applyOrder(fx.set, ['item-a']);

      expect(await order(), isEmpty);
    });
  });
}

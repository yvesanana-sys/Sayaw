import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/jack_and_jill.dart';

import 'db_harness.dart';

/// A `Random` that hands out a known sequence, so a draw can be asserted on
/// rather than merely watched.
class _ScriptedRandom implements Random {
  _ScriptedRandom(this.values);

  final List<int> values;
  int _next = 0;

  @override
  int nextInt(int max) {
    final value = values[_next++ % values.length];
    return value % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  late SayawDatabase db;

  setUp(() async {
    db = openTestDatabase();
    await db.into(db.danceTypes).insert(DanceTypesCompanion.insert(
          id: 'bachata',
          name: 'Bachata',
          slug: 'bachata',
        ));
  });

  Future<void> addTrack(String id, {String? dance = 'bachata'}) =>
      db.trackDao.upsert(TracksCompanion.insert(
        id: id,
        sourceType: SourceType.local,
        localPath: Value('/music/$id.flac'),
        title: 'Track $id',
        defaultDanceTypeId: Value(dance),
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));

  Future<List<String>> addPeople(List<String> names) async =>
      [for (final name in names) await db.participantDao.add(name)];

  group('what it needs before it can draw', () {
    test('nobody in the room', () async {
      await addTrack('a');

      expect(await JackAndJill(db: db).problems('bachata'),
          contains(DrawProblem.notEnoughDancers));
    });

    test('one person is not a pair', () async {
      await addTrack('a');
      await addPeople(['Ana']);

      expect(await JackAndJill(db: db).problems('bachata'),
          contains(DrawProblem.notEnoughDancers));
    });

    test('everyone has gone home', () async {
      await addTrack('a');
      final ids = await addPeople(['Ana', 'Yusuf']);
      for (final id in ids) {
        await db.participantDao.setPresent(id, false);
      }

      expect(await JackAndJill(db: db).problems('bachata'),
          contains(DrawProblem.notEnoughDancers));
    });

    test('nothing in the library filed under that dance', () async {
      await addTrack('a', dance: null);
      await addPeople(['Ana', 'Yusuf']);

      expect(await JackAndJill(db: db).problems('bachata'),
          contains(DrawProblem.noTracks));
    });

    test('with a track and two people there is nothing missing', () async {
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf']);

      expect(await JackAndJill(db: db).problems('bachata'), isEmpty);
    });
  });

  group('the draw', () {
    test('a song and two people, both from the room', () async {
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf']);

      final draw = await JackAndJill(db: db).draw('bachata');

      expect(draw.isComplete, isTrue);
      expect(draw.track!.title, 'Track a');
      expect([for (final d in draw.dancers) d.name], hasLength(2));
      expect(draw.danceType!.name, 'Bachata');
    });

    test('never the same person twice', () async {
      // The bug a caller has to resolve out loud in front of a room.
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf', 'Marta']);

      for (var i = 0; i < 40; i++) {
        final draw = await JackAndJill(db: db).draw('bachata');
        expect(draw.dancers[0].id, isNot(draw.dancers[1].id));
      }
    });

    test('only people who are still here', () async {
      await addTrack('a');
      final ids = await addPeople(['Ana', 'Yusuf', 'Gone']);
      await db.participantDao.setPresent(ids[2], false);

      for (var i = 0; i < 20; i++) {
        final draw = await JackAndJill(db: db).draw('bachata');
        expect([for (final d in draw.dancers) d.name],
            isNot(contains('Gone')));
      }
    });

    test('only tracks filed under that dance', () async {
      await addTrack('bachata-one');
      await addTrack('a-waltz', dance: null);
      await addPeople(['Ana', 'Yusuf']);

      for (var i = 0; i < 20; i++) {
        final draw = await JackAndJill(db: db).draw('bachata');
        expect(draw.track!.id, 'bachata-one');
      }
    });

    test('it prefers whoever has danced least', () async {
      // A uniform shuffle over a two-hour event reliably leaves somebody never
      // picked, and that person is standing right there.
      await addTrack('a');
      final ids = await addPeople(['Ana', 'Yusuf', 'Marta', 'Nikhil']);
      // Everyone but Nikhil has danced a lot.
      for (var i = 0; i < 5; i++) {
        await db.participantDao.recordDraw(ids.take(3));
      }

      final picked = <String>{};
      for (var i = 0; i < 10; i++) {
        final draw = await JackAndJill(db: db, random: Random(i))
            .draw('bachata', poolSize: 2);
        picked.addAll([for (final d in draw.dancers) d.name]);
      }

      expect(picked, contains('Nikhil'));
    });

    test('a pool of one is still widened to a pair', () async {
      // Two is the floor: a pool of one cannot make a pair, whatever was
      // asked for.
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf', 'Marta']);

      final draw =
          await JackAndJill(db: db).draw('bachata', poolSize: 1);

      expect(draw.dancers, hasLength(2));
    });

    test('the randomness is really used', () async {
      // A scripted Random proves the draw reads it rather than always taking
      // the head of the list.
      await addTrack('a');
      await addTrack('b');
      await addPeople(['Ana', 'Yusuf']);

      final first = await JackAndJill(db: db, random: _ScriptedRandom([0]))
          .draw('bachata');
      final second = await JackAndJill(db: db, random: _ScriptedRandom([1]))
          .draw('bachata');

      expect(first.track!.id, isNot(second.track!.id));
    });

    test('one person in the room draws one, not a crash', () async {
      await addTrack('a');
      await addPeople(['Ana']);

      final draw = await JackAndJill(db: db).draw('bachata');

      expect(draw.dancers, hasLength(1));
      expect(draw.isComplete, isFalse);
    });

    test('an empty library draws nobody a song, not a crash', () async {
      await addPeople(['Ana', 'Yusuf']);

      final draw = await JackAndJill(db: db).draw('bachata');

      expect(draw.track, isNull);
      expect(draw.isComplete, isFalse);
      expect(draw.dancers, hasLength(2));
    });

    test('a dance nobody has heard of is not a crash', () async {
      await addPeople(['Ana', 'Yusuf']);

      final draw = await JackAndJill(db: db).draw('no-such-dance');

      expect(draw.danceType, isNull);
      expect(draw.isComplete, isFalse);
    });
  });

  group('counting it', () {
    test('drawing does not count until it is committed', () async {
      // A caller who redraws because the pair just danced together should not
      // have that count against either of them.
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf']);

      await JackAndJill(db: db).draw('bachata');

      expect([for (final p in await db.participantDao.all()) p.drawCount],
          [0, 0]);
    });

    test('committing records both dancers', () async {
      await addTrack('a');
      await addPeople(['Ana', 'Yusuf']);
      final jj = JackAndJill(db: db);

      await jj.commit(await jj.draw('bachata'));

      expect([for (final p in await db.participantDao.all()) p.drawCount],
          [1, 1]);
    });

    test('committing a draw that never came together records nothing',
        () async {
      await addPeople(['Ana', 'Yusuf']);
      final jj = JackAndJill(db: db);

      await jj.commit(const Draw(track: null, dancers: []));

      expect([for (final p in await db.participantDao.all()) p.drawCount],
          [0, 0]);
    });
  });
}

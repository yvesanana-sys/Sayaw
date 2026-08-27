import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';

import 'db_harness.dart';

void main() {
  late SayawDatabase db;

  setUp(() => db = openTestDatabase());

  group('taking a roster at the door', () {
    test('a new event starts with nobody on the list', () async {
      expect(await db.participantDao.all(), isEmpty);
    });

    test('someone added is present by default', () async {
      await db.participantDao.add('Marta');

      final marta = (await db.participantDao.all()).single;
      expect(marta.name, 'Marta');
      expect(marta.isPresent, isTrue);
      expect(marta.drawCount, 0);
    });

    test('the same person twice is the same person', () async {
      // A roster taken at a door gets the same person entered twice, and two
      // Martas in a draw is a bug the caller resolves out loud in front of a
      // room.
      final first = await db.participantDao.add('Marta');
      final second = await db.participantDao.add('marta');

      expect(second, first);
      expect(await db.participantDao.all(), hasLength(1));
    });

    test('surrounding whitespace is not a different person', () async {
      final first = await db.participantDao.add('Marta');

      expect(await db.participantDao.add('  Marta  '), first);
    });

    test('a name that is only whitespace is refused', () async {
      await expectLater(
        db.participantDao.add('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('the list is alphabetical, which is how a door list is read',
        () async {
      for (final name in ['Yusuf', 'Ana', 'Marta']) {
        await db.participantDao.add(name);
      }

      expect([for (final p in await db.participantDao.all()) p.name],
          ['Ana', 'Marta', 'Yusuf']);
    });
  });

  group('who can be drawn', () {
    test('only the people still here', () async {
      final ana = await db.participantDao.add('Ana');
      await db.participantDao.add('Yusuf');

      await db.participantDao.setPresent(ana, false);

      expect([for (final p in await db.participantDao.present()) p.name],
          ['Yusuf']);
    });

    test('leaving early does not take someone off the list', () async {
      // Their name should not have to be retyped next week.
      final ana = await db.participantDao.add('Ana');
      await db.participantDao.setPresent(ana, false);

      expect(await db.participantDao.all(), hasLength(1));
    });

    test('someone who comes back can be drawn again', () async {
      final ana = await db.participantDao.add('Ana');
      await db.participantDao.setPresent(ana, false);
      await db.participantDao.setPresent(ana, true);

      expect(await db.participantDao.present(), hasLength(1));
    });

    test('whoever has danced least comes first', () async {
      // So a caller who wants a fair night can take from the top rather than
      // trusting a shuffle to be kind.
      final ana = await db.participantDao.add('Ana');
      final yusuf = await db.participantDao.add('Yusuf');
      await db.participantDao.recordDraw([ana, ana, yusuf].toSet());
      await db.participantDao.recordDraw([ana]);

      expect([for (final p in await db.participantDao.present()) p.name],
          ['Yusuf', 'Ana']);
    });
  });

  group('counting draws', () {
    test('being drawn is recorded', () async {
      final ana = await db.participantDao.add('Ana');
      final yusuf = await db.participantDao.add('Yusuf');

      await db.participantDao.recordDraw([ana, yusuf]);

      expect([for (final p in await db.participantDao.all()) p.drawCount],
          [1, 1]);
    });

    test('it accumulates across a night', () async {
      final ana = await db.participantDao.add('Ana');

      await db.participantDao.recordDraw([ana]);
      await db.participantDao.recordDraw([ana]);

      expect((await db.participantDao.all()).single.drawCount, 2);
    });

    test('recording nothing touches nothing', () async {
      final ana = await db.participantDao.add('Ana');
      await db.participantDao.recordDraw([ana]);

      await db.participantDao.recordDraw(const []);

      expect((await db.participantDao.all()).single.drawCount, 1);
    });

    test('the counts reset for the next event', () async {
      final ana = await db.participantDao.add('Ana');
      await db.participantDao.recordDraw([ana]);

      await db.participantDao.resetDraws();

      expect((await db.participantDao.all()).single.drawCount, 0);
    });
  });

  test('removing someone really removes them', () async {
    final ana = await db.participantDao.add('Ana');
    await db.participantDao.add('Yusuf');

    await db.participantDao.remove(ana);

    expect([for (final p in await db.participantDao.all()) p.name], ['Yusuf']);
  });

  test('the list is watchable, so a name typed at the door appears', () async {
    final seen = <int>[];
    final sub =
        db.participantDao.watchAll().listen((rows) => seen.add(rows.length));

    await db.participantDao.add('Ana');
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, contains(1));
  });
}

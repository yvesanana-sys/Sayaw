import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';

import 'db_harness.dart';

void main() {
  late SayawDatabase db;

  setUp(() => db = openTestDatabase());

  test('a new install has an empty soundboard', () async {
    // No sounds ship with the app — a whistle is the operator's own file.
    expect(await db.soundCueDao.all(), isEmpty);
  });

  test('a cue comes back as the audio layer\'s own type', () async {
    // `lib/audio/` never sees a database row, the same seam `QueueEntry` sits
    // behind.
    await db.soundCueDao
        .add(label: 'Whistle', filePath: '/fx/whistle.wav', id: 'w');

    final cue = (await db.soundCueDao.all()).single;
    expect(cue.id, 'w');
    expect(cue.label, 'Whistle');
    expect(cue.filePath, '/fx/whistle.wav');
  });

  test('a cue leaves the music alone unless it is asked not to', () async {
    await db.soundCueDao.add(label: 'Whistle', filePath: '/fx/w.wav');

    final cue = (await db.soundCueDao.all()).single;
    expect(cue.duckLevel, 1.0);
    expect(cue.ducks, isFalse);
  });

  test('a spoken cue records how far to dip', () async {
    await db.soundCueDao
        .add(label: 'Tag', filePath: '/fx/tag.wav', duckLevel: 0.3);

    expect((await db.soundCueDao.all()).single.ducks, isTrue);
  });

  test('cues keep the order they were added in', () async {
    for (final label in ['Whistle', 'Bell', 'Airhorn']) {
      await db.soundCueDao.add(label: label, filePath: '/fx/$label.wav');
    }

    expect(
      [for (final cue in await db.soundCueDao.all()) cue.label],
      ['Whistle', 'Bell', 'Airhorn'],
    );
  });

  test('a hotkey is optional', () async {
    await db.soundCueDao
        .add(label: 'Whistle', filePath: '/fx/w.wav', hotkey: '1', id: 'w');
    await db.soundCueDao.add(label: 'Bell', filePath: '/fx/b.wav', id: 'b');

    final rows = await db.select(db.soundCues).get();
    expect({for (final row in rows) row.id: row.hotkey},
        {'w': '1', 'b': null});
  });

  test('removing one leaves the rest', () async {
    await db.soundCueDao.add(label: 'Whistle', filePath: '/fx/w.wav', id: 'w');
    await db.soundCueDao.add(label: 'Bell', filePath: '/fx/b.wav', id: 'b');

    await db.soundCueDao.remove('w');

    expect([for (final cue in await db.soundCueDao.all()) cue.id], ['b']);
  });

  test('the list is watchable, so a button appears as soon as it is added',
      () async {
    final seen = <int>[];
    final sub = db.soundCueDao.watchAll().listen((cues) => seen.add(cues.length));

    await db.soundCueDao.add(label: 'Whistle', filePath: '/fx/w.wav');
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, contains(1));
  });
}

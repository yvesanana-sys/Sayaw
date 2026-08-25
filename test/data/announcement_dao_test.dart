import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/data/db/announcement_dao.dart';
import 'package:sayaw/data/db/database.dart';

import 'db_harness.dart';

void main() {
  late SayawDatabase db;
  late DriftAnnouncementCache store;

  const voice = TtsVoiceSettings(voiceId: 'en-GB-1', rate: 0.45, pitch: 1.1);
  final doorsOpen = DateTime.utc(2026, 8, 25, 19);

  setUp(() {
    db = openTestDatabase();
    store = DriftAnnouncementCache(db.announcementDao, voice);
  });

  test('a clip rendered before doors open is still there afterwards', () async {
    await withClock(Clock.fixed(doorsOpen), () async {
      await store.put(const AnnouncementClip(
        hash: 'abc',
        filePath: '/cache/abc.m4a',
        duration: Duration(milliseconds: 1420),
        text: 'Next dance: Viennese Waltz',
      ));
    });

    final clip = await store.get('abc');
    expect(clip!.filePath, '/cache/abc.m4a');
    expect(clip.text, 'Next dance: Viennese Waltz');

    // The duck envelope is scheduled from this, which is the whole reason
    // announcements are rendered to a file rather than spoken live.
    expect(clip.duration, const Duration(milliseconds: 1420));
  });

  test('the voice a clip was rendered with is recorded alongside it', () async {
    await store.put(const AnnouncementClip(
      hash: 'abc',
      filePath: '/cache/abc.m4a',
      duration: Duration(seconds: 1),
      text: 'Tango',
    ));

    final row = (await db.announcementDao.byHash('abc'))!;
    expect(row.voiceId, 'en-GB-1');
    expect(row.rate, 0.45);
    expect(row.pitch, 1.1);
  });

  test('a hash nobody has rendered yet is a miss, not an error', () async {
    expect(await store.get('never-rendered'), isNull);
  });

  test('re-rendering the same hash replaces the file it points at', () async {
    await store.put(const AnnouncementClip(
      hash: 'abc',
      filePath: '/cache/old.m4a',
      duration: Duration(seconds: 1),
      text: 'Tango',
    ));
    await store.put(const AnnouncementClip(
      hash: 'abc',
      filePath: '/cache/new.m4a',
      duration: Duration(seconds: 2),
      text: 'Tango',
    ));

    expect((await store.get('abc'))!.filePath, '/cache/new.m4a');
    expect(await db.select(db.announcementCache).get(), hasLength(1));
  });

  test('reading a clip marks it used, so eviction can tell the difference',
      () async {
    await withClock(Clock.fixed(doorsOpen), () async {
      await store.put(const AnnouncementClip(
        hash: 'used',
        filePath: '/cache/used.m4a',
        duration: Duration(seconds: 1),
        text: 'Tango',
      ));
      await store.put(const AnnouncementClip(
        hash: 'idle',
        filePath: '/cache/idle.m4a',
        duration: Duration(seconds: 1),
        text: 'Waltz',
      ));
    });

    final lastDance = doorsOpen.add(const Duration(hours: 4));
    await withClock(Clock.fixed(lastDance), () => store.get('used'));

    final stale = await db.announcementDao
        .unusedSince(doorsOpen.add(const Duration(hours: 1)));
    expect([for (final row in stale) row.hash], ['idle']);
  });

  test('a clip that has never been read falls back to when it was rendered',
      () async {
    await withClock(Clock.fixed(doorsOpen), () async {
      await db.announcementDao.put(AnnouncementCacheRow(
        hash: 'orphan',
        body: 'Bachata',
        rate: 0.5,
        pitch: 1.0,
        filePath: '/cache/orphan.m4a',
        durationMs: const Duration(seconds: 1),
        createdAt: clock.now(),
      ));
    });

    expect(
      [
        for (final row in await db.announcementDao
            .unusedSince(doorsOpen.add(const Duration(days: 30))))
          row.hash
      ],
      ['orphan'],
    );
    expect(await db.announcementDao.unusedSince(doorsOpen), isEmpty);
  });

  test('forgetting rows leaves the ones still in use alone', () async {
    for (final hash in ['a', 'b', 'c']) {
      await store.put(AnnouncementClip(
        hash: hash,
        filePath: '/cache/$hash.m4a',
        duration: const Duration(seconds: 1),
        text: hash,
      ));
    }

    expect(await db.announcementDao.forget(['a', 'c']), 2);
    expect([for (final row in await db.select(db.announcementCache).get()) row.hash],
        ['b']);
  });
}

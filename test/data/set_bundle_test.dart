import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sayaw/audio/crossfade_engine.dart' show AnnounceMode;
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/library/library_scanner.dart';
import 'package:sayaw/data/set_bundle.dart';

import '../fakes/fake_metadata_reader.dart';
import 'db_harness.dart';

/// A set built on one machine, saved to a stick with its music, opened on
/// another. Two databases, one folder between them.
void main() {
  late SayawDatabase here;
  late SayawDatabase there;
  late Directory music;
  late Directory stick;
  late String set;

  setUp(() async {
    here = openTestDatabase();
    there = openTestDatabase();
    music = Directory.systemTemp.createTempSync('sayaw-music');
    stick = Directory.systemTemp.createTempSync('sayaw-stick');
    addTearDown(() {
      music.deleteSync(recursive: true);
      stick.deleteSync(recursive: true);
    });

    await here.into(here.danceTypes).insert(
        DanceTypesCompanion.insert(id: 'waltz', name: 'Waltz', slug: 'waltz'));
    set = await here.playlistDao.createPlaylist(name: 'Saturday social');
    for (final id in ['01_(Waltz)_A', '02_(Waltz)_B', '03_(Tango)_C']) {
      File('${music.path}/$id.mp3').writeAsStringSync('not really audio $id');
      await here.trackDao.upsert(TracksCompanion.insert(
        id: id,
        sourceType: SourceType.local,
        localPath: Value('${music.path}/$id.mp3'),
        title: id,
        artist: const Value('Someone'),
        durationMs: const Value(Duration(minutes: 3)),
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
    }
    await here.playlistDao.appendTracks(
      playlistId: set,
      trackIds: ['01_(Waltz)_A', '02_(Waltz)_B', '03_(Tango)_C'],
    );
    final rows = await here.playlistDao.itemsOf(set);
    await (here.update(here.playlistItems)
          ..where((i) => i.id.equals(rows[0].item.id)))
        .write(const PlaylistItemsCompanion(danceTypeId: Value('waltz')));

    // Everything a set can carry: a join, an announcer, a per-row length,
    // and the set's own shape.
    File('${music.path}/partners.wav').writeAsStringSync('a voice');
    final cue = await here.soundCueDao.add(
        label: 'Take your partners',
        filePath: '${music.path}/partners.wav',
        duckLevel: 0.3);
    await here.playlistDao.setMergeIntoNext(itemId: rows[0].item.id, merge: true);
    await here.playlistDao.tagSoundCue(itemId: rows[2].item.id, cueId: cue);
    await (here.update(here.playlistItems)
          ..where((i) => i.id.equals(rows[1].item.id)))
        .write(const PlaylistItemsCompanion(
            targetDurationMs: Value(Duration(seconds: 90))));
    await here.playlistDao.setShape(set,
        songLimit: 5,
        targetDuration: const Duration(minutes: 2),
        rotationGap: const Duration(seconds: 10));
  });

  tearDown(() async {
    await here.close();
    await there.close();
  });

  SetBundler bundlerFor(SayawDatabase db) => SetBundler(
        db: db,
        scanner: LibraryScanner(db: db, reader: FakeMetadataReader()),
      );

  test('the file names everything, and the music travels beside it', () async {
    final report = await bundlerFor(here).export(set, into: stick);

    expect(p.basename(report.file.path), 'Saturday social.sayawset');
    expect(report.rows, 3);
    expect(report.skippedRemote, 0);
    expect(report.copied, 4, reason: 'three songs and one voice');
    expect(File('${stick.path}/Saturday social music/02_(Waltz)_B.mp3').existsSync(),
        isTrue);
    expect(File('${stick.path}/Saturday social sounds/partners.wav').existsSync(),
        isTrue);

    final bundle = SetBundle.decode(report.file.readAsStringSync());
    expect(bundle.rows.map((r) => r.file),
        ['01_(Waltz)_A.mp3', '02_(Waltz)_B.mp3', '03_(Tango)_C.mp3']);
    expect(bundle.rows[0].danceType, 'Waltz');
    expect(bundle.rows[0].mergeIntoNext, isTrue);
    expect(bundle.rows[1].targetDurationMs, 90000);
    expect(bundle.rows[2].sound, 'Take your partners');
    expect(bundle.sounds.single.file, 'partners.wav');
    expect(bundle.shape['songLimit'], 5);
    expect(bundle.shape['rotationGapMs'], 10000);
  });

  test('opened on another machine, it is the same set', () async {
    final exported = await bundlerFor(here).export(set, into: stick);

    final report = await bundlerFor(there).import(exported.file);

    expect(report.name, 'Saturday social');
    expect(report.rows, 3);
    expect(report.missing, isEmpty);
    expect(report.soundsAdded, 1);

    final rows = await there.playlistDao.itemsOf(report.playlistId);
    expect([for (final r in rows) p.basename(r.track!.localPath!)],
        ['01_(Waltz)_A.mp3', '02_(Waltz)_B.mp3', '03_(Tango)_C.mp3'],
        reason: 'the arrangement, in order');
    expect(rows[0].danceType?.name, 'Waltz',
        reason: 'a dance the other machine did not have was created');
    expect(rows[0].item.mergeIntoNext, isTrue);
    expect(rows[1].item.targetDurationMs, const Duration(seconds: 90));
    expect(rows[2].soundCue?.label, 'Take your partners');
    expect(rows[2].soundCue?.duckLevel, 0.3);
    expect(rows[2].soundCue!.filePath, contains('Saturday social sounds'));

    final playlist = (await there.playlistDao.byId(report.playlistId))!;
    expect(playlist.songLimit, 5);
    expect(playlist.targetDurationMs, const Duration(minutes: 2));
    expect(playlist.rotationGapMs, const Duration(seconds: 10));
    expect(playlist.announceMode, AnnounceMode.beforeMusic);

    // And the music came into the library from the stick.
    expect(await there.trackDao.count(), 3);
  });

  test('music already in the library is matched by name, not copied twice',
      () async {
    final exported =
        await bundlerFor(here).export(set, into: stick, copyMedia: false);
    // The other machine has the same files under a different path.
    final other = Directory.systemTemp.createTempSync('sayaw-other');
    addTearDown(() => other.deleteSync(recursive: true));
    for (final id in ['01_(Waltz)_A', '02_(Waltz)_B']) {
      await there.trackDao.upsert(TracksCompanion.insert(
        id: 'other-$id',
        sourceType: SourceType.local,
        localPath: Value('${other.path}/$id.mp3'),
        title: id,
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
    }

    final report = await bundlerFor(there).import(exported.file);

    expect(report.rows, 2);
    // The one the other machine does not have is said, not invented.
    expect(report.missing, ['03_(Tango)_C']);
    final rows = await there.playlistDao.itemsOf(report.playlistId);
    expect(rows.map((r) => r.track!.id), ['other-01_(Waltz)_A', 'other-02_(Waltz)_B']);
  });

  test('importing twice does not double the announcers', () async {
    final exported = await bundlerFor(here).export(set, into: stick);

    await bundlerFor(there).import(exported.file);
    final again = await bundlerFor(there).import(exported.file);

    expect(again.soundsAdded, 0);
    expect(await there.soundCueDao.all(), hasLength(1));
  });

  test('a file from a newer Sayaw is refused, not misread', () {
    expect(
      () => SetBundle.decode('{"sayaw": 99, "name": "x", "rows": []}'),
      throwsFormatException,
    );
  });
}

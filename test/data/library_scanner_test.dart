import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/library/library_scanner.dart';
import 'package:sayaw/data/sources/security_bookmarks.dart';
import 'package:sayaw/data/library/track_metadata.dart';

import '../fakes/fake_metadata_reader.dart';
import 'db_harness.dart';

/// Far enough ahead that a file written during the test is always older than
/// the row the scan writes about it, which is what "unchanged" means.
final _firstScan = DateTime.utc(2030);

void main() {
  late SayawDatabase db;
  late FakeMetadataReader reader;
  late LibraryScanner scanner;
  late Directory music;

  setUp(() {
    db = openTestDatabase();
    reader = FakeMetadataReader();
    scanner = LibraryScanner(db: db, reader: reader);
    music = Directory.systemTemp.createTempSync('sayaw-library');
    addTearDown(() => music.deleteSync(recursive: true));
  });

  Future<ScanReport> scan({DateTime? at, List<Directory>? roots}) =>
      withClock(Clock.fixed(at ?? _firstScan),
          () => scanner.scan(roots ?? [music]));

  group('what counts as music', () {
    test('audio files are imported and everything else is left alone',
        () async {
      _touch(music, 'kiss-of-fire.flac');
      _touch(music, 'sway.mp3');
      _touch(music, 'cover.jpg');
      _touch(music, 'setlist.txt');
      _touch(music, 'README');

      final report = await scan();

      expect(report.added, 2);
      expect(await _titles(db), ['kiss-of-fire', 'sway']);
    });

    test('subfolders are walked', () async {
      _touch(music, 'ballroom/standard/waltz.flac');
      _touch(music, 'ballroom/latin/rumba.m4a');
      _touch(music, 'social/bachata.mp3');

      expect((await scan()).added, 3);
    });

    test('hidden files and folders are skipped', () async {
      _touch(music, 'sway.mp3');
      _touch(music, '.hidden.mp3');

      // The resource fork macOS leaves beside every file it copies to a FAT
      // drive. It parses as a zero-length audio file if you let it.
      _touch(music, '._sway.mp3');
      _touch(music, '.Trash/deleted.flac');

      final report = await scan();
      expect(report.added, 1);
      expect(await _titles(db), ['sway']);
    });

    test('the extension is matched whatever case it is written in', () async {
      _touch(music, 'QUICKSTEP.MP3');
      _touch(music, 'Foxtrot.FlAc');

      expect((await scan()).added, 2);
    });
  });

  group('what a scan learns', () {
    test('a file with no tempo tag leaves the column empty', () async {
      // Most of a DJ library. A zero here would sort to the front of every
      // tempo-ordered set, so absence has to stay absence.
      _touch(music, 'untagged.mp3');
      reader.tags['untagged.mp3'] = const TrackMetadata(title: 'Untagged');

      await scan();

      expect((await db.select(db.tracks).get()).single.bpm, isNull);
    });

    test('tags land in the columns the library searches on', () async {
      _touch(music, 'sway.mp3');
      reader.tags['sway.mp3'] = const TrackMetadata(
        title: 'Sway',
        artist: 'Dean Martin',
        album: 'Dino: The Essential',
        year: 1954,
        duration: Duration(minutes: 2, seconds: 42),
        bitrateKbps: 320,
        sampleRateHz: 44100,
        bpm: 106.5,
      );

      await scan();

      final track = (await db.select(db.tracks).get()).single;
      expect(track.title, 'Sway');
      expect(track.artist, 'Dean Martin');
      expect(track.album, 'Dino: The Essential');
      expect(track.year, 1954);
      expect(track.bpm, 106.5,
          reason: 'the column the tempo-ordered modes sort on');
      expect(track.durationMs, const Duration(minutes: 2, seconds: 42));
      expect(track.bitrateKbps, 320);
      expect(track.sampleRateHz, 44100);
      expect(track.codec, 'mp3');
      expect(track.sourceType, SourceType.local);
    });

    test('an imported track is findable in search straight away', () async {
      _touch(music, 'sway.mp3');
      reader.tags['sway.mp3'] =
          const TrackMetadata(title: 'Sway', artist: 'Dean Martin');

      await scan();

      expect([for (final t in await db.trackDao.search('dean')) t.title],
          ['Sway']);
    });

    test('a file with no tags is imported under its filename, and said so',
        () async {
      _touch(music, 'unknown-rip-04.mp3');

      final report = await scan();

      expect(report.added, 1);
      expect(await _titles(db), ['unknown-rip-04']);
      expect(report.problems.single.path, endsWith('unknown-rip-04.mp3'));
      expect(report.problems.single.reason, contains('No readable tags'));
      expect(report.isClean, isFalse);
    });

    test('the same file reachable from two roots is imported once', () async {
      _touch(music, 'ballroom/waltz.flac');

      final report = await scan(roots: [music, Directory('${music.path}/ballroom')]);

      expect(report.added, 1);
      expect(await db.select(db.tracks).get(), hasLength(1));
    });
  });

  group('scanning again', () {
    setUp(() async {
      _touch(music, 'a.mp3');
      _touch(music, 'b.mp3');
      await scan();
    });

    test('a library that has not changed is not read again', () async {
      reader.reads.clear();

      final report = await scan(at: DateTime.utc(2030, 6));

      expect(report.unchanged, 2);
      expect(report.added, 0);
      expect(report.updated, 0);

      // The point of the mtime check: no tag parsing at all on a rescan.
      expect(reader.reads, isEmpty);
    });

    test('a file modified since last time is read again', () async {
      reader.reads.clear();
      File('${music.path}/a.mp3').setLastModifiedSync(DateTime.utc(2031));
      reader.tags['a.mp3'] = const TrackMetadata(title: 'Retagged');

      final report = await scan(at: DateTime.utc(2032));

      expect(report.updated, 1);
      expect(report.unchanged, 1);
      expect(reader.reads, ['a.mp3']);
      expect((await _titles(db))..sort(), ['Retagged', 'b']);
    });

    test('a re-import keeps the row it already had', () async {
      final before = (await db.select(db.tracks).get())
          .firstWhere((t) => t.title == 'a');

      File('${music.path}/a.mp3').setLastModifiedSync(DateTime.utc(2031));
      await scan(at: DateTime.utc(2032));

      final after = (await db.trackDao.byId(before.id))!;
      expect(after.addedAt, before.addedAt, reason: 'added_at is when it first arrived');
      expect(after.updatedAt, DateTime.utc(2032));
    });

    test('an afternoon of preparing a set survives a rescan', () async {
      // Cue points, trims and dance types are set by hand and are worth more
      // than anything in a tag. A rescan must not touch them.
      final track = (await db.select(db.tracks).get()).first;
      await db.into(db.danceTypes).insert(DanceTypesCompanion.insert(
          id: 'tango', name: 'Tango', slug: 'tango'));
      await (db.update(db.tracks)..where((t) => t.id.equals(track.id))).write(
        const TracksCompanion(
          cueInMs: Value(Duration(milliseconds: 1200)),
          cueOutMs: Value(Duration(seconds: 95)),
          gainDb: Value(-3.5),
          defaultDanceTypeId: Value('tango'),
        ),
      );

      File('${music.path}/${p.basename(track.localPath!)}')
          .setLastModifiedSync(DateTime.utc(2031));
      await scan(at: DateTime.utc(2032));

      final after = (await db.trackDao.byId(track.id))!;
      expect(after.cueInMs, const Duration(milliseconds: 1200));
      expect(after.cueOutMs, const Duration(seconds: 95));
      expect(after.gainDb, -3.5);
      expect(after.defaultDanceTypeId, 'tango');
    });
  });

  group('files that have gone', () {
    test('a missing file is reported and its row is left where it is',
        () async {
      _touch(music, 'a.mp3');
      _touch(music, 'b.mp3');
      await scan();

      File('${music.path}/b.mp3').deleteSync();
      final report = await scan(at: DateTime.utc(2030, 6));

      expect(report.missing.single, endsWith('b.mp3'));

      // Still in the library: an unmounted drive is the usual cause, and the
      // row is probably sitting in a set for Saturday.
      expect(await db.select(db.tracks).get(), hasLength(2));
    });

    test('a file seen this time gets a fresher stamp than one that was not',
        () async {
      _touch(music, 'a.mp3');
      _touch(music, 'b.mp3');
      await scan();

      File('${music.path}/b.mp3').deleteSync();
      await scan(at: DateTime.utc(2030, 6));

      final tracks = {
        for (final t in await db.select(db.tracks).get()) t.title: t,
      };
      expect(tracks['a']!.lastVerifiedAt, DateTime.utc(2030, 6));
      expect(tracks['b']!.lastVerifiedAt, _firstScan);
    });

    test('a track from a folder nobody scanned is not called missing',
        () async {
      // Someone scans their ballroom folder today and their latin folder
      // tomorrow. Neither scan should accuse the other folder of vanishing.
      _touch(music, 'ballroom/waltz.flac');
      _touch(music, 'latin/rumba.flac');
      await scan();

      final report = await scan(
        at: DateTime.utc(2030, 6),
        roots: [Directory('${music.path}/ballroom')],
      );

      expect(report.missing, isEmpty);
      expect(report.unchanged, 1);
    });
  });

  group('reporting', () {
    test('progress is reported per file, in order', () async {
      _touch(music, 'a.mp3');
      _touch(music, 'b.mp3');

      final seen = <int>[];
      await withClock(
        Clock.fixed(_firstScan),
        () => scanner.scan([music], onProgress: (n, path) => seen.add(n)),
      );

      expect(seen, [1, 2]);
    });

    test('a folder that is not there is reported, not thrown', () async {
      _touch(music, 'a.mp3');
      reader.tags['a.mp3'] = const TrackMetadata(title: 'A');

      final report = await scan(
        roots: [music, Directory('${music.path}/nope')],
      );

      expect(report.added, 1);
      expect(report.problems.single.path, endsWith('nope'));
    });

    test('a folder that cannot be read is reported and the scan carries on',
        // `chmod` is how a folder is made unreadable here, and Windows has
        // neither the command nor those semantics — the directory stays
        // readable, the scan finds the file inside it, and the test fails
        // having proved nothing. The behaviour it guards is real; only this
        // way of provoking it is POSIX-only.
        skip: Platform.isWindows
            ? 'needs POSIX directory permissions'
            : null, () async {
      _touch(music, 'a.mp3');
      reader.tags['a.mp3'] = const TrackMetadata(title: 'A');
      final locked = Directory('${music.path}/locked')..createSync();
      _touch(music, 'locked/b.mp3');
      Process.runSync('chmod', ['000', locked.path]);
      addTearDown(() => Process.runSync('chmod', ['755', locked.path]));

      final report = await scan();

      expect(report.added, 1);
      expect(report.problems.single.path, endsWith('locked'));
    });

    test('an empty library scans clean', () async {
      final report = await scan();
      expect(report.scanned, 0);
      expect(report.isClean, isTrue);
    });
  });

  group('the real tag reader', () {
    test('a file that is not audio reads as untagged rather than throwing',
        () async {
      _touch(music, 'truncated.mp3');

      expect(
        await const TagMetadataReader().read(File('${music.path}/truncated.mp3')),
        isNull,
      );
    });

    test('a file that is not there reads as untagged', () async {
      expect(
        await const TagMetadataReader().read(File('${music.path}/absent.mp3')),
        isNull,
      );
    });
  });

  group('security-scoped bookmarks', () {
    test('a platform without them stores none', () async {
      // Which is every platform this suite runs on, and every platform that
      // does not need one.
      _touch(music, 'sway.mp3');

      await scan();

      expect(
          (await db.select(db.tracks).get()).single.securityBookmark, isNull);
    });

    test('where the platform makes them, they are stored with the track',
        () async {
      // Without this the resolver has nothing to resolve, and a library
      // imported on Monday is unreadable on Tuesday.
      _touch(music, 'sway.mp3');
      _touch(music, 'tango.flac');

      await LibraryScanner(db: db, reader: reader, bookmarks: _StubBookmarks())
          .scan([music]);

      final rows = await db.select(db.tracks).get();
      expect(rows, hasLength(2));
      expect([for (final row in rows) row.securityBookmark],
          everyElement(isNotNull));
    });

    test('a file the platform will not bookmark is still imported', () async {
      // A bookmark is how a file is reached later; not having one is not a
      // reason to leave the track out of the library now.
      _touch(music, 'sway.mp3');

      final report = await LibraryScanner(
        db: db,
        reader: reader,
        bookmarks: _StubBookmarks(refuse: true),
      ).scan([music]);

      expect(report.added, 1);
      expect(
          (await db.select(db.tracks).get()).single.securityBookmark, isNull);
    });
  });
}

// ---------------------------------------------------------------------------

void _touch(Directory root, String relativePath) {
  final file = File('${root.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('not really audio');
}

Future<List<String>> _titles(SayawDatabase db) async =>
    [for (final track in await db.select(db.tracks).get()) track.title]..sort();

/// A platform that makes bookmarks, for the scan path that stores them.
class _StubBookmarks implements SecurityBookmarks {
  _StubBookmarks({this.refuse = false});

  final bool refuse;

  @override
  bool get isSupported => true;

  @override
  Future<String?> resolve(Uint8List bookmark) async => null;

  @override
  Future<List<Uint8List?>> create(List<String> paths) async => [
        for (final path in paths)
          refuse ? null : Uint8List.fromList(path.codeUnits),
      ];
}

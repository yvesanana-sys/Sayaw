import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../sources/security_bookmarks.dart';
import 'track_metadata.dart';

/// What the app will attempt to play from a folder.
///
/// Deliberately wider than the set of containers the tag reader understands:
/// what belongs in the library is what the decks can play, and a file with no
/// readable tags is imported under its filename rather than skipped. ExoPlayer,
/// AVPlayer and libmpv all handle everything here.
const Set<String> kAudioFileExtensions = {
  '.mp3',
  '.m4a',
  '.m4b',
  '.aac',
  '.flac',
  '.wav',
  '.aif',
  '.aiff',
  '.aifc',
  '.ogg',
  '.oga',
  '.opus',
  '.wma',
  '.ape',
  '.alac',
};

/// One file the scan could not deal with cleanly.
class ScanProblem {
  const ScanProblem(this.path, this.reason);

  final String path;

  /// Phrased for the operator: something they could act on.
  final String reason;

  @override
  String toString() => '$path: $reason';
}

class ScanReport {
  const ScanReport({
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.problems,
    required this.missing,
  });

  final int added;
  final int updated;
  final int unchanged;

  /// Files that were imported but told us less than they should have.
  final List<ScanProblem> problems;

  /// Tracks already in the library whose file was not where it used to be.
  ///
  /// Never deleted: a missing file is usually an unmounted drive, and the row
  /// is probably sitting in a set for Saturday. It is reported, and its
  /// `last_verified_at` simply stops moving.
  final List<String> missing;

  int get scanned => added + updated + unchanged;

  bool get isClean => problems.isEmpty && missing.isEmpty;
}

/// Walks folders of music into the `tracks` table.
///
/// Everything here is decisions — what counts as audio, what has changed since
/// last time, what to do with a file that will not parse — and none of it is
/// I/O it cannot be handed a fake for.
class LibraryScanner {
  LibraryScanner({
    required this.db,
    this.reader = const TagMetadataReader(),
    this.bookmarks = const NoSecurityBookmarks(),
    this.batchSize = 200,
  });

  final SayawDatabase db;
  final MetadataReader reader;

  /// How a path becomes a durable handle on the Apple platforms.
  ///
  /// A sandboxed grant does not survive a relaunch, so a library imported on
  /// Monday is unreadable on Tuesday without one of these. Defaults to the
  /// platforms that have no such thing, which is every platform a test runs
  /// on.
  final SecurityBookmarks bookmarks;

  /// Rows written per transaction. Large enough that a 10,000-file import is
  /// not 10,000 transactions, small enough that a scan interrupted halfway
  /// leaves most of its work behind.
  final int batchSize;

  /// Imports every audio file under [roots].
  ///
  /// A file already in the library is left alone unless it has been modified
  /// since it was last read, so a rescan of a large library is mostly a
  /// directory walk and one write.
  Future<ScanReport> scan(
    Iterable<Directory> roots, {
    void Function(int filesSeen, String path)? onProgress,
  }) async {
    final now = clock.now();
    final existing = await _existingByPath();

    final problems = <ScanProblem>[];
    final seen = <String>{};
    final pending = <TracksCompanion>[];
    final untouched = <String>[];

    var added = 0;
    var updated = 0;
    var filesSeen = 0;

    for (final root in roots) {
      await for (final file in _audioFilesIn(root, problems)) {
        final path = p.normalize(file.absolute.path);
        if (!seen.add(path)) continue;

        filesSeen++;
        onProgress?.call(filesSeen, path);

        final known = existing[path];
        final modified = _modifiedAt(file, problems);

        if (known != null &&
            modified != null &&
            !modified.isAfter(known.updatedAt)) {
          untouched.add(known.id);
          if (untouched.length >= batchSize) {
            await _markVerified(untouched, now);
          }
          continue;
        }

        final metadata = await reader.read(file);
        if (metadata == null || metadata.isEmpty) {
          problems.add(ScanProblem(
              path, 'No readable tags — imported under its filename'));
        }

        pending.add(_companionFor(
          path: path,
          file: file,
          metadata: metadata,
          known: known,
          now: now,
        ));
        known == null ? added++ : updated++;

        if (pending.length >= batchSize) await _write(pending);

        // A ten-thousand-file import is a long stretch of synchronous tag
        // parsing. Handing the event loop back between batches is what keeps
        // the progress bar drawing while it runs.
        await Future<void>.delayed(Duration.zero);
      }
    }

    await _write(pending);
    await _markVerified(untouched, now);

    return ScanReport(
      added: added,
      updated: updated,
      unchanged: filesSeen - added - updated,
      problems: problems,
      missing: [
        for (final path in existing.keys)
          if (!seen.contains(path) && _isUnder(path, roots)) path,
      ],
    );
  }

  // -------------------------------------------------------------------------

  /// Only the columns a scan is entitled to write.
  ///
  /// Cue points, gain trims and the default dance type are the operator's, set
  /// by hand and worth more than anything in a tag. Leaving them out of the
  /// companion leaves them out of the `DO UPDATE SET`, so a rescan cannot
  /// undo an afternoon of preparing a set.
  TracksCompanion _companionFor({
    required String path,
    required File file,
    required TrackMetadata? metadata,
    required Track? known,
    required DateTime now,
  }) =>
      TracksCompanion(
        id: Value(known?.id ?? newId()),
        sourceType: const Value(SourceType.local),
        localPath: Value(path),
        title: Value(metadata?.title ?? _titleFromFilename(path)),
        artist: Value(metadata?.artist),
        album: Value(metadata?.album),
        year: Value(metadata?.year),
        durationMs: Value(metadata?.duration ?? Duration.zero),
        codec: Value(_codecFor(path)),
        bitrateKbps: Value(metadata?.bitrateKbps),
        sampleRateHz: Value(metadata?.sampleRateHz),
        // Null where the file does not say. Keeping a BPM someone typed in by
        // hand would need a "who last wrote this" column, and a rescan that
        // silently reverted it is the worse of the two failures — so for now
        // the tag is the only source and the column follows it.
        bpm: Value(metadata?.bpm),
        addedAt: Value(known?.addedAt ?? now),
        updatedAt: Value(now),
        lastVerifiedAt: Value(now),
      );

  Future<Map<String, Track>> _existingByPath() async {
    final rows = await (db.select(db.tracks)
          ..where((t) => t.sourceType.equalsValue(SourceType.local)))
        .get();

    return {for (final row in rows) ?row.localPath: row};
  }

  Future<void> _write(List<TracksCompanion> pending) async {
    if (pending.isEmpty) return;
    await db.trackDao.upsertAll(await _bookmarked(pending));
    pending.clear();
  }

  /// The same rows with a security-scoped bookmark attached, where the
  /// platform makes them.
  ///
  /// Done a batch at a time rather than a file at a time: one channel round
  /// trip per transaction rather than per track, which on a ten-thousand-file
  /// import is the difference between a pause and an afternoon.
  Future<List<TracksCompanion>> _bookmarked(
      List<TracksCompanion> pending) async {
    if (!bookmarks.isSupported) return pending;

    final paths = [for (final row in pending) row.localPath.value ?? ''];
    final made = await bookmarks.create(paths);

    return [
      for (var i = 0; i < pending.length; i++)
        if (made[i] case final bookmark?)
          pending[i].copyWith(securityBookmark: Value(bookmark))
        else
          pending[i],
    ];
  }

  /// A file that has not changed still gets its "we saw it" stamp moved, which
  /// is what makes the missing list mean anything.
  Future<void> _markVerified(List<String> ids, DateTime now) async {
    if (ids.isEmpty) return;
    await (db.update(db.tracks)..where((t) => t.id.isIn(ids)))
        .write(TracksCompanion(lastVerifiedAt: Value(now)));
    ids.clear();
  }

  /// Depth-first, skipping hidden directories and never following symlinks —
  /// a link pointing at its own parent would otherwise walk forever.
  Stream<File> _audioFilesIn(Directory root, List<ScanProblem> problems) async* {
    final stack = <Directory>[root];

    while (stack.isNotEmpty) {
      final dir = stack.removeLast();

      final List<FileSystemEntity> entries;
      try {
        entries = await dir.list(followLinks: false).toList();
      } on FileSystemException catch (e) {
        problems.add(ScanProblem(dir.path, e.osError?.message ?? e.message));
        continue;
      }

      for (final entry in entries) {
        final name = p.basename(entry.path);

        // `.git`, `.Trash`, and the `._name` resource forks macOS leaves on
        // every file it copies to a FAT drive — which parse as empty audio.
        if (name.startsWith('.')) continue;

        if (entry is Directory) {
          stack.add(entry);
        } else if (entry is File &&
            kAudioFileExtensions.contains(p.extension(name).toLowerCase())) {
          yield entry;
        }
      }
    }
  }

  DateTime? _modifiedAt(File file, List<ScanProblem> problems) {
    try {
      return file.statSync().modified;
    } on FileSystemException catch (e) {
      problems.add(ScanProblem(file.path, e.osError?.message ?? e.message));
      return null;
    }
  }

  static bool _isUnder(String path, Iterable<Directory> roots) => roots.any(
      (root) => p.isWithin(p.normalize(root.absolute.path), path));

  static String _titleFromFilename(String path) =>
      p.basenameWithoutExtension(path);

  static String _codecFor(String path) =>
      p.extension(path).toLowerCase().replaceFirst('.', '');
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../audio/crossfade_engine.dart' show AnnounceMode;
import '../audio/fade_curves.dart' show FadeCurve;
import 'db/database.dart';
import 'library/library_scanner.dart';

/// A set as a file that travels: `<name>.sayawset`.
///
/// One JSON file holding everything a set is — its rows in order, each
/// row's dance, announcer, join to the next and overrides, the set's own
/// shape and transition defaults, and the announcer recordings it uses. The
/// music is not *in* the file; it is named by it, and travels beside it. A
/// set built on one laptop, saved with its music onto a USB stick, opens on
/// another with nothing typed.
///
/// Rows name their music by filename rather than path, because a path is a
/// fact about one machine. On import the file is looked for beside the set
/// first — the copy the export made — and then in the library it is being
/// imported into. A row whose music is nowhere is reported, not dropped
/// silently, and not invented: a track row with no track is not a row.
class SetBundle {
  const SetBundle({
    required this.name,
    required this.defaults,
    required this.shape,
    required this.sounds,
    required this.rows,
  });

  /// The file's extension, and what the importer looks for.
  static const extension = 'sayawset';

  /// Bumped when a change means an older app could not read a newer file.
  static const version = 1;

  final String name;
  final Map<String, Object?> defaults;
  final Map<String, Object?> shape;
  final List<BundledSound> sounds;
  final List<BundledRow> rows;

  /// Where the export puts the music beside `<name>.sayawset`.
  static String musicFolderFor(String name) => '$name music';

  /// Where the export puts the announcer recordings.
  static String soundsFolderFor(String name) => '$name sounds';

  Map<String, Object?> toJson() => {
        'sayaw': version,
        'name': name,
        'defaults': defaults,
        'shape': shape,
        'sounds': [for (final s in sounds) s.toJson()],
        'rows': [for (final r in rows) r.toJson()],
      };

  static SetBundle fromJson(Map<String, Object?> json) {
    final version = json['sayaw'];
    if (version is! int || version > SetBundle.version) {
      throw const FormatException('This set was saved by a newer Sayaw.');
    }
    return SetBundle(
      name: json['name'] as String? ?? 'Imported set',
      defaults: (json['defaults'] as Map?)?.cast<String, Object?>() ?? const {},
      shape: (json['shape'] as Map?)?.cast<String, Object?>() ?? const {},
      sounds: [
        for (final s in (json['sounds'] as List? ?? const []))
          BundledSound.fromJson((s as Map).cast<String, Object?>()),
      ],
      rows: [
        for (final r in (json['rows'] as List? ?? const []))
          BundledRow.fromJson((r as Map).cast<String, Object?>()),
      ],
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static SetBundle decode(String text) =>
      fromJson((jsonDecode(text) as Map).cast<String, Object?>());
}

/// An announcer recording the set uses, by the name on its button.
class BundledSound {
  const BundledSound({
    required this.label,
    required this.file,
    required this.duckLevel,
    required this.duckFadeMs,
    required this.restoreFadeMs,
  });

  final String label;

  /// Filename only. The recording travels in the sounds folder beside the set.
  final String file;
  final double duckLevel;
  final int duckFadeMs;
  final int restoreFadeMs;

  Map<String, Object?> toJson() => {
        'label': label,
        'file': file,
        'duckLevel': duckLevel,
        'duckFadeMs': duckFadeMs,
        'restoreFadeMs': restoreFadeMs,
      };

  static BundledSound fromJson(Map<String, Object?> j) => BundledSound(
        label: j['label'] as String,
        file: j['file'] as String,
        duckLevel: (j['duckLevel'] as num?)?.toDouble() ?? 1.0,
        duckFadeMs: j['duckFadeMs'] as int? ?? 120,
        restoreFadeMs: j['restoreFadeMs'] as int? ?? 400,
      );
}

/// One row of the set, as it travels.
class BundledRow {
  const BundledRow({
    required this.file,
    required this.title,
    this.artist,
    this.durationMs,
    this.danceType,
    this.sound,
    this.mergeIntoNext = false,
    this.announceMode,
    this.announcementText,
    this.crossfadeMs,
    this.fadeInCurve,
    this.fadeOutCurve,
    this.startOffsetMs = 0,
    this.endOffsetMs,
    this.targetDurationMs,
    this.gainOffsetDb = 0.0,
    this.pauseAfter = false,
  });

  /// Filename only; see [SetBundle].
  final String file;
  final String title;
  final String? artist;
  final int? durationMs;

  /// The dance's name. Matched to a dance type on import, created if new.
  final String? danceType;

  /// The label of the announcer tagged to this row, from [SetBundle.sounds].
  final String? sound;
  final bool mergeIntoNext;
  final String? announceMode;
  final String? announcementText;
  final int? crossfadeMs;
  final String? fadeInCurve;
  final String? fadeOutCurve;
  final int startOffsetMs;
  final int? endOffsetMs;
  final int? targetDurationMs;
  final double gainOffsetDb;
  final bool pauseAfter;

  Map<String, Object?> toJson() => {
        'file': file,
        'title': title,
        'artist': artist,
        'durationMs': durationMs,
        'danceType': danceType,
        'sound': sound,
        'mergeIntoNext': mergeIntoNext,
        'announceMode': announceMode,
        'announcementText': announcementText,
        'crossfadeMs': crossfadeMs,
        'fadeInCurve': fadeInCurve,
        'fadeOutCurve': fadeOutCurve,
        'startOffsetMs': startOffsetMs,
        'endOffsetMs': endOffsetMs,
        'targetDurationMs': targetDurationMs,
        'gainOffsetDb': gainOffsetDb,
        'pauseAfter': pauseAfter,
      }..removeWhere((_, v) => v == null);

  static BundledRow fromJson(Map<String, Object?> j) => BundledRow(
        file: j['file'] as String,
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String?,
        durationMs: j['durationMs'] as int?,
        danceType: j['danceType'] as String?,
        sound: j['sound'] as String?,
        mergeIntoNext: j['mergeIntoNext'] as bool? ?? false,
        announceMode: j['announceMode'] as String?,
        announcementText: j['announcementText'] as String?,
        crossfadeMs: j['crossfadeMs'] as int?,
        fadeInCurve: j['fadeInCurve'] as String?,
        fadeOutCurve: j['fadeOutCurve'] as String?,
        startOffsetMs: j['startOffsetMs'] as int? ?? 0,
        endOffsetMs: j['endOffsetMs'] as int?,
        targetDurationMs: j['targetDurationMs'] as int?,
        gainOffsetDb: (j['gainOffsetDb'] as num?)?.toDouble() ?? 0.0,
        pauseAfter: j['pauseAfter'] as bool? ?? false,
      );
}

/// What an export wrote, and what it could not.
class ExportReport {
  const ExportReport({
    required this.file,
    required this.rows,
    required this.skippedRemote,
    required this.copied,
  });

  /// The `.sayawset` file.
  final File file;
  final int rows;

  /// Rows on Plex or TIDAL, which have no file to travel. Left out and said.
  final int skippedRemote;

  /// Music and sounds copied beside the file.
  final int copied;
}

/// What an import found, and what it could not.
class ImportReport {
  const ImportReport({
    required this.playlistId,
    required this.name,
    required this.rows,
    required this.missing,
    required this.soundsAdded,
  });

  final String playlistId;
  final String name;
  final int rows;

  /// Titles whose music was neither beside the set nor in the library.
  final List<String> missing;
  final int soundsAdded;
}

/// Writes a set out as a bundle, and reads one back in.
class SetBundler {
  SetBundler({required this.db, LibraryScanner? scanner})
      : _scanner = scanner ?? LibraryScanner(db: db);

  final SayawDatabase db;
  final LibraryScanner _scanner;

  // -------------------------------------------------------------------------
  // Export
  // -------------------------------------------------------------------------

  /// Writes `<name>.sayawset` into [into], and with [copyMedia] the music
  /// and sounds it names into folders beside it.
  Future<ExportReport> export(
    String playlistId, {
    required Directory into,
    bool copyMedia = true,
  }) async {
    final playlist = await db.playlistDao.byId(playlistId);
    if (playlist == null) {
      throw ArgumentError.value(playlistId, 'playlistId', 'no such playlist');
    }
    final rows = await db.playlistDao.itemsOf(playlistId);
    final name = _safeName(playlist.name);

    final sounds = <String, BundledSound>{};
    final bundled = <BundledRow>[];
    var skipped = 0;
    final toCopy = <(String from, String toFolder)>[];

    for (final row in rows) {
      final track = row.track;
      if (track == null || track.localPath == null) {
        if (track != null) skipped++;
        continue;
      }
      final file = p.basename(track.localPath!);
      toCopy.add((track.localPath!, SetBundle.musicFolderFor(name)));

      final cue = row.soundCue;
      if (cue != null) {
        sounds.putIfAbsent(cue.label, () {
          toCopy.add((cue.filePath, SetBundle.soundsFolderFor(name)));
          return BundledSound(
            label: cue.label,
            file: p.basename(cue.filePath),
            duckLevel: cue.duckLevel,
            duckFadeMs: cue.duckFadeMs.inMilliseconds,
            restoreFadeMs: cue.restoreFadeMs.inMilliseconds,
          );
        });
      }

      final item = row.item;
      bundled.add(BundledRow(
        file: file,
        title: track.title,
        artist: track.artist,
        durationMs: track.durationMs.inMilliseconds,
        danceType: row.danceType?.name,
        sound: cue?.label,
        mergeIntoNext: item.mergeIntoNext,
        announceMode: item.announceMode?.name,
        announcementText: item.announcementText,
        crossfadeMs: item.crossfadeMs?.inMilliseconds,
        fadeInCurve: item.fadeInCurve?.name,
        fadeOutCurve: item.fadeOutCurve?.name,
        startOffsetMs: item.startOffsetMs.inMilliseconds,
        endOffsetMs: item.endOffsetMs?.inMilliseconds,
        targetDurationMs: item.targetDurationMs?.inMilliseconds,
        gainOffsetDb: item.gainOffsetDb,
        pauseAfter: item.pauseAfter,
      ));
    }

    final bundle = SetBundle(
      name: playlist.name,
      defaults: {
        'crossfadeMs': playlist.crossfadeMs.inMilliseconds,
        'fadeInCurve': playlist.fadeInCurve.name,
        'fadeOutCurve': playlist.fadeOutCurve.name,
        'announceMode': playlist.announceMode.name,
        'duckLevel': playlist.duckLevel,
        'duckFadeMs': playlist.duckFadeMs.inMilliseconds,
        'duckHoldMs': playlist.duckHoldMs.inMilliseconds,
        'duckRestoreFadeMs': playlist.duckRestoreFadeMs.inMilliseconds,
      },
      shape: {
        'songLimit': playlist.songLimit,
        'songDurationMs': playlist.targetDurationMs?.inMilliseconds,
        'rotationGapMs': playlist.rotationGapMs.inMilliseconds,
        'snowballStages': playlist.snowballStages,
      },
      sounds: sounds.values.toList(),
      rows: bundled,
    );

    await into.create(recursive: true);
    final file = File(p.join(into.path, '$name.${SetBundle.extension}'));
    await file.writeAsString(bundle.encode());

    var copied = 0;
    if (copyMedia) {
      for (final (from, folder) in toCopy) {
        final source = File(from);
        if (!source.existsSync()) continue;
        final dir = Directory(p.join(into.path, folder));
        await dir.create(recursive: true);
        final target = File(p.join(dir.path, p.basename(from)));
        // The same file already there — an earlier export, a second row of
        // the same song — is left alone rather than written twice.
        if (target.existsSync() &&
            target.lengthSync() == source.lengthSync()) {
          continue;
        }
        await source.copy(target.path);
        copied++;
      }
    }

    return ExportReport(
      file: file,
      rows: bundled.length,
      skippedRemote: skipped,
      copied: copied,
    );
  }

  // -------------------------------------------------------------------------
  // Import
  // -------------------------------------------------------------------------

  /// Reads a `.sayawset` file and builds the set it describes.
  ///
  /// Music beside the set is scanned into the library first, so a stick
  /// carrying the set and its songs needs nothing else. Then every row is
  /// matched by filename: the copy beside the set, or whatever the library
  /// already holds under that name. Announcer recordings become cues on the
  /// soundboard, matched by label so a second import does not double them.
  Future<ImportReport> import(File setFile) async {
    final bundle = SetBundle.decode(await setFile.readAsString());
    final dir = setFile.parent;
    final name = p.basenameWithoutExtension(setFile.path);

    final musicDir = Directory(p.join(dir.path, SetBundle.musicFolderFor(name)));
    if (musicDir.existsSync()) await _scanner.scan([musicDir]);

    final byName = <String, String>{};
    for (final track in await db.trackDao.localTracks()) {
      final path = track.localPath;
      if (path == null) continue;
      // Beside the set wins over the library's own copy when both exist,
      // which is what putting it first does here.
      final beside = p.isWithin(musicDir.path, path);
      byName.update(
        p.basename(path).toLowerCase(),
        (existing) => beside ? track.id : existing,
        ifAbsent: () => track.id,
      );
    }

    final soundsDir =
        Directory(p.join(dir.path, SetBundle.soundsFolderFor(name)));
    final cueByLabel = {
      for (final cue in await db.soundCueDao.all()) cue.label: cue.id,
    };
    var soundsAdded = 0;
    for (final sound in bundle.sounds) {
      if (cueByLabel.containsKey(sound.label)) continue;
      final file = File(p.join(soundsDir.path, sound.file));
      if (!file.existsSync()) continue;
      cueByLabel[sound.label] = await db.soundCueDao.add(
        label: sound.label,
        filePath: file.path,
        duckLevel: sound.duckLevel,
      );
      soundsAdded++;
    }

    final danceByName = <String, String>{};
    for (final dance in await db.select(db.danceTypes).get()) {
      danceByName[dance.name.toLowerCase()] = dance.id;
    }

    final defaults = bundle.defaults;
    final shape = bundle.shape;
    final playlistId = await db.playlistDao.createPlaylist(name: bundle.name);
    await (db.update(db.playlists)..where((pl) => pl.id.equals(playlistId)))
        .write(PlaylistsCompanion(
      crossfadeMs: _ms(defaults['crossfadeMs'], const Duration(seconds: 4)),
      fadeInCurve: Value(_curve(defaults['fadeInCurve'])),
      fadeOutCurve: Value(_curve(defaults['fadeOutCurve'])),
      announceMode: Value(_mode(defaults['announceMode'])),
      duckLevel: Value((defaults['duckLevel'] as num?)?.toDouble() ?? 0.2),
      duckFadeMs:
          _ms(defaults['duckFadeMs'], const Duration(milliseconds: 600)),
      duckHoldMs:
          _ms(defaults['duckHoldMs'], const Duration(milliseconds: 250)),
      duckRestoreFadeMs: _ms(
          defaults['duckRestoreFadeMs'], const Duration(milliseconds: 900)),
      songLimit: Value(shape['songLimit'] as int?),
      targetDurationMs: Value(_msOrNull(shape['songDurationMs'])),
      rotationGapMs: _ms(shape['rotationGapMs'], Duration.zero),
      snowballStages: Value(shape['snowballStages'] as int? ?? 0),
    ));

    final missing = <String>[];
    var placed = 0;
    for (final row in bundle.rows) {
      final trackId = byName[row.file.toLowerCase()];
      if (trackId == null) {
        missing.add(row.title.isEmpty ? row.file : row.title);
        continue;
      }

      String? danceId;
      if (row.danceType case final dance? when dance.trim().isNotEmpty) {
        danceId = danceByName[dance.toLowerCase()] ??=
            await _createDanceType(dance);
      }

      final itemId = await db.playlistDao.appendTrack(
        playlistId: playlistId,
        trackId: trackId,
        danceTypeId: danceId,
      );
      await (db.update(db.playlistItems)..where((i) => i.id.equals(itemId)))
          .write(PlaylistItemsCompanion(
        soundCueId: Value(row.sound == null ? null : cueByLabel[row.sound!]),
        mergeIntoNext: Value(row.mergeIntoNext),
        announceMode: Value(_modeOrNull(row.announceMode)),
        announcementText: Value(row.announcementText),
        crossfadeMs: Value(_msOrNull(row.crossfadeMs)),
        fadeInCurve: Value(_curveOrNull(row.fadeInCurve)),
        fadeOutCurve: Value(_curveOrNull(row.fadeOutCurve)),
        startOffsetMs: Value(Duration(milliseconds: row.startOffsetMs)),
        endOffsetMs: Value(_msOrNull(row.endOffsetMs)),
        targetDurationMs: Value(_msOrNull(row.targetDurationMs)),
        gainOffsetDb: Value(row.gainOffsetDb),
        pauseAfter: Value(row.pauseAfter),
      ));
      placed++;
    }

    return ImportReport(
      playlistId: playlistId,
      name: bundle.name,
      rows: placed,
      missing: missing,
      soundsAdded: soundsAdded,
    );
  }

  Future<String> _createDanceType(String name) async {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final id = slug.isEmpty ? 'dance-${DateTime.now().millisecondsSinceEpoch}' : slug;
    await db.into(db.danceTypes).insert(
          DanceTypesCompanion.insert(id: id, name: name, slug: id),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }

  // -------------------------------------------------------------------------

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), ' ').trim();
    return cleaned.isEmpty ? 'Set' : cleaned;
  }

  static Value<Duration> _ms(Object? v, Duration fallback) =>
      Value(v is int ? Duration(milliseconds: v) : fallback);

  static Duration? _msOrNull(Object? v) =>
      v is int ? Duration(milliseconds: v) : null;

  static FadeCurve _curve(Object? v) => _curveOrNull(v) ?? FadeCurve.equalPower;

  static FadeCurve? _curveOrNull(Object? v) => v is String
      ? FadeCurve.values.where((c) => c.name == v).firstOrNull
      : null;

  static AnnounceMode _mode(Object? v) =>
      _modeOrNull(v) ?? AnnounceMode.beforeMusic;

  static AnnounceMode? _modeOrNull(Object? v) => v is String
      ? AnnounceMode.values.where((m) => m.name == v).firstOrNull
      : null;
}

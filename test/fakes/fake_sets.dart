import 'dart:async';
import 'dart:io';

import 'package:sayaw/audio/crossfade_engine.dart' show AnnounceMode;
import 'package:sayaw/audio/fade_curves.dart' show FadeCurve;
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/set_bundle.dart';
import 'package:sayaw/ui/state/library_access.dart';

/// The operator's sets, with no database under them.
class FakeSets implements SetsAccess {
  FakeSets({List<Playlist>? sets, this.openPlaylistId = 'p1', this.isRunning = false})
      : sets = sets ?? [playlist('p1', 'Tonight'), playlist('p2', 'Class')];

  List<Playlist> sets;
  final _updates = StreamController<List<Playlist>>.broadcast();

  @override
  String? openPlaylistId;

  @override
  bool isRunning;

  final List<String> savedAs = [];
  final List<String> created = [];
  final List<String> opened = [];
  final List<(String, String)> renamed = [];
  final List<String> deleted = [];

  @override
  Stream<List<Playlist>> watchSets() async* {
    yield sets;
    yield* _updates.stream;
  }

  @override
  Future<String?> saveSetAs(String name) async {
    if (openPlaylistId == null) return null;
    savedAs.add(name);
    return 'copy-${savedAs.length}';
  }

  @override
  Future<String> newSet(String name) async {
    created.add(name);
    return 'new-${created.length}';
  }

  @override
  Future<bool> openSet(String id) async {
    if (isRunning) return false;
    opened.add(id);
    openPlaylistId = id;
    return true;
  }

  @override
  Future<void> renameSet(String id, String name) async => renamed.add((id, name));

  @override
  Future<void> deleteSet(String id) async => deleted.add(id);

  /// Every export, as (id, folder, copyMedia).
  final List<(String, String, bool)> exported = [];
  final List<String> imported = [];

  @override
  Future<ExportReport> exportSet(
    String id, {
    required Directory into,
    bool copyMedia = true,
  }) async {
    exported.add((id, into.path, copyMedia));
    return ExportReport(
      file: File('${into.path}/Tonight.sayawset'),
      rows: 3,
      skippedRemote: 0,
      copied: copyMedia ? 4 : 0,
    );
  }

  @override
  Future<ImportReport> importSet(File file) async {
    imported.add(file.path);
    return const ImportReport(
      playlistId: 'imported',
      name: 'Saturday social',
      rows: 3,
      missing: ['Lost song'],
      soundsAdded: 1,
    );
  }

  Future<void> close() => _updates.close();

  static Playlist playlist(String id, String name) => Playlist(
        id: id,
        name: name,
        crossfadeMs: const Duration(seconds: 4),
        fadeInCurve: FadeCurve.equalPower,
        fadeOutCurve: FadeCurve.equalPower,
        announceMode: AnnounceMode.beforeMusic,
        duckLevel: 0.2,
        duckFadeMs: const Duration(milliseconds: 600),
        duckHoldMs: const Duration(milliseconds: 250),
        duckRestoreFadeMs: const Duration(milliseconds: 900),
        ttsRate: 0.5,
        ttsPitch: 1.0,
        isArchived: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        rotationGapMs: Duration.zero,
        snowballStages: 0,
      );
}

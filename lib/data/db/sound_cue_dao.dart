import 'package:drift/drift.dart';

import '../../audio/soundboard.dart' show SoundCue;
import 'database.dart';
import 'tables.dart';

part 'sound_cue_dao.g.dart';

/// The soundboard's cues.
@DriftAccessor(tables: [SoundCues])
class SoundCueDao extends DatabaseAccessor<SayawDatabase>
    with _$SoundCueDaoMixin {
  SoundCueDao(super.db);

  SimpleSelectStatement<$SoundCuesTable, SoundCueRow> _ordered() =>
      select(soundCues)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortIndex),
          (c) => OrderingTerm.asc(c.label),
        ]);

  Stream<List<SoundCue>> watchAll() =>
      _ordered().map(toCue).watch();

  Future<List<SoundCue>> all() => _ordered().map(toCue).get();

  Future<String> add({
    required String label,
    required String filePath,
    double duckLevel = 1.0,
    String? hotkey,
    String? id,
  }) async {
    final rowId = id ?? newId();
    final last = await (selectOnly(soundCues)
          ..addColumns([soundCues.sortIndex.max()]))
        .getSingle();

    await into(soundCues).insert(SoundCuesCompanion.insert(
      id: rowId,
      label: label,
      filePath: filePath,
      duckLevel: Value(duckLevel),
      hotkey: Value(hotkey),
      sortIndex: Value((last.read(soundCues.sortIndex.max()) ?? 0) + 1),
    ));
    return rowId;
  }

  Future<int> remove(String id) =>
      (delete(soundCues)..where((c) => c.id.equals(id))).go();

  /// The audio layer's own type, so it never sees a database row.
  ///
  /// The same seam `QueueEntry` sits behind: `lib/audio/` knows nothing about
  /// Drift, which is what keeps its whole test suite runnable without one.
  static SoundCue toCue(SoundCueRow row) => SoundCue(
        id: row.id,
        label: row.label,
        filePath: row.filePath,
        duckLevel: row.duckLevel,
        duckFade: row.duckFadeMs,
        restoreFade: row.restoreFadeMs,
      );
}

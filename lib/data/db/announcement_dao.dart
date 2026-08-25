import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../audio/announcement_engine.dart';
import 'converters.dart';
import 'database.dart';
import 'tables.dart';

part 'announcement_dao.g.dart';

/// The durable half of the announcement cache.
///
/// Event Mode pre-renders every announcement in a set before doors open, which
/// is only worth doing if the results survive a restart — so they live in
/// `announcement_cache` rather than in memory.
@DriftAccessor(tables: [AnnouncementCache])
class AnnouncementDao extends DatabaseAccessor<SayawDatabase>
    with _$AnnouncementDaoMixin {
  AnnouncementDao(super.db);

  Future<AnnouncementCacheRow?> byHash(String hash) =>
      (select(announcementCache)..where((a) => a.hash.equals(hash)))
          .getSingleOrNull();

  Future<void> put(AnnouncementCacheRow row) =>
      into(announcementCache).insertOnConflictUpdate(row);

  Future<void> markUsed(String hash) =>
      (update(announcementCache)..where((a) => a.hash.equals(hash)))
          .write(AnnouncementCacheCompanion(lastUsedAt: Value(clock.now())));

  /// Clips not used since [cutoff]. The files are deleted by the caller, which
  /// owns the filesystem; this only forgets the rows.
  Future<List<AnnouncementCacheRow>> unusedSince(DateTime cutoff) {
    // Comparisons run against the stored representation, not the Dart one.
    final millis = const MillisConverter().toSql(cutoff);
    return (select(announcementCache)
          ..where((a) =>
              a.lastUsedAt.isSmallerThanValue(millis) |
              (a.lastUsedAt.isNull() & a.createdAt.isSmallerThanValue(millis))))
        .get();
  }

  Future<int> forget(Iterable<String> hashes) =>
      (delete(announcementCache)..where((a) => a.hash.isIn(hashes))).go();
}

/// The [AnnouncementCacheStore] the engine actually runs against.
///
/// [AnnouncementClip] carries only what playback needs — a file and its
/// duration. The table also records the voice it was rendered with, because a
/// clip synthesised at one rate is not interchangeable with the same words at
/// another, and eviction needs to know which is which.
class DriftAnnouncementCache implements AnnouncementCacheStore {
  DriftAnnouncementCache(this.dao, this.settings);

  final AnnouncementDao dao;
  final TtsVoiceSettings settings;

  @override
  Future<AnnouncementClip?> get(String hash) async {
    final row = await dao.byHash(hash);
    if (row == null) return null;

    await dao.markUsed(hash);
    return AnnouncementClip(
      hash: row.hash,
      filePath: row.filePath,
      duration: row.durationMs,
      text: row.body,
    );
  }

  @override
  Future<void> put(AnnouncementClip clip) {
    final now = clock.now();
    return dao.put(AnnouncementCacheRow(
      hash: clip.hash,
      body: clip.text,
      voiceId: settings.voiceId,
      rate: settings.rate,
      pitch: settings.pitch,
      filePath: clip.filePath,
      durationMs: clip.duration,
      createdAt: now,
      lastUsedAt: now,
    ));
  }
}

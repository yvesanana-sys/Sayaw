import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import 'converters.dart';
import 'database.dart';
import 'tables.dart';

part 'cache_dao.g.dart';

/// What is on disk, and what is on its way there.
///
/// `policy_allows_persist` is written once, by the downloader, from the answer
/// `MediaResolver.policyFor` gave. Nothing else sets it, and a row without it
/// is a row whose bytes should not be there.
@DriftAccessor(tables: [CacheEntries])
class CacheDao extends DatabaseAccessor<SayawDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  Future<CacheEntry?> byTrack(String trackId) =>
      (select(cacheEntries)..where((c) => c.trackId.equals(trackId)))
          .getSingleOrNull();

  /// Every entry, pinned or not. For clearing the library, where the files
  /// have to go before the rows cascade away and forget where they were.
  Future<List<CacheEntry>> all() => select(cacheEntries).get();

  Future<List<CacheEntry>> byTracks(Iterable<String> trackIds) =>
      (select(cacheEntries)..where((c) => c.trackId.isIn(trackIds))).get();

  Stream<CacheEntry?> watchTrack(String trackId) =>
      (select(cacheEntries)..where((c) => c.trackId.equals(trackId)))
          .watchSingleOrNull();

  /// Marks a download as started, recording the policy that authorised it.
  Future<void> begin(String trackId, {required bool policyAllowsPersist}) =>
      into(cacheEntries).insertOnConflictUpdate(CacheEntriesCompanion(
        trackId: Value(trackId),
        state: const Value(CacheState.pending),
        bytesDownloaded: const Value(0),
        policyAllowsPersist: Value(policyAllowsPersist),
        createdAt: Value(clock.now()),
      ));

  /// Records progress, and where the partial file is, so an interrupted
  /// download can pick up from the byte it stopped at rather than starting the
  /// night's worth of music again.
  Future<void> progress(
    String trackId, {
    required String path,
    required int received,
    required int total,
  }) =>
      (update(cacheEntries)..where((c) => c.trackId.equals(trackId))).write(
        CacheEntriesCompanion(
          state: const Value(CacheState.partial),
          cachePath: Value(path),
          bytesDownloaded: Value(received),
          byteSize: Value(total),
        ),
      );

  Future<void> complete(
    String trackId, {
    required String path,
    required int byteSize,
    DateTime? expiresAt,
  }) =>
      (update(cacheEntries)..where((c) => c.trackId.equals(trackId))).write(
        CacheEntriesCompanion(
          state: const Value(CacheState.complete),
          cachePath: Value(path),
          byteSize: Value(byteSize),
          bytesDownloaded: Value(byteSize),
          expiresAt: Value(expiresAt),
          lastAccessedAt: Value(clock.now()),
        ),
      );

  Future<void> fail(String trackId) =>
      (update(cacheEntries)..where((c) => c.trackId.equals(trackId)))
          .write(const CacheEntriesCompanion(state: Value(CacheState.failed)));

  /// Moves the entry's place in the eviction queue. Called when a track plays,
  /// which is what makes "least recently used" mean what it says.
  Future<void> touch(String trackId) =>
      (update(cacheEntries)..where((c) => c.trackId.equals(trackId))).write(
        CacheEntriesCompanion(lastAccessedAt: Value(clock.now())),
      );

  /// Exempt from eviction. What Event Mode pins for tonight's set.
  Future<void> setPinned(String trackId, bool pinned) =>
      (update(cacheEntries)..where((c) => c.trackId.equals(trackId)))
          .write(CacheEntriesCompanion(pinned: Value(pinned)));

  Future<void> unpinAll() =>
      update(cacheEntries).write(const CacheEntriesCompanion(pinned: Value(false)));

  Future<void> forget(String trackId) =>
      (delete(cacheEntries)..where((c) => c.trackId.equals(trackId))).go();

  /// Total bytes held by finished downloads.
  Future<int> bytesHeld() async {
    final sum = cacheEntries.byteSize.sum();
    final row = await (selectOnly(cacheEntries)
          ..addColumns([sum])
          ..where(cacheEntries.state.equalsValue(CacheState.complete)))
        .getSingle();
    return row.read(sum) ?? 0;
  }

  /// What to throw away first: unpinned finished downloads, least recently
  /// used at the front. Matches `idx_cache_lru`.
  Future<List<CacheEntry>> evictionQueue() => (select(cacheEntries)
        ..where((c) =>
            c.state.equalsValue(CacheState.complete) & c.pinned.equals(false))
        ..orderBy([
          (c) => OrderingTerm.asc(c.lastAccessedAt),
          (c) => OrderingTerm.asc(c.createdAt),
        ]))
      .get();

  /// Finished downloads whose licence or signed URL has run out.
  Future<List<CacheEntry>> expiredAt(DateTime moment) {
    final millis = const MillisConverter().toSql(moment);
    return (select(cacheEntries)
          ..where((c) =>
              c.state.equalsValue(CacheState.complete) &
              c.expiresAt.isSmallerThanValue(millis)))
        .get();
  }
}

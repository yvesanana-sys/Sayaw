import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../../media_resolver.dart' show CachePolicy;
import 'plex_api_client.dart';
import 'plex_library.dart';

class ImportReport {
  const ImportReport({
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.total,
  });

  final int added;
  final int updated;
  final int unchanged;

  /// What the server said the section holds, which is not always what came
  /// back — a track can vanish mid-import.
  final int total;

  int get imported => added + updated + unchanged;
}

/// Copies a Plex music library into the local mirror.
///
/// Aggregated search happens against that mirror rather than against three
/// services at query time, which is the whole reason searching still works
/// with the venue wifi down. The cost is this: an import up front, and a
/// re-import when the library changes.
class PlexImporter {
  PlexImporter({
    required this.db,
    required this.plex,
    this.pageSize = 200,
  });

  final SayawDatabase db;
  final PlexApiClient plex;

  /// Tracks per request. A DJ's library is routinely tens of thousands, and
  /// the server will happily try to serialise all of them into one response.
  final int pageSize;

  /// Imports every track in [sectionKey].
  ///
  /// A track whose part has not been touched since last time is skipped
  /// without a write: Plex bumps a part's `updatedAt` when the file behind it
  /// changes, so a re-import of an unchanged library is a walk and nothing
  /// else.
  Future<ImportReport> importSection(
    String accountId,
    String sectionKey, {
    void Function(int imported, int total)? onProgress,
  }) async {
    final now = clock.now();
    final account = await db.sourceAccountDao.byId(accountId);
    if (account == null) {
      throw ArgumentError.value(accountId, 'accountId', 'not connected');
    }

    final policy = cachePolicyForServer(owned: account.isOwned);
    final existing = await _existingByRatingKey(accountId);

    var added = 0;
    var updated = 0;
    var unchanged = 0;
    var start = 0;
    var total = 0;

    final pending = <TracksCompanion>[];
    final untouched = <String>[];

    while (true) {
      final page = await plex.tracksIn(accountId, sectionKey,
          start: start, size: pageSize);
      if (page.tracks.isEmpty) break;

      total = page.total;

      for (final track in page.tracks) {
        final known = existing[track.ratingKey];

        if (known != null &&
            track.partUpdatedAt != null &&
            known.sourceUpdatedAt == track.partUpdatedAt) {
          untouched.add(known.id);
          unchanged++;
          continue;
        }

        pending.add(_companionFor(
          track: track,
          known: known,
          accountId: accountId,
          policy: policy,
          now: now,
        ));
        known == null ? added++ : updated++;
      }

      await _write(pending);
      await _markVerified(untouched, now);

      start += page.tracks.length;
      onProgress?.call(start, total);

      if (start >= total) break;
    }

    return ImportReport(
      added: added,
      updated: updated,
      unchanged: unchanged,
      total: total,
    );
  }

  /// Only the columns an import is entitled to write.
  ///
  /// Cue points, gain trims and the default dance type belong to the operator
  /// and are worth more than anything the server knows. Leaving them out of
  /// the companion leaves them out of the `DO UPDATE SET`, so a re-import
  /// cannot undo an afternoon of preparing a set — the same rule the folder
  /// scanner follows.
  TracksCompanion _companionFor({
    required PlexTrack track,
    required Track? known,
    required String accountId,
    required CachePolicy policy,
    required DateTime now,
  }) =>
      TracksCompanion(
        id: Value(known?.id ?? newId()),
        sourceType: const Value(SourceType.plex),
        accountId: Value(accountId),
        sourceId: Value(track.ratingKey),
        sourcePartId: Value(track.partId),
        sourceUpdatedAt: Value(track.partUpdatedAt),
        title: Value(track.title),
        artist: Value(track.artist),
        album: Value(track.album),
        year: Value(track.year),
        durationMs: Value(track.duration ?? Duration.zero),
        codec: Value(track.codec),
        bitrateKbps: Value(track.bitrateKbps),
        cachePolicy: Value(policy),
        addedAt: Value(known?.addedAt ?? now),
        updatedAt: Value(now),
        lastVerifiedAt: Value(now),
      );

  Future<Map<String, Track>> _existingByRatingKey(String accountId) async {
    final rows = await (db.select(db.tracks)
          ..where((t) =>
              t.sourceType.equalsValue(SourceType.plex) &
              t.accountId.equals(accountId)))
        .get();

    return {for (final row in rows) ?row.sourceId: row};
  }

  Future<void> _write(List<TracksCompanion> pending) async {
    if (pending.isEmpty) return;
    await db.trackDao.upsertAll(pending);
    pending.clear();
  }

  Future<void> _markVerified(List<String> ids, DateTime now) async {
    if (ids.isEmpty) return;
    await (db.update(db.tracks)..where((t) => t.id.isIn(ids)))
        .write(TracksCompanion(lastVerifiedAt: Value(now)));
    ids.clear();
  }
}

/// What a track from this server may be written to disk.
///
/// Your own server is your own files, so a full offline cache is fine. A
/// library someone shared with you is not, and `MediaResolver.policyFor` is
/// the gate that enforces it — this is where the answer is recorded so the
/// gate has something to read after a restart.
CachePolicy cachePolicyForServer({required bool owned}) =>
    owned ? CachePolicy.allow : CachePolicy.forbid;

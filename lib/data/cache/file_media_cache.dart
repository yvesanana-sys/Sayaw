import 'dart:io';

import '../db/database.dart';
import '../media_resolver.dart';

/// The read side of the on-disk cache.
///
/// Answers one question — is there a finished, unexpired copy of this on disk?
/// — and cannot write anything. Downloading is `MediaDownloader`, which asks
/// `MediaResolver.policyFor` first.
class FileMediaCache implements MediaCache {
  const FileMediaCache(this.db);

  final SayawDatabase db;

  @override
  Future<String?> completeFileFor(TrackSource source) async {
    final track = await _trackFor(source);
    if (track == null) return null;

    final entry = await db.cacheDao.byTrack(track.id);
    if (entry == null || entry.state != CacheState.complete) return null;
    if (entry.cachePath == null) return null;

    // An expired entry is not a file to play: a Plex part that has been
    // replaced, or an offline licence that has run out.
    if (entry.expiresAt case final expiry? when expiry.isBefore(DateTime.now())) {
      return null;
    }

    // The row can outlive the file — an operator clearing space, a cache
    // directory on a volume that is not mounted. Trust the disk over the row.
    if (!File(entry.cachePath!).existsSync()) return null;

    await db.cacheDao.touch(track.id);
    return entry.cachePath;
  }

  /// The inverse of `PlaylistRepository.sourceFor`: `cache_entries` is keyed by
  /// track, and the resolver only knows the source it came from.
  Future<Track?> _trackFor(TrackSource source) => switch (source) {
        LocalSource s => db.trackDao
            .bySource(sourceType: SourceType.local, localPath: s.path),
        PlexSource s => db.trackDao.bySource(
            sourceType: SourceType.plex,
            accountId: s.accountId,
            sourceId: s.ratingKey,
          ),
        TidalSource s => db.trackDao.bySource(
            sourceType: SourceType.tidal,
            accountId: s.accountId,
            sourceId: s.trackId,
          ),
      };
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../audio/deck.dart' show PlayableMedia;
import '../db/database.dart';
import '../media_resolver.dart';
import '../playlist_repository.dart';

/// Why a download did not happen.
class DownloadRefused implements Exception {
  DownloadRefused(this.reason);
  final String reason;

  @override
  String toString() => 'DownloadRefused: $reason';
}

/// The only thing in the app that writes media bytes to disk.
///
/// Every call asks [MediaResolver.policyFor] first and refuses anything that
/// does not come back [CachePolicy.allow]. That is what makes the TIDAL
/// restriction — no persisting decrypted audio without an offline entitlement
/// — enforced by construction rather than by everyone remembering.
class MediaDownloader {
  MediaDownloader({
    required this.db,
    required this.resolver,
    required this.dio,
    required this.directory,
  });

  final SayawDatabase db;
  final MediaResolver resolver;
  final Dio dio;

  /// Where the bytes go. One flat directory keyed by track id: a set that
  /// spans four Plex libraries and a folder of local files has no natural tree
  /// to mirror, and a flat one is trivial to measure and to empty.
  final Directory directory;

  /// Downloads [track] unless policy forbids it.
  ///
  /// Resumes where a previous attempt stopped: a four-hour set over venue wifi
  /// is not something to start again from the beginning because a download
  /// dropped at 90%.
  Future<CacheEntry> download(
    Track track, {
    void Function(int received, int total)? onProgress,
  }) async {
    final source = await _sourceFor(track);
    final policy = resolver.policyFor(source);

    if (policy != CachePolicy.allow) {
      throw DownloadRefused(switch (policy) {
        CachePolicy.sessionOnly =>
          'This track may be streamed but not kept on disk',
        CachePolicy.forbid => 'This track may not be kept on disk',
        CachePolicy.allow => '',
      });
    }

    final media = await resolver.resolve(source);
    if (media.uri.isScheme('file')) {
      throw DownloadRefused('That track is already a local file');
    }

    await db.cacheDao.begin(track.id, policyAllowsPersist: true);

    final partial = File(p.join(directory.path, '${track.id}.part'));
    final finished = File(p.join(directory.path, track.id));

    try {
      await directory.create(recursive: true);
      final size = await _fetch(media, partial, onProgress);

      // Rename rather than write in place, so a file under `finished` is
      // always a whole one — a half-written track that plays for ten seconds
      // and stops is worse on a dance floor than one that never appears.
      await partial.rename(finished.path);

      await db.cacheDao.complete(
        track.id,
        path: finished.path,
        byteSize: size,
        expiresAt: media.expiresAt,
      );
    } on Object {
      await db.cacheDao.fail(track.id);
      rethrow;
    }

    return (await db.cacheDao.byTrack(track.id))!;
  }

  /// Removes a track's bytes and forgets the row.
  Future<void> remove(String trackId) async {
    final entry = await db.cacheDao.byTrack(trackId);
    if (entry?.cachePath case final path?) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await db.cacheDao.forget(trackId);
  }

  /// Throws away the least recently used tracks until the cache fits in
  /// [maxBytes]. Pinned entries — tonight's set — are never touched.
  ///
  /// Returns how many were removed.
  Future<int> evictTo(int maxBytes) async {
    var held = await db.cacheDao.bytesHeld();
    if (held <= maxBytes) return 0;

    var removed = 0;
    for (final entry in await db.cacheDao.evictionQueue()) {
      if (held <= maxBytes) break;
      await remove(entry.trackId);
      held -= entry.byteSize;
      removed++;
    }
    return removed;
  }

  /// Drops entries whose signed URL or offline licence has run out.
  Future<int> evictExpired() async {
    final expired = await db.cacheDao.expiredAt(DateTime.now());
    for (final entry in expired) {
      await remove(entry.trackId);
    }
    return expired.length;
  }

  // -------------------------------------------------------------------------

  /// Streams the body into [target], appending when there is already part of
  /// it there. Returns the finished size.
  Future<int> _fetch(
    PlayableMedia media,
    File target,
    void Function(int received, int total)? onProgress,
  ) async {
    final alreadyHave = target.existsSync() ? target.lengthSync() : 0;

    final response = await dio.getUri<ResponseBody>(
      media.uri,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          ...media.headers,
          if (alreadyHave > 0) 'Range': 'bytes=$alreadyHave-',
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // 206 means the server honoured the range and is sending the tail. Any
    // other success means it is sending the whole thing, so what is on disk is
    // no longer a prefix of it.
    final resuming = response.statusCode == 206 && alreadyHave > 0;
    if (!resuming && alreadyHave > 0) await target.delete();

    final total = _totalBytes(response, alreadyHave: resuming ? alreadyHave : 0);
    var received = resuming ? alreadyHave : 0;

    final sink = target.openWrite(
      mode: resuming ? FileMode.append : FileMode.write,
    );

    try {
      await for (final Uint8List chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
    } finally {
      await sink.close();
    }

    return target.lengthSync();
  }

  /// What the whole file will be, from `Content-Range` when resuming and
  /// `Content-Length` otherwise. Zero when the server will not say, which the
  /// UI reads as "no percentage available" rather than as an empty file.
  static int _totalBytes(Response<ResponseBody> response,
      {required int alreadyHave}) {
    final range = response.headers.value('content-range');
    if (range != null) {
      final total = int.tryParse(range.split('/').last);
      if (total != null) return total;
    }

    final length = int.tryParse(response.headers.value('content-length') ?? '');
    return length == null ? 0 : length + alreadyHave;
  }

  Future<TrackSource> _sourceFor(Track track) async {
    final accountId = track.accountId;
    final account =
        accountId == null ? null : await db.sourceAccountDao.byId(accountId);
    return PlaylistRepository.sourceFor(track, account: account);
  }
}

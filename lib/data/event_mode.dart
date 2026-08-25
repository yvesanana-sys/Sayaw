import '../audio/announcement_engine.dart';
import '../audio/crossfade_engine.dart' show AnnounceMode;
import 'cache/media_downloader.dart';
import 'db/database.dart';
import 'media_resolver.dart';
import 'playlist_repository.dart';

/// What will happen to one row of the set when the network goes.
enum PreflightOutcome {
  /// Plays with no connection at all: a local file, or a download that
  /// finished and is pinned.
  readyOffline,

  /// Reachable now, and only now. TIDAL without an offline entitlement, or a
  /// Plex library someone shared with you.
  streamingOnly,

  /// The path no longer resolves. An unmounted volume, or a folder grant that
  /// expired — SAF permissions and macOS security-scoped bookmarks both do.
  missingFile,

  /// Policy allows a copy but getting one did not work.
  notDownloaded,

  /// A row the engine cannot play at all, whatever the network is doing.
  notPlayable,
}

class PreflightItem {
  const PreflightItem({
    required this.itemId,
    required this.title,
    required this.outcome,
    this.detail,
  });

  final String itemId;
  final String title;
  final PreflightOutcome outcome;

  /// Phrased for the operator, when there is something to say beyond the
  /// outcome itself.
  final String? detail;
}

/// What a DJ standing in a venue at six o'clock needs to know.
class PreflightReport {
  const PreflightReport({
    required this.items,
    required this.announcementsRendered,
    required this.announcementsMissing,
  });

  final List<PreflightItem> items;

  /// Announcement audio is always local, so a rendered clip keeps working
  /// however bad the wifi gets.
  final int announcementsRendered;

  /// Rows that wanted an announcement and did not get one — a mute TTS engine,
  /// or a recorded clip that has been moved.
  final int announcementsMissing;

  int get total => items.length;

  int countOf(PreflightOutcome outcome) =>
      items.where((item) => item.outcome == outcome).length;

  int get readyCount => countOf(PreflightOutcome.readyOffline);

  /// True when the whole set would run with the venue's wifi unplugged.
  bool get readyOffline => readyCount == total;
}

/// Which part of the walk is running, for a progress readout that says what it
/// is doing rather than spinning.
enum PreflightStep { resolving, downloading, announcing }

class PreflightProgress {
  const PreflightProgress({
    required this.step,
    required this.done,
    required this.total,
    this.title,
  });

  final PreflightStep step;
  final int done;
  final int total;

  /// What it is working on, so a stall has a name attached to it.
  final String? title;
}

/// "Prepare for offline".
///
/// Walks the set, downloads what policy permits, pre-renders every
/// announcement, checks that every local path still resolves, and reports what
/// will and will not play. Run over the venue's wifi before doors open and the
/// set becomes deterministic.
class EventPreflight {
  EventPreflight({
    required this.db,
    required this.repository,
    required this.downloader,
    required this.announcements,
  });

  final SayawDatabase db;
  final PlaylistRepository repository;
  final MediaDownloader downloader;
  final AnnouncementEngine announcements;

  Future<PreflightReport> prepare(
    String playlistId, {
    void Function(PreflightProgress)? onProgress,
  }) async {
    onProgress?.call(const PreflightProgress(
        step: PreflightStep.resolving, done: 0, total: 0));

    final rows = await db.playlistDao.itemsOf(playlistId);
    final resolved = await repository.buildQueue(playlistId);

    final entries = {for (final e in resolved.entries) e.itemId: e};
    final unavailable = {for (final u in resolved.unavailable) u.itemId: u};
    final accounts = {
      for (final a in await db.select(db.sourceAccounts).get()) a.id: a,
    };

    // Last event's pins are not this event's. Clear them before pinning, so
    // eviction is free to reclaim a set that is over.
    await db.cacheDao.unpinAll();

    final items = <PreflightItem>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final title = row.track?.title ?? row.danceType?.name ?? 'Untitled';

      onProgress?.call(PreflightProgress(
        step: PreflightStep.downloading,
        done: i,
        total: rows.length,
        title: title,
      ));

      if (unavailable[row.item.id] case final problem?) {
        items.add(PreflightItem(
          itemId: row.item.id,
          title: title,
          outcome: switch (problem.kind) {
            UnavailableKind.fileMissing => PreflightOutcome.missingFile,
            UnavailableKind.unreachable => PreflightOutcome.notDownloaded,
            UnavailableKind.unsupportedRow => PreflightOutcome.notPlayable,
          },
          detail: problem.reason,
        ));
        continue;
      }

      final track = row.track;
      if (track == null || entries[row.item.id] == null) {
        items.add(PreflightItem(
          itemId: row.item.id,
          title: title,
          outcome: PreflightOutcome.notPlayable,
        ));
        continue;
      }

      items.add(await _prepareTrack(track, itemId: row.item.id, accounts: accounts));
    }

    final announced = await _renderAnnouncements(resolved, onProgress);

    return PreflightReport(
      items: items,
      announcementsRendered: announced.$1,
      announcementsMissing: announced.$2,
    );
  }

  // -------------------------------------------------------------------------

  Future<PreflightItem> _prepareTrack(
    Track track, {
    required String itemId,
    required Map<String, SourceAccount> accounts,
  }) async {
    // It resolved a moment ago, so a local file is on disk right now and needs
    // nothing further. This is where an expired folder grant shows up, and it
    // has already shown up as `missingFile` above.
    final source = PlaylistRepository.sourceFor(
      track,
      account: accounts[track.accountId],
    );

    if (source is LocalSource) {
      return PreflightItem(
        itemId: itemId,
        title: track.title,
        outcome: PreflightOutcome.readyOffline,
      );
    }

    if (repository.resolver.policyFor(source) != CachePolicy.allow) {
      return PreflightItem(
        itemId: itemId,
        title: track.title,
        outcome: PreflightOutcome.streamingOnly,
        detail: 'Streaming only — will be skipped without a connection',
      );
    }

    try {
      final existing = await db.cacheDao.byTrack(track.id);
      if (existing?.state != CacheState.complete) {
        await downloader.download(track);
      }

      // Pinned so tonight's set survives an eviction triggered by anything
      // else that gets downloaded between now and the last dance.
      await db.cacheDao.setPinned(track.id, true);

      return PreflightItem(
        itemId: itemId,
        title: track.title,
        outcome: PreflightOutcome.readyOffline,
      );
    } on Object catch (e) {
      return PreflightItem(
        itemId: itemId,
        title: track.title,
        outcome: PreflightOutcome.notDownloaded,
        detail: e is DownloadRefused ? e.reason : 'Could not be downloaded',
      );
    }
  }

  /// Renders every announcement in the set to a file up front, so no
  /// transition pays for synthesis and none of them needs the network.
  ///
  /// Returns (rendered, missing).
  Future<(int, int)> _renderAnnouncements(
    ResolvedQueue resolved,
    void Function(PreflightProgress)? onProgress,
  ) async {
    var rendered = 0;
    var missing = 0;

    // A set with forty Cha-Chas announces "Cha-Cha" forty times and renders it
    // once; the engine's cache deduplicates on the hash of what is spoken.
    for (var i = 0; i < resolved.entries.length; i++) {
      final entry = resolved.entries[i];

      onProgress?.call(PreflightProgress(
        step: PreflightStep.announcing,
        done: i,
        total: resolved.entries.length,
        title: entry.title,
      ));

      if (entry.spec.announceMode == AnnounceMode.off) continue;

      final clip = await announcements.clipFor(entry);
      clip == null ? missing++ : rendered++;
    }

    return (rendered, missing);
  }
}

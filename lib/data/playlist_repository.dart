import '../audio/crossfade_engine.dart';
import '../audio/deck.dart' show PlayableMedia;
import 'db/database.dart';
import 'media_resolver.dart';

/// A set, turned into something the engine can play.
///
/// [unavailable] is not an error list to log and forget: it is what Event Mode
/// shows the operator before doors open. A row that will not play is worth
/// knowing about at 6pm, not at the moment the floor is waiting for it.
class ResolvedQueue {
  const ResolvedQueue({required this.entries, required this.unavailable});

  final List<QueueEntry> entries;
  final List<UnavailableItem> unavailable;

  bool get isCompletelyPlayable => unavailable.isEmpty;
}

class UnavailableItem {
  const UnavailableItem({
    required this.itemId,
    required this.title,
    required this.kind,
    required this.reason,
  });

  final String itemId;
  final String title;
  final UnavailableKind kind;

  /// Phrased for the operator, not for a log file.
  final String reason;
}

/// Why a row will not play, in the terms the operator can act on: find the
/// file, get the network back, or accept that the app cannot do this yet.
enum UnavailableKind { fileMissing, unreachable, unsupportedRow }

/// Turns stored rows into [QueueEntry]s.
///
/// This is the layer `TransitionSpec` refers to when it says its settings are
/// "already merged from playlist defaults and item-level overrides": below it,
/// nothing knows a playlist exists, and the audio engine never sees a database
/// row or a source type.
class PlaylistRepository {
  PlaylistRepository({required this.db, required this.resolver});

  final SayawDatabase db;
  final MediaResolver resolver;

  /// Resolves a whole set in one pass.
  ///
  /// Signed URLs from TIDAL expire, so an entry whose `media.expiresAt` has
  /// passed should be refreshed with [resolveRow] before it plays rather than
  /// trusted hours later.
  Future<ResolvedQueue> buildQueue(String playlistId) async {
    final playlist = await db.playlistDao.byId(playlistId);
    if (playlist == null) {
      throw ArgumentError.value(playlistId, 'playlistId', 'no such playlist');
    }

    final rows = await db.playlistDao.itemsOf(playlistId);
    final accounts = await _accountsById();

    final entries = <QueueEntry>[];
    final unavailable = <UnavailableItem>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];

      // The engine plays media. A silence gap, a standalone announcement or a
      // marker has none, and is reported rather than dropped silently so the
      // operator can see the set is not being played as written.
      if (row.item.itemType != PlaylistItemType.track || row.track == null) {
        unavailable.add(UnavailableItem(
          itemId: row.item.id,
          title: row.danceType?.name ?? row.item.itemType.name,
          kind: UnavailableKind.unsupportedRow,
          reason: '${row.item.itemType.name} rows are not playable yet',
        ));
        continue;
      }

      try {
        entries.add(await resolveRow(
          row,
          playlist: playlist,
          nextDanceTypeName: _nextDanceTypeName(rows, i),
          mergedFromPrevious: _mergedFromPrevious(rows, i),
          account: accounts[row.track!.accountId],
        ));
      } on UnavailableOffline catch (e) {
        unavailable.add(UnavailableItem(
          itemId: row.item.id,
          title: row.track!.title,
          // A local track that will not resolve is a file the operator can go
          // and find; a remote one is a server or a connection.
          kind: row.track!.sourceType == SourceType.local
              ? UnavailableKind.fileMissing
              : UnavailableKind.unreachable,
          reason: e.reason,
        ));
      }
    }

    return ResolvedQueue(entries: entries, unavailable: unavailable);
  }

  /// Resolves one row. Throws [UnavailableOffline] if its media cannot be
  /// reached from here.
  Future<QueueEntry> resolveRow(
    PlaylistRow row, {
    required Playlist playlist,
    String? nextDanceTypeName,
    bool mergedFromPrevious = false,
    SourceAccount? account,
  }) async {
    final track = row.track;
    if (track == null) {
      throw ArgumentError.value(row.item.id, 'row', 'row has no track');
    }
    final item = row.item;

    final media = await _resolveMedia(row, account: account);

    return QueueEntry(
      itemId: item.id,
      media: media,
      spec: specFor(
        playlist,
        item,
        taggedCue: row.soundCue != null,
        mergedFromPrevious: mergedFromPrevious,
      ),
      danceTypeName: row.danceType?.name,
      announcementText: announcementTextFor(row, next: nextDanceTypeName),
      announcementClipPath: announcementClipFor(row),
      // The row's own cap first, then the set's. Null on both plays the track
      // to its end, which is what a set built song by song wants; a rotation
      // or a competition round sets one on the playlist and every row inherits
      // it without forty identical overrides.
      targetDuration: item.targetDurationMs ?? playlist.targetDurationMs,
      title: track.title,
      artist: track.artist ?? '',
    );
  }

  /// Re-resolves one entry's media, for a signed URL that is about to expire.
  ///
  /// Only the media is replaced. A TIDAL URL dying at the ninety-minute mark
  /// says nothing about the crossfade the operator set for that row, so
  /// rebuilding the whole entry would be work with a chance of changing
  /// something under a set that is already running.
  ///
  /// Throws when the row has been deleted out from under the queue; the engine
  /// treats that as a reason to keep the URL it has rather than to stop.
  Future<QueueEntry> refreshEntry(QueueEntry entry) async {
    final row = await db.playlistDao.rowById(entry.itemId);
    if (row == null || row.track == null) {
      throw StateError('item ${entry.itemId} is no longer in the set');
    }

    final accounts = await _accountsById();
    return entry.withMedia(await _resolveMedia(
      row,
      account: accounts[row.track!.accountId],
    ));
  }

  /// The one place a row's trims and cue points turn into playable media, so
  /// a refresh mid-set resolves on exactly the terms the set was built on.
  Future<PlayableMedia> _resolveMedia(
    PlaylistRow row, {
    SourceAccount? account,
  }) {
    final track = row.track!;
    final item = row.item;

    return resolver.resolve(
      sourceFor(track, account: account),
      // Two independent trims: the track's own ReplayGain or manual level, and
      // a nudge for this one appearance of it in this one set.
      gainDb: track.gainDb + item.gainOffsetDb,
      cueIn: track.cueInMs + item.startOffsetMs,
      cueOut: item.endOffsetMs ?? track.cueOutMs,
    );
  }

  /// Playlist defaults with the row's overrides applied.
  ///
  /// Null on a row means inherit, which is why these columns are nullable in a
  /// table whose playlist-level equivalents are not.
  ///
  /// [taggedCue] says the operator has pointed this row at one of their own
  /// clips. That is a statement about *when* as well as what: tagging a cue to
  /// a row means "play this across the transition", so it carries the set's
  /// announcement mode over to `duckOver` on its own. A row that names a mode
  /// explicitly still wins, and a rotation still forces the sequential shape
  /// whatever this says — see `TransitionSpec.isSequential` — so The Mixer
  /// plays the same tagged clip cleanly in its gap rather than over a fade
  /// that is not happening.
  ///
  /// [mergedFromPrevious] says the row before this one leads into it as one
  /// dance, and it settles everything: the overlap, the silence of the
  /// announcer, the absence of a rotation gap. A tagged cue on a merged row
  /// is kept for when the row is reached any other way — a tap, a set opened
  /// on it — but a merge does not speak.
  static TransitionSpec specFor(
    Playlist playlist,
    PlaylistItem item, {
    bool taggedCue = false,
    bool mergedFromPrevious = false,
  }) =>
      mergedFromPrevious
          ? TransitionSpec.merge(
              duckLevel: playlist.duckLevel,
              duckFade: playlist.duckFadeMs,
              duckHold: playlist.duckHoldMs,
              duckRestoreFade: playlist.duckRestoreFadeMs,
              pauseAfter: item.pauseAfter,
            )
          : TransitionSpec(
        crossfade: item.crossfadeMs ?? playlist.crossfadeMs,
        fadeInCurve: item.fadeInCurve ?? playlist.fadeInCurve,
        fadeOutCurve: item.fadeOutCurve ?? playlist.fadeOutCurve,
        announceMode: item.announceMode ??
            (taggedCue ? AnnounceMode.duckOver : playlist.announceMode),
        // The duck envelope is a property of the room and the voice, not of one
        // song, so it is deliberately not overridable per row.
        duckLevel: playlist.duckLevel,
        duckFade: playlist.duckFadeMs,
        duckHold: playlist.duckHoldMs,
        duckRestoreFade: playlist.duckRestoreFadeMs,
        // A property of the night rather than of one song, like the duck
        // envelope above it, so there is deliberately no per-row override.
        rotationGap: playlist.rotationGapMs,
        pauseAfter: item.pauseAfter,
      );

  /// Rebuilds the sealed source from the flattened columns — the `TrackMapper`
  /// of ARCHITECTURE §2.2, and the last point at which anything knows which
  /// service a track came from.
  static TrackSource sourceFor(Track track, {SourceAccount? account}) {
    switch (track.sourceType) {
      case SourceType.local:
        return LocalSource(
          path: track.localPath,
          contentUri: track.contentUri,
          bookmark: track.securityBookmark,
        );

      case SourceType.plex:
        final machineIdentifier = account?.machineIdentifier;
        if (account == null || machineIdentifier == null) {
          throw UnavailableOffline(
              'The Plex server this track came from is no longer connected');
        }
        return PlexSource(
          accountId: account.id,
          machineIdentifier: machineIdentifier,
          ratingKey: track.sourceId!,
          partId: track.sourcePartId,
          partUpdatedAt: track.sourceUpdatedAt,
          // What decides whether this track may ever be written to disk. It is
          // recorded on the account when the server is connected, so the
          // answer survives a restart rather than being assumed.
          isOwnedServer: account.isOwned,
        );

      case SourceType.tidal:
        if (account == null) {
          throw UnavailableOffline('The TIDAL account for this track is gone');
        }
        return TidalSource(accountId: account.id, trackId: track.sourceId!);
    }
  }

  /// Which audio file announces this row, most specific first.
  ///
  /// A cue the operator tagged to this one row beats a path set on the row,
  /// which beats the clip recorded for the whole dance type. All three are
  /// files on the announcement deck by the time the engine sees them, so a
  /// hand-recorded MC and a synthesised voice cost a transition the same.
  static String? announcementClipFor(PlaylistRow row) =>
      row.soundCue?.filePath ??
      row.item.announcementClipPath ??
      row.danceType?.customClipPath;

  /// Whether the row before [index] runs into it as one dance.
  static bool _mergedFromPrevious(List<PlaylistRow> rows, int index) =>
      index > 0 && rows[index - 1].item.mergeIntoNext;

  /// What the voice will say before this row.
  ///
  /// An explicit line on the row wins over the dance type's template, and both
  /// are templates: `{name}` is this dance, `{next}` is the one after it.
  static String? announcementTextFor(PlaylistRow row, {String? next}) {
    final template = switch (row.item.announcementText) {
      final String text when text.trim().isNotEmpty => text,
      _ => row.danceType?.ttsTemplate,
    };
    if (template == null) return null;

    // Substituting an empty value leaves a hole and its spacing behind —
    // "Next dance:  , then Waltz" — which a synthesiser reads as a pause in
    // the wrong place.
    final spoken = template
        .replaceAll('{name}', row.danceType?.name ?? '')
        .replaceAll('{next}', next ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([,.!?;:])'), (m) => m[1]!)
        .trim();

    return spoken.isEmpty ? null : spoken;
  }

  // ---------------------------------------------------------------------

  Future<Map<String, SourceAccount>> _accountsById() async => {
        for (final account in await db.select(db.sourceAccounts).get())
          account.id: account,
      };

  static String? _nextDanceTypeName(List<PlaylistRow> rows, int index) {
    for (var i = index + 1; i < rows.length; i++) {
      final name = rows[i].danceType?.name;
      if (name != null) return name;
    }
    return null;
  }
}

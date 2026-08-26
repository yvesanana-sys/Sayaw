import 'dart:async';
import 'dart:io';

import '../../audio/crossfade_engine.dart';
import '../../data/cache/media_downloader.dart';
import '../../data/db/database.dart';
import '../../data/event_mode.dart';
import '../../data/library/library_scanner.dart';
import '../../data/media_resolver.dart' show NetworkMode, UnavailableOffline;
import '../../data/playlist_repository.dart';
import 'library_access.dart';
import 'playback_ui_state.dart';

/// The seam between the audio engine and what the screen draws.
///
/// [PlaybackController] holds the view model and takes the operator's input;
/// [CrossfadeEngine] owns timing, gain and the two decks. Neither knows about
/// the other. This connects them: commands go down, engine events come back
/// up, and the queue is loaded from the database in between.
///
/// It lives in `ui/state` rather than `audio/` on purpose — the audio layer
/// stays free of any dependency on the UI, which is what keeps its whole test
/// suite runnable without a widget tree.
class PlaybackSession implements LibraryAccess, EventModeAccess {
  PlaybackSession({
    required this.engine,
    required this.repository,
    required this.controller,
    this.downloader,
    this.uiTick = const Duration(milliseconds: 100),
  }) {
    _events = engine.events.listen(_onEngineEvent);
    controller.attach(this);
  }

  final CrossfadeEngine engine;
  final PlaylistRepository repository;
  final PlaybackController controller;

  /// Absent in a build with nowhere to write to, which makes preparing for
  /// offline unavailable rather than silently doing nothing.
  final MediaDownloader? downloader;

  /// The engine writes gains at 50 Hz. A progress arc does not need that, and
  /// on a tablet running a four-hour event the difference is battery.
  final Duration uiTick;

  late final StreamSubscription<EngineEvent> _events;
  Timer? _ticker;

  String? _playlistId;
  String? get playlistId => _playlistId;

  @override
  String? get openPlaylistId => _playlistId;

  /// Which rows the engine actually accepted, in engine order. The queue the
  /// operator sees can contain rows the engine skipped, so the two index
  /// spaces are not the same and this is what maps between them.
  List<String> _engineItemIds = const [];

  // -------------------------------------------------------------------------
  // Loading
  // -------------------------------------------------------------------------

  /// Reads a set out of the database, resolves it, and hands the playable part
  /// to the engine.
  ///
  /// Rows that will not play stay in the queue the operator sees, greyed and
  /// labelled. Dropping them would make the list on screen disagree with the
  /// list they built, which is worse than showing a row that cannot start.
  Future<ResolvedQueue> openPlaylist(String playlistId) async {
    final resolved = await repository.buildQueue(playlistId);
    final rows = await repository.db.playlistDao.itemsOf(playlistId);

    final reasons = {
      for (final item in resolved.unavailable) item.itemId: _reasonFor(item),
    };

    _playlistId = playlistId;
    _engineItemIds = [for (final entry in resolved.entries) entry.itemId];

    controller.setQueue([
      for (final row in rows)
        QueueItemUi(
          id: row.item.id,
          title: row.track?.title ?? row.danceType?.name ?? 'Untitled',
          artist: row.track?.artist ?? '',
          danceType: row.danceType?.name,
          duration: row.track?.durationMs,
          position: row.item.position,
          unavailable: reasons[row.item.id],
        ),
    ]);

    // The set's own shape, not the engine's: how many songs to play is a
    // property of the night the operator planned, and the engine is told it
    // rather than asked to work it out.
    await engine.loadQueue(
      resolved.entries,
      songLimit: (await repository.db.playlistDao.byId(playlistId))?.songLimit,
    );
    _publish();
    return resolved;
  }

  /// The network changed underneath an open set.
  ///
  /// With nothing loaded on a deck the set is simply resolved again: accurate
  /// in both directions, and there is no transition to interrupt.
  ///
  /// Mid-set is the interesting case, and there rows are only ever marked
  /// *down*. Reopening would call `engine.loadQueue`, dropping whatever is
  /// preloaded and prerolled on the standby deck — and this can fire in the
  /// middle of a crossfade. Nor can a row be marked back *up*: the engine was
  /// handed its queue when the set was opened and cannot take a skipped row
  /// back without that same reload, so drawing it as available would be a
  /// promise the engine will not keep. It becomes true again when the set is
  /// next opened, which is the honest moment for it.
  Future<void> applyNetworkMode(NetworkMode mode) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;

    if (engine.phase == EnginePhase.idle) {
      await openPlaylist(playlistId);
      return;
    }

    if (mode != NetworkMode.localOnly) return;

    // The availability view, not a re-resolve: this must not open a socket at
    // the exact moment the network has been established to be gone.
    final playable =
        await repository.db.playlistDao.offlineAvailability(playlistId);

    controller.setQueue([
      for (final item in controller.queueSnapshot)
        if (item.isPlayable && playable[item.id] == false)
          item.withUnavailable(UnavailableReason.offline)
        else
          item,
    ]);
  }

  // -------------------------------------------------------------------------
  // Transport
  // -------------------------------------------------------------------------

  /// The play button under one of the two decks.
  ///
  /// On the audible deck this is play/pause. On the standby deck it means
  /// "start the one that is cued up", which is a transition — the same thing
  /// the crossfade button does, and the same thing a DJ means by pressing play
  /// on the other deck.
  Future<void> togglePlay(DeckSlot slot) {
    if (slot != activeSlot) return skipNext();
    return engine.phase == EnginePhase.playing ? pause() : play();
  }

  Future<void> play() => engine.play();

  Future<void> pause() => engine.pause();

  /// Honours the configured crossfade rather than cutting: a hard cut on a
  /// full floor is jarring.
  Future<void> skipNext() => engine.skipNext();

  Future<void> stop() => engine.stop();

  /// The crossfader, with an engine behind it: 0 is deck A alone, 1 is deck B.
  ///
  /// Straight through. Which physical deck is audible, whether a transition is
  /// already running and what to do when the fader reaches the end are all the
  /// engine's business, and duplicating any of that here would give the screen
  /// a second opinion about the state of the mix.
  Future<void> setCrossfader(double value) => engine.setCrossfader(value);

  DeckSlot get activeSlot => engine.activeIsA ? DeckSlot.a : DeckSlot.b;

  // -------------------------------------------------------------------------
  // Queue edits
  // -------------------------------------------------------------------------

  /// Moves a row, writing the new position to the database.
  ///
  /// The engine is not reloaded: it has already preloaded and prerolled the
  /// next track, and tearing that down to honour a drag would put a gap in the
  /// transition that is seconds away. The new order takes effect from the row
  /// after the one on standby.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;

    await repository.db.playlistDao
        .move(playlistId: playlistId, oldIndex: oldIndex, newIndex: newIndex);

    final rows = await repository.db.playlistDao.itemsOf(playlistId);
    final byId = {for (final item in controller.queueSnapshot) item.id: item};

    controller.setQueue([
      for (final row in rows)
        if (byId[row.item.id] case final existing?)
          existing.copyWith(position: row.item.position),
    ]);
  }

  // -------------------------------------------------------------------------
  // The library
  // -------------------------------------------------------------------------

  /// Aggregated search across everything in the local mirror.
  ///
  /// Local files, Plex and TIDAL all live in one table, so this keeps working
  /// with the venue wifi down — the aggregation happened at import time.
  @override
  Future<List<Track>> searchLibrary(String query, {int limit = 50}) =>
      repository.db.trackDao.search(query, limit: limit);

  @override
  Future<List<Track>> recentTracks({int limit = 50}) =>
      repository.db.trackDao.recentlyAdded(limit: limit);

  /// Adds a track to the end of the open set.
  ///
  /// Written to the database first, then handed to the engine, which appends
  /// without disturbing whatever is already loaded and prerolled.
  @override
  Future<void> addToSet(String trackId) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;

    final itemId = await repository.db.playlistDao
        .appendTrack(playlistId: playlistId, trackId: trackId);

    final rows = await repository.db.playlistDao.itemsOf(playlistId);
    final row = rows.firstWhere((r) => r.item.id == itemId);
    final playlist = (await repository.db.playlistDao.byId(playlistId))!;

    controller.setQueue([
      ...controller.queueSnapshot,
      QueueItemUi(
        id: row.item.id,
        title: row.track?.title ?? 'Untitled',
        artist: row.track?.artist ?? '',
        danceType: row.danceType?.name,
        duration: row.track?.durationMs,
        position: row.item.position,
      ),
    ]);

    try {
      final entry = await repository.resolveRow(row, playlist: playlist);
      _engineItemIds = [..._engineItemIds, entry.itemId];
      await engine.appendToQueue(entry);
    } on UnavailableOffline {
      // It is in the set and on screen; the engine will simply never reach it.
      // Reopening the set is what turns that into a labelled row, and that is
      // not something to do underneath a running transition.
    }

    _publish();
  }

  /// Imports folders of music into the library.
  ///
  /// Only meaningful where `dart:io` paths are: on Android a folder picker
  /// hands back a SAF tree URI rather than a path, which is a different import
  /// route and is not built yet.
  @override
  /// Walks the open set, downloads what policy permits, pre-renders every
  /// announcement and reports what will and will not play without a
  /// connection.
  @override
  Future<PreflightReport> prepareForOffline({
    void Function(PreflightProgress)? onProgress,
  }) async {
    final playlistId = _playlistId;
    final downloader = this.downloader;
    if (playlistId == null || downloader == null) {
      throw StateError('No set is open to prepare');
    }

    final report = await EventPreflight(
      db: repository.db,
      repository: repository,
      downloader: downloader,
      announcements: engine.announcements,
    ).prepare(playlistId, onProgress: onProgress);

    // The set on screen was resolved before any of this ran, so a row that has
    // just been downloaded is still drawn as unplayable until it is reloaded.
    await openPlaylist(playlistId);

    return report;
  }

  @override
  Future<ScanReport> scanFolders(
    Iterable<Directory> folders, {
    void Function(int filesSeen, String path)? onProgress,
  }) =>
      LibraryScanner(db: repository.db).scan(folders, onProgress: onProgress);

  Future<void> dispose() async {
    _ticker?.cancel();
    controller.detach(this);
    await _events.cancel();
  }

  // -------------------------------------------------------------------------

  void _onEngineEvent(EngineEvent event) {
    _publish();

    final playing = event.phase == EnginePhase.playing ||
        event.phase == EnginePhase.crossfading ||
        event.phase == EnginePhase.announcing ||
        event.phase == EnginePhase.fadingOut;

    if (playing) {
      _ticker ??= Timer.periodic(uiTick, (_) => _publish());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Pushes the engine's current state into the view model.
  ///
  /// One direction only: the engine is the authority while a session is
  /// attached, so nothing here reads back what the controller last drew.
  void _publish() {
    final entry = engine.currentEntry;
    final active = activeSlot;

    final next = engine.standbyEntry;

    controller.applyEngineState(
      activeSlot: active,
      phase: engine.phase,
      currentIndex: _queueIndexOf(entry?.itemId),
      crossfader: _crossfaderPosition(),
      active: DeckUiState(
        title: entry?.title ?? '',
        artist: entry?.artist ?? '',
        position: engine.activePosition,
        duration: engine.activeDuration,
        isPlaying: engine.phase != EnginePhase.idle &&
            engine.phase != EnginePhase.paused,
        gain: engine.activeFade,
      ),
      standby: DeckUiState(
        title: next?.title ?? '',
        artist: next?.artist ?? '',
        duration: next?.media.cueOut,
        // Loaded and prerolled, but silent until the transition starts.
        isPlaying: engine.phase == EnginePhase.crossfading,
        gain: engine.standbyFade,
      ),
    );
  }

  /// Where the fader would have to be to produce the gains the engine is
  /// writing, so an automatic transition moves the thumb and leaves it at the
  /// end it arrived at.
  ///
  /// Null while the operator has hold of it. The round trip through the
  /// equal-power curve is not the identity — a fader at 0.25 produces gains
  /// that read back as 0.29 — so feeding this into a slider under someone's
  /// thumb would fight them.
  double? _crossfaderPosition() {
    if (engine.isManualFade) return null;

    final a = engine.activeIsA ? engine.activeFade : engine.standbyFade;
    final b = engine.activeIsA ? engine.standbyFade : engine.activeFade;

    final sum = a + b;
    if (sum <= 0) return null;
    return b / sum;
  }

  /// The engine counts only the rows it accepted; the operator sees all of
  /// them. Translate before anything highlights a row.
  int _queueIndexOf(String? itemId) {
    if (itemId == null) return -1;
    return controller.queueSnapshot.indexWhere((item) => item.id == itemId);
  }

  static UnavailableReason _reasonFor(UnavailableItem item) =>
      switch (item.kind) {
        UnavailableKind.fileMissing => UnavailableReason.fileMissing,
        UnavailableKind.unreachable => UnavailableReason.offline,
        UnavailableKind.unsupportedRow => UnavailableReason.unsupportedRowType,
      };

  /// Exposed for the queue list, which needs to know whether a row is one the
  /// engine will actually reach.
  bool willPlay(String itemId) => _engineItemIds.contains(itemId);
}

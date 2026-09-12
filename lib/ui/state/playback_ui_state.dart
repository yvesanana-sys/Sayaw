import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/crossfade_engine.dart' show EnginePhase;
import '../../data/fractional_order.dart';
import '../../data/media_resolver.dart' show NetworkMode;
import '../../data/set_ordering.dart' show SnowballProgress;
import 'library_access.dart';
import 'playback_session.dart';

/// Which of the two music decks.
enum DeckSlot {
  a,
  b;

  String get label => this == DeckSlot.a ? 'A' : 'B';
  DeckSlot get other => this == DeckSlot.a ? DeckSlot.b : DeckSlot.a;
}

@immutable
class DeckUiState {
  const DeckUiState({
    this.title = '',
    this.artist = '',
    this.position = Duration.zero,
    this.duration,
    this.isPlaying = false,
    this.gain = 0.0,
  });

  final String title;
  final String artist;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;

  /// Composed output level in `[0, 1]` — what the meter draws.
  final double gain;

  bool get isLoaded => title.isNotEmpty;

  /// Fraction of the track elapsed, for the progress arc. Zero-length and
  /// unknown-length media both read as 0 rather than NaN.
  double get progress {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return 0.0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  DeckUiState copyWith({
    String? title,
    String? artist,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    double? gain,
  }) {
    return DeckUiState(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      gain: gain ?? this.gain,
    );
  }
}

/// Why a queue row cannot be played on this device.
///
/// Surfaced in the list rather than skipped silently: a track vanishing
/// mid-set with no explanation is the failure mode this exists to prevent.
enum UnavailableReason {
  /// A DRM-protected stream on a platform whose deck cannot decrypt it.
  drmUnsupportedOnPlatform,

  /// Local file whose path no longer resolves — unmounted drive, revoked
  /// folder grant.
  fileMissing,

  /// Streaming-only source with no connectivity.
  offline,

  /// A silence gap, a standalone announcement or a marker. The operator put it
  /// in the set deliberately, so it is shown greyed rather than hidden.
  unsupportedRowType;

  String get message => switch (this) {
        UnavailableReason.drmUnsupportedOnPlatform =>
          'Not playable on Windows — this track is DRM-protected.',
        UnavailableReason.fileMissing => 'File not found.',
        UnavailableReason.offline => 'Needs an internet connection.',
        UnavailableReason.unsupportedRowType =>
          'This kind of row cannot be played yet.',
      };
}

@immutable
class QueueItemUi {
  const QueueItemUi({
    required this.id,
    required this.title,
    required this.artist,
    required this.position,
    this.danceType,
    this.duration,
    this.bpm,
    this.unavailable,
    this.soundCueId,
    this.soundCueLabel,
    this.mergeIntoNext = false,
  });

  final String id;
  final String title;
  final String artist;

  /// Fractional sort key. See `lib/data/fractional_order.dart`.
  final double position;

  final String? danceType;
  final Duration? duration;

  /// The tempo this row is ordered on — its own tag, or its dance type's
  /// range. Null when nothing is known. See `lib/data/set_ordering.dart`.
  final double? bpm;

  final UnavailableReason? unavailable;

  /// The soundboard cue tagged to this row, which announces it. Null when the
  /// row says whatever the dance type says, or nothing at all.
  final String? soundCueId;

  /// What that cue is called on the bar — 'Whistle', 'Next: Waltz'. Carried
  /// beside the id so a row can name its clip without the list holding a
  /// second copy of the soundboard.
  final String? soundCueLabel;

  /// This row runs into the one after it as one dance — the mixer's join.
  final bool mergeIntoNext;

  bool get isPlayable => unavailable == null;

  bool get hasSoundCue => soundCueId != null;

  QueueItemUi copyWith({double? position}) => QueueItemUi(
        id: id,
        title: title,
        artist: artist,
        position: position ?? this.position,
        danceType: danceType,
        duration: duration,
        bpm: bpm,
        unavailable: unavailable,
        soundCueId: soundCueId,
        soundCueLabel: soundCueLabel,
        mergeIntoNext: mergeIntoNext,
      );

  /// Its own method rather than a `copyWith` argument: [unavailable] is
  /// nullable, so a named parameter could not tell "leave it alone" from
  /// "clear it", and clearing it is exactly what a network coming back does.
  QueueItemUi withUnavailable(UnavailableReason? reason) => QueueItemUi(
        id: id,
        title: title,
        artist: artist,
        position: position,
        danceType: danceType,
        duration: duration,
        bpm: bpm,
        unavailable: reason,
        soundCueId: soundCueId,
        soundCueLabel: soundCueLabel,
        mergeIntoNext: mergeIntoNext,
      );

  /// The same row tagged to a different cue, or to none.
  ///
  /// Its own method for the reason [withUnavailable] is: null means "nothing
  /// is tagged here any more", which a `copyWith` argument could not tell from
  /// "leave it alone" — and clearing a tag is half of what the picker does.
  QueueItemUi withSoundCue({String? cueId, String? label}) => QueueItemUi(
        id: id,
        title: title,
        artist: artist,
        position: position,
        danceType: danceType,
        duration: duration,
        bpm: bpm,
        unavailable: unavailable,
        soundCueId: cueId,
        soundCueLabel: label,
        mergeIntoNext: mergeIntoNext,
      );

  /// The same row, joined to the next or separated from it.
  QueueItemUi withMergeIntoNext(bool merge) => QueueItemUi(
        id: id,
        title: title,
        artist: artist,
        position: position,
        danceType: danceType,
        duration: duration,
        bpm: bpm,
        unavailable: unavailable,
        soundCueId: soundCueId,
        soundCueLabel: soundCueLabel,
        mergeIntoNext: merge,
      );
}

/// What will be heard at the next transition, and where in it.
///
/// Derived from the row that is cued up rather than from the one playing: an
/// announcement introduces the track it is attached to, which is the one being
/// faded *to*. That is the single most confusing thing about tagging a row,
/// and this is what makes it visible before the transition rather than after.
@immutable
class NextAnnouncementUi {
  const NextAnnouncementUi({
    required this.label,
    required this.isRecording,
    required this.timing,
  });

  /// The cue's name when the operator tagged one, otherwise the words that
  /// will be spoken.
  final String label;

  /// Their own recording rather than a synthesised voice.
  final bool isRecording;

  final AnnouncementTiming timing;
}

/// Where in the transition the announcement lands.
enum AnnouncementTiming {
  /// Over the crossfade, with the music ducked underneath it.
  overTheCrossfade,

  /// The music out, the voice alone, then the music in.
  beforeTheMusic,

  /// In the silence a rotation holds for the floor to change partners.
  inTheRotationGap;

  String get description => switch (this) {
        AnnouncementTiming.overTheCrossfade => 'over the crossfade',
        AnnouncementTiming.beforeTheMusic => 'before the music',
        AnnouncementTiming.inTheRotationGap => 'in the rotation gap',
      };
}

@immutable
class PlaybackUiState {
  const PlaybackUiState({
    this.deckA = const DeckUiState(),
    this.deckB = const DeckUiState(),
    this.crossfader = 0.0,
    this.queue = const [],
    this.currentIndex = -1,
    this.phase = EnginePhase.idle,
    this.performanceMode = false,
    this.networkMode = NetworkMode.online,
    this.offlineServices = const [],
    this.snowball,
    this.announcement,
    this.nextMerges = false,
    this.songLength,
    this.setName = '',
  });

  final DeckUiState deckA;
  final DeckUiState deckB;

  /// Crossfader position: `0.0` is deck A alone, `1.0` is deck B alone.
  final double crossfader;

  final List<QueueItemUi> queue;
  final int currentIndex;
  final EnginePhase phase;
  final bool performanceMode;

  /// What the app can actually reach. See `lib/data/connectivity.dart` — this
  /// is the probed answer, not what the OS claims about the radio.
  final NetworkMode networkMode;

  /// Configured services that are not answering, by the name the operator gave
  /// them. Empty when the radio itself is down: there is nothing to single out.
  final List<String> offlineServices;

  /// Where a Snowball has climbed to. Null when the open set is not one.
  final SnowballProgress? snowball;

  /// What the next transition will say. Null when it will say nothing.
  final NextAnnouncementUi? announcement;

  /// The next transition runs the song into the one cued as one dance: a
  /// blend, no voice, no gap. Drawn where the announcement would be, so a
  /// silent join reads as intended rather than as a tag that failed.
  final bool nextMerges;

  /// How much of each song the set plays before it hands over. Null plays
  /// each to its end.
  final Duration? songLength;

  /// What the open set is called. Empty with none open.
  final String setName;

  DeckUiState deck(DeckSlot slot) =>
      slot == DeckSlot.a ? deckA : deckB;

  /// Drives the wakelock. A tablet sleeping mid-event is a show-stopper, so
  /// this is deliberately generous: anything that is not fully stopped counts.
  bool get anyDeckPlaying => deckA.isPlaying || deckB.isPlaying;

  PlaybackUiState copyWith({
    DeckUiState? deckA,
    DeckUiState? deckB,
    double? crossfader,
    List<QueueItemUi>? queue,
    int? currentIndex,
    EnginePhase? phase,
    bool? performanceMode,
    NetworkMode? networkMode,
    List<String>? offlineServices,
    bool? nextMerges,
    Duration? songLength,
    String? setName,
  }) {
    return PlaybackUiState(
      deckA: deckA ?? this.deckA,
      deckB: deckB ?? this.deckB,
      crossfader: crossfader ?? this.crossfader,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      performanceMode: performanceMode ?? this.performanceMode,
      networkMode: networkMode ?? this.networkMode,
      offlineServices: offlineServices ?? this.offlineServices,
      snowball: snowball,
      announcement: announcement,
      nextMerges: nextMerges ?? this.nextMerges,
      songLength: songLength ?? this.songLength,
      setName: setName ?? this.setName,
    );
  }

  /// Its own method for the same reason [QueueItemUi.withUnavailable] is:
  /// null here means "this set is not a Snowball", and a `copyWith` argument
  /// could not tell that from "leave it alone" — which would leave a stage
  /// indicator on screen for a set that no longer has one.
  PlaybackUiState withSnowball(SnowballProgress? snowball) => PlaybackUiState(
        deckA: deckA,
        deckB: deckB,
        crossfader: crossfader,
        queue: queue,
        currentIndex: currentIndex,
        phase: phase,
        performanceMode: performanceMode,
        networkMode: networkMode,
        offlineServices: offlineServices,
        snowball: snowball,
        announcement: announcement,
        nextMerges: nextMerges,
        songLength: songLength,
        setName: setName,
      );

  /// Its own method for the reason [withSnowball] is: null means "each song
  /// to its end", which a `copyWith` argument could not tell from "leave it".
  PlaybackUiState withSongLength(Duration? songLength) => PlaybackUiState(
        deckA: deckA,
        deckB: deckB,
        crossfader: crossfader,
        queue: queue,
        currentIndex: currentIndex,
        phase: phase,
        performanceMode: performanceMode,
        networkMode: networkMode,
        offlineServices: offlineServices,
        snowball: snowball,
        announcement: announcement,
        nextMerges: nextMerges,
        songLength: songLength,
        setName: setName,
      );

  /// Its own method for the same reason [withSnowball] is: null means "the
  /// next transition says nothing", which a `copyWith` argument could not tell
  /// from "leave it alone" — and going quiet is half of what tagging does.
  PlaybackUiState withAnnouncement(NextAnnouncementUi? announcement) =>
      PlaybackUiState(
        deckA: deckA,
        deckB: deckB,
        crossfader: crossfader,
        queue: queue,
        currentIndex: currentIndex,
        phase: phase,
        performanceMode: performanceMode,
        networkMode: networkMode,
        offlineServices: offlineServices,
        snowball: snowball,
        announcement: announcement,
        nextMerges: nextMerges,
        songLength: songLength,
        setName: setName,
      );
}

/// UI-facing playback state, and the one surface the widgets give commands to.
///
/// Nothing here does audio work. With no [PlaybackSession] attached it simply
/// moves its own state, which is what lets every widget test run without
/// libmpv or ExoPlayer behind it. Attach a session and the same commands go to
/// the engine instead, and the state comes back from the engine's events —
/// authority moves, the call sites do not.
class PlaybackController extends Notifier<PlaybackUiState> {
  @override
  PlaybackUiState build() => const PlaybackUiState();

  PlaybackSession? _session;

  /// Called by [PlaybackSession] as it is constructed.
  void attach(PlaybackSession session) {
    _session = session;
    ref.read(playbackSessionProvider.notifier).set(session);
  }

  void detach(PlaybackSession session) {
    if (!identical(_session, session)) return;
    _session = null;
    ref.read(playbackSessionProvider.notifier).set(null);
  }

  /// The queue as last drawn. The session needs it to translate between the
  /// engine's index space, which counts only playable rows, and the operator's,
  /// which counts every row they put in the set.
  List<QueueItemUi> get queueSnapshot => state.queue;

  /// The engine's view of the world, pushed in after every event and on the UI
  /// tick. One direction only: this never reads back what was last drawn.
  void applyEngineState({
    required DeckSlot activeSlot,
    required EnginePhase phase,
    required int currentIndex,
    required DeckUiState active,
    required DeckUiState standby,
    double? crossfader,
    SnowballProgress? snowball,
    NextAnnouncementUi? announcement,
    bool nextMerges = false,
    Duration? songLength,
    String? setName,
  }) {
    state = state.copyWith(
      deckA: activeSlot == DeckSlot.a ? active : standby,
      deckB: activeSlot == DeckSlot.a ? standby : active,
      phase: phase,
      currentIndex: currentIndex,
      // Null means the operator has the fader, and the engine is following
      // them rather than the other way round.
      crossfader: crossfader,
      nextMerges: nextMerges,
      setName: setName,
    )
        .withSnowball(snowball)
        .withAnnouncement(announcement)
        .withSongLength(songLength);
  }

  // -- transport -------------------------------------------------------------

  void togglePlay(DeckSlot slot) {
    if (_session case final session?) {
      session.togglePlay(slot);
      return;
    }
    final deck = state.deck(slot);
    if (!deck.isLoaded) return;
    _setDeck(slot, deck.copyWith(isPlaying: !deck.isPlaying));
    _syncPhase();
  }

  void pauseAll() {
    if (_session case final session?) {
      session.pause();
      return;
    }
    state = state.copyWith(
      deckA: state.deckA.copyWith(isPlaying: false),
      deckB: state.deckB.copyWith(isPlaying: false),
      phase: EnginePhase.paused,
    );
  }

  /// Stop, as distinct from pause: silence now, and the current track back at
  /// its start for the next play. The set is not unloaded.
  void stop() {
    if (_session case final session?) {
      session.stopToCue();
      return;
    }
    state = state.copyWith(
      deckA: state.deckA.copyWith(isPlaying: false, position: Duration.zero),
      deckB: state.deckB.copyWith(isPlaying: false, position: Duration.zero),
      phase: EnginePhase.paused,
    );
  }

  /// Plays [item] now, through the crossfade. The engine decides what that
  /// means for a set that is stopped or paused; here it is the intent.
  void playFrom(QueueItemUi item) {
    if (!item.isPlayable) return;
    if (_session case final session?) {
      session.jumpTo(item.id);
      return;
    }
    final index = state.queue.indexWhere((q) => q.id == item.id);
    if (index < 0) return;
    _setDeck(
      DeckSlot.a,
      DeckUiState(
        title: item.title,
        artist: item.artist,
        duration: item.duration,
        isPlaying: true,
        gain: 1.0,
      ),
    );
    state = state.copyWith(currentIndex: index, phase: EnginePhase.playing);
  }

  /// Return the deck to its cue point without changing what is loaded.
  void cue(DeckSlot slot) {
    // No engine equivalent yet: the standby deck is already sitting at its cue
    // point, and rewinding the audible one mid-dance is not something to do by
    // accident. Left inert rather than given a plausible-looking wrong meaning.
    if (_session != null) return;

    final deck = state.deck(slot);
    if (!deck.isLoaded) return;
    _setDeck(slot, deck.copyWith(position: Duration.zero, isPlaying: false));
    _syncPhase();
  }

  void loadToDeck(DeckSlot slot, QueueItemUi item) {
    if (!item.isPlayable) return;
    _setDeck(
      slot,
      DeckUiState(
        title: item.title,
        artist: item.artist,
        duration: item.duration,
        gain: slot == DeckSlot.a ? 1 - state.crossfader : state.crossfader,
      ),
    );
  }

  /// Operator-triggered transition. Slams the crossfader to the standby deck
  /// and starts it; the engine owns the actual ramp, this is the intent.
  void crossfadeNow() {
    if (_session case final session?) {
      session.skipNext();
      return;
    }
    final toB = state.crossfader < 0.5;
    state = state.copyWith(
      crossfader: toB ? 1.0 : 0.0,
      deckA: state.deckA.copyWith(isPlaying: !toB && state.deckA.isLoaded),
      deckB: state.deckB.copyWith(isPlaying: toB && state.deckB.isLoaded),
      phase: EnginePhase.crossfading,
    );
    _applyCrossfaderGains();
  }

  void setCrossfader(double value) {
    final position = value.clamp(0.0, 1.0);
    state = state.copyWith(crossfader: position);

    // With a session attached the decks are the engine's, and it writes the
    // gains — including starting the deck that is cued up, and completing the
    // handover when the fader reaches the far end.
    if (_session case final session?) {
      session.setCrossfader(position);
      return;
    }

    _applyCrossfaderGains();
  }

  void setPerformanceMode(bool enabled) =>
      state = state.copyWith(performanceMode: enabled);

  /// Pushed in by `ConnectivityService` through the runtime. Drives the banner
  /// and nothing else — what the resolver does about it is decided in the data
  /// layer, which is where the consequences are.
  void setNetworkMode(
    NetworkMode mode, {
    List<String> offlineServices = const [],
  }) =>
      state = state.copyWith(
        networkMode: mode,
        offlineServices: List.unmodifiable(offlineServices),
      );

  // -- queue -----------------------------------------------------------------

  void setQueue(List<QueueItemUi> items) =>
      state = state.copyWith(queue: List.unmodifiable(items));

  /// Moves one row and rewrites only that row's position.
  ///
  /// [newIndex] uses `ReorderableListView.onReorderItem`'s post-removal
  /// convention — the index the row lands on once lifted out. When the
  /// destination gap is too tight to subdivide, the whole playlist is
  /// renormalized and the move retried: the rare path, and still one
  /// transaction.
  void reorderQueue(int oldIndex, int newIndex) {
    final queue = state.queue;
    if (oldIndex < 0 || oldIndex >= queue.length) return;
    if (newIndex < 0 || newIndex >= queue.length) return;

    if (_session case final session?) {
      session.reorder(oldIndex, newIndex);
      return;
    }

    final positions = [for (final item in queue) item.position];
    var moved = reorderPosition(positions, oldIndex, newIndex);

    var items = [...queue];
    if (moved == null) {
      final fresh = renormalize(items.length);
      items = [
        for (var i = 0; i < items.length; i++)
          items[i].copyWith(position: fresh[i]),
      ];
      moved = reorderPosition(fresh, oldIndex, newIndex);
    }

    final row = items.removeAt(oldIndex);
    items.insert(newIndex, row.copyWith(position: moved));

    state = state.copyWith(queue: List.unmodifiable(items));
  }

  // -- internals -------------------------------------------------------------

  void _setDeck(DeckSlot slot, DeckUiState deck) {
    state = slot == DeckSlot.a
        ? state.copyWith(deckA: deck)
        : state.copyWith(deckB: deck);
  }

  /// The crossfader is one multiplicative stage among several — the same model
  /// the engine uses. Here it only sets what the meters draw.
  void _applyCrossfaderGains() {
    state = state.copyWith(
      deckA: state.deckA.copyWith(gain: 1.0 - state.crossfader),
      deckB: state.deckB.copyWith(gain: state.crossfader),
    );
  }

  void _syncPhase() {
    state = state.copyWith(
      phase: state.anyDeckPlaying ? EnginePhase.playing : EnginePhase.paused,
    );
  }
}

final playbackProvider =
    NotifierProvider<PlaybackController, PlaybackUiState>(
  PlaybackController.new,
);

/// The live session, or null where there is no audio behind the screen — every
/// widget test, and the moment before the runtime has finished starting.
///
/// Widgets that need the library or the database reach it through here rather
/// than holding a database of their own, which keeps them renderable without
/// one.
final playbackSessionProvider =
    NotifierProvider<PlaybackSessionHolder, PlaybackSession?>(
  PlaybackSessionHolder.new,
);

class PlaybackSessionHolder extends Notifier<PlaybackSession?> {
  @override
  PlaybackSession? build() => null;

  void set(PlaybackSession? session) => state = session;
}

/// The library, narrowed to what browsing it needs.
///
/// Separate from [playbackSessionProvider] so a widget test can stand a
/// library up without an engine, and so the pane cannot reach for playback
/// controls it has no business touching.
final libraryAccessProvider = Provider<LibraryAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// Preparing the open set to run without a connection.
final eventModeProvider = Provider<EventModeAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// How many songs the night runs to, and how much of each.
final setShapeProvider = Provider<SetShapeAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// Tagging a row in the open set with one of the operator's own clips.
final cueTagProvider = Provider<CueTagAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// Taking rows out of the open set, and putting one back.
final queueEditProvider = Provider<QueueEditAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// Joining rows of the open set into one dance.
final mergeProvider = Provider<MergeAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// The sets the operator keeps.
final setsProvider = Provider<SetsAccess?>(
  (ref) => ref.watch(playbackSessionProvider),
);

/// What the open set is called, for the queue's header.
final setNameProvider = Provider<String>(
  (ref) => ref.watch(playbackProvider.select((s) => s.setName)),
);

/// How much of each song plays, for the chips under the decks.
final songLengthProvider = Provider<Duration?>(
  (ref) => ref.watch(playbackProvider.select((s) => s.songLength)),
);

/// Whether the next transition is a merge. Narrow, like the announcement.
final nextMergesProvider = Provider<bool>(
  (ref) => ref.watch(playbackProvider.select((s) => s.nextMerges)),
);

/// Narrow selector so the wakelock listener does not rebuild on every position
/// tick — the engine updates position at 50 Hz.
final anyDeckPlayingProvider = Provider<bool>(
  (ref) => ref.watch(playbackProvider.select((s) => s.anyDeckPlaying)),
);

/// What the banner draws. Narrow for the same reason as above: it sits at the
/// top of every layout and must not rebuild sixty times a second.
final networkModeProvider = Provider<NetworkMode>(
  (ref) => ref.watch(playbackProvider.select((s) => s.networkMode)),
);

/// Where a Snowball has climbed to, or null when the set is not one.
final snowballProvider = Provider<SnowballProgress?>(
  (ref) => ref.watch(playbackProvider.select((s) => s.snowball)),
);

/// What the next transition will say. Narrow, like the two above: the strip
/// that draws it sits between the decks and must not rebuild on a position
/// tick.
final nextAnnouncementProvider = Provider<NextAnnouncementUi?>(
  (ref) => ref.watch(playbackProvider.select((s) => s.announcement)),
);

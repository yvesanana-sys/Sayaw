import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/crossfade_engine.dart' show EnginePhase;
import '../../data/fractional_order.dart';

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
  offline;

  String get message => switch (this) {
        UnavailableReason.drmUnsupportedOnPlatform =>
          'Not playable on Windows — this track is DRM-protected.',
        UnavailableReason.fileMissing => 'File not found.',
        UnavailableReason.offline => 'Needs an internet connection.',
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
    this.unavailable,
  });

  final String id;
  final String title;
  final String artist;

  /// Fractional sort key. See `lib/data/fractional_order.dart`.
  final double position;

  final String? danceType;
  final Duration? duration;
  final UnavailableReason? unavailable;

  bool get isPlayable => unavailable == null;

  QueueItemUi copyWith({double? position}) => QueueItemUi(
        id: id,
        title: title,
        artist: artist,
        position: position ?? this.position,
        danceType: danceType,
        duration: duration,
        unavailable: unavailable,
      );
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
  });

  final DeckUiState deckA;
  final DeckUiState deckB;

  /// Crossfader position: `0.0` is deck A alone, `1.0` is deck B alone.
  final double crossfader;

  final List<QueueItemUi> queue;
  final int currentIndex;
  final EnginePhase phase;
  final bool performanceMode;

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
  }) {
    return PlaybackUiState(
      deckA: deckA ?? this.deckA,
      deckB: deckB ?? this.deckB,
      crossfader: crossfader ?? this.crossfader,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }
}

/// UI-facing playback state.
///
/// Deliberately decoupled from [CrossfadeEngine]: the engine needs real decks,
/// and real decks need libmpv or ExoPlayer. Keeping the view model separate is
/// what lets every widget test in this phase run hermetically, and it is the
/// same seam the engine's event stream will feed once the shell is wired to
/// audio. Nothing here does audio work — it holds what the screen draws.
class PlaybackController extends Notifier<PlaybackUiState> {
  @override
  PlaybackUiState build() => const PlaybackUiState();

  // -- transport -------------------------------------------------------------

  void togglePlay(DeckSlot slot) {
    final deck = state.deck(slot);
    if (!deck.isLoaded) return;
    _setDeck(slot, deck.copyWith(isPlaying: !deck.isPlaying));
    _syncPhase();
  }

  void pauseAll() {
    state = state.copyWith(
      deckA: state.deckA.copyWith(isPlaying: false),
      deckB: state.deckB.copyWith(isPlaying: false),
      phase: EnginePhase.paused,
    );
  }

  /// Return the deck to its cue point without changing what is loaded.
  void cue(DeckSlot slot) {
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
    state = state.copyWith(crossfader: value.clamp(0.0, 1.0));
    _applyCrossfaderGains();
  }

  void setPerformanceMode(bool enabled) =>
      state = state.copyWith(performanceMode: enabled);

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

/// Narrow selector so the wakelock listener does not rebuild on every position
/// tick — the engine updates position at 50 Hz.
final anyDeckPlayingProvider = Provider<bool>(
  (ref) => ref.watch(playbackProvider.select((s) => s.anyDeckPlaying)),
);

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:sayaw/audio/deck.dart';

/// One `setVolume` call, stamped with the virtual time it happened at.
///
/// The engine writes gains at 50 Hz; asserting on the *shape* of that stream is
/// how every crossfade property in the suite gets checked without listening to
/// anything.
class VolumeEvent {
  const VolumeEvent(this.at, this.volume, this.seq);

  /// Virtual time since the deck was constructed.
  final Duration at;
  final double volume;

  /// See [nextSeq].
  final int seq;

  @override
  String toString() => '${at.inMilliseconds}ms -> ${volume.toStringAsFixed(4)}';
}

/// One lifecycle call, stamped with the virtual time it happened at.
class CallEvent {
  const CallEvent(this.at, this.name, this.seq);
  final Duration at;
  final String name;

  /// See [nextSeq].
  final int seq;

  @override
  String toString() => '${at.inMilliseconds}ms:$name';
}

/// A monotonic counter across every deck in a test.
///
/// Fake time does not advance across microtasks, so a volume written just
/// before a `play` and one written just after it carry the same timestamp.
/// Ordering matters for exactly one question — whether a deck was brought up
/// to level before it started or after — and a gap there is silence on a
/// dance floor, so it needs to be assertable.
int _seq = 0;
int nextSeq() => ++_seq;

/// A [Deck] with no audio stack behind it.
///
/// Position advances purely as a function of virtual time, so a 4-minute track
/// plays out in whatever wall time `FakeAsync.elapse` takes to walk its timer
/// queue — microseconds. Nothing here touches a platform channel, a file, or a
/// real clock.
class FakeDeck implements Deck {
  FakeDeck(this.id, {this.trackDuration = const Duration(seconds: 30)})
      : _epoch = clock.now();

  @override
  final String id;

  final DateTime _epoch;

  /// What [duration] reports once media is loaded. Mutable so a test can change
  /// track length between loads.
  Duration trackDuration;

  /// Every volume write, in order. The engine coalesces nothing here — that is
  /// the real decks' job — so this is the raw gain envelope.
  final List<VolumeEvent> volumeEvents = [];

  /// Lifecycle call log, stamped with virtual time.
  ///
  /// Timestamps matter: `loadQueue` stops both decks before it starts, so a
  /// bare `calls.contains('stop')` would be satisfied by initialisation and
  /// would not notice a retired deck being left running.
  final List<CallEvent> callEvents = [];

  /// Call names in order, without timestamps.
  List<String> get calls => [for (final c in callEvents) c.name];

  /// Whether [name] was called at or after [since].
  bool calledSince(String name, Duration since) =>
      callEvents.any((c) => c.name == name && c.at >= since);

  void _record(String name) =>
      callEvents.add(CallEvent(_now, name, nextSeq()));

  /// Set to make every [load] throw, exercising the failed-preload path.
  Object? loadError;

  /// URIs whose [load] should throw, leaving other media loadable. Decks
  /// alternate roles, so failing a *track* needs this rather than [loadError].
  final Set<String> failUris = {};

  PlayableMedia? _media;
  double _volume = 1.0;
  bool _playing = false;

  /// Position is `_base` plus however much virtual time has elapsed since the
  /// deck was last started. Pausing folds the elapsed span back into `_base`.
  Duration _base = Duration.zero;
  DateTime? _startedAt;

  final _status = StreamController<DeckStatus>.broadcast();
  final _positions = StreamController<Duration>.broadcast();
  Timer? _positionTicker;

  Duration get _now => clock.now().difference(_epoch);

  bool get isPlaying => _playing;

  /// The most recent volume written, or 1.0 if none.
  double get lastVolume => volumeEvents.isEmpty ? 1.0 : volumeEvents.last.volume;

  @override
  Future<void> load(PlayableMedia media) async {
    _record('load');
    final failure = loadError ??
        (failUris.contains(media.uri.toString())
            ? StateError('cannot load ${media.uri}')
            : null);
    if (failure != null) {
      _status.add(DeckStatus(DeckPlaybackState.error, error: failure));
      throw failure;
    }
    _media = media;
    _base = media.cueIn;
    _startedAt = null;
    _playing = false;
    _status.add(const DeckStatus(DeckPlaybackState.ready));
  }

  @override
  Future<void> preroll() async => _record('preroll');

  /// Simulates a backend that accepts [load] without throwing and then fails
  /// to actually play — reported only here, the way `Soundboard.fire` cannot
  /// see without watching the status stream.
  void emitAsyncError(Object error) =>
      _status.add(DeckStatus(DeckPlaybackState.error, error: error));

  @override
  Future<void> play() async {
    _record('play');
    if (_playing) return;
    _playing = true;
    _startedAt = clock.now();
    _status.add(const DeckStatus(DeckPlaybackState.playing));
    _positionTicker ??= Timer.periodic(
      const Duration(milliseconds: 20),
      (_) => _positions.add(position),
    );
  }

  @override
  Future<void> pause() async {
    _record('pause');
    _foldElapsed();
    _playing = false;
    _positionTicker?.cancel();
    _positionTicker = null;
    _status.add(const DeckStatus(DeckPlaybackState.paused));
  }

  @override
  Future<void> stop() async {
    _record('stop');
    _foldElapsed();
    _playing = false;
    _base = Duration.zero;
    _media = null;
    _positionTicker?.cancel();
    _positionTicker = null;
    _status.add(const DeckStatus(DeckPlaybackState.idle));
  }

  @override
  Future<void> seek(Duration position) async {
    _record('seek');
    _base = position;
    _startedAt = _playing ? clock.now() : null;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    volumeEvents.add(VolumeEvent(_now, _volume, nextSeq()));
  }

  void _foldElapsed() {
    final started = _startedAt;
    if (started != null) _base += clock.now().difference(started);
    _startedAt = null;
  }

  @override
  Duration get position {
    final started = _startedAt;
    if (!_playing || started == null) return _base;
    return _base + clock.now().difference(started);
  }

  @override
  Duration? get duration => _media == null ? null : trackDuration;

  @override
  double get volume => _volume;

  @override
  PlayableMedia? get media => _media;

  @override
  Stream<DeckStatus> get statusStream => _status.stream;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Future<void> dispose() async {
    _positionTicker?.cancel();
    await _status.close();
    await _positions.close();
  }
}

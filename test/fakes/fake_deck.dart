import 'dart:async';

import 'package:clock/clock.dart';
import 'package:sayaw/audio/deck.dart';

/// One `setVolume` call, stamped with the virtual time it happened at.
///
/// The engine writes gains at 50 Hz; asserting on the *shape* of that stream is
/// how every crossfade property in the suite gets checked without listening to
/// anything.
class VolumeEvent {
  const VolumeEvent(this.at, this.volume);

  /// Virtual time since the deck was constructed.
  final Duration at;
  final double volume;

  @override
  String toString() => '${at.inMilliseconds}ms -> ${volume.toStringAsFixed(4)}';
}

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

  /// Call log, for asserting on lifecycle rather than gain.
  final List<String> calls = [];

  /// Set to make [load] throw, exercising the failed-preload path.
  Object? loadError;

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
    calls.add('load');
    if (loadError != null) {
      final e = loadError!;
      _status.add(DeckStatus(DeckPlaybackState.error, error: e));
      throw e;
    }
    _media = media;
    _base = media.cueIn;
    _startedAt = null;
    _playing = false;
    _status.add(const DeckStatus(DeckPlaybackState.ready));
  }

  @override
  Future<void> preroll() async => calls.add('preroll');

  @override
  Future<void> play() async {
    calls.add('play');
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
    calls.add('pause');
    _foldElapsed();
    _playing = false;
    _positionTicker?.cancel();
    _positionTicker = null;
    _status.add(const DeckStatus(DeckPlaybackState.paused));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
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
    calls.add('seek');
    _base = position;
    _startedAt = _playing ? clock.now() : null;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    volumeEvents.add(VolumeEvent(_now, _volume));
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

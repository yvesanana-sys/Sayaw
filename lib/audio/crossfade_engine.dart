import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';

import 'announcement_engine.dart';
import 'deck.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';

enum AnnounceMode {
  /// No announcement.
  off,

  /// Music fades to silence, the voice plays clean, then the next track fades
  /// in. Maximum intelligibility — correct for competition rounds.
  beforeMusic,

  /// The crossfade runs normally and the music dips underneath the voice.
  /// Keeps the floor moving — correct for social nights.
  duckOver,
}

/// Per-item transition settings, already merged from playlist defaults and
/// item-level overrides by the repository layer.
class TransitionSpec {
  const TransitionSpec({
    this.crossfade = const Duration(seconds: 4),
    this.fadeInCurve = FadeCurve.equalPower,
    this.fadeOutCurve = FadeCurve.equalPower,
    this.announceMode = AnnounceMode.beforeMusic,
    this.duckLevel = 0.20,
    this.duckFade = const Duration(milliseconds: 600),
    this.duckHold = const Duration(milliseconds: 250),
    this.duckRestoreFade = const Duration(milliseconds: 900),
    this.pauseAfter = false,
  });

  final Duration crossfade;
  final FadeCurve fadeInCurve;
  final FadeCurve fadeOutCurve;
  final AnnounceMode announceMode;

  /// Music level while the voice plays, as a fraction of current level.
  final double duckLevel;
  final Duration duckFade;
  final Duration duckHold;
  final Duration duckRestoreFade;

  /// Stop after this item and wait for the operator (applause, MC handover).
  final bool pauseAfter;

  bool get isGapless => crossfade <= Duration.zero;
}

/// One playable row of a playlist, resolved and ready for a deck.
class QueueEntry {
  const QueueEntry({
    required this.itemId,
    required this.media,
    required this.spec,
    this.danceTypeName,
    this.announcementText,
    this.announcementClipPath,
    this.targetDuration,
    this.title = '',
    this.artist = '',
  });

  final String itemId;
  final PlayableMedia media;
  final TransitionSpec spec;

  final String? danceTypeName;
  final String? announcementText;
  final String? announcementClipPath;

  /// Hard cap on play time, e.g. 1:45 for a competition round.
  final Duration? targetDuration;

  final String title;
  final String artist;

  /// Static per-track trim from ReplayGain plus any manual offset.
  double get trimGain => dbToAmplitude(media.gainDb).clamp(0.0, 1.0);
}

enum EnginePhase { idle, playing, fadingOut, announcing, crossfading, paused }

class EngineEvent {
  const EngineEvent(this.phase, {this.currentIndex, this.entry});
  final EnginePhase phase;
  final int? currentIndex;
  final QueueEntry? entry;
}

/// The dual-deck scheduler.
///
/// Two music decks alternate roles: one is *active* (audible), the other is
/// *standby* (loaded, prerolled, silent). Every 20 ms the engine reads the
/// active deck's position, decides whether a transition is due, computes the
/// two crossfade gains, multiplies them by the duck bus and per-track trim, and
/// writes the result to both decks.
///
/// All of that is plain Dart against the [Deck] interface, so the entire thing
/// runs under test with a fake clock and a [Deck] stub — no audio hardware, no
/// platform channels, no real time.
class CrossfadeEngine {
  CrossfadeEngine({
    required Deck deckA,
    required Deck deckB,
    required this.bus,
    required this.announcements,
    this.tick = const Duration(milliseconds: 20),
  })  : _a = deckA,
        _b = deckB {
    _busSub = bus.changes.listen((_) => _applyGains());
  }

  final Deck _a;
  final Deck _b;
  final MusicGainBus bus;
  final AnnouncementEngine announcements;
  final Duration tick;

  StreamSubscription<double>? _busSub;
  Timer? _ticker;

  final _events = StreamController<EngineEvent>.broadcast();
  Stream<EngineEvent> get events => _events.stream;

  List<QueueEntry> _queue = const [];
  int _index = -1;

  bool _activeIsA = true;
  Deck get _active => _activeIsA ? _a : _b;
  Deck get _standby => _activeIsA ? _b : _a;

  QueueEntry? _activeEntry;
  QueueEntry? _standbyEntry;

  EnginePhase _phase = EnginePhase.idle;
  EnginePhase get phase => _phase;

  // Fade state, recomputed each tick.
  double _activeFade = 1.0;
  double _standbyFade = 0.0;

  DateTime? _fadeStartedAt;
  Duration _fadeDuration = Duration.zero;
  bool _transitionInFlight = false;

  QueueEntry? get currentEntry => _activeEntry;
  int get currentIndex => _index;

  // -------------------------------------------------------------------------
  // Queue control
  // -------------------------------------------------------------------------

  Future<void> loadQueue(List<QueueEntry> entries, {int startIndex = 0}) async {
    await stop();
    _queue = List.unmodifiable(entries);
    _index = startIndex - 1;
    if (_queue.isNotEmpty) await _advanceToNext(immediate: true);
  }

  Future<void> play() async {
    if (_activeEntry == null) return;
    await _active.play();
    _setPhase(EnginePhase.playing);
    _startTicker();
  }

  Future<void> pause() async {
    _ticker?.cancel();
    await _active.pause();
    await _standby.pause();
    _setPhase(EnginePhase.paused);
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    _transitionInFlight = false;
    await _a.stop();
    await _b.stop();
    _activeEntry = null;
    _standbyEntry = null;
    _setPhase(EnginePhase.idle);
  }

  /// Operator-triggered skip. Honours the configured crossfade rather than
  /// cutting, because a hard cut on a full dance floor is jarring.
  Future<void> skipNext({bool immediate = false}) async {
    if (_transitionInFlight) return;
    if (immediate) {
      await _advanceToNext(immediate: true);
      await play();
    } else {
      await _beginTransition();
    }
  }

  // -------------------------------------------------------------------------
  // Tick loop
  // -------------------------------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(tick, (_) => _onTick());
  }

  void _onTick() {
    final entry = _activeEntry;
    if (entry == null) return;

    if (_phase == EnginePhase.crossfading || _phase == EnginePhase.fadingOut) {
      _advanceFade();
      return;
    }

    if (_phase != EnginePhase.playing || _transitionInFlight) return;

    final remaining = _remainingOnActive(entry);
    if (remaining == null) return;

    // Gapless: no overlap, so hand off exactly at the boundary.
    if (entry.spec.isGapless) {
      if (remaining <= tick) unawaited(_beginTransition());
      return;
    }

    if (remaining <= entry.spec.crossfade) unawaited(_beginTransition());
  }

  /// Time left before this item must hand over. Honours `cueOut` and a
  /// competition-style `targetDuration`, whichever comes first.
  Duration? _remainingOnActive(QueueEntry entry) {
    final total = _active.duration;
    if (total == null) return null;

    final cueIn = entry.media.cueIn;
    final hardEnd = entry.media.cueOut ?? total;
    final targeted =
        entry.targetDuration == null ? hardEnd : cueIn + entry.targetDuration!;

    final end = hardEnd < targeted ? hardEnd : targeted;
    final left = end - _active.position;
    return left.isNegative ? Duration.zero : left;
  }

  // -------------------------------------------------------------------------
  // Transitions
  // -------------------------------------------------------------------------

  Future<void> _beginTransition() async {
    if (_transitionInFlight) return;
    _transitionInFlight = true;

    final outgoing = _activeEntry;
    final incoming = _standbyEntry;

    if (incoming == null) {
      // End of queue: fade out and stop rather than cutting to silence.
      await _fadeActiveToSilence(
        outgoing?.spec.crossfade ?? const Duration(seconds: 2),
        outgoing?.spec.fadeOutCurve ?? FadeCurve.equalPower,
      );
      await stop();
      _transitionInFlight = false;
      return;
    }

    final spec = incoming.spec;

    switch (spec.announceMode) {
      case AnnounceMode.off:
        await _runCrossfade(spec);

      case AnnounceMode.duckOver:
        // The duck and the crossfade run concurrently. Because the duck is a
        // separate multiplicative stage, it attenuates both decks equally and
        // leaves the crossfade ratio untouched.
        final clip = await announcements.clipFor(incoming);
        unawaited(_runCrossfade(spec));
        if (clip != null) {
          await announcements.announceWithDuck(clip, spec: spec, bus: bus);
        }

      case AnnounceMode.beforeMusic:
        // Sequential: silence, then voice, then music.
        _setPhase(EnginePhase.fadingOut);
        await _fadeActiveToSilence(spec.crossfade, spec.fadeOutCurve);
        await _active.stop();

        final clip = await announcements.clipFor(incoming);
        if (clip != null) {
          _setPhase(EnginePhase.announcing);
          await announcements.announceSolo(clip);
        }
        await _startIncoming(spec);
    }

    _transitionInFlight = false;

    if (spec.pauseAfter) {
      await pause();
    }
  }

  /// Overlapping crossfade: start standby, ramp both decks in opposite
  /// directions over [spec.crossfade], then retire the outgoing deck.
  Future<void> _runCrossfade(TransitionSpec spec) async {
    await _standby.play();

    _fadeStartedAt = clock.now();
    _fadeDuration = spec.crossfade;
    _currentSpec = spec;
    _setPhase(EnginePhase.crossfading);

    await _awaitFadeComplete();
    await _completeSwap();
  }

  Future<void> _startIncoming(TransitionSpec spec) async {
    await _swapRoles();
    await _active.play();

    _activeFade = 0.0;
    _standbyFade = 0.0;
    _fadeStartedAt = clock.now();
    _fadeDuration = spec.crossfade;
    _currentSpec = spec;
    _setPhase(EnginePhase.crossfading);
    _applyGains();

    await _awaitFadeComplete();
    _activeFade = 1.0;
    _applyGains();
    _setPhase(EnginePhase.playing);

    await _preloadNext();
  }

  Future<void> _fadeActiveToSilence(Duration duration, FadeCurve curve) async {
    _fadeStartedAt = clock.now();
    _fadeDuration = duration;
    _currentSpec = TransitionSpec(crossfade: duration, fadeOutCurve: curve);
    _setPhase(EnginePhase.fadingOut);
    await _awaitFadeComplete();
    _activeFade = 0.0;
    _applyGains();
  }

  TransitionSpec _currentSpec = const TransitionSpec();

  void _advanceFade() {
    final started = _fadeStartedAt;
    if (started == null || _fadeDuration <= Duration.zero) return;

    final elapsed = clock.now().difference(started).inMilliseconds;
    final t = (elapsed / _fadeDuration.inMilliseconds).clamp(0.0, 1.0);

    if (_phase == EnginePhase.fadingOut) {
      _activeFade = fadeOutGain(_currentSpec.fadeOutCurve, t);
      _standbyFade = 0.0;
    } else {
      final g = crossfadeGains(
        t,
        outCurve: _currentSpec.fadeOutCurve,
        inCurve: _currentSpec.fadeInCurve,
      );
      // During a crossfade the *standby* deck is the incoming one; after
      // _startIncoming the roles are already swapped and only _activeFade moves.
      if (_standbyEntry != null && _phase == EnginePhase.crossfading &&
          _standby.media != null) {
        _activeFade = g.outgoing;
        _standbyFade = g.incoming;
      } else {
        _activeFade = fadeInGain(_currentSpec.fadeInCurve, t);
        _standbyFade = 0.0;
      }
    }

    _applyGains();

    if (t >= 1.0) _fadeStartedAt = null;
  }

  Future<void> _awaitFadeComplete() async {
    final total = _fadeDuration.inMilliseconds;
    if (total <= 0) return;
    final deadline = clock.now().add(_fadeDuration + tick);
    while (clock.now().isBefore(deadline) && _fadeStartedAt != null) {
      await Future<void>.delayed(tick);
    }
  }

  /// Applies the composed gain to both decks.
  ///
  ///     volume = crossfadeGain x duckBus x perTrackTrim
  ///
  /// This single expression is the whole mixing model.
  void _applyGains() {
    final duck = bus.value;
    final aTrim = _activeEntry?.trimGain ?? 1.0;
    final sTrim = _standbyEntry?.trimGain ?? 1.0;

    unawaited(_active.setVolume(_clamp(_activeFade * duck * aTrim)));
    unawaited(_standby.setVolume(_clamp(_standbyFade * duck * sTrim)));
  }

  double _clamp(double v) => math.max(0.0, math.min(1.0, v));

  Future<void> _completeSwap() async {
    final retired = _active;
    await retired.stop();

    await _swapRoles();
    _activeFade = 1.0;
    _standbyFade = 0.0;
    _applyGains();

    _setPhase(EnginePhase.playing);
    await _preloadNext();
  }

  Future<void> _swapRoles() async {
    _activeIsA = !_activeIsA;
    _activeEntry = _standbyEntry;
    _standbyEntry = null;
    _index++;
    _emit();
  }

  // -------------------------------------------------------------------------
  // Preloading
  // -------------------------------------------------------------------------

  Future<void> _advanceToNext({bool immediate = false}) async {
    _index++;
    if (_index >= _queue.length) return;

    _activeEntry = _queue[_index];
    await _active.load(_activeEntry!.media);
    await _active.preroll();
    _activeFade = 1.0;
    _standbyFade = 0.0;
    _applyGains();
    _emit();

    await _preloadNext();
  }

  /// Loads and prerolls the next entry onto the standby deck, and asks the
  /// announcement engine to render its clip now — so the transition costs
  /// nothing but a gain ramp when it arrives.
  Future<void> _preloadNext() async {
    final nextIndex = _index + 1;
    if (nextIndex >= _queue.length) {
      _standbyEntry = null;
      return;
    }

    final next = _queue[nextIndex];
    _standbyEntry = next;

    try {
      await _standby.load(next.media);
      await _standby.preroll();
      await _standby.setVolume(0);
      // Pre-render the TTS now rather than at the transition. This is the
      // payoff for caching announcements as files instead of speaking live.
      unawaited(announcements.warm(next));
    } catch (e) {
      // A dead URL or missing file must not stall the set. Drop this entry and
      // try the one after it; the UI surfaces it separately.
      _standbyEntry = null;
      _events.add(EngineEvent(_phase, currentIndex: _index, entry: next));
    }
  }

  void _setPhase(EnginePhase p) {
    if (_phase == p) return;
    _phase = p;
    _emit();
  }

  void _emit() =>
      _events.add(EngineEvent(_phase, currentIndex: _index, entry: _activeEntry));

  Future<void> dispose() async {
    _ticker?.cancel();
    await _busSub?.cancel();
    await _events.close();
    await _a.dispose();
    await _b.dispose();
  }
}

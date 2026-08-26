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

  /// The same row with freshly resolved media, for a signed URL replaced
  /// before it expired. Nothing else about the row changes: the spec, the
  /// announcement and the titles were merged when the set was built and do
  /// not go stale just because a URL did.
  QueueEntry withMedia(PlayableMedia media) => QueueEntry(
        itemId: itemId,
        media: media,
        spec: spec,
        danceTypeName: danceTypeName,
        announcementText: announcementText,
        announcementClipPath: announcementClipPath,
        targetDuration: targetDuration,
        title: title,
        artist: artist,
      );
}

/// Re-resolves an entry whose signed URL is close to expiry, returning one
/// with fresh media.
///
/// Supplied from above, because resolving a row means knowing about playlists
/// and source accounts and the engine deliberately knows about neither.
typedef EntryRefresher = Future<QueueEntry> Function(QueueEntry entry);

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
    this.refresh,
    this.tick = const Duration(milliseconds: 20),
  })  : _a = deckA,
        _b = deckB {
    _busSub = bus.changes.listen((_) => _applyGains());
  }

  final Deck _a;
  final Deck _b;
  final MusicGainBus bus;
  final AnnouncementEngine announcements;

  /// How to re-resolve an entry whose URL is about to expire. Null leaves the
  /// engine playing exactly what it was handed, which is what a set of local
  /// files wants.
  final EntryRefresher? refresh;

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

  /// Queue index of [_standbyEntry], which is not always `_index + 1` because
  /// unplayable entries are skipped during preload.
  int _standbyIndex = -1;

  /// The row after standby, re-resolved ahead of time. There are only two
  /// decks, so this is resolved and not buffered.
  ///
  /// Only ever a hint: [_loadOnto] still checks expiry on whatever it is
  /// handed, so a look-ahead that has itself gone stale in the meantime costs
  /// nothing beyond the refresh it failed to save.
  QueueEntry? _lookahead;
  int _lookaheadIndex = -1;

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

  /// Which physical deck is audible. The two swap roles every transition, so
  /// a UI drawing two decks cannot assume the set started on A and stayed
  /// there.
  bool get activeIsA => _activeIsA;

  /// Where the audible deck has got to, for a progress readout. The engine
  /// reads this every tick anyway; exposing it saves the UI from holding a
  /// reference to the decks themselves.
  Duration get activePosition => _active.position;
  Duration? get activeDuration => _active.duration;

  /// What is cued up behind the audible deck, already loaded and prerolled.
  QueueEntry? get standbyEntry => _standbyEntry;

  /// The two crossfade gains as of the last tick, before the duck bus and the
  /// per-track trim are multiplied in. Meters drawn from these show what the
  /// engine is actually doing rather than what the operator asked for.
  double get activeFade => _activeFade;
  double get standbyFade => _standbyFade;

  // -------------------------------------------------------------------------
  // Queue control
  // -------------------------------------------------------------------------

  Future<void> loadQueue(List<QueueEntry> entries, {int startIndex = 0}) async {
    await stop();
    _queue = List.unmodifiable(entries);
    _index = startIndex - 1;
    if (_queue.isNotEmpty) await _advanceToNext(immediate: true);
  }

  /// Adds an item to the end of the running set.
  ///
  /// Deliberately not a reload: the standby deck is already loaded and
  /// prerolled, and tearing that down to add a track at the end would put a
  /// hole in a transition that might be seconds away. The one case that does
  /// need work is a set that had run out of anything to play next, where this
  /// is now the next thing.
  Future<void> appendToQueue(QueueEntry entry) async {
    _queue = List.unmodifiable([..._queue, entry]);

    if (_standbyEntry == null && _phase != EnginePhase.idle) {
      await _preloadNext();
    }
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
    // Release the latch: any in-flight transition sees the phase change and
    // abandons itself, so the next play() is free to retrigger it.
    _transitionInFlight = false;
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    _transitionInFlight = false;
    await _a.stop();
    await _b.stop();
    _activeEntry = null;
    _standbyEntry = null;
    // Whatever was resolved ahead belongs to the set being left behind.
    // `loadQueue` comes through here, so this covers a reload too.
    _lookahead = null;
    _lookaheadIndex = -1;
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
      final faded = await _fadeActiveToSilence(
        outgoing?.spec.crossfade ?? const Duration(seconds: 2),
        outgoing?.spec.fadeOutCurve ?? FadeCurve.equalPower,
      );
      if (faded) await stop();
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
        if (!await _fadeActiveToSilence(spec.crossfade, spec.fadeOutCurve)) {
          _transitionInFlight = false;
          return;
        }
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

    if (await _awaitFadeComplete()) await _completeSwap();
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

    if (!await _awaitFadeComplete()) return;
    _activeFade = 1.0;
    _applyGains();
    _setPhase(EnginePhase.playing);

    await _preloadNext();
  }

  Future<bool> _fadeActiveToSilence(Duration duration, FadeCurve curve) async {
    _fadeStartedAt = clock.now();
    _fadeDuration = duration;
    _currentSpec = TransitionSpec(crossfade: duration, fadeOutCurve: curve);
    _setPhase(EnginePhase.fadingOut);
    if (!await _awaitFadeComplete()) return false;
    _activeFade = 0.0;
    _applyGains();
    return true;
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

  /// Waits for the in-flight fade to reach its end.
  ///
  /// Returns false if the fade was *abandoned* rather than finished — the
  /// engine was paused or stopped part-way through. The deadline alone is not
  /// enough to decide this: pausing cancels the ticker, so `_advanceFade` stops
  /// running and the fade never progresses, but wall time keeps passing. A
  /// caller that treated the deadline as success would retire the outgoing
  /// deck and advance the queue while the operator had the set paused.
  Future<bool> _awaitFadeComplete() async {
    if (_fadeDuration <= Duration.zero) return true;
    final deadline = clock.now().add(_fadeDuration + tick);
    while (clock.now().isBefore(deadline)) {
      if (!_isFading) break;             // abandoned part-way
      if (_fadeStartedAt == null) break; // reached the end
      await Future<void>.delayed(tick);
    }
    return _isFading;
  }

  /// Whether a fade is still the engine's current business. Pausing or stopping
  /// clears this, and every exit from [_awaitFadeComplete] is gated on it.
  bool get _isFading =>
      _phase == EnginePhase.crossfading || _phase == EnginePhase.fadingOut;

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
    // Not `_index++`: the standby is not always the very next row, because
    // _preloadNext skips entries that fail to load.
    _index = _standbyIndex >= 0 ? _standbyIndex : _index + 1;
    _standbyIndex = -1;
    _emit();
  }

  // -------------------------------------------------------------------------
  // Preloading
  // -------------------------------------------------------------------------

  Future<void> _advanceToNext({bool immediate = false}) async {
    _index++;
    if (_index >= _queue.length) return;

    _activeEntry = await _loadOnto(_active, _queue[_index]);
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
    for (var i = _index + 1; i < _queue.length; i++) {
      final next = _takeLookahead(i) ?? _queue[i];
      try {
        final loaded = await _loadOnto(_standby, next);
        await _standby.preroll();
        await _standby.setVolume(0);
        _standbyEntry = loaded;
        _standbyIndex = i;
        // Pre-render the TTS now rather than at the transition. This is the
        // payoff for caching announcements as files instead of speaking live.
        unawaited(announcements.warm(loaded));
        // And start on the one after it, now that there is a whole track's
        // worth of time to do it in.
        unawaited(_lookAheadPast(i));
        return;
      } catch (e) {
        // A dead URL or missing file must not stall the set: keep walking the
        // queue until something loads. The UI surfaces the skip separately.
        _standbyEntry = null;
        _standbyIndex = -1;
        _events.add(EngineEvent(_phase, currentIndex: _index, entry: next));
      }
    }

    // Nothing further in the queue is playable.
    _standbyEntry = null;
    _standbyIndex = -1;
  }

  /// The pre-resolved entry for [index], if that is what was looked ahead to.
  ///
  /// Keyed on the index rather than held as "the next one" because
  /// [_preloadNext] walks past rows that fail to load, and the row it settles
  /// on is not always the one the look-ahead was aimed at.
  QueueEntry? _takeLookahead(int index) {
    if (index != _lookaheadIndex) return null;
    final entry = _lookahead;
    _lookahead = null;
    _lookaheadIndex = -1;
    return entry;
  }

  /// Re-resolves the row that will become standby after this one, while there
  /// is a whole track's worth of time to do it in.
  ///
  /// ARCHITECTURE §Prefetch during playback asks for N+2 kept ready. With two
  /// decks it can be resolved but not buffered, and resolving is the half that
  /// hurts: the refresh at load time runs with the transition latch held, so
  /// on a venue's wifi it is seconds during which [skipNext] returns without
  /// doing anything and the operator's crossfade button appears dead. This
  /// moves that cost into the middle of a track, where nothing is waiting on
  /// it.
  ///
  /// It does not add refreshes, it moves them: the work only happens for a URL
  /// that would have expired before its turn came anyway.
  Future<void> _lookAheadPast(int standbyIndex) async {
    final refresh = this.refresh;
    if (refresh == null) return;

    final index = standbyIndex + 1;
    if (index >= _queue.length) return;

    final entry = _queue[index];
    final due = _timeUntilStandbyEnds();
    if (due == null || !entry.media.expiresWithin(due)) return;

    final QueueEntry fresh;
    try {
      fresh = await refresh(entry);
    } catch (_) {
      // Exactly as at load time: the URL in hand has not expired yet, and the
      // load-time refresh gets one more attempt at it when the row comes up.
      return;
    }

    // The set may have been reloaded while that was in flight, in which case
    // this index means something else now.
    if (index >= _queue.length || !identical(_queue[index], entry)) return;

    _lookahead = fresh;
    _lookaheadIndex = index;
  }

  /// Roughly when the row after standby will be handed to a deck: what is left
  /// of the audible track, plus the whole of the one cued up behind it.
  ///
  /// Approximate on purpose, and it does not need to be better. It decides
  /// only whether a URL is worth re-resolving early, so being a few seconds
  /// out means doing work that was going to be done anyway, or not doing it
  /// and falling back to the refresh at load time.
  Duration? _timeUntilStandbyEnds() {
    final entry = _activeEntry;
    if (entry == null) return null;

    final remaining = _remainingOnActive(entry);
    if (remaining == null) return null;

    return remaining + (_standby.duration ?? Duration.zero);
  }

  /// Loads [entry] onto [deck], re-resolving it first when its URL is close
  /// enough to expiry to die mid-transition. Returns what was actually
  /// loaded, so the caller records the fresh entry rather than the stale one.
  Future<QueueEntry> _loadOnto(Deck deck, QueueEntry entry) async {
    final loaded = await _refreshed(entry);
    await deck.load(loaded.media);
    return loaded;
  }

  Future<QueueEntry> _refreshed(QueueEntry entry) async {
    final refresh = this.refresh;
    if (refresh == null || !entry.media.isExpiringSoon) return entry;

    try {
      return await refresh(entry);
    } catch (_) {
      // A refresh that fails is not a reason to drop the track. The URL in
      // hand has not expired yet — it is merely about to — and playing it is
      // better than a hole in the set. If it really is dead, the load fails
      // and the caller's existing skip handling takes over.
      return entry;
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

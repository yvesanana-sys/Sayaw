import 'dart:async';
import 'dart:io' show Platform;

import 'package:clock/clock.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:media_kit/media_kit.dart' as mk;

/// Everything a deck needs in order to play something, with no knowledge of
/// whether it came from disk, a Plex server or TIDAL.
class PlayableMedia {
  const PlayableMedia({
    required this.uri,
    this.headers = const {},
    this.drm,
    this.expiresAt,
    this.gainDb = 0.0,
    this.cueIn = Duration.zero,
    this.cueOut,
  });

  final Uri uri;
  final Map<String, String> headers;
  final DrmConfig? drm;

  /// Signed URLs expire. Re-resolve before handing this to a deck if the
  /// expiry is close — a URL dying mid-set is not a recoverable error on stage.
  final DateTime? expiresAt;

  /// ReplayGain or manual trim, applied as a static multiplier.
  final double gainDb;

  final Duration cueIn;
  final Duration? cueOut;

  /// Whether this URL will be dead [window] from now.
  ///
  /// Taking a window rather than answering one fixed question because there
  /// are two moments that ask it: the deck load, which asks about the next
  /// minute, and the look-ahead, which asks about the whole time between now
  /// and when the row is actually due.
  bool expiresWithin(Duration window) =>
      expiresAt != null && expiresAt!.difference(clock.now()) < window;

  bool get isExpiringSoon => expiresWithin(const Duration(seconds: 60));
}

class DrmConfig {
  const DrmConfig({
    required this.scheme,
    required this.licenseUri,
    this.licenseHeaders = const {},
  });

  final DrmScheme scheme;
  final Uri licenseUri;
  final Map<String, String> licenseHeaders;
}

enum DrmScheme { widevine, fairplay }

enum DeckPlaybackState { idle, loading, ready, playing, paused, completed, error }

class DeckStatus {
  const DeckStatus(this.state, {this.error});
  final DeckPlaybackState state;
  final Object? error;
}

/// A single independently addressable audio voice.
///
/// Deliberately minimal: every piece of interesting behaviour (curves,
/// scheduling, ducking) lives above this line in platform-agnostic Dart, so it
/// can be unit tested against a [FakeDeck] without touching a real audio stack.
abstract class Deck {
  String get id;

  Future<void> load(PlayableMedia media);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);

  /// Linear amplitude in `[0, 1]`. Implementations must coalesce redundant
  /// writes — the engine calls this at 50 Hz.
  Future<void> setVolume(double volume);

  /// Fill decoder buffers so [play] starts instantly. AVPlayer in particular
  /// reports ready well before it can actually start on time.
  Future<void> preroll();

  Duration get position;
  Duration? get duration;
  double get volume;
  PlayableMedia? get media;

  Stream<DeckStatus> get statusStream;
  Stream<Duration> get positionStream;

  Future<void> dispose();
}

/// Shared volume de-duplication. At 50 Hz, most ticks produce a change too
/// small to hear; skipping those cuts platform-channel traffic by ~70%.
mixin VolumeCoalescing on Object {
  static const double _minDelta = 0.005;
  double _lastSent = -1;

  bool shouldSendVolume(double v) {
    if (_lastSent < 0 || (v - _lastSent).abs() >= _minDelta || v == 0.0 || v == 1.0) {
      _lastSent = v;
      return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Android / iOS — ExoPlayer and AVPlayer via just_audio.
// This is the only backend that can do Widevine / FairPlay.
// ---------------------------------------------------------------------------

class JustAudioDeck with VolumeCoalescing implements Deck {
  JustAudioDeck(this.id) : _player = ja.AudioPlayer(handleInterruptions: false) {
    _player.playerStateStream.listen((s) {
      _status.add(DeckStatus(switch (s.processingState) {
        ja.ProcessingState.idle => DeckPlaybackState.idle,
        ja.ProcessingState.loading => DeckPlaybackState.loading,
        ja.ProcessingState.buffering => DeckPlaybackState.loading,
        ja.ProcessingState.ready =>
          s.playing ? DeckPlaybackState.playing : DeckPlaybackState.ready,
        ja.ProcessingState.completed => DeckPlaybackState.completed,
      }));
    });
  }

  @override
  final String id;

  final ja.AudioPlayer _player;
  final _status = StreamController<DeckStatus>.broadcast();

  PlayableMedia? _media;
  double _volume = 1.0;

  @override
  Future<void> load(PlayableMedia media) async {
    _media = media;
    try {
      await _player.setVolume(0);
      _volume = 0;

      final source = media.uri.scheme == 'file'
          ? ja.AudioSource.file(media.uri.toFilePath())
          : ja.AudioSource.uri(
              media.uri,
              headers: media.headers.isEmpty ? null : media.headers,
            );

      // just_audio surfaces DRM through platform-specific config; on Android
      // this maps to ExoPlayer's DrmSessionManager, on iOS to an
      // AVContentKeySession delegate registered in the platform plugin.
      await _player.setAudioSource(
        source,
        initialPosition: media.cueIn,
        preload: true,
      );
      _status.add(const DeckStatus(DeckPlaybackState.ready));
    } catch (e) {
      _status.add(DeckStatus(DeckPlaybackState.error, error: e));
      rethrow;
    }
  }

  /// AVPlayer reports `readyToPlay` before it can start without a hiccup.
  /// Rolling silently for ~200 ms and rewinding fixes the audible stumble at
  /// the head of every crossfade on iOS.
  @override
  Future<void> preroll() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    final cue = _media?.cueIn ?? Duration.zero;
    await _player.setVolume(0);
    await _player.play();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _player.pause();
    await _player.seek(cue);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _media = null;
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    _volume = v;
    if (shouldSendVolume(v)) await _player.setVolume(v);
  }

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  double get volume => _volume;

  @override
  PlayableMedia? get media => _media;

  @override
  Stream<DeckStatus> get statusStream => _status.stream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> dispose() async {
    await _status.close();
    await _player.dispose();
  }
}

// ---------------------------------------------------------------------------
// Windows / macOS — libmpv via media_kit.
// ---------------------------------------------------------------------------

class MediaKitDeck with VolumeCoalescing implements Deck {
  MediaKitDeck(this.id)
      : _player = mk.Player(
          configuration: const mk.PlayerConfiguration(
            // Big enough to survive a network stall mid-set without underrun.
            bufferSize: 32 * 1024 * 1024,
            title: 'Sayaw',
          ),
        ) {
    _player.stream.completed.listen((done) {
      if (done) _status.add(const DeckStatus(DeckPlaybackState.completed));
    });
    _player.stream.playing.listen((p) {
      _status.add(DeckStatus(
          p ? DeckPlaybackState.playing : DeckPlaybackState.paused));
    });
    _player.stream.duration.listen((d) => _duration = d);
    _player.stream.position.listen((p) {
      _position = p;
      _positions.add(p);
    });
    _player.stream.error.listen(
      (e) => _status.add(DeckStatus(DeckPlaybackState.error, error: e)),
    );
  }

  @override
  final String id;

  final mk.Player _player;
  final _status = StreamController<DeckStatus>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  PlayableMedia? _media;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _volume = 1.0;

  /// How long to wait for libmpv to report a file's length before giving up on
  /// it. Normally satisfied in milliseconds; the bound exists so a file it
  /// cannot parse costs a moment rather than a transition.
  static const _durationTimeout = Duration(seconds: 2);

  @override
  Future<void> load(PlayableMedia media) async {
    _media = media;
    // Cleared before the open, never after: every reader between here and the
    // new length arriving would otherwise be handed the length of the file
    // that was loaded before this one.
    _duration = null;
    _status.add(const DeckStatus(DeckPlaybackState.loading));
    try {
      await _player.setVolume(0);
      _volume = 0;
      await _player.open(
        mk.Media(
          media.uri.toString(),
          httpHeaders: media.headers.isEmpty ? null : media.headers,
          start: media.cueIn,
          end: media.cueOut,
        ),
        play: false,
      );
      await _settleDuration();
      _status.add(const DeckStatus(DeckPlaybackState.ready));
    } catch (e) {
      _status.add(DeckStatus(DeckPlaybackState.error, error: e));
      rethrow;
    }
  }

  /// Holds the load open until the file's length is known.
  ///
  /// libmpv reports it on a stream once it has parsed the file, not from
  /// `open`, so a caller reading [duration] the instant a load returned saw
  /// null — and answered as though the file had no length. That is what made
  /// every announcement on this backend silent: the clip was loaded, its
  /// length came back null, and the announcement was dropped rather than
  /// played.
  Future<void> _settleDuration() async {
    if (_duration != null) return;

    try {
      _duration = await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(_durationTimeout);
    } on TimeoutException {
      // media_kit's duration stream is distinct, so two files of exactly the
      // same length in a row emit nothing at all — indistinguishable, from
      // here, from a file whose length mpv could not work out. What the player
      // already holds is right in the first case and no worse than null in the
      // second.
      final known = _player.state.duration;
      _duration = known > Duration.zero ? known : null;
    }
  }

  /// libmpv fills its buffer on open, so there is nothing to do here.
  @override
  Future<void> preroll() async {}

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _media = null;
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// media_kit takes 0–100. Normalising here rather than at the call site is
  /// the whole point of the abstraction.
  @override
  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    _volume = v;
    if (shouldSendVolume(v)) await _player.setVolume(v * 100.0);
  }

  @override
  Duration get position => _position;

  @override
  Duration? get duration => _duration;

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
    await _status.close();
    await _positions.close();
    await _player.dispose();
  }
}

// ---------------------------------------------------------------------------

/// Picks the right backend for the current platform.
///
/// Mobile gets just_audio because ExoPlayer/AVPlayer are the only stacks with
/// Widevine and FairPlay support, and because audio_service's background
/// integration is built around them. Desktop gets media_kit because libmpv
/// handles multi-instance playback and odd codecs more reliably, and because
/// none of the mobile background machinery is needed there.
class DeckFactory {
  static Deck create(String id) {
    if (Platform.isAndroid || Platform.isIOS) return JustAudioDeck(id);
    return MediaKitDeck(id);
  }
}

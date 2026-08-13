import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;

import 'crossfade_engine.dart';
import 'deck.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';

/// A rendered announcement: a real audio file with a *known* duration.
///
/// Rendering TTS to a file rather than speaking it live is the single most
/// important decision in this module. It buys three things:
///
///  1. The duration is known before playback starts, so the duck envelope can
///     be scheduled precisely instead of guessed or driven by a completion
///     callback that arrives late.
///  2. Pre-recorded MC clips and synthesised speech travel the same code path —
///     both are just files on the announcement deck.
///  3. Zero synthesis latency at the transition, and full offline operation.
class AnnouncementClip {
  const AnnouncementClip({
    required this.hash,
    required this.filePath,
    required this.duration,
    required this.text,
  });

  final String hash;
  final String filePath;
  final Duration duration;
  final String text;
}

class TtsVoiceSettings {
  const TtsVoiceSettings({
    this.voiceId,
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  final String? voiceId;
  final double rate;
  final double pitch;
  final double volume;
}

/// Renders, caches and plays dance announcements, and owns the ducking
/// envelope applied to the music bus while a voice is speaking.
class AnnouncementEngine {
  AnnouncementEngine({
    required Deck voiceDeck,
    required String cacheDirectory,
    required this.settings,
    AnnouncementCacheStore? store,
    ClipFactory? clipFactory,
  })  : _deck = voiceDeck,
        _store = store ?? InMemoryAnnouncementCache() {
    _clips = clipFactory ??
        PlatformClipFactory(
          deck: voiceDeck,
          cacheDirectory: cacheDirectory,
          settings: settings,
        );
  }

  final Deck _deck;
  final AnnouncementCacheStore _store;
  final TtsVoiceSettings settings;

  /// Everything outside this class: the filesystem, the platform TTS engine,
  /// and reading a rendered file's duration back. Swapped in tests for a
  /// factory that returns clips of known length without touching any of them.
  late final ClipFactory _clips;

  final Map<String, Future<AnnouncementClip?>> _inFlight = {};

  // -------------------------------------------------------------------------
  // Text resolution
  // -------------------------------------------------------------------------

  /// Explicit item text wins, then the dance type, then nothing.
  String? _textFor(QueueEntry entry) {
    if (entry.announcementText != null && entry.announcementText!.isNotEmpty) {
      return entry.announcementText;
    }
    if (entry.danceTypeName != null && entry.danceTypeName!.isNotEmpty) {
      return 'Next dance: ${entry.danceTypeName}';
    }
    return null;
  }

  String _hashFor(String text) => announcementHash(text, settings);

  // -------------------------------------------------------------------------
  // Rendering
  // -------------------------------------------------------------------------

  /// Called by the engine as soon as an item is preloaded, so synthesis never
  /// happens on the critical path of a transition.
  Future<void> warm(QueueEntry entry) => clipFor(entry).then((_) {});

  /// Returns a playable clip for [entry], or null if it has no announcement.
  Future<AnnouncementClip?> clipFor(QueueEntry entry) {
    // A hand-recorded clip bypasses TTS entirely.
    final custom = entry.announcementClipPath;
    if (custom != null && custom.isNotEmpty && _clips.exists(custom)) {
      return _clips.probe(custom, text: entry.danceTypeName ?? '');
    }

    final text = _textFor(entry);
    if (text == null) return Future.value(null);

    final hash = _hashFor(text);

    // Deduplicate: a playlist with forty Cha-Chas renders "Cha-Cha" once.
    return _inFlight.putIfAbsent(hash, () async {
      try {
        final cached = await _store.get(hash);
        if (cached != null && _clips.exists(cached.filePath)) return cached;

        final clip = await _clips.render(text, hash);
        if (clip != null) await _store.put(clip);
        return clip;
      } finally {
        // Keep the map small; the durable cache is _store.
        scheduleMicrotask(() => _inFlight.remove(hash));
      }
    });
  }

  // -------------------------------------------------------------------------
  // Playback
  // -------------------------------------------------------------------------

  /// Plays the clip with the music already silent. Used by
  /// [AnnounceMode.beforeMusic].
  Future<void> announceSolo(AnnouncementClip clip) async {
    await _deck.load(PlayableMedia(uri: Uri.file(clip.filePath)));
    await _deck.setVolume(1.0);
    await _deck.play();
    // The duration came from the file itself, so this wait is exact.
    await Future<void>.delayed(clip.duration + const Duration(milliseconds: 120));
    await _deck.stop();
  }

  /// Plays the clip over live music, ducking and restoring the music bus.
  /// Used by [AnnounceMode.duckOver].
  ///
  /// Envelope:
  ///
  ///     1.0 ──╲                          ╱── 1.0
  ///            ╲ duckFade      restoreFade
  ///             ╲____________________╱
  ///              duckLevel   hold
  ///             [ voice plays ]
  Future<void> announceWithDuck(
    AnnouncementClip clip, {
    required TransitionSpec spec,
    required MusicGainBus bus,
  }) async {
    await _deck.load(PlayableMedia(uri: Uri.file(clip.filePath)));
    await _deck.setVolume(0.0);

    // Duck down, then start speaking. Logarithmic drops quickly and holds,
    // which clears space for the voice without a slow audible slide.
    await bus.announcementDuck.rampTo(
      spec.duckLevel,
      spec.duckFade,
      curve: FadeCurve.logarithmic,
    );

    await _deck.setVolume(1.0);
    await _deck.play();
    await Future<void>.delayed(clip.duration);
    await _deck.stop();

    await Future<void>.delayed(spec.duckHold);

    // Come back up on an S-curve so the return is smooth rather than a step.
    await bus.announcementDuck.rampTo(
      1.0,
      spec.duckRestoreFade,
      curve: FadeCurve.sCurve,
    );
  }

  /// Operator-triggered one-off ("last dance", "please clear the floor").
  Future<void> speakNow(
    String text, {
    required MusicGainBus bus,
    double duckLevel = 0.2,
  }) async {
    final hash = _hashFor(text);
    final clip = await _store.get(hash) ?? await _clips.render(text, hash);
    if (clip == null) return;
    await announceWithDuck(
      clip,
      spec: TransitionSpec(duckLevel: duckLevel),
      bus: bus,
    );
  }

  Future<void> dispose() => _deck.dispose();
}

// ---------------------------------------------------------------------------

/// The cache key for a piece of speech: the text plus every voice setting that
/// would change how it sounds. Changing the rate re-renders; replaying the same
/// dance name forty times in an event does not.
String announcementHash(String text, TtsVoiceSettings settings) {
  final key = jsonEncode({
    'text': text,
    'voice': settings.voiceId,
    'rate': settings.rate,
    'pitch': settings.pitch,
  });
  return sha1.convert(utf8.encode(key)).toString();
}

/// Everything [AnnouncementEngine] needs from outside itself: the filesystem,
/// the platform speech synthesiser, and reading a rendered file's duration.
///
/// This is the seam that makes announcement sequencing testable. The engine's
/// interesting behaviour is *when* it ducks and for how long, which is derived
/// entirely from `clip.duration`. Injecting a factory that returns a known
/// duration lets every announcement envelope be asserted without a TTS engine,
/// an audio backend, or a single byte of disk.
abstract class ClipFactory {
  /// Whether a previously rendered file is still present.
  bool exists(String path);

  /// Synthesises [text] to an audio file, or null if synthesis failed.
  Future<AnnouncementClip?> render(String text, String hash);

  /// Reads an existing file's duration back.
  Future<AnnouncementClip?> probe(String path,
      {required String text, String? hash});
}

/// The production [ClipFactory]: native TTS to a file, duration read back off
/// the voice deck.
class PlatformClipFactory implements ClipFactory {
  PlatformClipFactory({
    required Deck deck,
    required String cacheDirectory,
    required this.settings,
  })  // A named parameter cannot be private, so `this._deck` is unavailable.
      // ignore: prefer_initializing_formals
      : _deck = deck,
        _cacheDir = cacheDirectory;

  static const _desktopTts = MethodChannel('sayaw/tts');

  final Deck _deck;
  final String _cacheDir;
  final TtsVoiceSettings settings;

  final FlutterTts _tts = FlutterTts();

  @override
  bool exists(String path) => File(path).existsSync();

  @override
  Future<AnnouncementClip?> render(String text, String hash) async {
    final outPath = p.join(_cacheDir, '$hash.wav');
    await Directory(_cacheDir).create(recursive: true);

    if (Platform.isAndroid || Platform.isIOS) {
      await _configureTts();
      // flutter_tts writes to the app's TTS output directory on Android and to
      // a path on iOS; both accept a bare filename plus this flag.
      await _tts.setSharedInstance(true);
      final ok = await _tts.synthesizeToFile(text, '$hash.wav');
      if (ok != 1) return null;
    } else {
      // Windows: SpeechSynthesizer.SynthesizeTextToStreamAsync
      // macOS:   AVSpeechSynthesizer.write(_:toBufferCallback:)
      // Both are ~40 lines of platform code behind this channel; flutter_tts's
      // desktop synthesizeToFile coverage is not dependable enough to rely on.
      final result = await _desktopTts.invokeMethod<String>('synthesizeToFile', {
        'text': text,
        'path': outPath,
        'voiceId': settings.voiceId,
        'rate': settings.rate,
        'pitch': settings.pitch,
      });
      if (result == null) return null;
    }

    if (!exists(outPath)) return null;
    return probe(outPath, text: text, hash: hash);
  }

  /// Loads the file on the voice deck purely to read its duration back.
  @override
  Future<AnnouncementClip?> probe(String path,
      {required String text, String? hash}) async {
    await _deck.load(PlayableMedia(uri: Uri.file(path)));
    final d = _deck.duration;
    if (d == null) return null;
    return AnnouncementClip(
      hash: hash ?? announcementHash(text, settings),
      filePath: path,
      duration: d,
      text: text,
    );
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(settings.rate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);
    if (settings.voiceId != null) {
      await _tts.setVoice({'name': settings.voiceId!, 'locale': ''});
    }
  }
}

// ---------------------------------------------------------------------------

abstract class AnnouncementCacheStore {
  Future<AnnouncementClip?> get(String hash);
  Future<void> put(AnnouncementClip clip);
}

/// Swap for a Drift-backed store writing to `announcement_cache` in production.
class InMemoryAnnouncementCache implements AnnouncementCacheStore {
  final _map = <String, AnnouncementClip>{};

  @override
  Future<AnnouncementClip?> get(String hash) async => _map[hash];

  @override
  Future<void> put(AnnouncementClip clip) async => _map[clip.hash] = clip;
}

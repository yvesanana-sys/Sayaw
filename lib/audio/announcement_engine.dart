import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;

import 'crossfade_engine.dart';
import 'deck.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';
import 'system_voice.dart';

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
  Future<void> warm(QueueEntry entry) async {
    // A row that will not speak has nothing to render. On the desktop this is
    // a synthesiser process per row, and a merged block of three songs would
    // otherwise pay for three voices nobody hears.
    if (entry.spec.announceMode == AnnounceMode.off) return;
    try {
      await clipFor(entry);
    } on Object {
      // Nothing waits on a warm. A clip that cannot be rendered or read is
      // answered again at the transition, where the decision to go without it
      // is made — an unhandled error here would take the app down for a file
      // the operator moved.
    }
  }

  /// Returns a playable clip for [entry], or null if it has no announcement.
  ///
  /// Null covers "nothing to say" and "nothing that can be said" alike, and it
  /// never throws. This is called from inside a transition that has already
  /// begun: an exception here does not lose an announcement, it stops a
  /// crossfade with a room on the floor. A file the operator moved, a TTS
  /// engine that will not answer, a cache that cannot be read — all of them
  /// cost the voice and none of them cost the set.
  Future<AnnouncementClip?> clipFor(QueueEntry entry) async {
    try {
      // A hand-recorded clip bypasses TTS entirely.
      final custom = entry.announcementClipPath;
      if (custom != null && custom.isNotEmpty && _clips.exists(custom)) {
        return await _clips.probe(custom, text: entry.danceTypeName ?? '');
      }

      final text = _textFor(entry);
      if (text == null) return null;

      final hash = _hashFor(text);

      // Deduplicate: a playlist with forty Cha-Chas renders "Cha-Cha" once.
      return await _inFlight.putIfAbsent(hash, () async {
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
    } on Object {
      return null;
    }
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

  /// Cuts a voice off mid-word.
  ///
  /// For the transport's stop, where silence has to mean silence. The duck on
  /// the music bus is left to the announcement that owns it: its envelope
  /// still runs to the end and restores the bus on time, and nothing here
  /// should bring the music back up underneath a stop.
  Future<void> silence() => _deck.stop();

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
    SystemVoice? voice,
  })  // A named parameter cannot be private, so `this._deck` is unavailable.
      // ignore: prefer_initializing_formals
      : _deck = deck,
        _cacheDir = cacheDirectory,
        _voice = voice ?? SystemVoice.platform();

  final Deck _deck;
  final String _cacheDir;
  final TtsVoiceSettings settings;

  /// The desktop synthesiser. Injected in tests so nothing has to shell out.
  final SystemVoice _voice;

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
      // The desktop platforms have no dependable render-to-file plugin, so
      // this drives the synthesiser the operating system already ships.
      final spoke = await _voice.synthesize(
        text: text,
        outPath: outPath,
        settings: settings,
      );
      if (!spoke) {
        // Every caller above turns a null clip into a transition that simply
        // runs without a voice, which on the floor is indistinguishable from a
        // row nobody tagged. This is the one place that still knows *why*, so
        // it is the only place that can say so.
        debugPrint(
          'sayaw: announcement not rendered — '
          '${await _voice.describeMissing() ?? 'the synthesiser failed.'}',
        );
        return null;
      }
    }

    if (!exists(outPath)) return null;
    return probe(outPath, text: text, hash: hash);
  }

  /// The length assumed for a clip whose backend will not report one.
  ///
  /// Announcing on a guessed envelope is a small error — the music comes back
  /// up a little early or late. Announcing nothing is a silent one, and it is
  /// the failure this whole path exists to prevent. `Soundboard.assumedLength`
  /// is the same trade for the same reason.
  static const assumedLength = Duration(seconds: 3);

  /// Loads the file on the voice deck purely to read its duration back.
  @override
  Future<AnnouncementClip?> probe(String path,
      {required String text, String? hash}) async {
    try {
      await _deck.load(PlayableMedia(uri: Uri.file(path)));
    } on Object {
      // A file the operator has moved, or one the backend cannot decode. This
      // runs on the path of a transition that is already under way, so it
      // answers "no clip" rather than throwing into it.
      return null;
    }

    // Zero is not a length either: a backend that has not parsed the file yet
    // reports it, and an announcement timed at zero is started and stopped in
    // the same instant. The deck guards against this too; this is the last
    // line, because the cost of being wrong here is a voice nobody hears.
    final known = _deck.duration;
    final duration =
        known == null || known <= Duration.zero ? assumedLength : known;

    return AnnouncementClip(
      hash: hash ?? announcementHash(text, settings),
      filePath: path,
      duration: duration,
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

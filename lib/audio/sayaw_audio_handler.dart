import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'announcement_engine.dart';
import 'crossfade_engine.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';

/// Background playback, lock-screen controls and OS audio-session handling.
///
/// On Android this runs inside a foreground service; on iOS it relies on the
/// `audio` background mode. macOS has no such constraint, so there it only
/// drives `MPNowPlayingInfoCenter` and the media keys.
///
/// It mirrors an engine it is given. It does not own one — see [attach].
class SayawAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  SayawAudioHandler({
    required this.engine,
    required this.bus,
    required this.announcements,
  }) {
    _events = engine.events.listen(_publish);
  }

  final CrossfadeEngine engine;
  final MusicGainBus bus;
  final AnnouncementEngine announcements;

  late final StreamSubscription<EngineEvent> _events;

  /// The platforms `audio_service` ships an implementation for.
  ///
  /// Android, iOS and macOS. ARCHITECTURE §1.3 wants `SystemMediaTransportControls`
  /// on Windows, which is a different plugin entirely and not this one — so a
  /// Windows rig gets no media session and is otherwise unaffected.
  static bool get isSupportedHere =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  /// Wraps an already-running engine in an OS media session.
  ///
  /// Takes its collaborators rather than building them. Constructing a deck
  /// here would put a second engine behind the lock screen while the operator
  /// drove the real one from the deck screen — the pause button would report
  /// success and nothing would go quiet.
  ///
  /// Returns null where there is no media session to attach to. Call once per
  /// process: `AudioService.init` is a one-shot.
  static Future<SayawAudioHandler?> attach({
    required CrossfadeEngine engine,
    required MusicGainBus bus,
    required AnnouncementEngine announcements,
  }) async {
    if (!isSupportedHere) return null;

    final handler = SayawAudioHandler(
      engine: engine,
      bus: bus,
      announcements: announcements,
    );

    await handler._configureSession();

    return AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.sayaw.audio',
        androidNotificationChannelName: 'Playback',
        // Keep the service alive between tracks — a set has gaps, and letting
        // Android reclaim the service mid-event is fatal.
        //
        // `androidNotificationOngoing: true` cannot be combined with this:
        // audio_service asserts against the pair, because an ongoing (undismissable)
        // notification has no effect once the service stays in the foreground
        // through a pause. Setting it here was a compile-time error, and it was
        // the redundant half of the pair — this line is the one that matters.
        androidStopForegroundOnPause: false,
      ),
    );
  }

  Future<void> _configureSession() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      // Never duckOthers: we control both the music and the voice, so we duck
      // internally and get an exact configurable level and curve instead of
      // whatever fixed attenuation the OS applies.
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));

    // Transient focus loss (a notification, Siri) rides the systemDuck stage,
    // which multiplies with any in-flight announcement duck rather than
    // fighting it.
    session.becomingNoisyEventStream.listen((_) => pause());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            bus.systemDuck.rampTo(0.4, const Duration(milliseconds: 200));
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            bus.systemDuck.rampTo(1.0, const Duration(milliseconds: 400),
                curve: FadeCurve.sCurve);
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            break; // Resume is the operator's call, not ours, mid-event.
        }
      }
    });
  }

  void _publish(EngineEvent e) {
    final entry = e.entry;
    if (entry != null) {
      mediaItem.add(MediaItem(
        id: entry.itemId,
        title: entry.title,
        artist: entry.artist,
        genre: entry.danceTypeName,
        // The competition cap when there is one, because the row really will
        // stop there; otherwise however long the deck says the file is.
        duration: entry.targetDuration ?? engine.activeDuration,
      ));
    }

    playbackState.add(playbackState.value.copyWith(
      // No previous, and no seek. There is nothing behind either of them —
      // the engine has no notion of going back, and rewinding the audible deck
      // in the middle of a dance is not something to hand a lock screen. A
      // control that does nothing is worse than one that is not offered.
      controls: [
        if (isPlaying(e.phase)) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      playing: isPlaying(e.phase),
      processingState: switch (e.phase) {
        EnginePhase.idle => AudioProcessingState.idle,
        EnginePhase.paused => AudioProcessingState.ready,
        _ => AudioProcessingState.ready,
      },
      // Only moves on an engine event; audio_service extrapolates between them
      // from `updateTime` while `playing` is true, which is what keeps the
      // notification's clock running without a second 50 Hz ticker.
      updatePosition: engine.activePosition,
      queueIndex: e.currentIndex,
    ));
  }

  /// Whether sound is coming out. A fade-out and an announcement both count:
  /// a lock screen showing "paused" while the room can still hear the set is
  /// the wrong answer.
  static bool isPlaying(EnginePhase phase) => switch (phase) {
        EnginePhase.playing ||
        EnginePhase.crossfading ||
        EnginePhase.announcing ||
        EnginePhase.fadingOut =>
          true,
        EnginePhase.idle || EnginePhase.paused => false,
      };

  @override
  Future<void> play() => engine.play();

  @override
  Future<void> pause() => engine.pause();

  @override
  Future<void> stop() => engine.stop();

  @override
  Future<void> skipToNext() => engine.skipNext();

  /// Not an `AudioHandler` member — that interface has no volume command, since
  /// system volume is the OS's business. This is Sayaw's own master fader,
  /// driven from the UI and from `customAction`.
  Future<void> setVolume(double volume) async =>
      bus.master.setImmediate(volume);

  /// Big red button for the MC: dip the music and speak over it now.
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'speakNow') {
      await announcements.speakNow(
        extras?['text'] as String? ?? '',
        bus: bus,
        duckLevel: (extras?['duckLevel'] as num?)?.toDouble() ?? 0.2,
      );
    }
  }

  /// Stops mirroring the engine. The engine itself belongs to the runtime and
  /// is disposed there — this only lets go of it.
  Future<void> dispose() => _events.cancel();
}

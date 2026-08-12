import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'announcement_engine.dart';
import 'crossfade_engine.dart';
import 'deck.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';

/// Background playback, lock-screen controls and OS audio-session handling.
///
/// On Android this runs inside a foreground service; on iOS it relies on the
/// `audio` background mode. On Windows and macOS there is no such constraint,
/// so the handler exists mainly to drive SMTC / MPNowPlayingInfoCenter.
class SayawAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  SayawAudioHandler({
    required this.engine,
    required this.bus,
    required this.announcements,
  }) {
    engine.events.listen(_publish);
  }

  final CrossfadeEngine engine;
  final MusicGainBus bus;
  final AnnouncementEngine announcements;

  static Future<SayawAudioHandler> init({
    required String announcementCacheDir,
  }) async {
    final bus = MusicGainBus();

    final announcements = AnnouncementEngine(
      voiceDeck: DeckFactory.create('voice'),
      cacheDirectory: announcementCacheDir,
      settings: const TtsVoiceSettings(),
    );

    final engine = CrossfadeEngine(
      deckA: DeckFactory.create('A'),
      deckB: DeckFactory.create('B'),
      bus: bus,
      announcements: announcements,
    );

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
        androidNotificationOngoing: true,
        // Keep the service alive between tracks — a set has gaps, and letting
        // Android reclaim the service mid-event is fatal.
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
        duration: entry.targetDuration,
      ));
    }

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (e.phase == EnginePhase.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      playing: e.phase == EnginePhase.playing ||
          e.phase == EnginePhase.crossfading ||
          e.phase == EnginePhase.announcing,
      processingState: switch (e.phase) {
        EnginePhase.idle => AudioProcessingState.idle,
        EnginePhase.paused => AudioProcessingState.ready,
        _ => AudioProcessingState.ready,
      },
      queueIndex: e.currentIndex,
    ));
  }

  @override
  Future<void> play() => engine.play();

  @override
  Future<void> pause() => engine.pause();

  @override
  Future<void> stop() => engine.stop();

  @override
  Future<void> skipToNext() => engine.skipNext();

  @override
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
}

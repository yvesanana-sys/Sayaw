import 'package:audio_service/audio_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/deck.dart';
import 'package:sayaw/audio/gain_bus.dart';
import 'package:sayaw/audio/sayaw_audio_handler.dart';

import '../fakes/fake_clip_factory.dart';
import '../fakes/fake_deck.dart';

/// The handler over a real engine and fake decks.
///
/// `BaseAudioHandler` is streams and nothing else, so all of this runs without
/// a platform channel. Only `attach` needs one, and that is the one thing here
/// that cannot be exercised in a test.
class _Rig {
  _Rig({Duration track = const Duration(seconds: 10)}) {
    a = FakeDeck('A', trackDuration: track);
    b = FakeDeck('B', trackDuration: track);
    bus = MusicGainBus();
    announcements = AnnouncementEngine(
      voiceDeck: FakeDeck('voice', trackDuration: const Duration(seconds: 2)),
      cacheDirectory: '/fake',
      settings: const TtsVoiceSettings(),
      clipFactory: FakeClipFactory(),
    );
    engine = CrossfadeEngine(
      deckA: a,
      deckB: b,
      bus: bus,
      announcements: announcements,
    );
    handler = SayawAudioHandler(
      engine: engine,
      bus: bus,
      announcements: announcements,
    );
  }

  late final FakeDeck a;
  late final FakeDeck b;
  late final MusicGainBus bus;
  late final AnnouncementEngine announcements;
  late final CrossfadeEngine engine;
  late final SayawAudioHandler handler;

  void start(List<QueueEntry> queue, FakeAsync async) {
    engine.loadQueue(queue);
    async.flushMicrotasks();
    engine.play();
    async.flushMicrotasks();
  }
}

QueueEntry _entry(
  String id, {
  String artist = '',
  String? danceTypeName,
  Duration? targetDuration,
  Duration crossfade = const Duration(seconds: 4),
}) =>
    QueueEntry(
      itemId: id,
      media: PlayableMedia(uri: Uri.parse('fake://$id')),
      spec: TransitionSpec(crossfade: crossfade, announceMode: AnnounceMode.off),
      targetDuration: targetDuration,
      danceTypeName: danceTypeName,
      title: id,
      artist: artist,
    );

void main() {
  group('what the lock screen is told', () {
    test('the track the engine is actually playing', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([
          _entry('Kiss of Fire', artist: 'Georgia Gibbs', danceTypeName: 'Tango'),
        ], async);

        final item = rig.handler.mediaItem.value!;
        expect(item.id, 'Kiss of Fire');
        expect(item.artist, 'Georgia Gibbs');
        expect(item.genre, 'Tango');
      });
    });

    test('a competition cap is the duration, not the length of the file', () {
      // The row really will stop at 1:45, so telling the notification the file
      // is four minutes long would draw a progress bar that never fills.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 4));
        rig.start([
          _entry('round', targetDuration: const Duration(seconds: 105)),
        ], async);

        expect(rig.handler.mediaItem.value!.duration,
            const Duration(seconds: 105));
      });
    });

    test('an uncapped row reports what the deck says the file is', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 3));
        rig.start([_entry('social')], async);

        expect(rig.handler.mediaItem.value!.duration,
            const Duration(minutes: 3));
      });
    });

    test('playing, and then not', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);
        expect(rig.handler.playbackState.value.playing, isTrue);

        rig.engine.pause();
        async.flushMicrotasks();

        expect(rig.handler.playbackState.value.playing, isFalse);
        expect(rig.handler.playbackState.value.processingState,
            AudioProcessingState.ready);
      });
    });

    test('a fade-out still reads as playing', () {
      // The room can still hear the set. A lock screen saying "paused" while
      // music is coming out of the PA is the wrong answer.
      for (final phase in EnginePhase.values) {
        expect(
          SayawAudioHandler.isPlaying(phase),
          phase != EnginePhase.idle && phase != EnginePhase.paused,
          reason: '$phase',
        );
      }
    });

    test('the position moves with the set', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        expect(rig.handler.playbackState.value.updatePosition,
            greaterThan(Duration.zero));
      });
    });
  });

  group('the controls it offers', () {
    test('no previous, because there is nothing behind it', () {
      // The engine has no notion of going back, and rewinding the audible deck
      // in the middle of a dance is not something to hand a lock screen.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        final controls = rig.handler.playbackState.value.controls;
        expect(controls, isNot(contains(MediaControl.skipToPrevious)));
        expect(controls, contains(MediaControl.skipToNext));
      });
    });

    test('no seek action, because nothing implements one', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        expect(rig.handler.playbackState.value.systemActions,
            isNot(contains(MediaAction.seek)));
      });
    });

    test('pause while playing, play while paused', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);
        expect(rig.handler.playbackState.value.controls,
            contains(MediaControl.pause));

        rig.engine.pause();
        async.flushMicrotasks();

        expect(rig.handler.playbackState.value.controls,
            contains(MediaControl.play));
      });
    });
  });

  group('commands reach the engine that is making the sound', () {
    // The regression this file exists for: the handler used to build its own
    // decks, bus and engine. Wired up as written, the lock screen would have
    // driven a second, silent engine — pause would report success and the
    // room would keep dancing.
    test('pause stops the deck the set is playing on', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        rig.handler.pause();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.paused);
        expect(rig.a.calls, contains('pause'));
      });
    });

    test('play resumes it', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);
        rig.engine.pause();
        async.flushMicrotasks();

        rig.handler.play();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('skipToNext runs the configured crossfade, not a cut', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        rig.handler.skipToNext();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.crossfading);
      });
    });

    test('stop stops it', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        rig.handler.stop();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.idle);
      });
    });

    test('the master fader is the one the set plays through', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        rig.handler.setVolume(0.5);
        async.flushMicrotasks();

        expect(rig.bus.master.value, 0.5);
      });
    });
  });

  test('disposing lets go of the engine', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.start([_entry('one'), _entry('two')], async);

      rig.handler.dispose();
      async.flushMicrotasks();

      final before = rig.handler.playbackState.value;
      rig.engine.pause();
      async.flushMicrotasks();

      expect(rig.handler.playbackState.value.playing, before.playing);
    });
  });

  test('there is no media session where audio_service has no implementation',
      () {
    // Linux, and the Windows rig the ARCHITECTURE table hands to SMTC instead.
    // `attach` returning null is what keeps the rest of the app unaffected.
    expect(SayawAudioHandler.isSupportedHere, isFalse,
        reason: 'these tests run on Linux');
  });
}

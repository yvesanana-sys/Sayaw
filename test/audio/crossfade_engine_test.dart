import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/deck.dart';
import 'package:sayaw/audio/fade_curves.dart';
import 'package:sayaw/audio/gain_bus.dart';

import '../fakes/fake_clip_factory.dart';
import '../fakes/fake_deck.dart';

const _tick = Duration(milliseconds: 20);

QueueEntry _entry(
  String id, {
  Duration crossfade = const Duration(seconds: 4),
  AnnounceMode mode = AnnounceMode.off,
  Duration cueIn = Duration.zero,
  Duration? cueOut,
  Duration? targetDuration,
  String? danceTypeName,
  String? announcementClipPath,
  bool merge = false,
  DateTime? expiresAt,
  double duckLevel = 0.2,
  Duration duckFade = const Duration(milliseconds: 600),
  Duration duckHold = const Duration(milliseconds: 250),
  Duration duckRestoreFade = const Duration(milliseconds: 900),
  Duration rotationGap = Duration.zero,
}) {
  return QueueEntry(
    itemId: id,
    media: PlayableMedia(
      uri: Uri.parse('fake://$id'),
      cueIn: cueIn,
      cueOut: cueOut,
      expiresAt: expiresAt,
    ),
    spec: merge
        ? const TransitionSpec.merge()
        : TransitionSpec(
            crossfade: crossfade,
            announceMode: mode,
            duckLevel: duckLevel,
            duckFade: duckFade,
            duckHold: duckHold,
            duckRestoreFade: duckRestoreFade,
            rotationGap: rotationGap,
          ),
    targetDuration: targetDuration,
    danceTypeName: danceTypeName,
    announcementClipPath: announcementClipPath,
    title: id,
  );
}

/// A phase transition, stamped with virtual time.
class _PhaseAt {
  _PhaseAt(this.at, this.phase);
  final Duration at;
  final EnginePhase phase;
  @override
  String toString() => '${at.inMilliseconds}ms:${phase.name}';
}

/// Two deck volumes written in the same `_applyGains` call.
class _Gains {
  _Gains(this.at, this.a, this.b);
  final Duration at;
  final double a;
  final double b;
  double get power => a * a + b * b;
  @override
  String toString() => '${at.inMilliseconds}ms a=$a b=$b';
}

class _Rig {
  _Rig({
    Duration track = const Duration(seconds: 10),
    Duration clip = const Duration(seconds: 2),
    EntryRefresher? refresh,
  }) {
    epoch = clock.now();
    a = FakeDeck('A', trackDuration: track);
    b = FakeDeck('B', trackDuration: track);
    voice = FakeDeck('voice', trackDuration: clip);
    bus = MusicGainBus();
    clips = FakeClipFactory(clipDuration: clip);
    announcements = AnnouncementEngine(
      voiceDeck: voice,
      cacheDirectory: '/fake',
      settings: const TtsVoiceSettings(),
      clipFactory: clips,
    );
    engine = CrossfadeEngine(
      deckA: a,
      deckB: b,
      bus: bus,
      announcements: announcements,
      refresh: refresh,
    );
    engine.events.listen((e) {
      phases.add(_PhaseAt(now, e.phase));
      final i = e.currentIndex;
      if (i != null && i > maxIndexSeen) maxIndexSeen = i;
      if (e.entry != null && e.phase != EnginePhase.idle) {
        final id = e.entry!.itemId;
        if (activeItems.isEmpty || activeItems.last != id) activeItems.add(id);
      }
    });
    bus.announcementDuck.changes.listen((v) => duckValues.add(MapEntry(now, v)));
  }

  late final DateTime epoch;
  late final FakeDeck a;
  late final FakeDeck b;
  late final FakeDeck voice;
  late final MusicGainBus bus;
  late final FakeClipFactory clips;
  late final AnnouncementEngine announcements;
  late final CrossfadeEngine engine;

  final phases = <_PhaseAt>[];
  int maxIndexSeen = -1;
  final activeItems = <String>[];
  final duckValues = <MapEntry<Duration, double>>[];

  Duration get now => clock.now().difference(epoch);

  /// Deck volume writes that happened in the same `_applyGains` call, matched
  /// on their virtual timestamp.
  List<_Gains> get gains {
    final byTime = <Duration, List<double?>>{};
    for (final e in a.volumeEvents) {
      byTime.putIfAbsent(e.at, () => [null, null])[0] = e.volume;
    }
    for (final e in b.volumeEvents) {
      byTime.putIfAbsent(e.at, () => [null, null])[1] = e.volume;
    }
    final out = <_Gains>[];
    for (final k in byTime.keys.toList()..sort()) {
      final v = byTime[k]!;
      if (v[0] != null && v[1] != null) out.add(_Gains(k, v[0]!, v[1]!));
    }
    return out;
  }

  /// When the engine first entered [phase], or null.
  Duration? firstAt(EnginePhase phase) {
    for (final p in phases) {
      if (p.phase == phase) return p.at;
    }
    return null;
  }

  void start(List<QueueEntry> queue, FakeAsync async) {
    engine.loadQueue(queue);
    async.flushMicrotasks();
    engine.play();
    async.flushMicrotasks();
  }
}

void main() {
  group('crossfade gain law', () {
    test('equal-power crossfade holds constant power at every tick', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        final start = rig.firstAt(EnginePhase.crossfading);
        expect(start, isNotNull, reason: 'a crossfade should have happened');

        final during = rig.gains
            .where((g) => g.at >= start! && g.b > 0 && g.a > 0)
            .toList();
        expect(during.length, greaterThan(50),
            reason: 'expected many samples across a 4s fade, got ${during.length}');

        for (final g in during) {
          expect(g.power, closeTo(1.0, 0.01), reason: 'power dipped at $g');
        }
      });
    });

    test('a duck mid-crossfade preserves the ratio between the decks', () {
      List<_Gains> run({required bool duck}) {
        late List<_Gains> out;
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([_entry('one'), _entry('two')], async);

          // Reach the middle of the crossfade, then duck.
          async.elapse(const Duration(milliseconds: 8000));
          async.flushMicrotasks();
          if (duck) {
            rig.bus.announcementDuck.setImmediate(0.3);
            async.flushMicrotasks();
          }
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          out = rig.gains;
        });
        return out;
      }

      final plain = run(duck: false);
      final ducked = run(duck: true);

      var compared = 0;
      for (final p in plain) {
        final d = ducked.where((x) => x.at == p.at);
        if (d.isEmpty) continue;
        if (p.a <= 0 || p.b <= 0) continue;
        if (d.first.a <= 0 || d.first.b <= 0) continue;
        expect(d.first.a / d.first.b, closeTo(p.a / p.b, 1e-6),
            reason: 'ratio diverged at ${p.at.inMilliseconds}ms');
        compared++;
      }
      expect(compared, greaterThan(20),
          reason: 'expected a meaningful overlap to compare');
    });
  });

  group('transition timing', () {
    test('begins one crossfade before the end of the track', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([_entry('one'), _entry('two')], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        final start = rig.firstAt(EnginePhase.crossfading)!;
        expect(start.inMilliseconds, closeTo(6000, _tick.inMilliseconds),
            reason: '10s track, 4s crossfade -> starts at 6s');
      });
    });

    test('cueOut brings the transition forward', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([
          _entry('one', cueOut: const Duration(seconds: 8)),
          _entry('two'),
        ], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        final start = rig.firstAt(EnginePhase.crossfading)!;
        expect(start.inMilliseconds, closeTo(4000, _tick.inMilliseconds),
            reason: 'cueOut 8s, 4s crossfade -> starts at 4s');
      });
    });

    test('targetDuration wins when it is sooner than cueOut', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([
          _entry('one',
              cueOut: const Duration(seconds: 9),
              targetDuration: const Duration(seconds: 7)),
          _entry('two'),
        ], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        final start = rig.firstAt(EnginePhase.crossfading)!;
        expect(start.inMilliseconds, closeTo(3000, _tick.inMilliseconds),
            reason: 'effective end 7s, 4s crossfade -> starts at 3s');
      });
    });

    test('cueIn offsets the target duration', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 20));
        rig.start([
          _entry('one',
              cueIn: const Duration(seconds: 5),
              targetDuration: const Duration(seconds: 8)),
          _entry('two'),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        // Effective end is cueIn + targetDuration = 13s of deck position, and
        // the deck starts at position 5s, so 8s of playback, less the 4s fade.
        final start = rig.firstAt(EnginePhase.crossfading)!;
        expect(start.inMilliseconds, closeTo(4000, _tick.inMilliseconds));
      });
    });
  });

  group('gapless', () {
    test('a zero-length crossfade never overlaps the decks', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 5));
        rig.start([
          _entry('one', crossfade: Duration.zero),
          _entry('two', crossfade: Duration.zero),
        ], async);

        async.elapse(const Duration(seconds: 8));
        async.flushMicrotasks();

        for (final g in rig.gains) {
          expect(g.a > 0 && g.b > 0, isFalse,
              reason: 'both decks were audible at $g');
        }
      });
    });
  });

  group('role swap', () {
    test('standby becomes active, retired deck stops, index advances by one', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([_entry('one'), _entry('two')], async);

        expect(rig.engine.currentIndex, 0);
        expect(rig.a.isPlaying, isTrue, reason: 'deck A starts as active');

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.engine.currentIndex, 1, reason: 'exactly one item advanced');
        expect(rig.engine.currentEntry?.itemId, 'two');
        expect(rig.b.isPlaying, isTrue, reason: 'deck B is now the active deck');

        // Deliberately not `calls.contains('stop')`: loadQueue stops both decks
        // before it starts, so that assertion passes even if the retired deck
        // is left running. It must be stopped *after* the crossfade began.
        final crossfadeStart = rig.firstAt(EnginePhase.crossfading)!;
        expect(rig.a.calledSince('stop', crossfadeStart), isTrue,
            reason: 'the retired deck must be stopped, not left running');
        expect(rig.a.isPlaying, isFalse, reason: 'retired deck still playing');
      });
    });
  });

  group('end of queue', () {
    test('the last item fades to silence and the engine goes idle', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start([_entry('only')], async);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.idle,
            reason: 'should settle at idle, not keep ticking');

        // The last thing written to the deck must be silence, and it must have
        // arrived gradually rather than as a cut.
        final volumes = rig.a.volumeEvents.map((e) => e.volume).toList();
        expect(volumes.last, closeTo(0.0, 1e-9), reason: 'should end silent');

        final fading = rig.a.volumeEvents
            .where((e) => e.volume > 0.01 && e.volume < 0.99)
            .length;
        expect(fading, greaterThan(20),
            reason: 'expected a gradual fade, saw $fading intermediate values');
      });
    });
  });

  group('announcements', () {
    test('beforeMusic silences the music before the voice starts', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 2),
        );
        rig.start([
          _entry('one'),
          _entry('two', mode: AnnounceMode.beforeMusic, danceTypeName: 'Waltz'),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(rig.clips.rendered, contains('Next dance: Waltz'));

        final voicePlay =
            rig.voice.callEvents.firstWhere((c) => c.name == 'play').at;
        final voiceStop = rig.voice.callEvents
            .lastWhere((c) => c.name == 'stop', orElse: () => rig.voice.callEvents.last)
            .at;
        expect(voiceStop, greaterThan(voicePlay));

        // 1. The outgoing music must have reached silence before the voice began.
        final musicSilentBy = rig.a.volumeEvents
            .lastWhere((e) => e.volume > 0.001,
                orElse: () => rig.a.volumeEvents.first)
            .at;
        expect(musicSilentBy, lessThanOrEqualTo(voicePlay),
            reason: 'music was still audible when the voice began');

        // 2. The incoming deck must stay silent for the whole announcement —
        //    the point of beforeMusic is that the voice is heard clean.
        final earlyIncoming = rig.b.volumeEvents
            .where((e) => e.at <= voiceStop && e.volume > 0.001)
            .toList();
        expect(earlyIncoming, isEmpty,
            reason: 'incoming deck came up during the announcement: '
                '$earlyIncoming');

        // 3. And it must actually come up afterwards, rather than never.
        expect(rig.b.volumeEvents.any((e) => e.at > voiceStop && e.volume > 0.5),
            isTrue,
            reason: 'incoming deck never faded in after the announcement');
      });
    });

    test('duckOver dips the music and restores it', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 2),
        );
        rig.start([
          _entry('one'),
          _entry('two', mode: AnnounceMode.duckOver, danceTypeName: 'Bachata'),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        final values = rig.duckValues;
        expect(values, isNotEmpty, reason: 'the duck stage should have moved');

        final lowest = values.map((e) => e.value).reduce((x, y) => x < y ? x : y);
        expect(lowest, closeTo(0.2, 0.01), reason: 'should reach duckLevel');
        expect(values.last.value, closeTo(1.0, 1e-6),
            reason: 'should return to unity');
      });
    });

    test('a clip that cannot be read costs the announcement, not the set', () {
      // The file the operator tagged has been moved since. The transition is
      // already under way when that is discovered, so it goes ahead without a
      // voice rather than stopping in the middle of it.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.clips.throwOnProbe = true;

        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.duckOver,
              announcementClipPath: '/clips/moved.wav'),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(rig.activeItems, contains('two'),
            reason: 'the set carried on into the next track');
        expect(rig.duckValues.isEmpty || rig.duckValues.last.value == 1.0,
            isTrue,
            reason: 'the music was never left ducked for a voice that '
                'never spoke');
      });
    });

    test('and the crossfade button still works afterwards', () {
      // The flag that guards a transition has to be released on the way out of
      // a failure as well as a success. Left set, every later crossfade is a
      // silent no-op — the operator presses it in front of a room and nothing
      // happens, for the rest of the night.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.clips.throwOnProbe = true;

        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.duckOver,
              announcementClipPath: '/clips/moved.wav'),
          _entry('three',
              mode: AnnounceMode.duckOver,
              announcementClipPath: '/clips/moved.wav'),
        ], async);

        rig.engine.skipNext();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();
        expect(rig.activeItems, contains('two'));

        rig.engine.skipNext();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();
        expect(rig.activeItems, contains('three'),
            reason: 'a second crossfade after a failed announcement');
      });
    });

    test('the ducked span matches the configured envelope', () {
      fakeAsync((async) {
        const duckFade = Duration(milliseconds: 600);
        const clip = Duration(seconds: 2);
        const hold = Duration(milliseconds: 250);
        const restore = Duration(milliseconds: 900);

        final rig = _Rig(track: const Duration(seconds: 8), clip: clip);
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.duckOver,
              danceTypeName: 'Bachata',
              duckFade: duckFade,
              duckHold: hold,
              duckRestoreFade: restore),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        final moved = rig.duckValues.where((e) => e.value < 0.999).toList();
        expect(moved, isNotEmpty);

        final began = moved.first.key;
        final restored = rig.duckValues
            .lastWhere((e) => e.value < 0.999)
            .key;

        final span = restored - began;
        final expected = duckFade + clip + hold + restore;
        expect(
          (span - expected).abs(),
          lessThanOrEqualTo(_tick * 2),
          reason: 'ducked span was ${span.inMilliseconds}ms, '
              'expected ${expected.inMilliseconds}ms',
        );
      });
    });
  });

  group('resilience', () {
    test('a dead track mid-queue is skipped and the set continues', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        // Item two is a dead URL — a signed link that expired, or a volume that
        // is no longer mounted. Whichever deck ends up loading it must fail.
        rig.a.failUris.add('fake://two');
        rig.b.failUris.add('fake://two');

        rig.start(
          [_entry('one'), _entry('two'), _entry('three')],
          async,
        );
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.maxIndexSeen, 2,
            reason: 'the set should have reached the third item, not stopped '
                'at the dead one');
        expect(rig.a.calls.length + rig.b.calls.length, greaterThan(4));
      });
    });

    test('a standby deck that fails to load does not stall the set', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.b.loadError = StateError('dead url');

        rig.start([_entry('one'), _entry('two')], async);
        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        // The set must not hang mid-transition waiting on a deck that never
        // loaded; the engine should have run the first item out and settled.
        expect(rig.engine.phase, EnginePhase.idle);
      });
    });
  });

  group('pause', () {
    test('pausing mid-crossfade does not silently complete the transition', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([_entry('one'), _entry('two')], async);

        // 1s into the 4s crossfade, which begins at 6s.
        async.elapse(const Duration(milliseconds: 7000));
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.crossfading,
            reason: 'precondition: mid-crossfade');

        rig.engine.pause();
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.paused);

        // Let the crossfade's original wall-clock window pass while paused.
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.paused,
            reason: 'a paused engine must stay paused');
        expect(rig.engine.currentIndex, 0,
            reason: 'the transition must not complete while paused');
      });
    });
  });

  group('pause and resume', () {
    test('resuming after a mid-crossfade pause advances exactly once', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start(
            [_entry('one'), _entry('two'), _entry('three')], async);

        // 1s into the 4s crossfade.
        async.elapse(const Duration(milliseconds: 7000));
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.crossfading);

        rig.engine.pause();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));

        rig.engine.play();
        async.flushMicrotasks();

        // Long enough for both the abandoned fade's original deadline and the
        // retriggered one to elapse. If the abandoned transition still
        // completes, the queue advances twice for one transition.
        async.elapse(const Duration(milliseconds: 5000));
        async.flushMicrotasks();

        expect(rig.engine.currentIndex, 1,
            reason: 'one transition must advance the queue exactly one step');
      });
    });
  });

  group('stop', () {
    test('silence now, and the track back at its start for the next play', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 30));
        rig.start([_entry('one'), _entry('two')], async);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(rig.a.position, greaterThan(const Duration(seconds: 4)),
            reason: 'precondition: five seconds in');

        rig.engine.stopToCue();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.paused);
        expect(rig.a.isPlaying, isFalse);
        expect(rig.a.position, Duration.zero,
            reason: 'stop gives the position up; pause would hold it');
        // The set is still here: not torn down the way a reload does it.
        expect(rig.engine.currentEntry?.itemId, 'one');
        expect(rig.engine.standbyEntry?.itemId, 'two');
      });
    });

    test('play after stop starts the same track from the top', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 30));
        rig.start([_entry('one'), _entry('two')], async);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        rig.engine.stopToCue();
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'one');
        expect(rig.a.position.inMilliseconds, closeTo(2000, 100));
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('a stop mid-crossfade re-cues the deck that was coming in', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);

        // 1s into the 4s crossfade, which begins at 6s.
        async.elapse(const Duration(milliseconds: 7000));
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.crossfading);

        rig.engine.stopToCue();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        // The transition did not quietly complete while stopped, and the deck
        // that was coming in is back at its start with its volume down.
        expect(rig.engine.phase, EnginePhase.paused);
        expect(rig.engine.currentIndex, 0);
        expect(rig.b.position, Duration.zero);
        expect(rig.b.lastVolume, 0.0);
        expect(rig.a.lastVolume, 1.0);
      });
    });

    test('a voice mid-word is cut off', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 4),
        );
        rig.start([
          _entry('one'),
          _entry('two', mode: AnnounceMode.duckOver, danceTypeName: 'Waltz'),
        ], async);

        // The crossfade begins at 4s; the voice is speaking by 5s.
        async.elapse(const Duration(milliseconds: 5000));
        async.flushMicrotasks();
        expect(rig.voice.isPlaying, isTrue, reason: 'precondition: speaking');

        rig.engine.stopToCue();
        async.flushMicrotasks();

        expect(rig.voice.isPlaying, isFalse,
            reason: 'a stop that leaves the announcer talking is not a stop');
      });
    });

    test('with nothing loaded it is nothing', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.stopToCue();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.idle);
      });
    });
  });

  group('jumping to a row', () {
    test('with music on the floor it crossfades into the chosen row', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three'),
          _entry('four'),
        ], async);

        rig.engine.jumpTo(3);
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.crossfading,
            reason: 'through the crossfade, never a cut');

        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'four');
        expect(rig.engine.currentIndex, 3);
        // And the set carries on from there, not from where it was.
        expect(rig.engine.standbyEntry, isNull,
            reason: 'nothing after the last row');
      });
    });

    test('the row after the jump is cued behind it', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three'),
          _entry('four'),
        ], async);

        rig.engine.jumpTo(2);
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'three');
        expect(rig.engine.standbyEntry?.itemId, 'four');
      });
    });

    test('a jump carries the announcement of the row it lands on', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', mode: AnnounceMode.duckOver, danceTypeName: 'Samba'),
        ], async);

        rig.engine.jumpTo(2);
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        expect(rig.clips.rendered, contains('Next dance: Samba'));
      });
    });

    test('stopped, it becomes the track on the deck without starting', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.engine.loadQueue([_entry('one'), _entry('two'), _entry('three')]);
        async.flushMicrotasks();

        rig.engine.jumpTo(2);
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'three');
        expect(rig.engine.phase, EnginePhase.idle,
            reason: 'choosing a song is not the same as starting it');
        expect(rig.a.isPlaying, isFalse);
      });
    });

    test('paused, likewise', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);
        rig.engine.pause();
        async.flushMicrotasks();

        rig.engine.jumpTo(1);
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'two');
        expect(rig.engine.standbyEntry?.itemId, 'three');
        expect(rig.engine.phase, EnginePhase.paused);
      });
    });

    test('a row that will not load leaves the set as it was', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.b.failUris.add('fake://three');
        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three'),
          _entry('four'),
        ], async);
        expect(rig.engine.standbyEntry?.itemId, 'two');

        rig.engine.jumpTo(2);
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        // Still playing the first row, with the natural next re-cued rather
        // than an empty deck where the cued track used to be.
        expect(rig.engine.currentEntry?.itemId, 'one');
        expect(rig.engine.standbyEntry?.itemId, 'two');
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('an index off the end is ignored', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 5));
        rig.start([_entry('one'), _entry('two')], async);

        rig.engine.jumpTo(7);
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry?.itemId, 'one');
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });
  });

  group('a merge', () {
    test('is an overlap at full level, and short', () {
      const spec = TransitionSpec.merge();
      expect(spec.crossfade, TransitionSpec.mergeBlend);
      expect(spec.fadeInCurve, FadeCurve.equalPower);
      expect(spec.fadeOutCurve, FadeCurve.equalPower);
      expect(spec.isSequential, isFalse, reason: 'never music-out, music-in');
      expect(spec.isGapless, isFalse, reason: 'a blend, not a splice');
      expect(spec.merge, isTrue);
    });

    test('says nothing, even into a row that has a dance to announce', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([
          _entry('one'),
          _entry('two', merge: true, danceTypeName: 'Waltz'),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(rig.activeItems, contains('two'));
        expect(rig.clips.rendered, isEmpty,
            reason: 'the dance has not changed; there is nothing to say');
        expect(rig.duckValues, isEmpty, reason: 'nothing to duck under');
      });
    });

    test('runs the blend, not the set\'s crossfade, and starts on time', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([_entry('one'), _entry('two', merge: true)], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        // An 8s song and a 2.5s blend: the overlap begins at 5.5s, not at 4s
        // as the set's 4s crossfade would have it — the outgoing song is not
        // cut short by the difference.
        final start = rig.firstAt(EnginePhase.crossfading)!;
        expect(start.inMilliseconds,
            closeTo(8000 - TransitionSpec.mergeBlend.inMilliseconds, 100));
      });
    });

    test('holds no rotation gap, whatever the night is shaped like', () {
      // The floor is mid-dance and not changing partners: a merge inside a
      // rotation set still runs straight through.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([
          _entry('one', rotationGap: const Duration(seconds: 10)),
          _entry('two', merge: true),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(rig.phases.map((p) => p.phase), isNot(contains(EnginePhase.rotating)));
        expect(rig.activeItems, contains('two'));
      });
    });
  });

  group('gain composition', () {
    test('per-track trim scales the deck volume', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        final quiet = QueueEntry(
          itemId: 'quiet',
          media: PlayableMedia(uri: Uri.parse('fake://q'), gainDb: -6.0),
          spec: const TransitionSpec(announceMode: AnnounceMode.off),
        );
        rig.engine.loadQueue([quiet]);
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));

        expect(rig.a.lastVolume, closeTo(dbToAmplitude(-6.0), 0.01),
            reason: 'ReplayGain trim should multiply into the deck volume');
      });
    });

    test('the master fader scales playback', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([_entry('one')], async);

        rig.bus.master.setImmediate(0.5);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));

        expect(rig.a.lastVolume, closeTo(0.5, 0.01));
      });
    });
  });

  group('expiring URLs', () {
    /// Records what it was asked to refresh and hands back a fresh URL.
    ({List<String> asked, EntryRefresher refresh}) recorder() {
      final asked = <String>[];
      return (
        asked: asked,
        refresh: (entry) async {
          asked.add(entry.itemId);
          return entry.withMedia(PlayableMedia(
            uri: Uri.parse('fresh://${entry.itemId}'),
            cueIn: entry.media.cueIn,
            cueOut: entry.media.cueOut,
          ));
        },
      );
    }

    test('a URL nowhere near expiry is played untouched', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(hours: 3))),
        ], async);

        expect(r.asked, isEmpty);
        expect(rig.a.media!.uri.toString(), 'fake://one');
      });
    });

    test('a URL with no expiry at all is played untouched', () {
      // Local files and finished downloads. Nothing to refresh, and asking
      // would put a database read in front of every load.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([_entry('one')], async);

        expect(r.asked, isEmpty);
        expect(rig.a.media!.uri.toString(), 'fake://one');
      });
    });

    test('a URL about to expire is re-resolved before it reaches a deck', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(seconds: 30))),
        ], async);

        expect(r.asked, ['one']);
        expect(rig.a.media!.uri.toString(), 'fresh://one');
      });
    });

    test('the standby deck is refreshed too, not just the audible one', () {
      // The standby entry is the one most likely to go stale: it was resolved
      // when the set was built and does not play for another four minutes.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([
          _entry('one'),
          _entry('two', expiresAt: clock.now().add(const Duration(seconds: 10))),
        ], async);

        expect(r.asked, ['two']);
        expect(rig.b.media!.uri.toString(), 'fresh://two');
      });
    });

    test('the refreshed entry is what the engine reports playing', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(seconds: 5))),
        ], async);

        expect(rig.engine.currentEntry!.media.uri.toString(), 'fresh://one');
        expect(rig.engine.currentEntry!.itemId, 'one');
      });
    });

    test('a refresh that fails leaves the set playing what it had', () {
      // The URL in hand is about to expire, not expired. Playing it beats a
      // hole in the set, and it may well outlast the track.
      fakeAsync((async) {
        final rig = _Rig(
          refresh: (entry) async => throw StateError('server unreachable'),
        );
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(seconds: 5))),
        ], async);

        expect(rig.a.media!.uri.toString(), 'fake://one');
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('with no refresher the engine plays exactly what it was handed', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(seconds: 5))),
        ], async);

        expect(rig.a.media!.uri.toString(), 'fake://one');
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('a refresh happens once per load, not once per tick', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);
        rig.start([
          _entry('one', expiresAt: clock.now().add(const Duration(seconds: 30))),
        ], async);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(r.asked, ['one']);
      });
    });
  });

  group('look-ahead', () {
    /// Records what it was asked to refresh and hands back a URL with no
    /// expiry, so a second refresh of the same row is visible as a second ask.
    ({List<String> asked, EntryRefresher refresh}) recorder({
      Set<String> failFirst = const {},
    }) {
      final asked = <String>[];
      final failed = <String>{};
      return (
        asked: asked,
        refresh: (entry) async {
          asked.add(entry.itemId);
          if (failFirst.contains(entry.itemId) && failed.add(entry.itemId)) {
            throw StateError('server unreachable');
          }
          return entry.withMedia(PlayableMedia(
            uri: Uri.parse('fresh://${entry.itemId}'),
            cueIn: entry.media.cueIn,
            cueOut: entry.media.cueOut,
          ));
        },
      );
    }

    /// Long enough to outlive the audible track and the one cued behind it,
    /// which is the window the look-ahead asks about.
    DateTime soon() => clock.now().add(const Duration(seconds: 15));

    test('the row after standby is resolved while the current one plays', () {
      // The refresh at load time runs with the transition latch held, so on a
      // venue's wifi it is seconds in which skipNext does nothing at all. This
      // is that work moved into the middle of a track.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: soon()),
        ], async);

        expect(r.asked, ['three']);

        // Resolved, not buffered. There are two decks and both are spoken for.
        expect(rig.a.media!.uri.toString(), 'fake://one');
        expect(rig.b.media!.uri.toString(), 'fake://two');
      });
    });

    test('and it is not resolved again when it reaches a deck', () {
      // Moving the work, not adding to it.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: soon()),
        ], async);
        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        expect(r.asked, ['three']);
        expect(
          [rig.a.media!.uri.toString(), rig.b.media!.uri.toString()],
          contains('fresh://three'),
        );
      });
    });

    test('a URL that will outlast its turn is left alone', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: clock.now().add(const Duration(hours: 3))),
        ], async);

        expect(r.asked, isEmpty);
      });
    });

    test('a set of local files never asks', () {
      // No expiry on any of them, so there is nothing a look-ahead could do
      // but put a database read in front of every transition.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([_entry('one'), _entry('two'), _entry('three')], async);
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(r.asked, isEmpty);
      });
    });

    test('the end of the set is not looked past', () {
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([_entry('one'), _entry('two', expiresAt: soon())], async);

        // 'two' is standby, so it was refreshed on load; there is no row after
        // it to look ahead to.
        expect(r.asked, ['two']);
        expect(rig.engine.phase, EnginePhase.playing);
      });
    });

    test('a look-ahead that fails leaves the load-time refresh to try again',
        () {
      fakeAsync((async) {
        final r = recorder(failFirst: {'three'});
        final rig = _Rig(refresh: r.refresh);

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: soon()),
        ], async);
        expect(r.asked, ['three'], reason: 'the early attempt, which threw');

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        expect(r.asked, ['three', 'three']);
        expect(
          [rig.a.media!.uri.toString(), rig.b.media!.uri.toString()],
          contains('fresh://three'),
        );
      });
    });

    test('reloading the set discards what was resolved for the old one', () {
      // The look-ahead is keyed by index, and index 2 means something else
      // entirely once a different set is open.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(refresh: r.refresh);

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: soon()),
        ], async);
        expect(r.asked, ['three']);

        rig.engine.loadQueue([
          _entry('alpha'),
          _entry('beta'),
          _entry('gamma'),
        ]);
        async.flushMicrotasks();
        rig.engine.play();
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.activeItems, isNot(contains('three')));
        expect(rig.activeItems.last, 'gamma');
      });
    });

    test('a row the preload skipped does not misdirect what was resolved', () {
      // The look-ahead was aimed at 'three'. 'three' turns out to be dead, so
      // preload settles on 'four' instead — which must be loaded from the
      // queue, not from the entry resolved for a different row.
      fakeAsync((async) {
        final r = recorder();
        final rig = _Rig(track: const Duration(seconds: 6), refresh: r.refresh);
        for (final deck in [rig.a, rig.b]) {
          deck.failUris.addAll(['fake://three', 'fresh://three']);
        }

        rig.start([
          _entry('one'),
          _entry('two'),
          _entry('three', expiresAt: soon()),
          _entry('four'),
        ], async);

        // Just past the first transition, which is where preload walks past
        // the dead row and settles on the next one.
        async.elapse(const Duration(seconds: 7));
        async.flushMicrotasks();

        expect(rig.engine.standbyEntry!.itemId, 'four');
        expect(rig.engine.standbyEntry!.media.uri.toString(), 'fake://four');
      });
    });
  });

  group('the crossfader', () {
    /// Fader position, applied and settled.
    void drag(_Rig rig, FakeAsync async, double aToB) {
      rig.engine.setCrossfader(aToB);
      async.flushMicrotasks();
    }

    test('dragging off the end starts the deck that is cued up', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);
        expect(rig.b.calls, isNot(contains('play')));

        drag(rig, async, 0.3);

        expect(rig.engine.isManualFade, isTrue);
        expect(rig.b.calls, contains('play'));
        expect(rig.b.volumeEvents.last.volume, greaterThan(0));
      });
    });

    test('the gains follow the fader through the configured curve', () {
      // Equal power at the centre: both decks at 1/root-2, which is the
      // property that removes the hole in the middle of a transition.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        drag(rig, async, 0.5);

        expect(rig.a.volumeEvents.last.volume, closeTo(0.7071, 0.001));
        expect(rig.b.volumeEvents.last.volume, closeTo(0.7071, 0.001));
      });
    });

    test('reaching the far end completes the handover', () {
      // The same end state an automatic crossfade leaves, so the set carries
      // on from there rather than needing a nudge.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);

        drag(rig, async, 1.0);

        expect(rig.engine.isManualFade, isFalse);
        expect(rig.engine.activeIsA, isFalse, reason: 'B is audible now');
        expect(rig.engine.currentEntry!.itemId, 'two');
        expect(rig.engine.phase, EnginePhase.playing);
        // And the next row is cued up behind it.
        expect(rig.engine.standbyEntry!.itemId, 'three');
      });
    });

    test('dragging back re-cues the deck that was coming up', () {
      // Not left eight seconds in: the next transition has to start that row
      // at the top.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        drag(rig, async, 0.4);
        async.elapse(const Duration(seconds: 3));
        drag(rig, async, 0.0);

        expect(rig.engine.isManualFade, isFalse);
        expect(rig.engine.phase, EnginePhase.playing);
        expect(rig.engine.activeIsA, isTrue, reason: 'no handover happened');
        expect(rig.b.calls, contains('seek'));
        expect(rig.b.position, Duration.zero);
        expect(rig.a.volumeEvents.last.volume, closeTo(1.0, 0.001));
      });
    });

    test('grabbing it mid-transition takes over from the timer', () {
      // The moment a DJ actually reaches for it: the automatic fade started
      // while the floor still had eight bars left in it.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 10));
        rig.start([_entry('one'), _entry('two')], async);

        async.elapse(const Duration(seconds: 7));
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.crossfading,
            reason: 'the automatic transition should have begun');

        drag(rig, async, 0.5);
        final held = rig.a.volumeEvents.last.volume;

        // The timer would have finished the fade and retired deck A by now.
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.engine.isManualFade, isTrue);
        expect(rig.engine.activeIsA, isTrue, reason: 'no handover happened');
        expect(rig.a.volumeEvents.last.volume, closeTo(held, 0.001));
      });
    });

    test('the set does not run on underneath the operator', () {
      // Holding the fader half way is a decision, not a stall. Nothing may
      // start a second transition behind it.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 4));
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);

        drag(rig, async, 0.5);
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry!.itemId, 'one');
        expect(rig.engine.isManualFade, isTrue);
      });
    });

    test('A-left B-right, whichever deck happens to be audible', () {
      // The two swap roles at every transition. After one handover, dragging
      // back toward A is dragging toward the deck that is now on standby.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);

        drag(rig, async, 1.0);
        expect(rig.engine.activeIsA, isFalse);

        // Deck A played the first track and has since been re-loaded as the
        // standby. Only what happens from here is the subject.
        rig.a.callEvents.clear();
        rig.b.callEvents.clear();

        // Toward A is now toward the deck on standby, so this is a fade, not
        // a return to where the fader already was.
        drag(rig, async, 0.0);

        expect(rig.a.calls, contains('play'),
            reason: 'dragging to A should bring deck A up, not deck B');
        expect(rig.engine.activeIsA, isTrue);
        expect(rig.engine.currentEntry!.itemId, 'three');
      });
    });

    test('with nothing cued up there is nothing to fade to', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one')], async);

        drag(rig, async, 1.0);

        expect(rig.engine.isManualFade, isFalse);
        expect(rig.engine.phase, EnginePhase.playing);
        expect(rig.engine.currentEntry!.itemId, 'one');
      });
    });

    test('a paused set is not started by the fader', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);
        rig.engine.pause();
        async.flushMicrotasks();

        drag(rig, async, 0.6);

        expect(rig.engine.isManualFade, isFalse);
        expect(rig.engine.phase, EnginePhase.paused);
      });
    });

    test('pausing gives the fader back', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);
        drag(rig, async, 0.5);

        rig.engine.pause();
        async.flushMicrotasks();

        expect(rig.engine.isManualFade, isFalse);
      });
    });

    group('the announcement', () {
      test('plays once the fade is past centre', () {
        // At a ballroom event the floor not being told the next dance is a
        // functional failure, whichever control the operator used.
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([
            _entry('one'),
            _entry('two', mode: AnnounceMode.duckOver, danceTypeName: 'Waltz'),
          ], async);

          drag(rig, async, 0.6);
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          // Not `clips.rendered`: the engine pre-renders every standby clip
          // at preload time whether or not it is ever spoken. The voice deck
          // is what says the room heard it.
          expect(rig.voice.calls, contains('play'));
          expect(rig.duckValues.map((e) => e.value).any((v) => v < 0.5), isTrue,
              reason: 'the music should have dipped under the voice');
        });
      });

      test('a nudge short of centre does not trigger one', () {
        // Otherwise brushing the fader announces the next dance to the room.
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([
            _entry('one'),
            _entry('two', mode: AnnounceMode.duckOver, danceTypeName: 'Waltz'),
          ], async);

          drag(rig, async, 0.2);
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          expect(rig.voice.calls, isNot(contains('play')));
        });
      });

      test('beforeMusic degrades to ducking rather than being dropped', () {
        // It wants silence, a clean voice, then music. The operator is already
        // mixing the two together, so the clean-voice half is not available.
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([
            _entry('one'),
            _entry('two',
                mode: AnnounceMode.beforeMusic, danceTypeName: 'Tango'),
          ], async);

          drag(rig, async, 0.7);
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          expect(rig.voice.calls, contains('play'));
          // The outgoing deck never went silent: this is an overlap, not the
          // sequential form.
          expect(rig.a.volumeEvents.last.volume, greaterThan(0.0));
        });
      });

      test('a row set to no announcement stays silent', () {
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([
            _entry('one'),
            _entry('two', mode: AnnounceMode.off, danceTypeName: 'Waltz'),
          ], async);

          drag(rig, async, 0.8);
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          expect(rig.voice.calls, isNot(contains('play')));
        });
      });

      test('it is announced once, not on every pixel of the drag', () {
        fakeAsync((async) {
          final rig = _Rig();
          rig.start([
            _entry('one'),
            _entry('two', mode: AnnounceMode.duckOver, danceTypeName: 'Waltz'),
          ], async);

          for (var i = 5; i <= 9; i++) {
            drag(rig, async, i / 10);
          }
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          expect(rig.voice.calls.where((c) => c == 'play').length, 1);
        });
      });
    });
  });

  group('the shape of a set', () {
    test('a song limit stops the set after that many, mid-playlist', () {
      // "Play exactly three and stop", over a playlist of six.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.engine.loadQueue(
          [for (var i = 1; i <= 6; i++) _entry('t$i')],
          songLimit: 3,
        );
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        expect(rig.engine.songsPlayed, 3);
        expect(rig.activeItems, ['t1', 't2', 't3']);
        expect(rig.engine.phase, EnginePhase.idle);
      });
    });

    test('it fades out rather than cutting to silence', () {
      // Same path the end of a playlist takes. A hard cut on a full floor is
      // the thing the whole engine exists to avoid.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.engine.loadQueue([_entry('one'), _entry('two')], songLimit: 1);
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.firstAt(EnginePhase.fadingOut), isNotNull);
        expect(rig.engine.phase, EnginePhase.idle);
      });
    });

    test('a limit of one plays one song and nothing is ever cued behind it',
        () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.loadQueue([_entry('one'), _entry('two')], songLimit: 1);
        async.flushMicrotasks();

        expect(rig.engine.currentEntry!.itemId, 'one');
        expect(rig.engine.standbyEntry, isNull);
        expect(rig.b.calls, isNot(contains('load')));
      });
    });

    test('skipping does not get past the limit', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.loadQueue(
          [_entry('one'), _entry('two'), _entry('three')],
          songLimit: 2,
        );
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();

        // Long enough to settle the crossfade, short enough that the second
        // track has not run itself out.
        rig.engine.skipNext();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(rig.engine.currentEntry!.itemId, 'two');

        rig.engine.skipNext();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.idle);
        expect(rig.activeItems, ['one', 'two']);
      });
    });

    test('no limit plays the whole list', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start([_entry('one'), _entry('two'), _entry('three')], async);

        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();

        expect(rig.activeItems, ['one', 'two', 'three']);
      });
    });

    test('a limit counts songs played, not rows of the playlist', () {
      // Starting a six-row set at row three with a limit of two plays two
      // songs, not none.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.engine.loadQueue(
          [for (var i = 1; i <= 6; i++) _entry('t$i')],
          startIndex: 2,
          songLimit: 2,
        );
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();

        expect(rig.activeItems, ['t3', 't4']);
      });
    });

    test('the readout counts from zero before anything starts', () {
      fakeAsync((async) {
        final rig = _Rig();
        expect(rig.engine.songsPlayed, 0);

        rig.engine.loadQueue([_entry('one'), _entry('two')], songLimit: 5);
        async.flushMicrotasks();

        expect(rig.engine.songsPlayed, 1);
        expect(rig.engine.songLimit, 5);
      });
    });

    test('a per-song cap hands over early, without trimming the file', () {
      // "Two minutes of every track": the deck still holds a four-minute file,
      // and the transition comes at two.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(minutes: 4));
        rig.start([
          _entry('one',
              targetDuration: const Duration(seconds: 20),
              crossfade: const Duration(seconds: 2)),
          _entry('two'),
        ], async);

        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();
        expect(rig.engine.currentEntry!.itemId, 'one',
            reason: 'still inside the capped span');
        expect(rig.a.duration, const Duration(minutes: 4),
            reason: 'the deck still holds the whole file; the cap is a hand-'
                'over point, not a trim');

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry!.itemId, 'two');
      });
    });
  });

  group('partner rotation', () {
    test('the music stops, the floor is told, and then it waits', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 2),
        );
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.beforeMusic,
              danceTypeName: 'Waltz',
              rotationGap: const Duration(seconds: 6)),
        ], async);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        final order = [for (final p in rig.phases) p.phase];
        expect(
          order,
          containsAllInOrder([
            EnginePhase.fadingOut,
            EnginePhase.announcing,
            EnginePhase.rotating,
            EnginePhase.crossfading,
          ]),
          reason: 'music out, chime, wait, music in — in that order',
        );
      });
    });

    test('nothing is audible for the whole gap', () {
      // The point of the thing. A rotation under a track still playing is not
      // a rotation.
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 1),
        );
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.off,
              rotationGap: const Duration(seconds: 5)),
        ], async);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        final gapStart = rig.firstAt(EnginePhase.rotating)!;
        final musicBack = rig.firstAt(EnginePhase.crossfading)!;

        final audible = [
          ...rig.a.volumeEvents,
          ...rig.b.volumeEvents,
        ].where((e) => e.at >= gapStart && e.at < musicBack && e.volume > 0.001);

        expect(audible, isEmpty, reason: 'sound during the gap: $audible');
      });
    });

    test('the gap lasts as long as it was told to', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 1),
        );
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.off,
              rotationGap: const Duration(seconds: 6)),
        ], async);

        async.elapse(const Duration(seconds: 40));
        async.flushMicrotasks();

        final gapStart = rig.firstAt(EnginePhase.rotating)!;
        final musicBack = rig.firstAt(EnginePhase.crossfading)!;

        expect((musicBack - gapStart).inMilliseconds,
            closeTo(const Duration(seconds: 6).inMilliseconds, 100));
      });
    });

    test('a gap forces the sequential shape even on an overlapping row', () {
      // There is nowhere to put a silence inside a crossfade.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.duckOver,
              rotationGap: const Duration(seconds: 3)),
        ], async);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.firstAt(EnginePhase.rotating), isNotNull);
        // The outgoing deck reached silence before the incoming one came up,
        // which an overlap never does.
        final aSilent = rig.a.volumeEvents
            .lastWhere((e) => e.volume > 0.001)
            .at;
        final bUp = rig.b.volumeEvents.firstWhere((e) => e.volume > 0.001).at;
        expect(aSilent, lessThan(bUp));
      });
    });

    test('no gap leaves an ordinary set exactly as it was', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 8));
        rig.start([_entry('one'), _entry('two', mode: AnnounceMode.off)], async);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.firstAt(EnginePhase.rotating), isNull);
      });
    });

    test('pausing during the gap stops the next song starting behind it', () {
      // The operator pressed pause in the silence. Coming back eight seconds
      // later to find the set had carried on regardless is the failure.
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 8),
          clip: const Duration(seconds: 1),
        );
        rig.start([
          _entry('one'),
          _entry('two',
              mode: AnnounceMode.off,
              rotationGap: const Duration(seconds: 10)),
        ], async);

        // Into the gap, then pause.
        while (rig.engine.phase != EnginePhase.rotating) {
          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();
        }
        rig.engine.pause();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.paused);
        expect(rig.engine.currentEntry!.itemId, 'one',
            reason: 'the next song must not have started by itself');
      });
    });

    test('a rotation counts against the song limit like any other song', () {
      fakeAsync((async) {
        final rig = _Rig(
          track: const Duration(seconds: 6),
          clip: const Duration(seconds: 1),
        );
        rig.engine.loadQueue(
          [
            for (var i = 1; i <= 5; i++)
              _entry('t$i',
                  mode: AnnounceMode.off,
                  rotationGap: const Duration(seconds: 2)),
          ],
          songLimit: 3,
        );
        async.flushMicrotasks();
        rig.engine.play();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        expect(rig.activeItems, ['t1', 't2', 't3']);
        expect(rig.engine.phase, EnginePhase.idle);
      });
    });
  });

  group('continuous flow', () {
    /// A set with no crossfade and nothing spoken between tracks.
    List<QueueEntry> flowing(List<String> ids) => [
          for (final id in ids)
            _entry(id, crossfade: Duration.zero, mode: AnnounceMode.off),
        ];

    test('the next track is at full level before it starts', () {
      // The whole of gapless. Bringing the deck up after it has started leaves
      // it playing silence for a platform round-trip — and the outgoing deck
      // has already been stopped by then.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start(flowing(['one', 'two']), async);

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        final started = rig.b.callEvents.firstWhere((c) => c.name == 'play');
        final atLevel =
            rig.b.volumeEvents.firstWhere((e) => e.volume > 0.001);

        expect(atLevel.seq, lessThan(started.seq),
            reason: 'the deck came up to level only after it was playing');
      });
    });

    test('the outgoing deck is stopped, not left running underneath', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start(flowing(['one', 'two']), async);

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(rig.a.volumeEvents.last.volume, 0.0);
        expect([for (final c in rig.a.callEvents) c.name], contains('stop'));
      });
    });

    test('no ramp happens at all', () {
      // A crossfade of zero must not become a very fast crossfade: there is
      // no intermediate gain either deck should ever be written at.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start(flowing(['one', 'two']), async);

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        final partial = [
          ...rig.a.volumeEvents,
          ...rig.b.volumeEvents,
        ].where((e) => e.volume > 0.001 && e.volume < 0.999);

        expect(partial, isEmpty, reason: 'intermediate gains: $partial');
      });
    });

    test('the set runs straight through several tracks', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 4));
        rig.start(flowing(['one', 'two', 'three', 'four']), async);

        async.elapse(const Duration(seconds: 40));
        async.flushMicrotasks();

        expect(rig.activeItems, ['one', 'two', 'three', 'four']);
      });
    });

    test('the handoff lands at the end of the track, not before it', () {
      // A gapless set is trimmed by nothing: the transition is due at the
      // boundary and within one tick of it.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start(flowing(['one', 'two']), async);

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        final handoff = rig.b.callEvents.firstWhere((c) => c.name == 'play').at;
        expect(handoff.inMilliseconds,
            closeTo(const Duration(seconds: 6).inMilliseconds, 40));
      });
    });

    test('a rotation gap still wins over a zero crossfade', () {
      // Both are "no crossfade", and the rotation is the one with something to
      // say about what happens in between.
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.start([
          _entry('one', crossfade: Duration.zero, mode: AnnounceMode.off),
          _entry('two',
              crossfade: Duration.zero,
              mode: AnnounceMode.off,
              rotationGap: const Duration(seconds: 3)),
        ], async);

        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(rig.firstAt(EnginePhase.rotating), isNotNull);
      });
    });
  });


  group('building a set by hand', () {
    // Found by running the app: adding tracks to an empty playlist left every
    // deck empty, so the transport did nothing at all. It is the first thing
    // anyone does.
    test('the first track added reaches a deck', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.loadQueue([]);
        async.flushMicrotasks();

        rig.engine.appendToQueue(_entry('one'));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry!.itemId, 'one');
        expect(rig.a.media!.uri.toString(), 'fake://one');
      });
    });

    test('and it can then actually be played', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.loadQueue([]);
        async.flushMicrotasks();
        rig.engine.appendToQueue(_entry('one'));
        async.flushMicrotasks();

        rig.engine.play();
        async.flushMicrotasks();

        expect(rig.engine.phase, EnginePhase.playing);
        expect(rig.a.calls, contains('play'));
      });
    });

    test('the second is cued up behind it before anything starts', () {
      // Otherwise the set runs out after one track: the transition finds no
      // standby and fades to silence.
      fakeAsync((async) {
        final rig = _Rig();
        rig.engine.loadQueue([]);
        async.flushMicrotasks();

        rig.engine.appendToQueue(_entry('one'));
        async.flushMicrotasks();
        rig.engine.appendToQueue(_entry('two'));
        async.flushMicrotasks();

        expect(rig.engine.standbyEntry!.itemId, 'two');
      });
    });

    test('a set built cold plays all the way through', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 6));
        rig.engine.loadQueue([]);
        async.flushMicrotasks();

        for (final id in ['one', 'two', 'three']) {
          rig.engine.appendToQueue(_entry(id));
          async.flushMicrotasks();
        }

        rig.engine.play();
        async.elapse(const Duration(seconds: 40));
        async.flushMicrotasks();

        expect(rig.activeItems, ['one', 'two', 'three']);
      });
    });

    test('appending to a running set still does not disturb the cued deck', () {
      // The behaviour that was already right and has to stay that way.
      fakeAsync((async) {
        final rig = _Rig();
        rig.start([_entry('one'), _entry('two')], async);

        final cued = rig.b.media;
        rig.engine.appendToQueue(_entry('three'));
        async.flushMicrotasks();

        expect(rig.b.media, same(cued));
      });
    });

    test('a set that ran out picks up something appended after it', () {
      fakeAsync((async) {
        final rig = _Rig(track: const Duration(seconds: 4));
        rig.start([_entry('one')], async);
        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();
        expect(rig.engine.phase, EnginePhase.idle);

        rig.engine.appendToQueue(_entry('two'));
        async.flushMicrotasks();

        expect(rig.engine.currentEntry!.itemId, 'two');
      });
    });
  });

}






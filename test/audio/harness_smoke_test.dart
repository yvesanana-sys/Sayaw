import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/deck.dart';
import 'package:sayaw/audio/gain_bus.dart';

import '../fakes/fake_deck.dart';

/// A 6-second track with a 4-second crossfade: the transition begins at 2s and
/// the whole scenario needs 8 seconds of virtual time.
const _trackLength = Duration(seconds: 6);
const _crossfade = Duration(seconds: 4);
const _virtualSpan = Duration(seconds: 8);

QueueEntry _entry(String id) => QueueEntry(
      itemId: id,
      media: PlayableMedia(uri: Uri.parse('fake://$id')),
      spec: const TransitionSpec(
        crossfade: _crossfade,
        announceMode: AnnounceMode.off,
      ),
      title: id,
    );

/// Outcome of one fully simulated crossfade.
class _Outcome {
  _Outcome(this.a, this.b, this.index);
  final FakeDeck a;
  final FakeDeck b;
  final int index;
}

/// Plays a two-item queue through one complete crossfade in virtual time.
_Outcome _crossfadeOnce() {
  late _Outcome outcome;

  fakeAsync((async) {
    final a = FakeDeck('A', trackDuration: _trackLength);
    final b = FakeDeck('B', trackDuration: _trackLength);
    final engine = CrossfadeEngine(
      deckA: a,
      deckB: b,
      bus: MusicGainBus(),
      announcements: AnnouncementEngine(
        voiceDeck: FakeDeck('voice'),
        cacheDirectory: '/nonexistent',
        settings: const TtsVoiceSettings(),
      ),
    );

    engine.loadQueue([_entry('one'), _entry('two')]);
    async.flushMicrotasks();

    engine.play();
    async.flushMicrotasks();

    async.elapse(_virtualSpan);
    async.flushMicrotasks();

    outcome = _Outcome(a, b, engine.currentIndex);
    engine.dispose();
  });

  return outcome;
}

void main() {
  // AnnouncementEngine builds a FlutterTts in a field initializer, which
  // registers a MethodChannel handler and so needs a binding. Nothing in these
  // tests ever speaks — Prompt 1b replaces this with a proper seam.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a 4-second crossfade runs to completion in virtual time', () {
    final r = _crossfadeOnce();

    expect(r.index, 1, reason: 'should have advanced exactly one item');
    expect(r.b.volumeEvents, isNotEmpty,
        reason: 'the incoming deck should have been ramped up');
    expect(r.a.calls, contains('stop'),
        reason: 'the retired deck should have been stopped');
  });

  test('virtual time massively outruns wall time', () {
    // The point of the harness: a 4-second crossfade must not cost 4 seconds.
    //
    // Asserted as a ratio rather than a fixed millisecond budget on purpose. An
    // absolute bound encodes the speed of whichever machine it was written on —
    // measured here at 16ms best case, with a tail past 60ms under CPU
    // contention and 80-170ms on the first run of a process while the VM JITs
    // the engine.
    //
    // The bound is 20x rather than the ~400x actually observed, so that a cold,
    // contended CI box still passes. Anything approaching 1x would mean virtual
    // time had stopped being virtual, which is the regression worth catching.
    const minSpeedup = 20;

    final wall = Stopwatch()..start();
    final r = _crossfadeOnce();
    wall.stop();

    expect(r.index, 1, reason: 'the measured run must be a real crossfade');
    expect(
      wall.elapsedMicroseconds * minSpeedup,
      lessThan(_virtualSpan.inMicroseconds),
      reason: 'expected >${minSpeedup}x speedup, got '
          '${(_virtualSpan.inMicroseconds / wall.elapsedMicroseconds).round()}x',
    );
  });

  test('clock.now() is driven by FakeAsync, not the wall clock', () {
    fakeAsync((async) {
      final start = clock.now();
      async.elapse(const Duration(hours: 3));
      expect(clock.now().difference(start), const Duration(hours: 3));
    });
  });
}

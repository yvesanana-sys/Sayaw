import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/gain_bus.dart';
import 'package:sayaw/audio/soundboard.dart';

import '../fakes/fake_deck.dart';

const _whistle = SoundCue(
  id: 'whistle',
  label: 'Whistle',
  filePath: '/fx/whistle.wav',
);

const _spoken = SoundCue(
  id: 'tag',
  label: 'Tag!',
  filePath: '/fx/tag.wav',
  duckLevel: 0.3,
  duckFade: Duration(milliseconds: 100),
  restoreFade: Duration(milliseconds: 200),
);

class _Rig {
  _Rig({Duration cue = const Duration(seconds: 1)}) {
    deck = FakeDeck('cue', trackDuration: cue);
    bus = MusicGainBus();
    board = Soundboard(cueDeck: deck, bus: bus);
    bus.manualDuck.changes.listen(manualDuck.add);
    bus.announcementDuck.changes.listen(announcementDuck.add);
  }

  late final FakeDeck deck;
  late final MusicGainBus bus;
  late final Soundboard board;

  final manualDuck = <double>[];
  final announcementDuck = <double>[];
}

void main() {
  group('firing a cue', () {
    test('it plays, without anything being told to stop', () {
      // The whole point of a tag call: the floor does not stop.
      fakeAsync((async) {
        final rig = _Rig();

        rig.board.fire(_whistle);
        async.flushMicrotasks();

        expect(rig.deck.media!.uri.toString(), 'file:///fx/whistle.wav');
        expect(rig.deck.calls, contains('play'));
      });
    });

    test('a whistle leaves the music completely alone', () {
      // It is louder than the mix and cuts through on its own. Dipping for it
      // would announce the cue before the cue does.
      fakeAsync((async) {
        final rig = _Rig();

        rig.board.fire(_whistle);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(rig.manualDuck, isEmpty);
        expect(rig.bus.manualDuck.value, 1.0);
      });
    });

    test('a spoken cue dips the music and puts it back', () {
      fakeAsync((async) {
        final rig = _Rig();

        rig.board.fire(_spoken);
        async.elapse(const Duration(milliseconds: 150));
        async.flushMicrotasks();
        expect(rig.bus.manualDuck.value, closeTo(0.3, 0.05));

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(rig.bus.manualDuck.value, closeTo(1.0, 0.001));
      });
    });

    test('it finishes and stops itself', () {
      fakeAsync((async) {
        final rig = _Rig(cue: const Duration(milliseconds: 500));

        rig.board.fire(_whistle);
        expect(rig.board.isSounding, isTrue);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(rig.board.isSounding, isFalse);
        expect(rig.deck.calls, contains('stop'));
      });
    });
  });

  group('what it must not disturb', () {
    test('it never touches the announcement duck', () {
      // Two ducks sharing a stage is the bug this separation exists to
      // prevent: the cue's restore would bring the music up underneath a
      // voice that is still speaking.
      fakeAsync((async) {
        final rig = _Rig();

        rig.board.fire(_spoken);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(rig.announcementDuck, isEmpty);
      });
    });

    test('a cue that cannot be loaded does not leave the music dipped', () {
      // A file the operator has since moved. The dip would otherwise stay
      // down with nothing on screen saying why.
      fakeAsync((async) {
        final rig = _Rig();
        rig.deck.loadError = StateError('no such file');

        rig.board.fire(_spoken);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(rig.bus.manualDuck.value, closeTo(1.0, 0.001));
        expect(rig.board.isSounding, isFalse);
      });
    });

    test('and it answers rather than throwing', () {
      // This is called from a button and left unawaited. An exception there is
      // an unhandled async error that the operator never finds out about,
      // which is the worst of both: no sound and no explanation.
      fakeAsync((async) {
        final rig = _Rig();
        rig.deck.loadError = StateError('no such file');

        bool? sounded;
        rig.board.fire(_whistle).then((value) => sounded = value);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(sounded, isFalse);
      });
    });

    test('a cue that did sound says so', () {
      fakeAsync((async) {
        final rig = _Rig(cue: const Duration(milliseconds: 200));

        bool? sounded;
        rig.board.fire(_whistle).then((value) => sounded = value);
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(sounded, isTrue);
      });
    });
  });

  group('pressing it twice', () {
    test('the second press restarts the cue', () {
      // One deck cannot overlap itself, and twice on the whistle means twice.
      fakeAsync((async) {
        final rig = _Rig(cue: const Duration(seconds: 2));

        rig.board.fire(_whistle);
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        rig.deck.callEvents.clear();
        rig.board.fire(_whistle);
        async.flushMicrotasks();

        expect(rig.deck.calls, containsAllInOrder(['stop', 'load', 'play']));
      });
    });

    test('the first press does not bring the music up under the second', () {
      // The generation check. Without it the superseded cue's restore fires
      // mid-way through the live one.
      fakeAsync((async) {
        final rig = _Rig(cue: const Duration(seconds: 2));

        rig.board.fire(_spoken);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        rig.board.fire(_spoken);
        // Past where the first cue would have finished and restored, but well
        // inside the second.
        async.elapse(const Duration(milliseconds: 1400));
        async.flushMicrotasks();

        expect(rig.bus.manualDuck.value, closeTo(0.3, 0.05),
            reason: 'the music came back up under a cue still sounding');
      });
    });
  });

  test('silencing it brings the music straight back', () {
    fakeAsync((async) {
      final rig = _Rig(cue: const Duration(seconds: 10));

      rig.board.fire(_spoken);
      async.elapse(const Duration(milliseconds: 200));
      async.flushMicrotasks();

      rig.board.silence();
      async.flushMicrotasks();

      expect(rig.bus.manualDuck.value, 1.0);
      expect(rig.board.isSounding, isFalse);
    });
  });

  test('a cue whose length the deck cannot report is assumed short', () {
    // Holding the music down for an unknown length on a guess is the worse
    // failure of the two.
    expect(Soundboard.assumedLength, lessThan(const Duration(seconds: 5)));
  });
}

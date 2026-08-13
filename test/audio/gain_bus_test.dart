import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/fade_curves.dart';
import 'package:sayaw/audio/gain_bus.dart';

void main() {
  group('GainStage', () {
    test('setImmediate cancels an in-flight ramp and completes its future', () {
      fakeAsync((async) {
        final stage = GainStage('test');
        var done = false;
        stage.rampTo(0.0, const Duration(seconds: 2)).then((_) => done = true);

        async.elapse(const Duration(seconds: 1));
        expect(stage.value, closeTo(0.5, 0.02), reason: 'halfway down');

        stage.setImmediate(0.9);
        async.flushMicrotasks();

        expect(stage.value, 0.9);
        expect(done, isTrue, reason: 'the abandoned ramp must not hang');

        // The cancelled timer must not keep writing.
        async.elapse(const Duration(seconds: 2));
        expect(stage.value, 0.9);
      });
    });

    test('a ramp interrupted by a second starts from the current value', () {
      fakeAsync((async) {
        final stage = GainStage('test');
        var firstDone = false;
        stage
            .rampTo(0.0, const Duration(seconds: 2))
            .then((_) => firstDone = true);

        // Halfway down: 1.0 -> 0.0 on an sCurve is 0.5 at the midpoint.
        async.elapse(const Duration(seconds: 1));
        final interruptedAt = stage.value;
        expect(interruptedAt, closeTo(0.5, 0.02));

        stage.rampTo(1.0, const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(firstDone, isTrue,
            reason: "the interrupted ramp's future must still complete");

        // Had it restarted from the original 1.0 it would already be at 1.0
        // and never move. It should instead climb from ~0.5.
        async.elapse(const Duration(milliseconds: 500));
        final midway = stage.value;
        expect(midway, greaterThan(interruptedAt),
            reason: 'should be climbing from the interrupted value');
        expect(midway, lessThan(1.0), reason: 'should not have jumped to target');
        expect(midway, closeTo(0.75, 0.03),
            reason: '0.5 + (1.0 - 0.5) * sCurve(0.5)');

        async.elapse(const Duration(milliseconds: 500));
        expect(stage.value, closeTo(1.0, 1e-9));
      });
    });

    test('a ramp to the value it already holds is a no-op that completes', () {
      fakeAsync((async) {
        final stage = GainStage('test');
        var done = false;
        stage.rampTo(1.0, const Duration(seconds: 2)).then((_) => done = true);

        async.flushMicrotasks();
        expect(done, isTrue, reason: 'must not wait out the duration');
        expect(stage.value, 1.0);
      });
    });

    test('a zero-duration ramp applies immediately', () {
      fakeAsync((async) {
        final stage = GainStage('test');
        var done = false;
        stage.rampTo(0.3, Duration.zero).then((_) => done = true);

        async.flushMicrotasks();
        expect(done, isTrue);
        expect(stage.value, 0.3);
      });
    });

    test('ramp shapes the interpolation between its own endpoints', () {
      fakeAsync((async) {
        final stage = GainStage('test', initial: 0.2);
        stage.rampTo(1.0, const Duration(seconds: 1), curve: FadeCurve.linear);

        async.elapse(const Duration(milliseconds: 500));
        // Linear from 0.2 to 1.0, not from 0.0 to 1.0.
        expect(stage.value, closeTo(0.6, 0.03));

        async.elapse(const Duration(milliseconds: 500));
        expect(stage.value, closeTo(1.0, 1e-9));
      });
    });

    test('values are clamped to [0, 1]', () {
      final stage = GainStage('test');
      stage.setImmediate(2.0);
      expect(stage.value, 1.0);
      stage.setImmediate(-1.0);
      expect(stage.value, 0.0);
    });
  });

  group('MusicGainBus', () {
    test('value is the product of all four stages', () {
      fakeAsync((async) {
        final bus = MusicGainBus();
        expect(bus.value, 1.0, reason: 'unity with nothing attenuating');

        bus.master.setImmediate(0.5);
        bus.announcementDuck.setImmediate(0.8);
        bus.systemDuck.setImmediate(0.6);
        bus.manualDuck.setImmediate(0.9);
        async.flushMicrotasks();

        expect(bus.value, closeTo(0.5 * 0.8 * 0.6 * 0.9, 1e-9));
        bus.dispose();
      });
    });

    test('ducks compose multiplicatively', () {
      fakeAsync((async) {
        final bus = MusicGainBus();

        bus.systemDuck.setImmediate(0.4);
        bus.announcementDuck.setImmediate(0.2);
        async.flushMicrotasks();

        expect(bus.value, closeTo(0.08, 1e-9),
            reason: 'an announcement duck under a system duck multiplies');
        bus.dispose();
      });
    });

    test('releasing one duck restores only its own contribution', () {
      fakeAsync((async) {
        final bus = MusicGainBus();

        bus.systemDuck.setImmediate(0.4);
        bus.announcementDuck.setImmediate(0.2);
        async.flushMicrotasks();
        expect(bus.value, closeTo(0.08, 1e-9));

        // The announcement finishes; the system is still ducking.
        bus.announcementDuck.setImmediate(1.0);
        async.flushMicrotasks();

        expect(bus.value, closeTo(0.4, 1e-9),
            reason: 'must not restore to 1.0 while systemDuck is engaged');

        bus.systemDuck.setImmediate(1.0);
        async.flushMicrotasks();
        expect(bus.value, closeTo(1.0, 1e-9));

        bus.dispose();
      });
    });

    test('concurrent ramps on separate stages compose at every instant', () {
      fakeAsync((async) {
        final bus = MusicGainBus();

        bus.announcementDuck
            .rampTo(0.2, const Duration(seconds: 1), curve: FadeCurve.linear);
        bus.systemDuck
            .rampTo(0.4, const Duration(seconds: 1), curve: FadeCurve.linear);

        for (var i = 0; i < 50; i++) {
          async.elapse(const Duration(milliseconds: 20));
          async.flushMicrotasks();
          final expected = bus.master.value *
              bus.announcementDuck.value *
              bus.systemDuck.value *
              bus.manualDuck.value;
          // The bus coalesces changes below 0.0005, so it may lag the exact
          // product by up to that much.
          expect(bus.value, closeTo(expected, 0.0005));
        }

        bus.dispose();
      });
    });

    test('emits on the changes stream as stages move', () {
      fakeAsync((async) {
        final bus = MusicGainBus();
        final seen = <double>[];
        bus.changes.listen(seen.add);

        bus.master.setImmediate(0.5);
        async.flushMicrotasks();
        bus.master.setImmediate(0.25);
        async.flushMicrotasks();

        expect(seen, [closeTo(0.5, 1e-9), closeTo(0.25, 1e-9)]);
        bus.dispose();
      });
    });
  });
}

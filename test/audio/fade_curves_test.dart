import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/fade_curves.dart';

/// 101 points: both endpoints plus every hundredth in between.
const _samples = 101;
double _t(int i) => i / (_samples - 1);

void main() {
  group('fade curves', () {
    test('fadeOut(c, t) == fadeIn(c, 1 - t) for every curve', () {
      for (final curve in FadeCurve.values) {
        for (var i = 0; i < _samples; i++) {
          final t = _t(i);
          expect(
            fadeOutGain(curve, t),
            closeTo(fadeInGain(curve, 1 - t), 1e-12),
            reason: '$curve at t=$t',
          );
        }
      }
    });

    test('every curve is monotonic non-decreasing on [0, 1]', () {
      for (final curve in FadeCurve.values) {
        var previous = fadeInGain(curve, 0);
        for (var i = 1; i < _samples; i++) {
          final t = _t(i);
          final current = fadeInGain(curve, t);
          expect(
            current,
            greaterThanOrEqualTo(previous),
            reason: '$curve dipped between ${_t(i - 1)} and $t',
          );
          previous = current;
        }
      }
    });

    test('every curve starts at exactly 0.0 and ends at exactly 1.0', () {
      for (final curve in FadeCurve.values) {
        expect(fadeInGain(curve, 0), 0.0, reason: '$curve at t=0');
        expect(fadeInGain(curve, 1), 1.0, reason: '$curve at t=1');
      }
    });

    test('every curve fades out from exactly 1.0 to exactly 0.0', () {
      for (final curve in FadeCurve.values) {
        expect(fadeOutGain(curve, 0), 1.0, reason: '$curve at t=0');
        expect(fadeOutGain(curve, 1), 0.0, reason: '$curve at t=1');
      }
    });

    test('input outside [0, 1] is clamped rather than extrapolated', () {
      for (final curve in FadeCurve.values) {
        expect(fadeInGain(curve, -0.5), fadeInGain(curve, 0), reason: '$curve');
        expect(fadeInGain(curve, 1.5), fadeInGain(curve, 1), reason: '$curve');
      }
    });

    test('equal-power holds constant power across the range', () {
      // sin²(x) + cos²(x) == 1 to within floating-point noise. The engine's
      // own tolerance is 0.01 because it also carries tick quantisation; the
      // curve maths itself is exact to machine precision, so this asserts far
      // tighter than the crossfade test does.
      for (var i = 0; i < _samples; i++) {
        final t = _t(i);
        final gain = fadeInGain(FadeCurve.equalPower, t);
        final loss = fadeOutGain(FadeCurve.equalPower, t);
        expect(
          gain * gain + loss * loss,
          closeTo(1.0, 1e-12),
          reason: 'equal-power lost constant power at t=$t',
        );
      }
    });

    test('crossfadeGains reports the same power', () {
      for (var i = 0; i < _samples; i++) {
        final g = crossfadeGains(_t(i));
        expect(g.power, closeTo(1.0, 1e-12), reason: 'at t=${_t(i)}');
      }
    });

    test('crossfadeGains hands each side to the curve it was given', () {
      final g = crossfadeGains(
        0.25,
        outCurve: FadeCurve.linear,
        inCurve: FadeCurve.exponential,
      );
      expect(g.outgoing, closeTo(fadeOutGain(FadeCurve.linear, 0.25), 1e-12));
      expect(g.incoming, closeTo(fadeInGain(FadeCurve.exponential, 0.25), 1e-12));
    });

    test('linear sits at 0.5 mid-crossfade, which is the level dip', () {
      // Documents *why* equalPower is the default: two linear-faded tracks at
      // the midpoint sum to roughly -3 dB rather than holding level.
      final g = crossfadeGains(
        0.5,
        outCurve: FadeCurve.linear,
        inCurve: FadeCurve.linear,
      );
      expect(g.outgoing, closeTo(0.5, 1e-12));
      expect(g.incoming, closeTo(0.5, 1e-12));
      expect(g.power, closeTo(0.5, 1e-12));
    });
  });

  group('curve shapes', () {
    test('exponential stays below linear, logarithmic stays above', () {
      for (var i = 1; i < _samples - 1; i++) {
        final t = _t(i);
        expect(fadeInGain(FadeCurve.exponential, t),
            lessThan(fadeInGain(FadeCurve.linear, t)));
        expect(fadeInGain(FadeCurve.logarithmic, t),
            greaterThan(fadeInGain(FadeCurve.linear, t)));
      }
    });

    test('sCurve is symmetric about its midpoint', () {
      for (var i = 0; i < _samples; i++) {
        final t = _t(i);
        expect(
          fadeInGain(FadeCurve.sCurve, t) +
              fadeInGain(FadeCurve.sCurve, 1 - t),
          closeTo(1.0, 1e-12),
          reason: 'sCurve asymmetric at t=$t',
        );
      }
    });

    test('dbLinear passes through -60 dB just above silence', () {
      // The floor is -60 dB, which is 0.001 of full scale — deliberately not
      // zero anywhere except the endpoint, where it is snapped so a fade to
      // silence actually reaches silence.
      expect(fadeInGain(FadeCurve.dbLinear, 0), 0.0);
      expect(fadeInGain(FadeCurve.dbLinear, 0.001), greaterThan(0.0));
      expect(fadeInGain(FadeCurve.dbLinear, 0.5), closeTo(0.0316, 1e-3));
    });
  });

  group('dB helpers', () {
    test('dbToAmplitude round-trips through amplitudeToDb', () {
      for (final db in [-60.0, -20.0, -6.0, -3.0, 0.0]) {
        expect(amplitudeToDb(dbToAmplitude(db)), closeTo(db, 1e-9));
      }
    });

    test('0 dB is unity gain and -6 dB is roughly half amplitude', () {
      expect(dbToAmplitude(0), closeTo(1.0, 1e-12));
      expect(dbToAmplitude(-6), closeTo(0.501, 1e-3));
    });

    test('silence maps to negative infinity rather than throwing', () {
      expect(amplitudeToDb(0), double.negativeInfinity);
    });
  });
}

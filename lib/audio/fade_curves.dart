import 'dart:math' as math;

/// The shape a gain change follows over time.
///
/// Every curve is defined by its *fade-in* form on `[0, 1]`, and fading out is
/// the same function read backwards:
///
///     fadeOut(t) == fadeIn(1 - t)
///
/// One definition therefore covers both directions, and there is no way for the
/// two to drift apart.
enum FadeCurve {
  /// `t`. Audible dip in the middle of a crossfade — two tracks at 0.5
  /// amplitude sum to roughly -3 dB. Fine for a fade to silence, poor between
  /// two tracks.
  linear,

  /// `t²`. Stays quiet longer, then rushes. Good for fading *into* a strong
  /// downbeat.
  exponential,

  /// `√t`. Rises fast then plateaus. Good for pulling music out from under a
  /// voice, because it clears headroom quickly.
  logarithmic,

  /// `sin(t·π/2)`. `sin² + cos² = 1`, so a crossfade between two tracks holds
  /// constant perceived loudness. **The default, and the reason transitions
  /// don't read as a stumble on a dance floor.**
  equalPower,

  /// `t²(3 − 2t)` — smoothstep. Gentle at both ends with no discontinuity in
  /// slope. Good for restoring a duck, where a sudden change of rate is more
  /// noticeable than the change of level.
  sCurve,

  /// Linear in decibels across a 60 dB range. Matches how a mixing desk fader
  /// behaves, which is what a DJ's hand expects.
  dbLinear,
}

/// The floor of the [FadeCurve.dbLinear] range. Anything quieter is silence.
const double _dbFloor = -60.0;

/// Gain for a fade *in* at normalised progress [t] in `[0, 1]`.
///
/// Guarantees, relied on by the engine and asserted in the tests:
///
///  * `fadeInGain(c, 0) == 0.0` and `fadeInGain(c, 1) == 1.0` for every curve
///  * monotonic non-decreasing across the range
double fadeInGain(FadeCurve curve, double t) {
  final x = t.clamp(0.0, 1.0);

  switch (curve) {
    case FadeCurve.linear:
      return x;

    case FadeCurve.exponential:
      return x * x;

    case FadeCurve.logarithmic:
      return math.sqrt(x);

    case FadeCurve.equalPower:
      return math.sin(x * math.pi / 2);

    case FadeCurve.sCurve:
      return x * x * (3 - 2 * x);

    case FadeCurve.dbLinear:
      // 10^(dB/20), sweeping dB from the floor up to 0. The endpoint is special
      // cased because a -60 dB floor is still 0.001 of full scale, not nothing,
      // and a fade that ends at 0.001 instead of 0.0 leaves an audible tail on
      // a fade-to-silence.
      if (x <= 0.0) return 0.0;
      return math.pow(10, (_dbFloor * (1 - x)) / 20).toDouble();
  }
}

/// Gain for a fade *out* at normalised progress [t] in `[0, 1]`.
///
/// Defined as the fade-in read backwards, so `fadeOutGain(c, 0) == 1.0` and
/// `fadeOutGain(c, 1) == 0.0`.
double fadeOutGain(FadeCurve curve, double t) =>
    fadeInGain(curve, 1.0 - t.clamp(0.0, 1.0));

/// The two deck gains at a single instant of a crossfade.
class CrossfadeGains {
  const CrossfadeGains({required this.outgoing, required this.incoming});

  /// Gain for the deck being retired.
  final double outgoing;

  /// Gain for the deck coming up.
  final double incoming;

  /// Summed power. With [FadeCurve.equalPower] on both sides this is 1.0
  /// throughout, which is the property that removes the hole in the middle of
  /// a transition.
  double get power => outgoing * outgoing + incoming * incoming;

  @override
  String toString() =>
      'CrossfadeGains(out: ${outgoing.toStringAsFixed(4)}, '
      'in: ${incoming.toStringAsFixed(4)})';
}

/// Both sides of a crossfade at normalised progress [t].
///
/// The two curves are independent so an operator can, say, pull the outgoing
/// track down logarithmically while the incoming one rises on an S-curve. Left
/// at the [FadeCurve.equalPower] default on both sides, `power` stays at 1.0
/// for the whole transition.
CrossfadeGains crossfadeGains(
  double t, {
  FadeCurve outCurve = FadeCurve.equalPower,
  FadeCurve inCurve = FadeCurve.equalPower,
}) {
  final x = t.clamp(0.0, 1.0);
  return CrossfadeGains(
    outgoing: fadeOutGain(outCurve, x),
    incoming: fadeInGain(inCurve, x),
  );
}

/// Decibels to a linear amplitude multiplier.
///
/// Used for ReplayGain and manual per-track trim, where the stored value is in
/// dB but the deck wants a multiplier.
double dbToAmplitude(double db) => math.pow(10, db / 20).toDouble();

/// Linear amplitude back to decibels. Silence maps to [double.negativeInfinity]
/// rather than throwing, so it is safe to call on a gain that has reached zero.
double amplitudeToDb(double amplitude) =>
    amplitude <= 0 ? double.negativeInfinity : 20 * (math.log(amplitude) / math.ln10);

import 'dart:async';

import 'fade_curves.dart';

/// One independently-animatable gain stage.
///
/// The whole ducking design rests on these being *multiplicative*. A duck for a
/// TTS announcement, a duck for a system notification, the user's master
/// volume, and the crossfade ratio are four separate stages; the deck volume is
/// their product. That means an announcement duck attenuates both decks equally
/// mid-crossfade and leaves the fade ratio untouched, and releasing the duck
/// restores the crossfade to exactly where it was.
class GainStage {
  GainStage(this.name, {double initial = 1.0}) : _value = initial;

  final String name;
  double _value;

  Timer? _ramp;
  Completer<void>? _rampDone;

  double get value => _value;

  final _changes = StreamController<double>.broadcast();
  Stream<double> get changes => _changes.stream;

  void setImmediate(double v) {
    _cancelRamp();
    _value = v.clamp(0.0, 1.0);
    _changes.add(_value);
  }

  /// Ramps to [target] over [duration]. Awaiting the returned future waits for
  /// the ramp to finish; starting a new ramp cancels and completes the old one,
  /// so a duck interrupted by another duck never leaves a dangling timer.
  Future<void> rampTo(
    double target,
    Duration duration, {
    FadeCurve curve = FadeCurve.sCurve,
    Duration tick = const Duration(milliseconds: 20),
  }) {
    _cancelRamp();

    final from = _value;
    final to = target.clamp(0.0, 1.0);

    if (duration <= Duration.zero || (to - from).abs() < 0.001) {
      setImmediate(to);
      return Future.value();
    }

    final done = Completer<void>();
    _rampDone = done;
    final started = DateTime.now();
    final totalMs = duration.inMilliseconds;

    _ramp = Timer.periodic(tick, (timer) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final t = (elapsed / totalMs).clamp(0.0, 1.0);

      // Shape the *interpolation*, not the absolute level, so a ramp from
      // 0.2 -> 1.0 curves between those endpoints rather than 0 -> 1.
      final shaped = fadeInGain(curve, t);
      _value = from + (to - from) * shaped;
      _changes.add(_value);

      if (t >= 1.0) {
        _value = to;
        _changes.add(_value);
        timer.cancel();
        _ramp = null;
        if (!done.isCompleted) done.complete();
      }
    });

    return done.future;
  }

  void _cancelRamp() {
    _ramp?.cancel();
    _ramp = null;
    if (_rampDone != null && !_rampDone!.isCompleted) _rampDone!.complete();
    _rampDone = null;
  }

  Future<void> dispose() async {
    _cancelRamp();
    await _changes.close();
  }
}

/// The music bus: every stage that attenuates the music decks.
class MusicGainBus {
  MusicGainBus() {
    for (final stage in stages) {
      stage.changes.listen((_) => _emit());
    }
  }

  /// User-facing volume.
  final master = GainStage('master');

  /// Announcement ducking — driven by [AnnouncementEngine].
  final announcementDuck = GainStage('announcementDuck');

  /// OS transient focus loss (an incoming notification on Android, a Siri
  /// invocation on iOS). Separate from the announcement duck so the two
  /// compose instead of overwriting each other.
  final systemDuck = GainStage('systemDuck');

  /// Manual DJ dip, mapped to a hardware key or a big on-screen button.
  final manualDuck = GainStage('manualDuck');

  List<GainStage> get stages => [master, announcementDuck, systemDuck, manualDuck];

  final _out = StreamController<double>.broadcast();
  Stream<double> get changes => _out.stream;

  double _last = 1.0;
  double get value => _last;

  void _emit() {
    final product = stages.fold<double>(1.0, (acc, s) => acc * s.value);
    if ((product - _last).abs() < 0.0005) return;
    _last = product;
    _out.add(product);
  }

  Future<void> dispose() async {
    for (final s in stages) {
      await s.dispose();
    }
    await _out.close();
  }
}

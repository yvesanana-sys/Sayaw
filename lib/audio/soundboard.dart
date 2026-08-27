import 'dart:async';

import 'deck.dart';
import 'fade_curves.dart';
import 'gain_bus.dart';

/// One cut-in sound: a whistle, a bell, a horn.
///
/// Not a `QueueEntry` and not an announcement. It never enters the set, never
/// moves the queue on, and the music underneath it keeps playing — the whole
/// point of a tag call is that the floor does not stop.
class SoundCue {
  const SoundCue({
    required this.id,
    required this.label,
    required this.filePath,
    this.duckLevel = 1.0,
    this.duckFade = const Duration(milliseconds: 120),
    this.restoreFade = const Duration(milliseconds: 400),
  });

  final String id;

  /// What the button says. 'Whistle', 'Bell', 'Rotate'.
  final String label;

  final String filePath;

  /// Where the music sits while this plays, as a fraction of its level.
  ///
  /// One by default, which leaves the music completely alone. A whistle is
  /// louder than the mix and cuts through on its own; dipping the music for
  /// it would announce the cue before the cue does. A spoken cue is the case
  /// that wants this below one.
  final double duckLevel;

  final Duration duckFade;
  final Duration restoreFade;

  /// Whether this cue touches the music at all.
  bool get ducks => duckLevel < 0.999;
}

/// Fires cut-in sounds over a running set.
///
/// Its own deck and its own gain stage, both deliberately. The deck means a
/// cue can sound while an announcement is speaking rather than cutting it off,
/// and [MusicGainBus.manualDuck] means a cue's dip multiplies with the
/// announcement's instead of fighting it — two ducks that shared a stage would
/// have the second one's restore bring the music up underneath the first.
class Soundboard {
  Soundboard({required Deck cueDeck, required this.bus}) : _deck = cueDeck;

  final Deck _deck;
  final MusicGainBus bus;

  /// A cue whose length the deck cannot report.
  ///
  /// A soundboard cue is a whistle, not a track. Holding the music down for an
  /// unknown length on a guess is the worse failure of the two, so the guess
  /// is short.
  static const assumedLength = Duration(seconds: 2);

  /// Which press is live.
  ///
  /// A second press supersedes the first, and the restore belonging to the
  /// superseded one must not fire — it would bring the music back up
  /// underneath a cue that is still sounding.
  int _generation = 0;

  bool _sounding = false;
  bool get isSounding => _sounding;

  /// Plays [cue] over whatever is running.
  ///
  /// Touches no transport: the decks keep playing, the queue does not move,
  /// and the engine is not told anything happened. The returned future
  /// completes when the cue has finished and the music is back up, which is
  /// what a test waits on — a caller pressing a button does not.
  ///
  /// False when it did not sound — a file the operator has since moved, a deck
  /// that would not load it. It does not throw for that: this is called from a
  /// button and left unawaited, and an exception on that path is an unhandled
  /// async error rather than anything the operator ever finds out about. They
  /// need telling instead, which is what the answer is for.
  Future<bool> fire(SoundCue cue) async {
    final generation = ++_generation;
    _sounding = true;

    try {
      // A press during a press restarts it. One deck cannot overlap itself,
      // and twice on the whistle means twice.
      await _deck.stop();
      await _deck.load(PlayableMedia(uri: Uri.file(cue.filePath)));
      await _deck.setVolume(1.0);

      if (cue.ducks) {
        await bus.manualDuck.rampTo(
          cue.duckLevel,
          cue.duckFade,
          curve: FadeCurve.logarithmic,
        );
      }

      final length = _deck.duration ?? assumedLength;
      await _deck.play();
      await Future<void>.delayed(length);

      if (generation == _generation) await _deck.stop();
      return true;
    } on Object {
      return false;
    } finally {
      // Whatever went wrong — a file that has been moved, a deck that will not
      // load it — the music must not be left sitting in a dip nobody can see
      // the cause of.
      if (generation == _generation) {
        _sounding = false;
        if (cue.ducks) {
          await bus.manualDuck.rampTo(
            1.0,
            cue.restoreFade,
            curve: FadeCurve.sCurve,
          );
        }
      }
    }
  }

  /// Stops a cue that is still sounding and brings the music straight back.
  Future<void> silence() async {
    _generation++;
    _sounding = false;
    await _deck.stop();
    bus.manualDuck.setImmediate(1.0);
  }

  Future<void> dispose() => _deck.dispose();
}

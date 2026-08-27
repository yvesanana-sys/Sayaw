import 'dart:async';

import 'package:sayaw/audio/soundboard.dart';
import 'package:sayaw/ui/state/soundboard_provider.dart';

/// A soundboard with no deck behind it.
class FakeSoundboard implements SoundboardAccess {
  FakeSoundboard([this.cues = const []]);

  List<SoundCue> cues;

  final _updates = StreamController<List<SoundCue>>.broadcast();

  /// Cues fired, in order, so a test can tell which button did what.
  final List<String> fired = [];
  int silenced = 0;

  /// The current list first, then anything that changes.
  ///
  /// A bare broadcast stream would drop the cues a test set up before the
  /// provider got around to subscribing, and the bar would draw empty for
  /// reasons that have nothing to do with the widget.
  @override
  Stream<List<SoundCue>> watchCues() async* {
    yield cues;
    yield* _updates.stream;
  }

  void emit(List<SoundCue> next) {
    cues = next;
    _updates.add(next);
  }

  final _failures = StreamController<String>.broadcast();

  @override
  Stream<String> get failures => _failures.stream;

  /// Makes the next press report that it did not sound.
  void failNext(String label) => _failures.add(label);

  @override
  void fire(SoundCue cue) => fired.add(cue.id);

  @override
  void silence() => silenced++;

  /// Cues added, as (label, path, duckLevel).
  final List<(String, String, double)> addedCues = [];
  final List<String> removedCues = [];

  @override
  Future<void> addCue({
    required String label,
    required String filePath,
    double duckLevel = 1.0,
  }) async =>
      addedCues.add((label, filePath, duckLevel));

  @override
  Future<void> removeCue(String id) async => removedCues.add(id);

  Future<void> close() async {
    await _updates.close();
    await _failures.close();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/soundboard.dart';

/// What the soundboard bar needs, and nothing else.
///
/// An interface for the same reason the library and Event Mode have one: a row
/// of buttons that fire a whistle should be pumpable without a deck, a gain
/// bus or a database behind it.
abstract class SoundboardAccess {
  /// The cues to draw, in the order the operator arranged them.
  Stream<List<SoundCue>> watchCues();

  /// Fires one. Returns at once — a button press must not sit waiting for a
  /// whistle to finish.
  void fire(SoundCue cue);

  /// Cues that were pressed and did not sound, by label.
  ///
  /// A cut-in that makes no noise is not a quiet failure: the operator pressed
  /// a button in front of a room and heard nothing, and needs to know it was
  /// the file rather than their timing.
  Stream<String> get failures;

  /// Stops whatever is sounding and brings the music straight back.
  void silence();

  /// Adds a cue for an audio file the operator picked.
  Future<void> addCue({
    required String label,
    required String filePath,
    double duckLevel,
  });

  Future<void> removeCue(String id);
}

/// The soundboard, or null where there is no audio behind the screen.
final soundboardProvider =
    Provider<SoundboardAccess?>((ref) => ref.watch(soundboardHolderProvider));

final soundboardHolderProvider =
    NotifierProvider<SoundboardHolder, SoundboardAccess?>(
  SoundboardHolder.new,
);

class SoundboardHolder extends Notifier<SoundboardAccess?> {
  @override
  SoundboardAccess? build() => null;

  void set(SoundboardAccess? soundboard) => state = soundboard;
}

/// Cues that were pressed and did not sound.
final soundboardFailureProvider = StreamProvider<String>((ref) {
  final soundboard = ref.watch(soundboardProvider);
  return soundboard?.failures ?? const Stream.empty();
});

/// The cue list on its own, so the shortcut bindings and the buttons can both
/// watch it without either rebuilding on the other's account.
final soundCuesProvider = StreamProvider<List<SoundCue>>((ref) {
  final soundboard = ref.watch(soundboardProvider);
  return soundboard?.watchCues() ?? const Stream.empty();
});

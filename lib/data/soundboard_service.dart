import 'dart:async';

import '../audio/soundboard.dart';
import '../ui/state/soundboard_provider.dart';
import 'db/database.dart';

/// The soundboard, joined to where its cues are stored.
///
/// The [Soundboard] itself knows nothing about a database and the database
/// knows nothing about a deck; this is the one place that holds both, the same
/// arrangement `PlaybackSession` has for the engine and the playlist tables.
class SoundboardService implements SoundboardAccess {
  const SoundboardService({required this.board, required this.db});

  final Soundboard board;
  final SayawDatabase db;

  @override
  Stream<List<SoundCue>> watchCues() => db.soundCueDao.watchAll();

  /// Deliberately not awaited.
  ///
  /// A cue runs for as long as the file does, and a button that stayed pressed
  /// for two seconds would be the wrong thing entirely — the operator has
  /// already moved on to the next cue by then.
  @override
  void fire(SoundCue cue) => unawaited(board.fire(cue));

  @override
  void silence() => unawaited(board.silence());
}

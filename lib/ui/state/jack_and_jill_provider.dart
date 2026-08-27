import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/jack_and_jill.dart';

/// What the draw dialog needs, and nothing else.
abstract class JackAndJillAccess {
  /// The dances the library is filed under, for the picker.
  Stream<List<DanceType>> watchDanceTypes();

  Future<Set<DrawProblem>> problems(String danceTypeId);

  Future<Draw> draw(String danceTypeId);

  /// Records a draw the operator actually announced.
  Future<void> commit(Draw draw);

  /// Adds the drawn track to the end of the open set, so the song the room
  /// was just promised is the song that plays.
  Future<void> addToSet(String trackId);
}

final jackAndJillProvider =
    Provider<JackAndJillAccess?>((ref) => ref.watch(jackAndJillHolderProvider));

final jackAndJillHolderProvider =
    NotifierProvider<JackAndJillHolder, JackAndJillAccess?>(
  JackAndJillHolder.new,
);

class JackAndJillHolder extends Notifier<JackAndJillAccess?> {
  @override
  JackAndJillAccess? build() => null;

  void set(JackAndJillAccess? access) => state = access;
}

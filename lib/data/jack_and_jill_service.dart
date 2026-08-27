import 'package:drift/drift.dart' show OrderingTerm;

import 'db/database.dart';
import 'jack_and_jill.dart';
import '../ui/state/jack_and_jill_provider.dart';
import '../ui/state/library_access.dart';

/// The draw, joined to the set it feeds.
///
/// The randomiser knows nothing about a playlist and [LibraryAccess] knows
/// nothing about a roster; this holds both, so the song a room was just
/// promised is the song that ends up queued.
class JackAndJillService implements JackAndJillAccess {
  const JackAndJillService({required this.db, required this.library});

  final SayawDatabase db;

  /// Null before the runtime has finished starting, which makes adding to the
  /// set unavailable rather than silently doing nothing.
  final LibraryAccess? library;

  JackAndJill get _draws => JackAndJill(db: db);

  @override
  Stream<List<DanceType>> watchDanceTypes() => (db.select(db.danceTypes)
        ..orderBy([(d) => OrderingTerm.asc(d.sortIndex)]))
      .watch();

  @override
  Future<Set<DrawProblem>> problems(String danceTypeId) =>
      _draws.problems(danceTypeId);

  @override
  Future<Draw> draw(String danceTypeId) => _draws.draw(danceTypeId);

  @override
  Future<void> commit(Draw draw) => _draws.commit(draw);

  @override
  Future<void> addToSet(String trackId) async =>
      library?.addToSet(trackId);

  @override
  Stream<List<Participant>> watchParticipants() =>
      db.participantDao.watchAll();

  @override
  Future<String> addParticipant(String name) => db.participantDao.add(name);

  @override
  Future<void> setPresent(String id, bool present) =>
      db.participantDao.setPresent(id, present);

  @override
  Future<void> removeParticipant(String id) => db.participantDao.remove(id);

  @override
  Future<void> resetDraws() => db.participantDao.resetDraws();
}

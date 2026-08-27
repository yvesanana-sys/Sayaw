import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'participant_dao.g.dart';

/// The people in the room.
@DriftAccessor(tables: [Participants])
class ParticipantDao extends DatabaseAccessor<SayawDatabase>
    with _$ParticipantDaoMixin {
  ParticipantDao(super.db);

  SimpleSelectStatement<$ParticipantsTable, Participant> _ordered() =>
      select(participants)..orderBy([(p) => OrderingTerm.asc(p.name)]);

  Stream<List<Participant>> watchAll() => _ordered().watch();

  Future<List<Participant>> all() => _ordered().get();

  /// Everyone who could be drawn right now.
  Future<List<Participant>> present() => (select(participants)
        ..where((p) => p.isPresent.equals(true))
        ..orderBy([
          // Fewest draws first, so a caller who wants a fair night can take
          // from the top rather than trusting a shuffle to be kind.
          (p) => OrderingTerm.asc(p.drawCount),
          (p) => OrderingTerm.asc(p.name),
        ]))
      .get();

  /// Adds someone, or returns the id of the person already on the list.
  ///
  /// Matched on the name as typed, case-insensitively: a roster taken at a
  /// door gets the same person entered twice, and two "Marta"s in a draw is a
  /// bug the caller has to resolve out loud in front of a room.
  Future<String> add(String name, {String? id}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'a participant needs a name');
    }

    final existing = await (select(participants)
          ..where((p) => p.name.lower().equals(trimmed.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    final rowId = id ?? newId();
    await into(participants).insert(ParticipantsCompanion.insert(
      id: rowId,
      name: trimmed,
      createdAt: clock.now(),
    ));
    return rowId;
  }

  /// Marks someone as here or gone.
  ///
  /// Not a delete: someone who leaves early stays on the list so their name is
  /// not retyped next week.
  Future<void> setPresent(String id, bool present) =>
      (update(participants)..where((p) => p.id.equals(id)))
          .write(ParticipantsCompanion(isPresent: Value(present)));

  Future<int> remove(String id) =>
      (delete(participants)..where((p) => p.id.equals(id))).go();

  /// Records that these people were drawn.
  Future<void> recordDraw(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    await customUpdate(
      'UPDATE participants SET draw_count = draw_count + 1 '
      'WHERE id IN (${List.filled(ids.length, '?').join(', ')})',
      variables: [for (final id in ids) Variable<String>(id)],
      updates: {participants},
    );
  }

  /// Puts everyone back to nobody-has-danced-yet, for the next event.
  Future<void> resetDraws() => (update(participants))
      .write(const ParticipantsCompanion(drawCount: Value(0)));
}

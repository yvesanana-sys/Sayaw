import 'dart:math';

import 'db/database.dart';

/// One Jack and Jill draw: a song, and the two people who will dance to it.
class Draw {
  const Draw({required this.track, required this.dancers, this.danceType});

  /// Null when the library has nothing filed under the chosen dance.
  final Track? track;

  /// Two people, or fewer when fewer are in the room. Never the same person
  /// twice.
  final List<Participant> dancers;

  final DanceType? danceType;

  bool get isComplete => track != null && dancers.length >= 2;
}

/// Why a draw could not be made.
enum DrawProblem {
  /// Nobody is signed in, or everyone has gone home.
  notEnoughDancers,

  /// The library has nothing filed under this dance.
  noTracks,
}

/// The two randomisers, run together.
///
/// Deliberately one class rather than two calls from the UI: a draw is a
/// single announcement in the room — "this song, these two" — and half of one
/// is not a thing the operator can do anything with.
class JackAndJill {
  JackAndJill({required this.db, Random? random})
      : _random = random ?? Random();

  final SayawDatabase db;
  final Random _random;

  /// What is missing, if anything.
  Future<Set<DrawProblem>> problems(String danceTypeId) async {
    final present = await db.participantDao.present();
    final tracks = await db.trackDao.byDanceType(danceTypeId);

    return {
      if (present.length < 2) DrawProblem.notEnoughDancers,
      if (tracks.isEmpty) DrawProblem.noTracks,
    };
  }

  /// Picks a track from [danceTypeId] and two people who are here.
  ///
  /// The people are drawn from the least-danced end of the room rather than
  /// uniformly. A uniform shuffle over a two-hour event reliably leaves
  /// somebody never picked, and that person is standing right there — so the
  /// draw takes the [poolSize] who have danced least and randomises within
  /// them. It is still a draw, and it is one nobody can be excluded from.
  Future<Draw> draw(String danceTypeId, {int poolSize = 6}) async {
    final danceType = await (db.select(db.danceTypes)
          ..where((d) => d.id.equals(danceTypeId)))
        .getSingleOrNull();

    final tracks = await db.trackDao.byDanceType(danceTypeId);
    final present = await db.participantDao.present();

    final track =
        tracks.isEmpty ? null : tracks[_random.nextInt(tracks.length)];

    // `present()` is already ordered fewest-draws-first, so the head of it is
    // the pool. Two is the floor, because a pool of one cannot make a pair.
    final pool = present.take(max(2, min(poolSize, present.length))).toList();
    final dancers = <Participant>[];

    while (dancers.length < 2 && pool.isNotEmpty) {
      dancers.add(pool.removeAt(_random.nextInt(pool.length)));
    }

    return Draw(track: track, dancers: dancers, danceType: danceType);
  }

  /// Records a draw the operator actually used.
  ///
  /// Separate from [draw] on purpose: a caller who redraws because the first
  /// pair just danced together should not have that count against either of
  /// them, and a draw nobody announced never happened.
  Future<void> commit(Draw draw) =>
      db.participantDao.recordDraw([for (final d in draw.dancers) d.id]);
}

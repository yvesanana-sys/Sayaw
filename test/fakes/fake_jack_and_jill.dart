import 'dart:async';

import 'package:clock/clock.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart' show CachePolicy;
import 'package:sayaw/data/jack_and_jill.dart';
import 'package:sayaw/ui/state/jack_and_jill_provider.dart';

DanceType fakeDance(String id, String name) => DanceType(
      id: id,
      name: name,
      slug: id,
      ttsTemplate: 'Next dance: {name}',
      sortIndex: 0,
    );

Participant fakePerson(String name) => Participant(
      id: name.toLowerCase(),
      name: name,
      isPresent: true,
      drawCount: 0,
      createdAt: clock.now(),
    );

Track fakeTrack(String id, {String title = 'Obsesion', String? artist}) => Track(
      id: id,
      sourceType: SourceType.local,
      title: title,
      artist: artist,
      durationMs: Duration.zero,
      cueInMs: Duration.zero,
      gainDb: 0,
      isDrm: false,
      cachePolicy: CachePolicy.allow,
      addedAt: clock.now(),
      updatedAt: clock.now(),
    );

/// A draw with no database behind it.
class FakeJackAndJill implements JackAndJillAccess {
  FakeJackAndJill({
    this.dances = const [],
    this.result,
    this.problemsFound = const {},
  });

  List<DanceType> dances;
  Draw? result;
  Set<DrawProblem> problemsFound;

  final List<String> drawn = [];
  final List<Draw> committed = [];
  final List<String> queued = [];

  @override
  Stream<List<DanceType>> watchDanceTypes() async* {
    yield dances;
  }

  @override
  Future<Set<DrawProblem>> problems(String danceTypeId) async => problemsFound;

  @override
  Future<Draw> draw(String danceTypeId) async {
    drawn.add(danceTypeId);
    return result ?? const Draw(track: null, dancers: []);
  }

  @override
  Future<void> commit(Draw draw) async => committed.add(draw);

  @override
  Future<void> addToSet(String trackId) async => queued.add(trackId);
}

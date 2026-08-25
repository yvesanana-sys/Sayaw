import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/gain_bus.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/playlist_repository.dart';
import 'package:sayaw/ui/state/playback_session.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';

import '../data/db_harness.dart';
import '../fakes/fake_clip_factory.dart';
import '../fakes/fake_deck.dart';
import '../fakes/fake_sources.dart';

/// Short enough to run in real time, long enough that a transition is a ramp
/// rather than a cut.
const _crossfade = Duration(milliseconds: 200);

/// Well beyond anything a test plays, so the only transitions are the ones the
/// test asks for.
const _trackLength = Duration(seconds: 30);

void main() {
  late SayawDatabase db;
  late ProviderContainer container;
  late PlaybackController controller;
  late FakeDeck deckA;
  late FakeDeck deckB;
  late CrossfadeEngine engine;
  late PlaybackSession session;
  late Directory music;
  late String set;

  setUp(() async {
    db = openTestDatabase();
    music = Directory.systemTemp.createTempSync('sayaw-session');
    addTearDown(() => music.deleteSync(recursive: true));

    container = ProviderContainer();
    addTearDown(container.dispose);
    controller = container.read(playbackProvider.notifier);

    deckA = FakeDeck('A', trackDuration: _trackLength);
    deckB = FakeDeck('B', trackDuration: _trackLength);
    engine = CrossfadeEngine(
      deckA: deckA,
      deckB: deckB,
      bus: MusicGainBus(),
      announcements: AnnouncementEngine(
        voiceDeck: FakeDeck('voice'),
        cacheDirectory: '/nonexistent',
        settings: const TtsVoiceSettings(),
        clipFactory: FakeClipFactory(),
      ),
    );

    set = await db.playlistDao.createPlaylist(name: 'Saturday Social');
    await (db.update(db.playlists)..where((p) => p.id.equals(set))).write(
      const PlaylistsCompanion(
        crossfadeMs: Value(_crossfade),
        announceMode: Value(AnnounceMode.off),
      ),
    );

    session = PlaybackSession(
      engine: engine,
      repository: PlaylistRepository(
        db: db,
        resolver: MediaResolver(
          plex: FakePlexClient(),
          tidal: FakeTidalClient(),
          cache: FakeMediaCache(),
          networkMode: () => NetworkMode.online,
        ),
      ),
      controller: controller,
      uiTick: const Duration(milliseconds: 20),
    );
    addTearDown(session.dispose);
  });

  group('opening a set', () {
    test('the queue on screen is the set as written', () async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);

      final queue = container.read(playbackProvider).queue;
      expect([for (final item in queue) item.title],
          ['Track a', 'Track b', 'Track c']);
      expect(queue.every((item) => item.isPlayable), isTrue);
    });

    test('a row that will not play stays visible, with the reason on it',
        () async {
      await _addTracks(db, set, music, ['a', 'gone', 'c']);
      File('${music.path}/gone.flac').deleteSync();

      final resolved = await session.openPlaylist(set);
      final queue = container.read(playbackProvider).queue;

      // Still three rows on screen: dropping one would make the list disagree
      // with the set the operator built.
      expect(queue, hasLength(3));
      expect(queue[1].unavailable, UnavailableReason.fileMissing);
      expect(session.willPlay('item-gone'), isFalse);

      // The engine was handed only the two it can play.
      expect(resolved.entries, hasLength(2));
    });

    test('the first track is loaded and showing before anything plays',
        () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);

      final state = container.read(playbackProvider);
      expect(state.deckA.title, 'Track a');
      expect(state.deckA.isPlaying, isFalse);
      expect(state.phase, EnginePhase.idle);

      // And the next one is already cued on the other deck.
      expect(state.deckB.title, 'Track b');
      expect(deckA.media!.uri, Uri.file('${music.path}/a.flac'));
    });
  });

  group('transport', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
    });

    test('play starts the audible deck and the screen follows', () async {
      await session.play();
      await _settle();

      final state = container.read(playbackProvider);
      expect(state.phase, EnginePhase.playing);
      expect(state.deckA.isPlaying, isTrue);
      expect(state.currentIndex, 0);
    });

    test('the position readout advances while it plays', () async {
      await session.play();
      await _settle(const Duration(milliseconds: 120));

      expect(container.read(playbackProvider).deckA.position,
          greaterThan(Duration.zero));
    });

    test('the play button on the audible deck pauses it', () async {
      await session.play();
      await _settle();

      controller.togglePlay(DeckSlot.a);
      await _settle();

      expect(container.read(playbackProvider).phase, EnginePhase.paused);
      expect(deckA.calls, contains('pause'));
    });

    test('the play button on the cued deck starts the transition', () async {
      await session.play();
      await _settle();

      controller.togglePlay(DeckSlot.b);
      await _settle(_crossfade * 3);

      // The decks have swapped roles: B is audible and playing the second
      // track, and the third is now cued behind it.
      expect(session.activeSlot, DeckSlot.b);
      final state = container.read(playbackProvider);
      expect(state.deckB.title, 'Track b');
      expect(state.deckA.title, 'Track c');
      expect(state.currentIndex, 1);
    });

    test('the crossfade button is the same transition', () async {
      await session.play();
      await _settle();

      controller.crossfadeNow();
      await _settle(_crossfade * 3);

      expect(container.read(playbackProvider).currentIndex, 1);
    });

    test('pausing everything stops both decks', () async {
      await session.play();
      await _settle();

      controller.pauseAll();
      await _settle();

      final state = container.read(playbackProvider);
      expect(state.phase, EnginePhase.paused);
      expect(state.anyDeckPlaying, isFalse);
    });

    test('the highlighted row is the operator\'s index, not the engine\'s',
        () async {
      // Rebuild the set with an unplayable row in front of the one playing.
      await db.playlistDao.removeItem('item-a');
      await _addTracks(db, set, music, ['gone'], atFront: true);
      File('${music.path}/gone.flac').deleteSync();
      await session.openPlaylist(set);

      await session.play();
      await _settle();

      // The engine is on its first entry; the operator is looking at row two.
      expect(engine.currentIndex, 0);
      expect(container.read(playbackProvider).currentIndex, 1);
    });
  });

  group('editing the set while it runs', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
    });

    test('a drag is written to the database, not just to the screen', () async {
      controller.reorderQueue(2, 0);
      await _settle();

      expect([
        for (final row in await db.playlistDao.itemsOf(set)) row.track!.title
      ], [
        'Track c',
        'Track a',
        'Track b'
      ]);
      expect([for (final item in container.read(playbackProvider).queue) item.title],
          ['Track c', 'Track a', 'Track b']);
    });

    test('the track already cued up keeps playing through a reorder', () async {
      await session.play();
      await _settle();

      controller.reorderQueue(2, 0);
      await _settle();

      // The engine is not reloaded: tearing down a prerolled deck to honour a
      // drag would put a hole in a transition that is seconds away.
      expect(container.read(playbackProvider).deckA.title, 'Track a');
      expect(engine.standbyEntry!.title, 'Track b');
    });
  });

  group('the library', () {
    test('search finds what a scan imported', () async {
      _touch(music, 'library/kiss-of-fire.flac');
      await session.scanFolders([Directory('${music.path}/library')]);

      final found = await session.searchLibrary('kiss');
      expect([for (final t in found) t.title], ['kiss-of-fire']);
    });

    test('adding a track puts it in the set, on screen and in the engine',
        () async {
      await _addTracks(db, set, music, ['a']);
      await session.openPlaylist(set);
      final track = await _importOne(db, music, 'later');

      await session.addToSet(track);
      await _settle();

      expect([
        for (final row in await db.playlistDao.itemsOf(set)) row.track!.title
      ], [
        'Track a',
        'Track later'
      ]);
      expect([for (final item in container.read(playbackProvider).queue) item.title],
          ['Track a', 'Track later']);
      expect(session.willPlay(
          (await db.playlistDao.itemsOf(set)).last.item.id), isTrue);
    });

    test('a set that had run out picks the new track up as its next', () async {
      await _addTracks(db, set, music, ['a']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      // One track in, nothing cued behind it.
      expect(engine.standbyEntry, isNull);

      await session.addToSet(await _importOne(db, music, 'later'));
      await _settle();

      expect(engine.standbyEntry!.title, 'Track later');
    });

    test('adding does not disturb the track already cued up', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final cued = engine.standbyEntry;
      final loadsBefore = deckB.calls.where((c) => c == 'load').length;

      await session.addToSet(await _importOne(db, music, 'later'));
      await _settle();

      // Reloading the standby deck to honour an append would put a hole in a
      // transition that might be seconds away.
      expect(engine.standbyEntry, same(cued));
      expect(deckB.calls.where((c) => c == 'load').length, loadsBefore);
    });

    test('adding before a set is open does nothing rather than throwing',
        () async {
      final track = await _importOne(db, music, 'orphan');
      await session.addToSet(track);

      expect(await db.select(db.playlistItems).get(), isEmpty);
    });
  });

  group('detaching', () {
    test('the controller goes back to moving its own state', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.dispose();

      // No engine behind it any more, so this is the local path again.
      controller.togglePlay(DeckSlot.a);
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);
      expect(deckA.calls, isNot(contains('play')));
    });
  });
}

// ---------------------------------------------------------------------------

/// Lets real timers run. The engine ticks at 20 ms and the session republishes
/// on the same order of magnitude, so a few dozen milliseconds is enough for
/// state to arrive.
Future<void> _settle([Duration duration = const Duration(milliseconds: 80)]) =>
    Future<void>.delayed(duration);

/// Puts one file on disk and one row in the library, and returns its track id.
Future<String> _importOne(
    SayawDatabase db, Directory music, String id) async {
  _touch(music, '$id.flac');
  await db.trackDao.upsert(TracksCompanion.insert(
    id: id,
    sourceType: SourceType.local,
    localPath: Value('${music.path}/$id.flac'),
    title: 'Track $id',
    addedAt: clock.now(),
    updatedAt: clock.now(),
  ));
  return id;
}

void _touch(Directory root, String relativePath) {
  final file = File('${root.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('not really audio');
}

Future<void> _addTracks(
  SayawDatabase db,
  String playlistId,
  Directory music,
  List<String> ids, {
  bool atFront = false,
}) async {
  for (final id in ids) {
    File('${music.path}/$id.flac').writeAsStringSync('not really audio');
    await db.trackDao.upsert(TracksCompanion.insert(
      id: id,
      sourceType: SourceType.local,
      localPath: Value('${music.path}/$id.flac'),
      title: 'Track $id',
      addedAt: clock.now(),
      updatedAt: clock.now(),
    ));
    await db.playlistDao.appendTrack(
      playlistId: playlistId,
      trackId: id,
      id: 'item-$id',
    );
  }

  if (atFront) {
    final rows = await db.playlistDao.itemsOf(playlistId);
    await db.playlistDao.move(
      playlistId: playlistId,
      oldIndex: rows.length - 1,
      newIndex: 0,
    );
  }
}

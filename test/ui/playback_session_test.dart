import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/gain_bus.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/playlist_repository.dart';
import 'package:sayaw/data/set_ordering.dart';
import 'package:sayaw/ui/state/library_access.dart';
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
  late FakeClipFactory clips;
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

    clips = FakeClipFactory();
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
        clipFactory: clips,
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

  group('announcing a row with the operator\'s own sound', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
    });

    Future<String> addCue(String label, String path) =>
        db.soundCueDao.add(label: label, filePath: path);

    test('the row on screen says which sound announces it', () async {
      final cue = await addCue('Take your partners', '/clips/partners.wav');

      await session.tagSoundCue(itemId: 'item-b', cueId: cue);

      final item = container.read(playbackProvider).queue[1];
      expect(item.soundCueId, cue);
      expect(item.soundCueLabel, 'Take your partners');
      expect(item.hasSoundCue, isTrue);
    });

    test('it is written to the set, not just to the screen', () async {
      final cue = await addCue('Take your partners', '/clips/partners.wav');

      await session.tagSoundCue(itemId: 'item-b', cueId: cue);

      final row = (await db.playlistDao.itemsOf(set))[1];
      expect(row.item.soundCueId, cue);
    });

    test('a sound tagged mid-set reaches the transition it was tagged for',
        () async {
      // Track b is already loaded and prerolled on the standby deck, with the
      // announcement it had at the time already rendered. Tagging has to reach
      // that copy, or the clip would not be heard until the set was reopened.
      final cue = await addCue('Waltz next', '/clips/waltz-next.wav');

      await session.tagSoundCue(itemId: 'item-b', cueId: cue);
      await _settle();

      expect(engine.standbyEntry!.announcementClipPath,
          '/clips/waltz-next.wav');
      // And over the crossfade rather than in place of it.
      expect(engine.standbyEntry!.spec.announceMode, AnnounceMode.duckOver);
      // Rendered now rather than at the transition, which is the whole point
      // of the engine holding a preloaded copy.
      expect(clips.probed, contains('/clips/waltz-next.wav'));
    });

    test('clearing it takes the sound off the row and off the deck', () async {
      final cue = await addCue('Waltz next', '/clips/waltz-next.wav');
      await session.tagSoundCue(itemId: 'item-b', cueId: cue);
      await _settle();

      await session.tagSoundCue(itemId: 'item-b', cueId: null);
      await _settle();

      expect(container.read(playbackProvider).queue[1].hasSoundCue, isFalse);
      expect(engine.standbyEntry!.announcementClipPath, isNull);
    });

    test('the row keeps playing through a tag', () async {
      await session.play();
      await _settle();
      final cue = await addCue('Waltz next', '/clips/waltz-next.wav');

      await session.tagSoundCue(itemId: 'item-b', cueId: cue);
      await _settle();

      // Nothing is reloaded: the deck that is audible and the one cued up
      // behind it both keep what they have.
      expect(container.read(playbackProvider).deckA.title, 'Track a');
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);
      expect(engine.standbyEntry!.title, 'Track b');
    });
  });

  group('what the next transition will say', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b']);
    });

    test('nothing, when the row coming up has nothing to say', () async {
      await session.openPlaylist(set);

      expect(container.read(playbackProvider).announcement, isNull);
    });

    test('the name the operator gave their own recording', () async {
      await session.openPlaylist(set);
      final cue = await db.soundCueDao
          .add(label: 'Take your partners', filePath: '/clips/p.wav');

      await session.tagSoundCue(itemId: 'item-b', cueId: cue);
      await _settle();

      // The cue's name, not its path: a path is not what the operator called
      // it, and the engine holds nothing else.
      final next = container.read(playbackProvider).announcement!;
      expect(next.label, 'Take your partners');
      expect(next.isRecording, isTrue);
      expect(next.timing, AnnouncementTiming.overTheCrossfade);
    });

    test('it describes the row cued up, not the one playing', () async {
      await session.openPlaylist(set);
      final cue = await db.soundCueDao
          .add(label: 'Take your partners', filePath: '/clips/p.wav');

      // Track a is audible; tagging it says nothing about the transition into
      // track b, which is the one about to happen. This is the mistake the
      // strip exists to make visible.
      await session.tagSoundCue(itemId: 'item-a', cueId: cue);
      await _settle();

      expect(container.read(playbackProvider).announcement, isNull);
    });

    test('clearing the tag empties it again', () async {
      await session.openPlaylist(set);
      final cue = await db.soundCueDao
          .add(label: 'Take your partners', filePath: '/clips/p.wav');
      await session.tagSoundCue(itemId: 'item-b', cueId: cue);
      await _settle();

      await session.tagSoundCue(itemId: 'item-b', cueId: null);
      await _settle();

      expect(container.read(playbackProvider).announcement, isNull);
    });
  });

  group('playing a row the operator tapped', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();
    });

    test('it crossfades into that row and the set carries on from there',
        () async {
      await session.jumpTo('item-c');
      await _settle(const Duration(milliseconds: 600));

      final state = container.read(playbackProvider);
      expect(state.currentIndex, 2);
      expect(engine.currentEntry?.itemId, 'item-c');
    });

    test('a row the engine could not load is not a destination', () async {
      await _addTracks(db, set, music, ['gone']);
      File('${music.path}/gone.flac').deleteSync();
      await session.openPlaylist(set);
      await session.play();
      await _settle();
      expect(session.willPlay('item-gone'), isFalse, reason: 'precondition');

      await session.jumpTo('item-gone');
      await _settle(const Duration(milliseconds: 600));

      expect(engine.currentEntry?.itemId, 'item-a',
          reason: 'still on the first row; nothing happened');
    });
  });

  group('stop', () {
    test('silence now, and the track back at its start', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.play();
      await _settle(const Duration(milliseconds: 300));
      expect(container.read(playbackProvider).deckA.position,
          greaterThan(Duration.zero),
          reason: 'precondition: some way in');

      await session.stopToCue();
      await _settle();

      final state = container.read(playbackProvider);
      expect(state.anyDeckPlaying, isFalse);
      expect(state.deckA.position, Duration.zero);
      // Still the same set, still the same row: not a reload.
      expect(state.deckA.title, 'Track a');
      expect(state.deckB.title, 'Track b');
    });
  });

  group('adding a whole folder at once', () {
    test('every row lands on screen and in the engine, in order', () async {
      await _addTracks(db, set, music, ['a']);
      await session.openPlaylist(set);
      for (final id in ['b', 'c', 'd']) {
        File('${music.path}/$id.flac').writeAsStringSync('not really audio');
        await db.trackDao.upsert(TracksCompanion.insert(
          id: id,
          sourceType: SourceType.local,
          localPath: Value('${music.path}/$id.flac'),
          title: 'Track $id',
          addedAt: clock.now(),
          updatedAt: clock.now(),
        ));
      }

      await session.addAllToSet(['d', 'b', 'c']);
      await _settle();

      expect(
        [for (final item in container.read(playbackProvider).queue) item.title],
        ['Track a', 'Track d', 'Track b', 'Track c'],
      );
      // Cued behind the one on deck, and the rest reachable by a tap.
      expect(engine.standbyEntry?.title, 'Track d');
      expect(session.willPlay('item-a'), isTrue);
    });

    test('the whole library, in the order a set should play', () async {
      await _addTracks(db, set, music, ['02_second', '01_first']);
      await session.openPlaylist(set);

      final ids = await session.everyTrackMatching('');

      expect(ids, ['01_first', '02_second']);
    });
  });

  group('running a row into the next', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
    });

    test('the row on screen shows the join, and the strip says merge',
        () async {
      await session.setMergeIntoNext(itemId: 'item-a', merge: true);
      await _settle();

      final state = container.read(playbackProvider);
      expect(state.queue[0].mergeIntoNext, isTrue);
      expect(state.queue[1].mergeIntoNext, isFalse);
      expect(state.nextMerges, isTrue);
      expect(state.announcement, isNull);
    });

    test('the deck already cued takes the merge without being reloaded',
        () async {
      await session.play();
      await _settle();
      expect(engine.standbyEntry?.spec.merge, isFalse, reason: 'precondition');

      await session.setMergeIntoNext(itemId: 'item-a', merge: true);
      await _settle();

      expect(engine.standbyEntry?.title, 'Track b');
      expect(engine.standbyEntry?.spec.merge, isTrue);
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);
    });

    test('the whole set at once, and back', () async {
      await session.play();
      await _settle();

      await session.setMergeAll(true);
      await _settle();

      final rows = await db.playlistDao.itemsOf(set);
      expect(rows.every((r) => r.item.mergeIntoNext), isTrue);
      expect(container.read(playbackProvider).queue.every((i) => i.mergeIntoNext),
          isTrue);
      expect(engine.standbyEntry?.spec.merge, isTrue,
          reason: 'the deck already cued took it without a reload');
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);

      await session.setMergeAll(false);
      await _settle();
      expect(engine.standbyEntry?.spec.merge, isFalse);
    });

    test('separating them puts the transition back', () async {
      await session.setMergeIntoNext(itemId: 'item-a', merge: true);
      await _settle();
      await session.setMergeIntoNext(itemId: 'item-a', merge: false);
      await _settle();

      expect(engine.standbyEntry?.spec.merge, isFalse);
      expect(container.read(playbackProvider).nextMerges, isFalse);
    });
  });

  group('how much of each song plays', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
    });

    test('is on screen for the chips, and changes under a running set',
        () async {
      expect(container.read(playbackProvider).songLength, isNull);
      await session.play();
      await _settle();

      final before = await session.readSetShape();
      final full = await session.writeSetShape(SetShape(
        songLimit: before.songLimit,
        songDuration: const Duration(minutes: 2),
        rotationGap: before.rotationGap,
        continuousFlow: before.continuousFlow,
        snowballStages: before.snowballStages,
      ));
      await _settle();

      expect(full, isTrue, reason: 'a length change applies live');
      expect(container.read(playbackProvider).songLength,
          const Duration(minutes: 2));
      expect(engine.currentEntry?.targetDuration, const Duration(minutes: 2));
      expect(engine.standbyEntry?.targetDuration, const Duration(minutes: 2));
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue,
          reason: 'nothing was reloaded');
    });

    test('a row with a length of its own keeps it', () async {
      await (db.update(db.playlistItems)..where((i) => i.id.equals('item-b')))
          .write(const PlaylistItemsCompanion(
              targetDurationMs: Value(Duration(seconds: 45))));
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      await session.writeSetShape(
          const SetShape(songDuration: Duration(minutes: 2)));
      await _settle();

      expect(engine.currentEntry?.targetDuration, const Duration(minutes: 2));
      expect(engine.standbyEntry?.targetDuration, const Duration(seconds: 45));
    });
  });

  group('clearing the library', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
    });

    test('empties the library, the set on screen and the decks', () async {
      final removed = await session.clearLibrary();
      await _settle();

      expect(removed, 2);
      expect(await session.libraryCount(), 0);
      final state = container.read(playbackProvider);
      expect(state.queue, isEmpty);
      expect(state.deckA.isLoaded, isFalse);
      expect(state.deckB.isLoaded, isFalse);
      expect(engine.currentEntry, isNull);
    });

    test('is refused while music plays', () async {
      await session.play();
      await _settle();

      final removed = await session.clearLibrary();
      await _settle();

      expect(removed, 0);
      expect(await session.libraryCount(), 2);
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue,
          reason: 'nothing was disturbed');
    });

    test('and the music files are not touched', () async {
      await session.clearLibrary();

      expect(File('${music.path}/a.flac').existsSync(), isTrue);
    });
  });

  group('the sets the operator keeps', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
    });

    test('the open set has its name on screen', () async {
      expect(container.read(playbackProvider).setName, 'Saturday Social');
    });

    test('saving a copy keeps the open set open', () async {
      final copyId = await session.saveSetAs('Keepsake');

      expect(copyId, isNotNull);
      expect(session.openPlaylistId, set);
      expect(await db.playlistDao.itemsOf(copyId!), hasLength(2));
      final names = [for (final p in await session.watchSets().first) p.name];
      expect(names, containsAll(['Saturday Social', 'Keepsake']));
    });

    test('opening another set puts it on the decks', () async {
      final other = await db.playlistDao.createPlaylist(name: 'Class');

      expect(await session.openSet(other), isTrue);

      final state = container.read(playbackProvider);
      expect(state.setName, 'Class');
      expect(state.queue, isEmpty);
    });

    test('but not while music plays', () async {
      final other = await db.playlistDao.createPlaylist(name: 'Class');
      await session.play();
      await _settle();

      expect(await session.openSet(other), isFalse);
      expect(container.read(playbackProvider).setName, 'Saturday Social');
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);
    });

    test('removing the open set opens the one used last', () async {
      final other = await db.playlistDao.createPlaylist(name: 'Class');
      await session.openSet(other);
      await session.openSet(set);

      await session.deleteSet(set);

      expect(container.read(playbackProvider).setName, 'Class');
      expect(await db.playlistDao.byId(set), isNull);
    });

    test('a set saved to a folder comes back as the open set', () async {
      final stick = Directory.systemTemp.createTempSync('sayaw-stick');
      addTearDown(() => stick.deleteSync(recursive: true));
      await db.playlistDao.setMergeIntoNext(itemId: 'item-a', merge: true);

      final exported = await session.exportSet(set, into: stick);
      expect(exported.rows, 2);
      expect(File('${stick.path}/Saturday Social music/a.flac').existsSync(),
          isTrue);

      final report = await session.importSet(exported.file);
      await _settle();

      expect(report.rows, 2);
      expect(report.missing, isEmpty);
      final state = container.read(playbackProvider);
      expect(state.setName, 'Saturday Social');
      expect(state.queue, hasLength(2));
      expect(state.queue[0].mergeIntoNext, isTrue);
      expect(session.openPlaylistId, report.playlistId,
          reason: 'the imported copy is what is on the decks now');
    });

    test('renaming the open set renames the header', () async {
      await session.renameSet(set, 'Friday');
      expect(container.read(playbackProvider).setName, 'Friday');
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

  group('the network changing under an open set', () {
    setUp(() async {
      await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
            id: 'plex',
            provider: SourceProvider.plex,
            displayName: 'Home Server',
            // Without this the rows do not resolve at all, which would make
            // every assertion below pass for the wrong reason.
            machineIdentifier: const Value('plex'),
            keychainRef: 'keychain-plex',
            createdAt: clock.now(),
          ));
    });

    test('with nothing playing, the set is simply resolved again', () async {
      // Idle is the safe moment for the accurate answer: nothing is loaded on
      // a deck, so there is no transition to interrupt.
      await _addTracks(db, set, music, ['a', 'gone']);
      await session.openPlaylist(set);
      expect(container.read(playbackProvider).queue[1].isPlayable, isTrue);

      File('${music.path}/gone.flac').deleteSync();
      await session.applyNetworkMode(NetworkMode.localOnly);

      expect(container.read(playbackProvider).queue[1].unavailable,
          UnavailableReason.fileMissing);
    });

    test('mid-set, a streamed row that is not downloaded is marked down',
        () async {
      await _addTracks(db, set, music, ['a']);
      await _addRemote(db, set, 'plexed');
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      await session.applyNetworkMode(NetworkMode.localOnly);

      final queue = container.read(playbackProvider).queue;
      expect(queue[0].isPlayable, isTrue, reason: 'a local file still plays');
      expect(queue[1].unavailable, UnavailableReason.offline);
    });

    test('a downloaded copy keeps the row playable', () async {
      // The whole point of Event Mode: the server going away does not matter
      // for a track that is already on the disk.
      await _addTracks(db, set, music, ['a']);
      await _addRemote(db, set, 'downloaded');
      await db.into(db.cacheEntries).insert(CacheEntriesCompanion.insert(
            trackId: 'downloaded',
            state: const Value(CacheState.complete),
            createdAt: clock.now(),
          ));
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      await session.applyNetworkMode(NetworkMode.localOnly);

      expect(container.read(playbackProvider).queue[1].isPlayable, isTrue);
    });

    test('mid-set, the deck that is cued up is left alone', () async {
      // Reopening the set would call loadQueue and drop what is already
      // preloaded and prerolled — with a crossfade possibly seconds away.
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final cued = deckB.media;
      await session.applyNetworkMode(NetworkMode.localOnly);
      await _settle();

      expect(deckB.media, same(cued));
      expect(container.read(playbackProvider).currentIndex, 0);
    });

    test('mid-set, a network coming back promises nothing the engine cannot '
        'keep', () async {
      // The engine was handed its queue when the set was opened and cannot
      // take a skipped row back without a reload. Drawing the row as available
      // again would be a lie until the set is next opened.
      await _addTracks(db, set, music, ['a']);
      await _addRemote(db, set, 'plexed');
      await session.openPlaylist(set);
      await session.play();
      await _settle();
      await session.applyNetworkMode(NetworkMode.localOnly);

      await session.applyNetworkMode(NetworkMode.online);

      expect(container.read(playbackProvider).queue[1].unavailable,
          UnavailableReason.offline);
    });

    test('with no set open there is nothing to say', () async {
      await session.applyNetworkMode(NetworkMode.localOnly);

      expect(container.read(playbackProvider).queue, isEmpty);
    });
  });

  group('the crossfader', () {
    setUp(() async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();
    });

    test('the fader on screen moves the decks', () async {
      // It used to move a number and nothing else: with a session attached
      // the slider was inert, which on the main screen of a DJ app is the
      // control most likely to be reached for in a hurry.
      controller.setCrossfader(1.0);
      await _settle();

      expect(session.activeSlot, DeckSlot.b);
      expect(container.read(playbackProvider).deckB.title, 'Track b');
      expect(deckB.calls, contains('play'));
    });

    test('half way is half way, not a handover', () async {
      controller.setCrossfader(0.5);
      await _settle();

      expect(session.activeSlot, DeckSlot.a, reason: 'nothing handed over yet');
      expect(deckA.volumeEvents.last.volume, closeTo(0.7071, 0.01));
      expect(deckB.volumeEvents.last.volume, closeTo(0.7071, 0.01));
    });

    test('the engine does not fight the thumb while it is held', () async {
      // Reading the gains back through the equal-power curve does not return
      // the fader position that produced them, so publishing it under a
      // moving thumb would make the slider jitter.
      controller.setCrossfader(0.6);
      await _settle(const Duration(milliseconds: 300));

      expect(container.read(playbackProvider).crossfader, closeTo(0.6, 1e-9));
    });

    test('an automatic transition moves the thumb to the end it arrived at',
        () async {
      expect(container.read(playbackProvider).crossfader, closeTo(0.0, 0.01));

      controller.crossfadeNow();
      await _settle(_crossfade * 3);

      expect(session.activeSlot, DeckSlot.b);
      expect(container.read(playbackProvider).crossfader, closeTo(1.0, 0.01));
    });

    test('dragging back leaves the set where it was', () async {
      controller.setCrossfader(0.4);
      await _settle();
      controller.setCrossfader(0.0);
      await _settle();

      expect(session.activeSlot, DeckSlot.a);
      expect(container.read(playbackProvider).deckA.title, 'Track a');
      expect(container.read(playbackProvider).currentIndex, 0);
    });
  });

  group('the shape of the set reaches the engine', () {
    test('a song limit set on the playlist is what the engine plays to',
        () async {
      await _addTracks(db, set, music, ['a', 'b', 'c', 'd']);
      await db.playlistDao
          .setShape(set, songLimit: 2, targetDuration: null);

      await session.openPlaylist(set);

      expect(engine.songLimit, 2);
      // All four rows are still on screen: the operator built them, and a set
      // that stops early is not a set with rows missing from the list.
      expect(container.read(playbackProvider).queue, hasLength(4));
      expect(engine.standbyEntry!.itemId, 'item-b');
    });

    test('a set with no limit plays the list as written', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);

      expect(engine.songLimit, isNull);
    });

    test('the per-song cap arrives on every entry', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: const Duration(seconds: 90));

      final resolved = await session.openPlaylist(set);

      expect(
        [for (final entry in resolved.entries) entry.targetDuration],
        everyElement(const Duration(seconds: 90)),
      );
    });
  });

  group('changing the shape of the set', () {
    test('with nothing playing, the whole change takes effect', () async {
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);

      final full = await session.writeSetShape(const SetShape(
        songLimit: 2,
        songDuration: Duration(seconds: 90),
      ));

      expect(full, isTrue);
      expect(engine.songLimit, 2);
      expect(engine.currentEntry!.targetDuration, const Duration(seconds: 90));
    });

    test('mid-set, the song count takes effect immediately', () async {
      // The engine only reads it when deciding what to cue up next, so
      // nothing already on a deck is disturbed.
      await _addTracks(db, set, music, ['a', 'b', 'c']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final cued = deckB.media;
      final full = await session
          .writeSetShape(const SetShape(songLimit: 1, songDuration: null));

      expect(full, isTrue, reason: 'the length did not change');
      expect(engine.songLimit, 1);
      expect(deckB.media, same(cued), reason: 'the cued deck is untouched');
    });

    test('mid-set, a new song length takes effect on the row playing',
        () async {
      // Read live by the engine's tick rather than baked into each entry at
      // open, so it no longer waits for the next set. The row playing takes
      // it too: two minutes chosen at 2:10 means now.
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final full = await session.writeSetShape(
          const SetShape(songLimit: null, songDuration: Duration(seconds: 30)));

      expect(full, isTrue);
      expect(engine.currentEntry!.targetDuration, const Duration(seconds: 30));
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue,
          reason: 'and nothing was reloaded to do it');

      // And on disk, so the next open agrees.
      expect((await db.playlistDao.byId(set))!.targetDurationMs,
          const Duration(seconds: 30));
    });


    test('continuous flow is the crossfade and the announcement, not a flag',
        () async {
      // Stored as what it means rather than beside it, so the two can never
      // disagree about whether this set has a crossfade.
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);

      await session.writeSetShape(const SetShape(continuousFlow: true));

      final playlist = (await db.playlistDao.byId(set))!;
      expect(playlist.crossfadeMs, Duration.zero);
      expect(playlist.announceMode, AnnounceMode.off);
      expect(session.engine.currentEntry!.spec.isGapless, isTrue);
    });

    test('and it reads back as itself', () async {
      await _addTracks(db, set, music, ['a']);
      await session.openPlaylist(set);
      await session.writeSetShape(const SetShape(continuousFlow: true));

      expect((await session.readSetShape()).continuousFlow, isTrue);
    });

    test('turning it off puts a crossfade back', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.writeSetShape(const SetShape(continuousFlow: true));

      await session.writeSetShape(const SetShape());

      final playlist = (await db.playlistDao.byId(set))!;
      expect(playlist.crossfadeMs, const Duration(seconds: 4));
      expect(playlist.announceMode, AnnounceMode.beforeMusic);
      expect((await session.readSetShape()).continuousFlow, isFalse);
    });

    test('what is read back is what was written', () async {
      await _addTracks(db, set, music, ['a']);
      await session.openPlaylist(set);

      await session.writeSetShape(const SetShape(
        songLimit: 7,
        songDuration: Duration(minutes: 3),
      ));

      final shape = await session.readSetShape();
      expect(shape.songLimit, 7);
      expect(shape.songDuration, const Duration(minutes: 3));
      expect(shape.isPlainList, isFalse);
    });

    test('a set nobody has opened has nothing to shape', () async {
      expect(await session.writeSetShape(const SetShape(songLimit: 3)), isFalse);
      expect((await session.readSetShape()).isPlainList, isTrue);
    });
  });

  group('ordering the set by tempo', () {
    Future<void> addWithBpm(String id, double? bpm) async {
      File('${music.path}/$id.flac').writeAsStringSync('not really audio');
      await db.trackDao.upsert(TracksCompanion.insert(
        id: id,
        sourceType: SourceType.local,
        localPath: Value('${music.path}/$id.flac'),
        title: 'Track $id',
        bpm: Value(bpm),
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
      await db.playlistDao
          .appendTrack(playlistId: set, trackId: id, id: 'item-$id');
    }

    test('the rows are really rewritten, not just redrawn', () async {
      // A generated order the operator cannot see, edit or undo would break
      // the rule the whole queue is built on.
      await addWithBpm('fast', 180);
      await addWithBpm('slow', 84);
      await addWithBpm('mid', 120);
      await session.openPlaylist(set);

      await session.orderSetByTempo(TempoOrder.ascending);

      expect(
        [for (final row in await db.playlistDao.itemsOf(set)) row.item.id],
        ['item-slow', 'item-mid', 'item-fast'],
      );
    });

    test('the queue on screen follows', () async {
      await addWithBpm('fast', 180);
      await addWithBpm('slow', 84);
      await session.openPlaylist(set);

      await session.orderSetByTempo(TempoOrder.ascending);

      expect(
        [for (final item in container.read(playbackProvider).queue) item.title],
        ['Track slow', 'Track fast'],
      );
    });

    test('it reports what it had to guess', () async {
      await addWithBpm('tagged', 120);
      await addWithBpm('mystery', null);
      await session.openPlaylist(set);

      final report = await session.orderSetByTempo(TempoOrder.ascending);

      expect(report.total, 2);
      expect(report.withoutTempo, ['item-mystery']);
      expect(report.isExact, isFalse);
    });

    test('mid-set it leaves the cued deck alone', () async {
      // The engine keeps the queue it was handed. Rebuilding it to honour a
      // reorder would drop what is preloaded, which is the same rule a drag
      // already follows.
      await addWithBpm('a', 180);
      await addWithBpm('b', 84);
      await addWithBpm('c', 120);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final cued = deckB.media;
      await session.orderSetByTempo(TempoOrder.ascending);
      await _settle();

      expect(deckB.media, same(cued));
      // But the database and the screen agree on the new order.
      expect(
        [for (final item in container.read(playbackProvider).queue) item.title],
        ['Track b', 'Track c', 'Track a'],
      );
    });

    test('with no set open there is nothing to order', () async {
      final report = await session.orderSetByTempo(TempoOrder.ascending);

      expect(report.total, 0);
    });
  });

  group('the snowball readout', () {
    Future<void> addWithBpm(String id, double? bpm) async {
      File('${music.path}/$id.flac').writeAsStringSync('not really audio');
      await db.trackDao.upsert(TracksCompanion.insert(
        id: id,
        sourceType: SourceType.local,
        localPath: Value('${music.path}/$id.flac'),
        title: 'Track $id',
        bpm: Value(bpm),
        addedAt: clock.now(),
        updatedAt: clock.now(),
      ));
      await db.playlistDao
          .appendTrack(playlistId: set, trackId: id, id: 'item-$id');
    }

    test('an ordinary set has none', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);

      expect(container.read(playbackProvider).snowball, isNull);
    });

    test('a snowball set reports the stage it is on', () async {
      await _addTracks(db, set, music, ['a', 'b', 'c', 'd']);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: null, snowballStages: 4);
      await session.openPlaylist(set);

      final snowball = container.read(playbackProvider).snowball!;
      expect(snowball.stage, 1);
      expect(snowball.stages, 4);
      expect(snowball.total, 4);
    });

    test('the tempo shown is the track playing, not a stage number', () async {
      // The honest half. A set that was never ordered shows a stage climbing
      // and a tempo that is not.
      await addWithBpm('slow', 84);
      await addWithBpm('fast', 180);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: null, snowballStages: 2);
      await session.openPlaylist(set);

      expect(container.read(playbackProvider).snowball!.bpm, 84);
    });

    test('the song limit is the climb, where there is one', () async {
      // Five stages over the twenty songs the operator planned, not over the
      // forty rows that happen to be in the playlist.
      await _addTracks(db, set, music, ['a', 'b', 'c', 'd', 'e', 'f']);
      await db.playlistDao.setShape(set,
          songLimit: 4, targetDuration: null, snowballStages: 2);
      await session.openPlaylist(set);

      expect(container.read(playbackProvider).snowball!.total, 4);
    });

    test('it climbs as the set does', () async {
      await _addTracks(db, set, music, ['a', 'b', 'c', 'd']);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: null, snowballStages: 4);
      await session.openPlaylist(set);
      await session.play();
      await _settle();
      expect(container.read(playbackProvider).snowball!.stage, 1);

      controller.crossfadeNow();
      await _settle(_crossfade * 3);

      expect(container.read(playbackProvider).snowball!.stage, 2);
    });

    test('turning it off clears the readout rather than leaving it up',
        () async {
      // The nullable-field trap: a `copyWith` that treats null as "leave it
      // alone" would strand a stage indicator on a set that no longer has one.
      await _addTracks(db, set, music, ['a', 'b']);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: null, snowballStages: 3);
      await session.openPlaylist(set);
      expect(container.read(playbackProvider).snowball, isNotNull);

      await session.writeSetShape(const SetShape());

      expect(container.read(playbackProvider).snowball, isNull);
    });

    test('one stage is not a climb', () async {
      await _addTracks(db, set, music, ['a', 'b']);
      await db.playlistDao.setShape(set,
          songLimit: null, targetDuration: null, snowballStages: 1);
      await session.openPlaylist(set);

      expect(container.read(playbackProvider).snowball, isNull);
    });
  });
}

// ---------------------------------------------------------------------------

/// A track that lives on a Plex server rather than on disk. Playable while the
/// server answers, and the interesting case the moment it stops.
Future<void> _addRemote(
    SayawDatabase db, String playlistId, String id) async {
  await db.trackDao.upsert(TracksCompanion.insert(
    id: id,
    sourceType: SourceType.plex,
    accountId: const Value('plex'),
    sourceId: Value(id),
    title: 'Track $id',
    addedAt: clock.now(),
    updatedAt: clock.now(),
  ));
  await db.playlistDao
      .appendTrack(playlistId: playlistId, trackId: id, id: 'item-$id');
}

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

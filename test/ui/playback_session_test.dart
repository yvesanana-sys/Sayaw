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

    test('mid-set, a new song length waits for the next set and says so',
        () async {
      // It is resolved into every entry when the set is opened, so honouring
      // it now would mean rebuilding the queue underneath a running set.
      await _addTracks(db, set, music, ['a', 'b']);
      await session.openPlaylist(set);
      await session.play();
      await _settle();

      final full = await session.writeSetShape(
          const SetShape(songLimit: null, songDuration: Duration(seconds: 30)));

      expect(full, isFalse);
      expect(engine.currentEntry!.targetDuration, isNull,
          reason: 'the row playing keeps the length it started with');

      // But it is on disk, so the next open picks it up.
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

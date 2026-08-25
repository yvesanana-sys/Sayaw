import '../../audio/announcement_engine.dart';
import '../../audio/crossfade_engine.dart';
import '../../audio/deck.dart';
import '../../audio/gain_bus.dart';
import '../../data/db/announcement_dao.dart';
import '../../data/db/database.dart';
import '../../data/media_resolver.dart';
import '../../data/playlist_repository.dart';
import '../../data/sources/unconfigured_sources.dart';
import 'playback_session.dart';
import 'playback_ui_state.dart';

/// Everything the app needs to make a sound, assembled in one place.
///
/// Three decks, a gain bus, the announcement engine, the resolver and the
/// repository: individually testable, and tedious to wire by hand at every
/// call site. Constructing them here keeps the seams — the audio layer still
/// takes its collaborators as arguments, and every one of them is swapped for
/// a fake in the test suite.
class PlaybackRuntime {
  PlaybackRuntime._({
    required this.db,
    required this.engine,
    required this.session,
    required this.decks,
    required this.bus,
  });

  final SayawDatabase db;
  final CrossfadeEngine engine;
  final PlaybackSession session;

  /// Held only so they can be disposed: everything that reads them goes
  /// through the engine.
  final List<Deck> decks;
  final MusicGainBus bus;

  /// Builds the real thing: platform decks, native TTS, the database.
  static PlaybackRuntime start({
    required SayawDatabase db,
    required PlaybackController controller,
    required String announcementCacheDirectory,
    TtsVoiceSettings voice = const TtsVoiceSettings(),
  }) {
    final deckA = DeckFactory.create('A');
    final deckB = DeckFactory.create('B');
    final voiceDeck = DeckFactory.create('voice');
    final bus = MusicGainBus();

    final engine = CrossfadeEngine(
      deckA: deckA,
      deckB: deckB,
      bus: bus,
      announcements: AnnouncementEngine(
        voiceDeck: voiceDeck,
        cacheDirectory: announcementCacheDirectory,
        settings: voice,
        store: DriftAnnouncementCache(db.announcementDao, voice),
      ),
    );

    return PlaybackRuntime._(
      db: db,
      engine: engine,
      decks: [deckA, deckB, voiceDeck],
      bus: bus,
      session: PlaybackSession(
        engine: engine,
        controller: controller,
        repository: PlaylistRepository(
          db: db,
          resolver: MediaResolver(
            plex: const UnconfiguredPlexClient(),
            tidal: const UnconfiguredTidalClient(),
            cache: const NoMediaCache(),
            // Nothing consults this until a Plex or TIDAL account exists to
            // consult it about; connectivity detection arrives with them.
            networkMode: () => NetworkMode.online,
          ),
        ),
      ),
    );
  }

  /// The set the app should open on launch: the most recent one, or a new
  /// empty one so there is somewhere to drop tracks on a fresh install.
  Future<String> openMostRecentPlaylist() async {
    final playlists = await session.repository.db.playlistDao.watchAll().first;

    final id = playlists.isNotEmpty
        ? playlists.first.id
        : await db.playlistDao.createPlaylist(name: 'Tonight');

    await session.openPlaylist(id);
    return id;
  }

  Future<void> dispose() async {
    await session.dispose();
    await engine.dispose();
    for (final deck in decks) {
      await deck.dispose();
    }
    await bus.dispose();
  }
}

import '../../audio/announcement_engine.dart';
import '../../audio/crossfade_engine.dart';
import '../../audio/deck.dart';
import '../../audio/gain_bus.dart';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/cache/file_media_cache.dart';
import '../../data/cache/media_downloader.dart';
import '../../data/db/announcement_dao.dart';
import '../../data/db/database.dart';
import '../../data/media_resolver.dart';
import '../../data/playlist_repository.dart';
import '../../data/sources/plex/plex_api_client.dart';
import '../../data/sources/sources_access.dart';
import '../../data/sources/plex/plex_identity.dart';
import '../../data/sources/plex/plex_auth.dart';
import '../../data/sources/secret_store.dart';
import '../../data/sources/sources_service.dart';
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
    required this.plex,
    required this.sources,
    required this.downloader,
    required this.decks,
    required this.bus,
  });

  final SayawDatabase db;
  final CrossfadeEngine engine;
  final PlaybackSession session;

  /// Held so the settings screen can run the sign-in flow against the same
  /// client the resolver plays through.
  final PlexApiClient plex;

  /// Connecting and disconnecting services, for the sources screen.
  final SourcesAccess sources;

  /// The only thing that writes media bytes to disk.
  final MediaDownloader downloader;

  /// Held only so they can be disposed: everything that reads them goes
  /// through the engine.
  final List<Deck> decks;
  final MusicGainBus bus;

  /// Builds the real thing: platform decks, native TTS, the database.
  static PlaybackRuntime start({
    required SayawDatabase db,
    required PlaybackController controller,
    required String announcementCacheDirectory,
    required String mediaCacheDirectory,
    required PlexIdentity plexIdentity,
    TtsVoiceSettings voice = const TtsVoiceSettings(),
    SecretStore secrets = const SecureSecretStore(),
    Dio? http,
  }) {
    final deckA = DeckFactory.create('A');
    final deckB = DeckFactory.create('B');
    final voiceDeck = DeckFactory.create('voice');
    final bus = MusicGainBus();

    final dio = http ?? Dio();

    // One client, not one per user of it: it remembers which of a server's
    // addresses answered, and a second copy would race them all again.
    final plex = PlexApiClient(
      dio: dio,
      identity: plexIdentity,
      secrets: secrets,
      accounts: db.sourceAccountDao,
    );

    final resolver = MediaResolver(
      plex: plex,
      tidal: const UnconfiguredTidalClient(),
      cache: FileMediaCache(db),
      // Connectivity is not watched yet, so this always claims a connection.
      // The cost of being wrong is bounded: the connection race gives every
      // address a few hundred milliseconds and then reports the server as
      // unreachable in words.
      networkMode: () => NetworkMode.online,
    );

    final repository = PlaylistRepository(db: db, resolver: resolver);

    final engine = CrossfadeEngine(
      deckA: deckA,
      deckB: deckB,
      bus: bus,
      // Signed Plex and TIDAL URLs expire. This is what stops one dying
      // between the moment the set was built and the moment the track is
      // due, which on a four-hour night is most of them.
      refresh: repository.refreshEntry,
      announcements: AnnouncementEngine(
        voiceDeck: voiceDeck,
        cacheDirectory: announcementCacheDirectory,
        settings: voice,
        store: DriftAnnouncementCache(db.announcementDao, voice),
      ),
    );

    final downloader = MediaDownloader(
      db: db,
      resolver: resolver,
      dio: dio,
      directory: Directory(mediaCacheDirectory),
    );

    return PlaybackRuntime._(
      db: db,
      engine: engine,
      plex: plex,
      downloader: downloader,
      sources: SourcesService(
        db: db,
        plex: plex,
        plexAuth: PlexAuth(dio: dio, identity: plexIdentity),
      ),
      decks: [deckA, deckB, voiceDeck],
      bus: bus,
      session: PlaybackSession(
        engine: engine,
        controller: controller,
        downloader: downloader,
        repository: repository,
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

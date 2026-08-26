import '../../audio/announcement_engine.dart';
import '../../audio/crossfade_engine.dart';
import '../../audio/deck.dart';
import '../../audio/gain_bus.dart';
import '../../audio/sayaw_audio_handler.dart';
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/cache/file_media_cache.dart';
import '../../data/cache/media_downloader.dart';
import '../../data/connectivity.dart';
import '../../data/db/announcement_dao.dart';
import '../../data/db/database.dart';
import '../../data/media_resolver.dart';
import '../../data/playlist_repository.dart';
import '../../data/sources/plex/plex_api_client.dart';
import '../../data/sources/plex/plex_reachability.dart';
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
    required this.connectivity,
    required this.decks,
    required this.bus,
    required this.networkEvents,
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

  /// What the resolver reads to decide whether reaching for a server is worth
  /// the timeout.
  final ConnectivityService connectivity;

  /// Held only so it can be cancelled, like [decks] and [bus] below.
  final StreamSubscription<NetworkMode> networkEvents;

  SayawAudioHandler? _mediaSession;

  /// The OS media session, once [startMediaSession] has run. Null on a
  /// platform that has none.
  SayawAudioHandler? get mediaSession => _mediaSession;

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
    NetworkRadio? radio,
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

    // The radio alone is not trusted anywhere: every verdict here comes from a
    // real request against a real server. See `lib/data/connectivity.dart`.
    final connectivity = ConnectivityService(
      radio: radio ?? ConnectivityPlusRadio(),
      probes: [PlexReachability(accounts: db.sourceAccountDao, plex: plex)],
    );

    final resolver = MediaResolver(
      plex: plex,
      tidal: const UnconfiguredTidalClient(),
      cache: FileMediaCache(db),
      // Read on every resolve rather than captured, so a set already loaded
      // picks up the change without being rebuilt.
      networkMode: () => connectivity.mode,
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

    final session = PlaybackSession(
      engine: engine,
      controller: controller,
      downloader: downloader,
      repository: repository,
    );

    final networkEvents = connectivity.changes.listen((mode) async {
      // The address that answered on the venue's wifi is not the one that
      // answers on a phone hotspot. Racing again on every transition costs one
      // round of probes; keeping a dead address costs the rest of the night.
      plex.forgetConnection();

      controller.setNetworkMode(mode,
          offlineServices: connectivity.unreachable);
      await session.applyNetworkMode(mode);
    });

    // Not awaited: the first probe is a network round-trip per server, and the
    // deck screen must draw before it finishes. Until it answers the mode is
    // `online`, which is what it was before any of this existed.
    unawaited(connectivity.start());

    return PlaybackRuntime._(
      db: db,
      engine: engine,
      plex: plex,
      downloader: downloader,
      connectivity: connectivity,
      networkEvents: networkEvents,
      sources: SourcesService(
        db: db,
        plex: plex,
        plexAuth: PlexAuth(dio: dio, identity: plexIdentity),
      ),
      decks: [deckA, deckB, voiceDeck],
      bus: bus,
      session: session,
    );
  }

  /// Puts this runtime's engine behind the lock screen and, on Android, the
  /// foreground service that stops the OS reclaiming playback mid-set.
  ///
  /// Separate from [start] because it is asynchronous and touches platform
  /// channels, while [start] is what every call site needs and stays
  /// synchronous. Call it once: `AudioService.init` is a one-shot, and a
  /// second session would be a second thing claiming audio focus.
  Future<void> startMediaSession() async {
    _mediaSession ??= await SayawAudioHandler.attach(
      engine: engine,
      bus: bus,
      // The engine's own, not a new one: the announcement duck the lock screen
      // triggers has to land on the bus the set is actually playing through.
      announcements: engine.announcements,
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
    await _mediaSession?.dispose();
    await networkEvents.cancel();
    await connectivity.dispose();
    await session.dispose();
    await engine.dispose();
    for (final deck in decks) {
      await deck.dispose();
    }
    await bus.dispose();
  }
}

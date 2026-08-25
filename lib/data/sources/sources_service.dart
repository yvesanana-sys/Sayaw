import '../db/database.dart';
import 'plex/plex_api_client.dart';
import 'plex/plex_auth.dart';
import 'plex/plex_importer.dart';
import 'plex/plex_library.dart';
import 'sources_access.dart';

/// The real [SourcesAccess]: plex.tv, the keychain and the accounts table.
class SourcesService implements SourcesAccess {
  const SourcesService({
    required this.db,
    required this.plexAuth,
    required this.plex,
  });

  final SayawDatabase db;
  final PlexAuth plexAuth;
  final PlexApiClient plex;

  @override
  Stream<List<SourceAccount>> watchAccounts() =>
      db.sourceAccountDao.watchAll();

  @override
  Future<PlexPin> requestPlexPin() => plexAuth.requestPin();

  @override
  Future<String?> checkPlexPin(String pinId) => plexAuth.checkPin(pinId);

  @override
  Future<List<PlexServer>> plexServers(String authToken) =>
      plex.servers(authToken);

  @override
  Future<void> connectPlexServer(PlexServer server) => plex.connect(server);

  @override
  Future<void> disconnect(String accountId) => plex.disconnect(accountId);

  @override
  Future<List<PlexSection>> musicSections(String accountId) =>
      plex.musicSections(accountId);

  @override
  Future<ImportReport> importSection(
    String accountId,
    String sectionKey, {
    void Function(int imported, int total)? onProgress,
  }) =>
      PlexImporter(db: db, plex: plex)
          .importSection(accountId, sectionKey, onProgress: onProgress);
}

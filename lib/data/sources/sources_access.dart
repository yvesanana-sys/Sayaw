import '../db/database.dart';
import 'plex/plex_api_client.dart';
import 'plex/plex_auth.dart';
import 'plex/plex_importer.dart';
import 'plex/plex_library.dart';

/// Connecting and disconnecting music services.
///
/// An interface for the same reason [LibraryAccess] is one: the screen that
/// runs a sign-in flow should be pumpable without a network stack, a keychain
/// or a database behind it.
abstract class SourcesAccess {
  Stream<List<SourceAccount>> watchAccounts();

  /// Starts a Plex sign-in. The operator approves [PlexPin.code] on plex.tv.
  Future<PlexPin> requestPlexPin();

  /// One poll. The screen drives the wait itself so it can show the code the
  /// whole time and let the operator give up.
  Future<String?> checkPlexPin(String pinId);

  /// Every server the approved account can reach.
  Future<List<PlexServer>> plexServers(String authToken);

  Future<void> connectPlexServer(PlexServer server);

  Future<void> disconnect(String accountId);

  /// The music libraries on a connected server.
  Future<List<PlexSection>> musicSections(String accountId);

  /// Copies one into the local mirror, so it can be searched offline.
  Future<ImportReport> importSection(
    String accountId,
    String sectionKey, {
    void Function(int imported, int total)? onProgress,
  });
}

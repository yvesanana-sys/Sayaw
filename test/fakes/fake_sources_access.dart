import 'dart:async';

import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/sources/plex/plex_api_client.dart';
import 'package:sayaw/data/sources/plex/plex_auth.dart';
import 'package:sayaw/data/sources/plex/plex_importer.dart';
import 'package:sayaw/data/sources/plex/plex_library.dart';
import 'package:sayaw/data/sources/sources_access.dart';

/// plex.tv, scripted.
///
/// The sign-in flow is a sequence of waits — for a PIN, for an approval, for a
/// list of servers — and a test drives each one by hand rather than by timing.
class FakeSources implements SourcesAccess {
  FakeSources({this.servers = const [], this.sections = const []});

  final _accounts = StreamController<List<SourceAccount>>.broadcast();
  List<SourceAccount> accounts = const [];

  /// Answered by [checkPlexPin] once [approve] is called.
  String? _token;

  List<PlexServer> servers;
  List<PlexSection> sections;

  /// Set to make the next [musicSections] or [importSection] fail.
  Object? importFailure;

  /// Progress the next import reports before finishing.
  List<(int, int)> importProgress = const [];

  ImportReport importResult =
      const ImportReport(added: 3, updated: 1, unchanged: 2, total: 6);

  final List<String> importedSections = [];

  /// Set to hold an import open until it is completed, so a test can look at
  /// the dialog while it is still running.
  Completer<void>? importGate;

  /// Set to make the next [requestPlexPin] fail.
  Object? pinFailure;

  final List<PlexServer> connected = [];
  final List<String> disconnected = [];
  int pinChecks = 0;
  int pinRequests = 0;

  void approve([String token = 'plex-token']) => _token = token;

  void publish(List<SourceAccount> next) {
    accounts = next;
    _accounts.add(next);
  }

  Future<void> close() => _accounts.close();

  @override
  Stream<List<SourceAccount>> watchAccounts() async* {
    yield accounts;
    yield* _accounts.stream;
  }

  @override
  Future<PlexPin> requestPlexPin() async {
    pinRequests++;
    if (pinFailure case final failure?) {
      pinFailure = null;
      throw failure;
    }
    return PlexPin(
      id: 'pin-1',
      code: 'AB12',
      linkUrl: Uri.parse('https://app.plex.tv/auth'),
    );
  }

  @override
  Future<String?> checkPlexPin(String pinId) async {
    pinChecks++;
    return _token;
  }

  @override
  Future<List<PlexServer>> plexServers(String authToken) async => servers;

  @override
  Future<void> connectPlexServer(PlexServer server) async {
    connected.add(server);
    publish([...accounts, accountFor(server)]);
  }

  @override
  Future<List<PlexSection>> musicSections(String accountId) async {
    if (importFailure case final failure?) {
      importFailure = null;
      throw failure;
    }
    return sections;
  }

  @override
  Future<ImportReport> importSection(
    String accountId,
    String sectionKey, {
    void Function(int imported, int total)? onProgress,
  }) async {
    importedSections.add(sectionKey);
    if (importFailure case final failure?) {
      importFailure = null;
      throw failure;
    }
    for (final (imported, total) in importProgress) {
      onProgress?.call(imported, total);
    }
    if (importGate case final gate?) await gate.future;
    return importResult;
  }

  @override
  Future<void> disconnect(String accountId) async {
    disconnected.add(accountId);
    publish([for (final a in accounts) if (a.id != accountId) a]);
  }

  static SourceAccount accountFor(PlexServer server) => SourceAccount(
        id: server.machineIdentifier,
        provider: SourceProvider.plex,
        displayName: server.name,
        keychainRef: 'plex:${server.machineIdentifier}',
        offlineEntitled: false,
        isOwned: server.owned,
        createdAt: DateTime.utc(2026),
      );
}

PlexServer fakeServer({
  String id = 'server-uuid',
  String name = 'Home Server',
  bool owned = true,
}) =>
    PlexServer(
      machineIdentifier: id,
      name: name,
      accessToken: 'server-token',
      owned: owned,
      connections: const [],
    );

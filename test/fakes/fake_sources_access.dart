import 'dart:async';

import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/sources/plex/plex_api_client.dart';
import 'package:sayaw/data/sources/plex/plex_auth.dart';
import 'package:sayaw/data/sources/sources_access.dart';

/// plex.tv, scripted.
///
/// The sign-in flow is a sequence of waits — for a PIN, for an approval, for a
/// list of servers — and a test drives each one by hand rather than by timing.
class FakeSources implements SourcesAccess {
  FakeSources({this.servers = const []});

  final _accounts = StreamController<List<SourceAccount>>.broadcast();
  List<SourceAccount> accounts = const [];

  /// Answered by [checkPlexPin] once [approve] is called.
  String? _token;

  List<PlexServer> servers;

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

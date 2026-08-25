import 'dart:async';

import 'package:dio/dio.dart';

import '../../db/database.dart';
import '../../media_resolver.dart';
import '../secret_store.dart';
import 'plex_identity.dart';

/// One way of reaching a server.
///
/// Plex hands out several per device and they are not interchangeable: on a
/// venue LAN the local address is dramatically faster and keeps working when
/// the WAN link dies, and the relay is a last resort that is bandwidth-capped
/// hard enough to matter for lossless audio.
class PlexConnection {
  const PlexConnection({
    required this.uri,
    required this.local,
    required this.relay,
  });

  final Uri uri;
  final bool local;
  final bool relay;

  /// Local first, then remote direct, then relay.
  int get preference => local ? 0 : (relay ? 2 : 1);

  static PlexConnection? fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    if (uri is! String) return null;
    return PlexConnection(
      uri: Uri.parse(uri),
      local: json['local'] == true,
      relay: json['relay'] == true,
    );
  }
}

class PlexServer {
  const PlexServer({
    required this.machineIdentifier,
    required this.name,
    required this.accessToken,
    required this.owned,
    required this.connections,
  });

  final String machineIdentifier;
  final String name;

  /// Per-server, and not the same as the account token. A shared library comes
  /// with its own.
  final String accessToken;

  /// Shared libraries get a stricter cache policy than your own server; see
  /// `MediaResolver.policyFor`.
  final bool owned;

  final List<PlexConnection> connections;

  static PlexServer? fromJson(Map<String, dynamic> json) {
    if (json['provides'] is String &&
        !(json['provides'] as String).split(',').contains('server')) {
      return null;
    }

    final id = json['clientIdentifier'];
    final token = json['accessToken'];
    if (id is! String || token is! String) return null;

    return PlexServer(
      machineIdentifier: id,
      name: json['name'] as String? ?? 'Plex Server',
      accessToken: token,
      owned: json['owned'] == true,
      connections: [
        for (final c in (json['connections'] as List? ?? const []))
          if (c is Map<String, dynamic>) ?PlexConnection.fromJson(c),
      ],
    );
  }
}

/// Talks to plex.tv and to the servers it points at.
class PlexApiClient implements PlexClient {
  PlexApiClient({
    required this.dio,
    required this.identity,
    required this.secrets,
    required this.accounts,
    this.probeTimeout = const Duration(seconds: 3),
  });

  final Dio dio;
  final PlexIdentity identity;
  final SecretStore secrets;
  final SourceAccountDao accounts;

  /// How long a connection gets to answer `/identity`. Short on purpose: this
  /// runs while the operator is waiting to start a set, and a dead WAN address
  /// would otherwise hold up a local one that is already answering.
  final Duration probeTimeout;

  /// The connection that answered, so the second track of the night does not
  /// race every address again.
  final Map<String, Uri> _resolved = {};

  @override
  String get clientIdentifier => identity.clientIdentifier;

  /// The key a server's token is stored under in the OS keychain.
  static String keychainRefFor(String machineIdentifier) =>
      'plex:$machineIdentifier';

  @override
  Future<String> token(String accountId) async {
    final account = await accounts.byId(accountId);
    if (account == null) {
      throw UnavailableOffline('That Plex server is no longer connected');
    }

    final token = await secrets.read(account.keychainRef);
    if (token == null) {
      throw UnavailableOffline(
          '${account.displayName} needs signing in to again');
    }
    return token;
  }

  /// Every server the account can reach, with the token for each.
  Future<List<PlexServer>> servers(String authToken) async {
    final response = await dio.getUri<List<dynamic>>(
      Uri.parse('https://plex.tv/api/v2/resources').replace(queryParameters: {
        'includeHttps': '1',
        'includeRelay': '1',
      }),
      options: Options(headers: {
        ...identity.headers,
        'X-Plex-Token': authToken,
      }),
    );

    return [
      for (final device in response.data ?? const [])
        if (device is Map<String, dynamic>) ?PlexServer.fromJson(device),
    ];
  }

  /// Signs a server in: stores its token in the keychain and its row in the
  /// database, keyed by machine identifier so reconnecting updates rather than
  /// duplicating.
  Future<String> connect(PlexServer server) async {
    final keychainRef = keychainRefFor(server.machineIdentifier);
    await secrets.write(keychainRef, server.accessToken);

    await accounts.connect(
      id: server.machineIdentifier,
      provider: SourceProvider.plex,
      displayName: server.name,
      machineIdentifier: server.machineIdentifier,
      keychainRef: keychainRef,
    );

    return server.machineIdentifier;
  }

  Future<void> disconnect(String accountId) async {
    final account = await accounts.byId(accountId);
    if (account == null) return;

    await secrets.delete(account.keychainRef);
    await accounts.forget(accountId);
    _resolved.remove(accountId);
  }

  @override
  Future<Uri> bestConnection(String accountId) async {
    if (_resolved[accountId] case final cached?) return cached;

    final account = await accounts.byId(accountId);
    if (account == null) {
      throw UnavailableOffline('That Plex server is no longer connected');
    }

    // The one that worked last time, tried alone first. On a venue LAN it is
    // usually still right, and this turns a five-way race into one request.
    if (account.baseUri case final remembered?) {
      final uri = Uri.parse(remembered);
      if (await _probe(uri, await token(accountId))) {
        return _resolved[accountId] = uri;
      }
    }

    final authToken = await token(accountId);
    final server = (await servers(authToken)).firstWhere(
      (s) => s.machineIdentifier == account.machineIdentifier,
      orElse: () =>
          throw UnavailableOffline('${account.displayName} is not reachable'),
    );

    final winner = await _race(server.connections, server.accessToken);
    if (winner == null) {
      throw UnavailableOffline(
          '${account.displayName} did not answer on any address');
    }

    await accounts.rememberConnection(accountId, winner);
    return _resolved[accountId] = winner;
  }

  /// Probes every address at once and takes the best one that answered.
  ///
  /// In parallel rather than in order because the failure being designed
  /// around is a remote address that hangs rather than refuses — waiting out
  /// its timeout before trying the local address is exactly the delay this
  /// avoids. Priority still decides the winner among those that replied.
  Future<Uri?> _race(List<PlexConnection> connections, String token) async {
    if (connections.isEmpty) return null;

    final ordered = [...connections]
      ..sort((a, b) => a.preference.compareTo(b.preference));

    final results = await Future.wait([
      for (final connection in ordered) _probe(connection.uri, token),
    ]);

    for (var i = 0; i < ordered.length; i++) {
      if (results[i]) return ordered[i].uri;
    }
    return null;
  }

  Future<bool> _probe(Uri uri, String token) async {
    try {
      final response = await dio.getUri<dynamic>(
        uri.replace(path: '/identity'),
        options: Options(
          headers: {...identity.headers, 'X-Plex-Token': token},
          sendTimeout: probeTimeout,
          receiveTimeout: probeTimeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } on Object {
      // Refused, timed out, TLS failure on a self-signed relay: all the same
      // answer, which is "not this one".
      return false;
    }
  }
}

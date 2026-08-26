import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/sources/plex/plex_api_client.dart';
import 'package:sayaw/data/sources/plex/plex_identity.dart';
import 'package:sayaw/data/sources/plex/plex_reachability.dart';

import '../fakes/fake_http.dart';
import '../fakes/fake_secret_store.dart';
import 'db_harness.dart';

const _identity = PlexIdentity(clientIdentifier: 'sayaw-test-uuid');

Map<String, dynamic> _server({required String id, required String name}) => {
      'name': name,
      'clientIdentifier': id,
      'accessToken': 'token-$id',
      'provides': 'server',
      'owned': true,
      'connections': [
        {'uri': 'https://$id.example:32400', 'local': true, 'relay': false},
      ],
    };

void main() {
  late SayawDatabase db;
  late FakeHttpAdapter http;
  late PlexApiClient plex;
  late PlexReachability probe;

  setUp(() {
    db = openTestDatabase();
    http = FakeHttpAdapter();
    plex = PlexApiClient(
      dio: fakeDio(http),
      identity: _identity,
      secrets: FakeSecretStore(),
      accounts: db.sourceAccountDao,
      probeTimeout: const Duration(milliseconds: 50),
    );
    probe = PlexReachability(accounts: db.sourceAccountDao, plex: plex);
  });

  test('nothing signed in is not the same as unreachable', () async {
    // A rig with only local files must not read as offline.
    expect(await probe.probe(), isEmpty);
    expect(http.requests, isEmpty);
  });

  test('reports each server under the name the operator sees', () async {
    // Not "Plex is down": a DJ with a home server and a friend's shared
    // library needs to know which of the two went, because only one of them
    // has tonight's music on it.
    await plex.connect(PlexServer.fromJson(
        _server(id: 'home', name: 'Home Server'))!);
    await plex.connect(PlexServer.fromJson(
        _server(id: 'marta', name: "Marta's Library"))!);

    http.on('GET plex.tv/api/v2/resources',
        FakeResponse([_server(id: 'home', name: 'Home Server')]));
    http.on('GET home.example/identity', FakeResponse({'size': 0}));

    final results = await probe.probe();

    expect(
      {for (final result in results) result.name: result.reachable},
      {'Home Server': true, "Marta's Library": false},
    );
  });

  test('a server that hangs does not hold up the verdict on the others',
      () async {
    // Probing in sequence would make the answer about the server that is
    // right there on the LAN wait out the timeout of the one that is gone.
    await plex.connect(PlexServer.fromJson(
        _server(id: 'home', name: 'Home Server'))!);
    await plex.connect(PlexServer.fromJson(
        _server(id: 'slow', name: 'Old NAS'))!);

    http.on('GET plex.tv/api/v2/resources',
        FakeResponse([_server(id: 'home', name: 'Home Server')]));
    http.on('GET home.example/identity', FakeResponse({'size': 0}));

    // The home server has played something, so its address is remembered.
    await plex.bestConnection('home');

    // Now the uplink goes: plex.tv accepts the connection and says nothing,
    // which is the only route left to a server never reached.
    http.on(
      'GET plex.tv/api/v2/resources',
      FakeResponse(const <dynamic>[], delay: const Duration(seconds: 5)),
    );

    final stopwatch = Stopwatch()..start();
    final results = await probe.probe();

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(
      {for (final result in results) result.name: result.reachable},
      {'Home Server': true, 'Old NAS': false},
    );
  });
}

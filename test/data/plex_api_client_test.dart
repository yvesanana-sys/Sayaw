import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/sources/plex/plex_api_client.dart';
import 'package:sayaw/data/sources/plex/plex_identity.dart';

import '../fakes/fake_http.dart';
import '../fakes/fake_secret_store.dart';
import 'db_harness.dart';

const _identity = PlexIdentity(clientIdentifier: 'sayaw-test-uuid');

/// One server on four addresses: the LAN, its public name, and the relay.
Map<String, dynamic> _server({
  String id = 'server-uuid',
  String name = 'Home Server',
  bool owned = true,
}) =>
    {
      'name': name,
      'clientIdentifier': id,
      'accessToken': 'server-token',
      'provides': 'server',
      'owned': owned,
      'connections': [
        {'uri': 'https://relay.plex.direct:443', 'local': false, 'relay': true},
        {'uri': 'https://public.example:32400', 'local': false, 'relay': false},
        {'uri': 'https://192-168-1-10.plex.direct:32400', 'local': true, 'relay': false},
      ],
    };

void main() {
  late SayawDatabase db;
  late FakeHttpAdapter http;
  late FakeSecretStore secrets;
  late PlexApiClient plex;

  setUp(() {
    db = openTestDatabase();
    http = FakeHttpAdapter();
    secrets = FakeSecretStore();
    plex = PlexApiClient(
      dio: fakeDio(http),
      identity: _identity,
      secrets: secrets,
      accounts: db.sourceAccountDao,
      probeTimeout: const Duration(milliseconds: 50),
    );
  });

  group('finding servers', () {
    test('reads the ones the account can reach', () async {
      http.on('GET plex.tv/api/v2/resources', FakeResponse([_server()]));

      final servers = await plex.servers('account-token');

      expect(servers.single.name, 'Home Server');
      expect(servers.single.machineIdentifier, 'server-uuid');
      expect(servers.single.accessToken, 'server-token');
      expect(servers.single.connections, hasLength(3));
    });

    test('asks for https and relay addresses, with the account token',
        () async {
      http.on('GET plex.tv/api/v2/resources', FakeResponse([_server()]));

      await plex.servers('account-token');

      final request = http.requests.single;
      expect(request.uri.queryParameters['includeHttps'], '1');
      expect(request.uri.queryParameters['includeRelay'], '1');
      expect(request.header('X-Plex-Token'), 'account-token');
    });

    test('players and other devices on the account are not servers', () async {
      http.on(
        'GET plex.tv/api/v2/resources',
        FakeResponse([
          {
            'name': 'Living Room TV',
            'clientIdentifier': 'tv',
            'accessToken': 't',
            'provides': 'player,controller',
            'connections': [],
          },
          _server(),
        ]),
      );

      expect([for (final s in await plex.servers('t')) s.name],
          ['Home Server']);
    });

    test('a shared library is marked as one', () async {
      http.on('GET plex.tv/api/v2/resources',
          FakeResponse([_server(owned: false)]));

      // MediaResolver.policyFor reads this: a shared library is not cacheable.
      expect((await plex.servers('t')).single.owned, isFalse);
    });
  });

  group('connecting a server', () {
    test('the token goes to the keychain and never to the database', () async {
      await plex.connect(PlexServer.fromJson(_server())!);

      expect(secrets.secrets['plex:server-uuid'], 'server-token');

      final account = (await db.sourceAccountDao.all()).single;
      expect(account.keychainRef, 'plex:server-uuid');
      expect(account.displayName, 'Home Server');
      expect(account.provider, SourceProvider.plex);

      // Nothing in the row is the token itself.
      final row = await db
          .customSelect('SELECT * FROM source_accounts')
          .getSingle();
      expect(row.data.values.map((v) => '$v'), isNot(contains('server-token')));
    });

    test('reconnecting the same server refreshes it rather than duplicating it',
        () async {
      await plex.connect(PlexServer.fromJson(_server())!);
      await plex.connect(
          PlexServer.fromJson(_server(name: 'Home Server (renamed)'))!);

      final accounts = await db.sourceAccountDao.all();
      expect(accounts, hasLength(1));
      expect(accounts.single.displayName, 'Home Server (renamed)');
    });

    test('disconnecting takes the secret with the row', () async {
      final id = await plex.connect(PlexServer.fromJson(_server())!);
      await plex.disconnect(id);

      expect(await db.sourceAccountDao.all(), isEmpty);
      expect(secrets.secrets, isEmpty);
    });

    test('the token comes back out of the keychain', () async {
      final id = await plex.connect(PlexServer.fromJson(_server())!);

      expect(await plex.token(id), 'server-token');
      expect(secrets.reads, contains('plex:server-uuid'));
    });

    test('a server that was disconnected reports that, not a null token',
        () async {
      await expectLater(
        plex.token('never-connected'),
        throwsA(isA<UnavailableOffline>()),
      );
    });

    test('a row whose secret has gone asks for a sign-in', () async {
      final id = await plex.connect(PlexServer.fromJson(_server())!);
      secrets.secrets.clear();

      await expectLater(
        plex.token(id),
        throwsA(isA<UnavailableOffline>().having(
            (e) => e.reason, 'reason', contains('signing in'))),
      );
    });
  });

  group('picking an address', () {
    late String accountId;

    setUp(() async {
      accountId = await plex.connect(PlexServer.fromJson(_server())!);
      http.on('GET plex.tv/api/v2/resources', FakeResponse([_server()]));
    });

    test('the LAN address wins when everything answers', () async {
      _allAnswer(http);

      expect(await plex.bestConnection(accountId),
          Uri.parse('https://192-168-1-10.plex.direct:32400'));
    });

    test('a hanging remote address does not hold up the local one', () async {
      // The venue's WAN link is dead: the public address accepts the socket
      // and then says nothing. Probing in sequence would wait it out.
      http.on('GET public.example/identity', FakeResponse.hangs());
      http.on('GET relay.plex.direct/identity', FakeResponse.hangs());
      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse({'size': 0}));

      expect(await plex.bestConnection(accountId),
          Uri.parse('https://192-168-1-10.plex.direct:32400'));
    });

    test('falls back to the public address away from the venue', () async {
      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());
      http.on('GET public.example/identity', FakeResponse({'size': 0}));
      http.on('GET relay.plex.direct/identity', FakeResponse({'size': 0}));

      expect(await plex.bestConnection(accountId),
          Uri.parse('https://public.example:32400'));
    });

    test('the relay is a last resort, not a peer', () async {
      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());
      http.on('GET public.example/identity', FakeResponse.refused());
      http.on('GET relay.plex.direct/identity', FakeResponse({'size': 0}));

      expect(await plex.bestConnection(accountId),
          Uri.parse('https://relay.plex.direct:443'));
    });

    test('a server that answers nowhere reports it in words', () async {
      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());
      http.on('GET public.example/identity', FakeResponse.refused());
      http.on('GET relay.plex.direct/identity', FakeResponse.refused());

      await expectLater(
        plex.bestConnection(accountId),
        throwsA(isA<UnavailableOffline>()
            .having((e) => e.reason, 'reason', contains('Home Server'))),
      );
    });

    test('the winner is remembered, so the next track does not race again',
        () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);

      final account = await db.sourceAccountDao.byId(accountId);
      expect(account!.baseUri, 'https://192-168-1-10.plex.direct:32400');
    });

    test('a second call does not go near the network', () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);
      final before = http.requests.length;

      await plex.bestConnection(accountId);

      expect(http.requests.length, before);
    });

    test('a remembered address is tried on its own before racing', () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);

      // A fresh client, as after a restart: the row remembers the address.
      final restarted = PlexApiClient(
        dio: fakeDio(http),
        identity: _identity,
        secrets: secrets,
        accounts: db.sourceAccountDao,
        probeTimeout: const Duration(milliseconds: 50),
      );
      http.requests.clear();

      expect(await restarted.bestConnection(accountId),
          Uri.parse('https://192-168-1-10.plex.direct:32400'));

      // One probe, not a resources call and four probes.
      expect(http.calls, ['GET 192-168-1-10.plex.direct/identity']);
    });

    test('a remembered address that has stopped working falls back to racing',
        () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);

      // The DJ took the laptop home: the LAN address is gone.
      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());

      final restarted = PlexApiClient(
        dio: fakeDio(http),
        identity: _identity,
        secrets: secrets,
        accounts: db.sourceAccountDao,
        probeTimeout: const Duration(milliseconds: 50),
      );

      expect(await restarted.bestConnection(accountId),
          Uri.parse('https://public.example:32400'));
    });
  });

  group('is the server there right now', () {
    late String accountId;

    setUp(() async {
      accountId = await plex.connect(PlexServer.fromJson(_server())!);
      http.on('GET plex.tv/api/v2/resources', FakeResponse([_server()]));
    });

    test('a server that answers costs one request to confirm', () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);
      http.requests.clear();

      expect(await plex.isReachable(accountId), isTrue);

      // This runs every thirty seconds for four hours. Re-racing all four
      // addresses each time would be the wrong shape entirely.
      expect(http.calls, ['GET 192-168-1-10.plex.direct/identity']);
    });

    test('a server that has stopped answering is not reachable', () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);

      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());

      expect(await plex.isReachable(accountId), isFalse);
    });

    test('and the address it gave up on is forgotten, so a move is survivable',
        () async {
      // Unplug the venue wifi, tether to a phone: the LAN address is gone and
      // the public one is now the only way in. Holding the old one would mean
      // a dead server for the rest of the night.
      _allAnswer(http);
      await plex.bestConnection(accountId);

      http.on('GET 192-168-1-10.plex.direct/identity', FakeResponse.refused());
      expect(await plex.isReachable(accountId), isFalse);

      http.requests.clear();
      expect(await plex.bestConnection(accountId),
          Uri.parse('https://public.example:32400'));
    });

    test('signed in but never reached is looked up, not assumed down',
        () async {
      // Nothing has played yet, so there is no remembered address. Reporting
      // the server as down here would put the app in offline mode on launch.
      _allAnswer(http);

      expect(await plex.isReachable(accountId), isTrue);
      expect(http.calls, contains('GET plex.tv/api/v2/resources'));
    });

    test('a portal that holds the request open does not stall the poll',
        () async {
      // A captive portal does not refuse: it accepts the connection and says
      // nothing. Without a bound here, every later probe queues behind it.
      http.on(
        'GET plex.tv/api/v2/resources',
        FakeResponse(const <dynamic>[], delay: const Duration(seconds: 5)),
      );

      final stopwatch = Stopwatch()..start();
      expect(await plex.isReachable(accountId), isFalse);

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('an account that is no longer connected is not reachable', () async {
      expect(await plex.isReachable('never-connected'), isFalse);
    });

    test('forgetting every connection makes the next resolve race again',
        () async {
      _allAnswer(http);
      await plex.bestConnection(accountId);

      plex.forgetConnection();
      http.requests.clear();
      await plex.bestConnection(accountId);

      expect(http.requests, isNotEmpty);
    });
  });
}

void _allAnswer(FakeHttpAdapter http) {
  for (final host in const [
    '192-168-1-10.plex.direct',
    'public.example',
    'relay.plex.direct',
  ]) {
    http.on('GET $host/identity', FakeResponse({'size': 0}));
  }
}

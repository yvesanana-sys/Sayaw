import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/sources/plex/plex_auth.dart';
import 'package:sayaw/data/sources/plex/plex_identity.dart';

import '../fakes/fake_http.dart';

const _identity = PlexIdentity(clientIdentifier: 'sayaw-test-uuid');

void main() {
  late FakeHttpAdapter http;
  late PlexAuth auth;

  setUp(() {
    http = FakeHttpAdapter();
    auth = PlexAuth(
      dio: fakeDio(http),
      identity: _identity,
      pollInterval: const Duration(milliseconds: 5),
      timeout: const Duration(milliseconds: 60),
    );
  });

  group('asking for a code', () {
    test('returns the code and somewhere to type it', () async {
      http.on('POST plex.tv/api/v2/pins',
          FakeResponse({'id': 12345, 'code': 'AB12'}));

      final pin = await auth.requestPin();

      expect(pin.id, '12345');
      expect(pin.code, 'AB12');
      expect(pin.linkUrl.toString(), contains('code=AB12'));
      expect(pin.linkUrl.toString(), contains('clientID=sayaw-test-uuid'));
    });

    test('identifies the app, and asks for JSON', () async {
      http.on('POST plex.tv/api/v2/pins',
          FakeResponse({'id': 1, 'code': 'AB12'}));

      await auth.requestPin();

      final request = http.requests.single;
      expect(request.uri.queryParameters['strong'], 'true');
      expect(request.header('X-Plex-Client-Identifier'), 'sayaw-test-uuid');
      expect(request.header('X-Plex-Product'), 'Sayaw');

      // Plex answers XML to anyone who does not say otherwise.
      expect(request.header('Accept'), 'application/json');
    });

    test('a reply with no code in it is an error, not a null pin', () async {
      http.on('POST plex.tv/api/v2/pins', FakeResponse({'error': 'nope'}));

      expect(auth.requestPin, throwsA(isA<PlexAuthException>()));
    });
  });

  group('waiting for approval', () {
    late PlexPin pin;

    setUp(() async {
      http.on('POST plex.tv/api/v2/pins',
          FakeResponse({'id': 42, 'code': 'AB12'}));
      pin = await auth.requestPin();
    });

    test('an approved code hands back a token', () async {
      http.on('GET plex.tv/api/v2/pins/42',
          FakeResponse({'id': 42, 'authToken': 'plex-token'}));

      expect(await auth.awaitApproval(pin), 'plex-token');
    });

    test('keeps asking while the code is still unapproved', () async {
      // Plex answers with the pin and a null token until someone approves it.
      http.on('GET plex.tv/api/v2/pins/42',
          FakeResponse({'id': 42, 'authToken': null}));

      final token = await auth.awaitApproval(pin);

      expect(token, isNull);
      expect(http.callsTo('GET plex.tv/api/v2/pins/42'), greaterThan(1));
    });

    test('an operator who never approves it is not an exception', () async {
      http.on('GET plex.tv/api/v2/pins/42', FakeResponse({'authToken': null}));

      // Null, so the caller shows the code again rather than an error.
      expect(await auth.awaitApproval(pin), isNull);
    });

    test('gives up when the budget runs out, by the clock', () async {
      http.on('GET plex.tv/api/v2/pins/42', FakeResponse({'authToken': null}));

      final started = DateTime.utc(2026, 8, 25, 19);
      var now = started;

      await withClock(Clock(() => now = now.add(const Duration(seconds: 30))),
          () => auth.awaitApproval(pin));

      // A 60 ms budget against a clock that jumps 30 s a tick: it stops on the
      // deadline rather than on wall time.
      expect(now.difference(started), lessThan(const Duration(minutes: 2)));
    });

    test('an expired code says so rather than polling a dead pin', () async {
      http.on('GET plex.tv/api/v2/pins/42',
          FakeResponse({'error': 'gone'}, status: 404));

      await expectLater(
        auth.awaitApproval(pin),
        throwsA(isA<PlexAuthException>()),
      );
      expect(http.callsTo('GET plex.tv/api/v2/pins/42'), 1);
    });

    test('a single poll is available for a UI that shows its own progress',
        () async {
      http.on('GET plex.tv/api/v2/pins/42',
          FakeResponse({'authToken': 'plex-token'}));

      expect(await auth.checkPin('42'), 'plex-token');
      expect(http.callsTo('GET plex.tv/api/v2/pins/42'), 1);
    });
  });
}

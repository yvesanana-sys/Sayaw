import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

import 'plex_identity.dart';

/// A PIN waiting to be approved on plex.tv.
class PlexPin {
  const PlexPin({required this.id, required this.code, required this.linkUrl});

  final String id;

  /// The four characters the operator types into plex.tv/link.
  final String code;

  /// Where to send them instead, if a browser can be opened for them.
  final Uri linkUrl;
}

/// Raised when plex.tv answers, but not the way the flow needs.
class PlexAuthException implements Exception {
  PlexAuthException(this.message);
  final String message;

  @override
  String toString() => 'PlexAuthException: $message';
}

/// Plex sign-in.
///
/// Not OAuth: plex.tv mints a short PIN, the operator approves it in a
/// browser, and the app polls until a token appears against it. That shape is
/// what makes it usable on a machine with no browser and on a tablet alike —
/// the approval can happen on a phone.
class PlexAuth {
  PlexAuth({
    required this.dio,
    required this.identity,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(minutes: 2),
  });

  final Dio dio;
  final PlexIdentity identity;

  /// Plex rate-limits this endpoint; two seconds is what their own clients use.
  final Duration pollInterval;

  /// A PIN expires after about fifteen minutes, but an operator who has not
  /// approved it in two is doing something else. Give up and let them retry
  /// rather than polling into the night.
  final Duration timeout;

  static final Uri _base = Uri.parse('https://plex.tv');

  Future<PlexPin> requestPin() async {
    final response = await dio.postUri<Map<String, dynamic>>(
      _base.replace(path: '/api/v2/pins', queryParameters: {'strong': 'true'}),
      options: Options(headers: identity.headers),
    );

    final body = response.data;
    final id = body?['id'];
    final code = body?['code'];
    if (id == null || code is! String) {
      throw PlexAuthException('plex.tv did not return a PIN');
    }

    return PlexPin(
      id: '$id',
      code: code,
      linkUrl: Uri.parse(
        'https://app.plex.tv/auth#?clientID=${identity.clientIdentifier}'
        '&code=$code&context%5Bdevice%5D%5Bproduct%5D=${identity.product}',
      ),
    );
  }

  /// Polls until the operator approves [pin], or until [timeout].
  ///
  /// Null means they never got round to it — a normal outcome, not an error,
  /// and the caller shows the code again rather than an exception.
  Future<String?> awaitApproval(PlexPin pin) async {
    final deadline = clock.now().add(timeout);

    while (clock.now().isBefore(deadline)) {
      final token = await _checkPin(pin.id);
      if (token != null) return token;
      await Future<void>.delayed(pollInterval);
    }

    return null;
  }

  /// One poll. Exposed so a UI can drive the wait itself and show progress.
  Future<String?> checkPin(String pinId) => _checkPin(pinId);

  Future<String?> _checkPin(String pinId) async {
    final response = await dio.getUri<Map<String, dynamic>>(
      _base.replace(path: '/api/v2/pins/$pinId'),
      options: Options(
        headers: identity.headers,
        // A PIN that has expired answers 404, and that is information rather
        // than a crash: the flow starts again with a fresh one.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 404) {
      throw PlexAuthException('That code expired. Start again for a new one.');
    }

    final token = response.data?['authToken'];
    return token is String && token.isNotEmpty ? token : null;
  }
}

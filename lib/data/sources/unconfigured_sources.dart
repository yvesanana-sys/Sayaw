import '../media_resolver.dart';

/// Stand-ins for the source clients that have not been written yet.
///
/// The resolver takes its collaborators as constructor arguments, so the app
/// cannot start without something in those slots. These say "not connected"
/// rather than pretending, which means a local library works end to end today
/// and a Plex or TIDAL row in a set reports a reason the operator can read
/// instead of throwing something unhandled at them mid-transition.
class UnconfiguredPlexClient implements PlexClient {
  const UnconfiguredPlexClient();

  @override
  String get clientIdentifier => 'sayaw';

  @override
  Future<String> token(String accountId) async =>
      throw UnavailableOffline('No Plex server is connected yet');

  @override
  Future<Uri> bestConnection(String accountId) async =>
      throw UnavailableOffline('No Plex server is connected yet');
}

class UnconfiguredTidalClient implements TidalClient {
  const UnconfiguredTidalClient();

  @override
  Future<String> accessToken(String accountId) async =>
      throw UnavailableOffline('No TIDAL account is connected yet');

  @override
  Future<TidalPlaybackInfo> playbackInfo(String accountId, String trackId) async =>
      throw UnavailableOffline('No TIDAL account is connected yet');

  /// Ships false, and stays false until TIDAL grants this integration an
  /// offline entitlement. `MediaResolver.policyFor` reads this rather than
  /// assuming, which is what keeps the restriction enforced by construction.
  @override
  bool hasOfflineEntitlement(String accountId) => false;
}

/// A cache with nothing in it, for a build with no cache directory to hand.
class NoMediaCache implements MediaCache {
  const NoMediaCache();

  @override
  Future<String?> completeFileFor(TrackSource source) async => null;
}

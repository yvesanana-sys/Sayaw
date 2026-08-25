/// Who Sayaw says it is to plex.tv.
///
/// The client identifier has to be stable across launches: Plex ties the
/// approved PIN, and every token minted from it, to that identifier. Generate
/// it once, keep it, and a reinstall that loses it means signing in again.
class PlexIdentity {
  const PlexIdentity({
    required this.clientIdentifier,
    this.product = 'Sayaw',
    this.version = '1.0',
    this.deviceName = 'Sayaw',
    this.platform,
  });

  final String clientIdentifier;
  final String product;
  final String version;

  /// What appears in the "Authorized Devices" list on plex.tv, so it should be
  /// something the operator recognises as the laptop in the DJ booth.
  final String deviceName;

  final String? platform;

  Map<String, String> get headers => {
        'X-Plex-Client-Identifier': clientIdentifier,
        'X-Plex-Product': product,
        'X-Plex-Version': version,
        'X-Plex-Device-Name': deviceName,
        'X-Plex-Platform': ?platform,
        // Plex answers XML unless asked otherwise, on every endpoint.
        'Accept': 'application/json',
      };
}

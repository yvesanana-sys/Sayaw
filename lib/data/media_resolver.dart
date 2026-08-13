import 'dart:io';
import 'dart:typed_data';

import '../audio/deck.dart';

/// Sealed source discriminator. Nothing outside this file needs to know which
/// service a track came from — the audio engine only ever sees [PlayableMedia].
sealed class TrackSource {
  const TrackSource();
}

class LocalSource extends TrackSource {
  const LocalSource({this.path, this.contentUri, this.bookmark});
  final String? path;
  final String? contentUri;   // Android SAF content://
  final Uint8List? bookmark;  // iOS/macOS security-scoped bookmark
}

class PlexSource extends TrackSource {
  const PlexSource({
    required this.accountId,
    required this.machineIdentifier,
    required this.ratingKey,
    this.partId,
    this.partUpdatedAt,
    this.isOwnedServer = true,
  });
  final String accountId;
  final String machineIdentifier;
  final String ratingKey;
  final String? partId;
  final int? partUpdatedAt;

  /// Shared libraries get a stricter default cache policy than your own server.
  final bool isOwnedServer;
}

class TidalSource extends TrackSource {
  const TidalSource({required this.accountId, required this.trackId});
  final String accountId;
  final String trackId;
}

/// What the app is permitted to write to disk for a given source.
enum CachePolicy {
  /// Persist freely. Local files and your own Plex library.
  allow,

  /// Buffer in memory for the current session only; never touch disk.
  sessionOnly,

  /// Do not retain at all.
  forbid,
}

enum NetworkMode { online, degraded, localOnly }

class UnavailableOffline implements Exception {
  UnavailableOffline(this.reason);
  final String reason;
  @override
  String toString() => 'UnavailableOffline: $reason';
}

/// Turns a stored track into something a [Deck] can play, and is the single
/// place that decides what may be cached.
///
/// Keeping the policy decision here — rather than in the download manager —
/// means there is exactly one code path that can authorise writing media bytes
/// to disk, which is what makes the TIDAL restriction enforceable by
/// construction rather than by convention.
class MediaResolver {
  MediaResolver({
    required this.plex,
    required this.tidal,
    required this.cache,
    required this.networkMode,
  });

  final PlexClient plex;
  final TidalClient tidal;
  final MediaCache cache;
  NetworkMode Function() networkMode;

  Future<PlayableMedia> resolve(
    TrackSource source, {
    double gainDb = 0.0,
    Duration cueIn = Duration.zero,
    Duration? cueOut,
  }) async {
    switch (source) {
      case LocalSource s:
        return _resolveLocal(s, gainDb, cueIn, cueOut);
      case PlexSource s:
        return _resolvePlex(s, gainDb, cueIn, cueOut);
      case TidalSource s:
        return _resolveTidal(s, gainDb, cueIn, cueOut);
    }
  }

  /// Policy is derived, never stored as free text, so a new source type can't
  /// accidentally default to "cacheable".
  CachePolicy policyFor(TrackSource source) => switch (source) {
        LocalSource _ => CachePolicy.allow,
        PlexSource s => s.isOwnedServer ? CachePolicy.allow : CachePolicy.forbid,
        // TIDAL: session-scoped only unless the account carries an offline
        // entitlement granted by TIDAL. See ARCHITECTURE.md §2.5 — persisting
        // decrypted TIDAL audio without that grant violates their terms.
        TidalSource s =>
          tidal.hasOfflineEntitlement(s.accountId) ? CachePolicy.allow : CachePolicy.sessionOnly,
      };

  // -------------------------------------------------------------------------

  Future<PlayableMedia> _resolveLocal(
      LocalSource s, double gainDb, Duration cueIn, Duration? cueOut) async {
    // macOS and iOS invalidate raw paths across launches; the bookmark is the
    // durable handle. Resolving it also re-acquires sandbox access.
    if (s.bookmark != null) {
      final resolved = await SecurityScopedBookmarks.resolve(s.bookmark!);
      if (resolved != null) {
        return PlayableMedia(
            uri: Uri.file(resolved), gainDb: gainDb, cueIn: cueIn, cueOut: cueOut);
      }
    }
    if (s.contentUri != null) {
      return PlayableMedia(
          uri: Uri.parse(s.contentUri!), gainDb: gainDb, cueIn: cueIn, cueOut: cueOut);
    }
    if (s.path != null && File(s.path!).existsSync()) {
      return PlayableMedia(
          uri: Uri.file(s.path!), gainDb: gainDb, cueIn: cueIn, cueOut: cueOut);
    }
    throw UnavailableOffline('Local file is missing or the volume is unmounted');
  }

  Future<PlayableMedia> _resolvePlex(
      PlexSource s, double gainDb, Duration cueIn, Duration? cueOut) async {
    final cached = await cache.completeFileFor(s);
    if (cached != null) {
      return PlayableMedia(
          uri: Uri.file(cached), gainDb: gainDb, cueIn: cueIn, cueOut: cueOut);
    }

    if (networkMode() == NetworkMode.localOnly) {
      throw UnavailableOffline('Plex server unreachable and track not cached');
    }

    final conn = await plex.bestConnection(s.accountId);
    final token = await plex.token(s.accountId);

    // Direct play when the codec is locally decodable; transcode otherwise.
    final uri = s.partId != null
        ? conn.resolve(
            '/library/parts/${s.partId}/${s.partUpdatedAt ?? 0}/file')
        : conn.resolve('/music/:/transcode/universal/start.mp3'
            '?path=/library/metadata/${s.ratingKey}&protocol=http&directPlay=1');

    return PlayableMedia(
      uri: uri,
      headers: {
        'X-Plex-Token': token,
        'X-Plex-Client-Identifier': plex.clientIdentifier,
        'Accept': 'application/json',
      },
      gainDb: gainDb,
      cueIn: cueIn,
      cueOut: cueOut,
    );
  }

  Future<PlayableMedia> _resolveTidal(
      TidalSource s, double gainDb, Duration cueIn, Duration? cueOut) async {
    if (networkMode() == NetworkMode.localOnly) {
      final cached = await cache.completeFileFor(s);
      if (cached != null && tidal.hasOfflineEntitlement(s.accountId)) {
        return PlayableMedia(
            uri: Uri.file(cached), gainDb: gainDb, cueIn: cueIn, cueOut: cueOut);
      }
      throw UnavailableOffline('TIDAL requires a connection for this track');
    }

    final info = await tidal.playbackInfo(s.accountId, s.trackId);

    return switch (info.manifestType) {
      // Unencrypted, short-lived direct URLs. Never persisted.
      TidalManifestType.bts => PlayableMedia(
          uri: info.directUrls.first,
          expiresAt: info.expiresAt,
          gainDb: gainDb + info.replayGainDb,
          cueIn: cueIn,
          cueOut: cueOut,
        ),

      // MPEG-DASH behind Widevine (Android/Windows) or FairPlay (Apple).
      // This branch is why mobile must run on ExoPlayer/AVPlayer.
      TidalManifestType.dash => PlayableMedia(
          uri: info.dashManifestUrl!,
          drm: DrmConfig(
            scheme: (Platform.isIOS || Platform.isMacOS)
                ? DrmScheme.fairplay
                : DrmScheme.widevine,
            licenseUri: info.licenseUri!,
            licenseHeaders: {'Authorization': 'Bearer ${await tidal.accessToken(s.accountId)}'},
          ),
          expiresAt: info.expiresAt,
          gainDb: gainDb + info.replayGainDb,
          cueIn: cueIn,
          cueOut: cueOut,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Collaborator interfaces — implemented in the service layer.
// ---------------------------------------------------------------------------

abstract class PlexClient {
  String get clientIdentifier;
  Future<String> token(String accountId);

  /// Races local, remote-direct and relay connections and returns the winner.
  /// On a venue LAN the local URI is dramatically faster and survives a dead WAN.
  Future<Uri> bestConnection(String accountId);
}

enum TidalManifestType { bts, dash }

class TidalPlaybackInfo {
  const TidalPlaybackInfo({
    required this.manifestType,
    this.directUrls = const [],
    this.dashManifestUrl,
    this.licenseUri,
    this.expiresAt,
    this.replayGainDb = 0.0,
  });

  final TidalManifestType manifestType;
  final List<Uri> directUrls;
  final Uri? dashManifestUrl;
  final Uri? licenseUri;
  final DateTime? expiresAt;
  final double replayGainDb;
}

abstract class TidalClient {
  Future<String> accessToken(String accountId);
  Future<TidalPlaybackInfo> playbackInfo(String accountId, String trackId);

  /// True only when TIDAL has granted this integration an offline entitlement.
  /// Ships false. Everything downstream reads this rather than assuming.
  bool hasOfflineEntitlement(String accountId);
}

abstract class MediaCache {
  Future<String?> completeFileFor(TrackSource source);

  /// Throws unless [MediaResolver.policyFor] returned [CachePolicy.allow].
  Future<void> download(TrackSource source, {required CachePolicy policy});
}

abstract class SecurityScopedBookmarks {
  static Future<String?> resolve(Uint8List bookmark) async => null; // platform channel
}

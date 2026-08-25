import 'package:sayaw/data/media_resolver.dart';

/// A Plex server that always answers, on a fixed URI.
class FakePlexClient implements PlexClient {
  FakePlexClient({this.connection = 'http://192.168.1.10:32400'});

  final String connection;
  final List<String> tokenRequests = [];

  @override
  String get clientIdentifier => 'sayaw-test';

  @override
  Future<String> token(String accountId) async {
    tokenRequests.add(accountId);
    return 'plex-token-$accountId';
  }

  @override
  Future<Uri> bestConnection(String accountId) async => Uri.parse(connection);
}

class FakeTidalClient implements TidalClient {
  FakeTidalClient({this.offlineEntitled = false});

  bool offlineEntitled;

  /// Appended to the URL, so a test can tell one signing apart from the next.
  /// Empty by default, which keeps a single resolve looking exactly like the
  /// real thing.
  String signature = '';

  DateTime? expiresAt = DateTime.utc(2026, 8, 25, 23);

  int playbackInfoCalls = 0;

  @override
  Future<String> accessToken(String accountId) async => 'tidal-token';

  @override
  Future<TidalPlaybackInfo> playbackInfo(String accountId, String trackId) async {
    playbackInfoCalls++;
    return TidalPlaybackInfo(
      manifestType: TidalManifestType.bts,
      directUrls: [
        Uri.parse('https://audio.tidal.com/$trackId.flac$signature'),
      ],
      expiresAt: expiresAt,
      replayGainDb: -1.5,
    );
  }

  @override
  bool hasOfflineEntitlement(String accountId) => offlineEntitled;
}

/// A cache that holds nothing unless a test puts something in it.
class FakeMediaCache implements MediaCache {
  final Map<String, String> files = {};

  @override
  Future<String?> completeFileFor(TrackSource source) async =>
      files[_key(source)];

  /// Pretends a download happened. The real one is `MediaDownloader`; this is
  /// only here so a test can say "this track is already cached".
  void hold(TrackSource source) => files[_key(source)] = '/cache/${_key(source)}';

  static String _key(TrackSource source) => switch (source) {
        LocalSource s => s.path ?? s.contentUri ?? '',
        PlexSource s => 'plex:${s.ratingKey}',
        TidalSource s => 'tidal:${s.trackId}',
      };
}

/// Reading a Plex server's music library.
library;

/// A library on the server. Only the music ones are of any use here.
class PlexSection {
  const PlexSection({required this.key, required this.title});

  final String key;
  final String title;

  /// Plex calls a music library an "artist" section, after what its top level
  /// holds.
  static PlexSection? fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'artist') return null;

    final key = json['key'];
    if (key == null) return null;

    return PlexSection(
      key: '$key',
      title: json['title'] as String? ?? 'Music',
    );
  }
}

/// One track as the server describes it.
class PlexTrack {
  const PlexTrack({
    required this.ratingKey,
    required this.title,
    this.artist,
    this.album,
    this.year,
    this.duration,
    this.partId,
    this.partUpdatedAt,
    this.codec,
    this.bitrateKbps,
  });

  final String ratingKey;
  final String title;
  final String? artist;
  final String? album;
  final int? year;
  final Duration? duration;

  /// The part is what actually gets played: a direct-play URL is built from
  /// this and [partUpdatedAt].
  final String? partId;

  /// Bumped by the server when the file behind the part changes, which is what
  /// makes a re-import able to skip everything that has not.
  final int? partUpdatedAt;

  final String? codec;
  final int? bitrateKbps;

  static PlexTrack? fromJson(Map<String, dynamic> json) {
    final ratingKey = json['ratingKey'];
    if (ratingKey == null) return null;

    // A track carries the artist two levels up and the album one: Plex nests
    // artist -> album -> track, and flattens the ancestors onto the leaf.
    final media = _first(json['Media']);
    final part = media == null ? null : _first(media['Part']);

    return PlexTrack(
      ratingKey: '$ratingKey',
      title: json['title'] as String? ?? 'Untitled',
      artist: json['grandparentTitle'] as String?,
      album: json['parentTitle'] as String?,
      year: json['year'] as int?,
      duration: _durationOf(json['duration']),
      partId: part?['id'] == null ? null : '${part!['id']}',
      partUpdatedAt: part?['updatedAt'] as int?,
      codec: media?['audioCodec'] as String?,
      bitrateKbps: media?['bitrate'] as int?,
    );
  }

  static Duration? _durationOf(Object? milliseconds) =>
      milliseconds is int && milliseconds > 0
          ? Duration(milliseconds: milliseconds)
          : null;

  static Map<String, dynamic>? _first(Object? list) {
    if (list is! List || list.isEmpty) return null;
    final first = list.first;
    return first is Map<String, dynamic> ? first : null;
  }
}

/// One page of a section.
class PlexPage {
  const PlexPage({required this.tracks, required this.total});

  final List<PlexTrack> tracks;

  /// How many the section holds in total, so a caller can show progress
  /// through a library of thirty thousand rather than a spinner.
  final int total;
}

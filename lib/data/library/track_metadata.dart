import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as tags;

/// What a scan managed to learn about a file from its tags.
///
/// Every field is optional on purpose. A DJ library is full of rips with no
/// tags, exports with the artist inside the title, and files whose container
/// the tag reader has never heard of — none of which stops them playing, so
/// none of them stops the file being imported.
class TrackMetadata {
  const TrackMetadata({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.duration,
    this.bitrateKbps,
    this.sampleRateHz,
  });

  final String? title;
  final String? artist;
  final String? album;
  final int? year;
  final Duration? duration;
  final int? bitrateKbps;
  final int? sampleRateHz;

  bool get isEmpty =>
      title == null && artist == null && album == null && duration == null;
}

/// Reading tags off a file.
///
/// An interface rather than a direct call so the scanner — which is where all
/// the decisions live — can be tested against files that do not exist, in
/// libraries of ten thousand tracks, without a single byte of audio.
abstract class MetadataReader {
  /// Null when nothing could be read. Implementations should not throw: a file
  /// that will not parse is a normal event during a library scan.
  Future<TrackMetadata?> read(File file);
}

/// The real one: ID3, Vorbis comments and iTunes atoms.
class TagMetadataReader implements MetadataReader {
  const TagMetadataReader();

  @override
  Future<TrackMetadata?> read(File file) async {
    try {
      final raw = tags.readMetadata(file);
      return TrackMetadata(
        title: _clean(raw.title),
        artist: _clean(raw.artist),
        album: _clean(raw.album),
        year: raw.year?.year,
        duration: raw.duration,
        // The parser reports bits per second; the schema stores kbps.
        bitrateKbps: raw.bitrate == null ? null : raw.bitrate! ~/ 1000,
        sampleRateHz: raw.sampleRate,
      );
    } on Object {
      // Unknown container, truncated file, or a tag frame the parser chokes
      // on. The file is still playable, so this is a null rather than a throw.
      return null;
    }
  }

  /// Tags arrive padded, and ID3v1 pads its fixed-width fields with NULs that
  /// end up inside the string rather than terminating it.
  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

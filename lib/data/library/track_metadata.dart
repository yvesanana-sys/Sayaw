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
    this.bpm,
  });

  final String? title;
  final String? artist;
  final String? album;
  final int? year;
  final Duration? duration;
  final int? bitrateKbps;
  final int? sampleRateHz;

  /// Beats per minute, where the file says so.
  ///
  /// What a floor is sorted by: a Waltz set that wanders between 84 and 174
  /// is two different dances. Very often absent — a DJ library is full of
  /// rips nobody analysed — so everything reading this has to cope with null.
  final double? bpm;

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
        bpm: _bpm(file),
      );
    } on Object {
      // Unknown container, truncated file, or a tag frame the parser chokes
      // on. The file is still playable, so this is a null rather than a throw.
      return null;
    }
  }

  /// BPM, which the generic `AudioMetadata` drops as format-specific.
  ///
  /// A second parse of the same file, which is not free during a scan of ten
  /// thousand tracks. The alternative is re-deriving every generic field from
  /// the format-specific tags by hand — five container types, each with its
  /// own fallback chain for something as ordinary as the artist — and getting
  /// one of those subtly wrong is a worse trade than parsing twice on an
  /// import that runs once.
  ///
  /// `getImage: false` matters: this call defaults to decoding cover art, and
  /// a 5 MB image per file would dwarf everything else about the scan.
  static double? _bpm(File file) {
    try {
      return switch (tags.readAllMetadata(file, getImage: false)) {
        // ID3v2 puts it in TBPM, as text.
        tags.Mp3Metadata m => parseBpm(m.bpm),

        // FLAC and OGG. The parser has no BPM field, so a `BPM` comment lands
        // in the bag of keys it did not recognise. Vorbis keys are
        // case-insensitive by spec and taggers disagree about which case to
        // write, so look the key up rather than index it.
        tags.VorbisMetadata m => parseBpm(_lookup(m.unknowns, 'BPM')),
        tags.ApeMetadata m => parseBpm(_lookup(m.unknowns, 'BPM')),

        // MP4's `tmpo` atom and RIFF have no route out of this parser.
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  static String? _lookup(Map<String, String> tags, String key) {
    for (final entry in tags.entries) {
      if (entry.key.toUpperCase() == key) return entry.value;
    }
    return null;
  }

  /// A BPM tag turned into a number, or null if it is not one.
  ///
  /// Tags are written by hand and by a decade of different taggers: "128",
  /// "128.5", "128 BPM", and — most commonly — "0", which is what a tagger
  /// writes for "not analysed" and must not be read as a real tempo.
  ///
  /// The upper bound rejects obvious garbage without arguing with the music.
  /// A Quickstep runs to about 208 and taggers sometimes store double-time,
  /// so anything under 400 is let through and treated as the file's opinion.
  static double? parseBpm(String? raw) {
    if (raw == null) return null;

    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(raw);
    if (match == null) return null;

    final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));
    if (value == null || value <= 0 || value >= 400) return null;
    return value;
  }

  /// Tags arrive padded, and ID3v1 pads its fixed-width fields with NULs that
  /// end up inside the string rather than terminating it.
  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

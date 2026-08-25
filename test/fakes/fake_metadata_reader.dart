import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sayaw/data/library/track_metadata.dart';

/// Tags without files.
///
/// Keyed by filename so a test can lay out a folder tree of empty files and
/// still describe what is supposedly inside them. Anything not in [tags] reads
/// as untagged, which is the case worth exercising most.
class FakeMetadataReader implements MetadataReader {
  FakeMetadataReader([Map<String, TrackMetadata>? tags])
      : tags = {...?tags};

  final Map<String, TrackMetadata> tags;

  /// Filenames handed to [read], in order. A rescan that re-reads a file it
  /// did not need to is the performance bug this catches.
  final List<String> reads = [];

  @override
  Future<TrackMetadata?> read(File file) async {
    final name = p.basename(file.path);
    reads.add(name);
    return tags[name];
  }
}

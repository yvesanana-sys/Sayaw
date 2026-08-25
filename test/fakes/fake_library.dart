import 'dart:io';

import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/library/library_scanner.dart';
import 'package:sayaw/data/media_resolver.dart' show CachePolicy;
import 'package:sayaw/ui/state/library_access.dart';

/// A library with no database under it.
///
/// Lets the pane be pumped at any window size with any number of rows, which
/// is what the layout, touch-target and keyboard tests actually care about.
class FakeLibrary implements LibraryAccess {
  FakeLibrary({List<Track>? tracks}) : tracks = tracks ?? libraryTracks();

  List<Track> tracks;

  /// Ids passed to [addToSet], in order.
  final List<String> added = [];

  /// Queries passed to [searchLibrary], in order.
  final List<String> queries = [];

  int recentCalls = 0;

  @override
  Future<List<Track>> searchLibrary(String query, {int limit = 50}) async {
    queries.add(query);
    final needle = query.toLowerCase();
    return [
      for (final track in tracks)
        if (track.title.toLowerCase().contains(needle) ||
            (track.artist ?? '').toLowerCase().contains(needle))
          track,
    ].take(limit).toList();
  }

  @override
  Future<List<Track>> recentTracks({int limit = 50}) async {
    recentCalls++;
    return tracks.take(limit).toList();
  }

  @override
  Future<void> addToSet(String trackId) async => added.add(trackId);

  @override
  Future<ScanReport> scanFolders(
    Iterable<Directory> folders, {
    void Function(int filesSeen, String path)? onProgress,
  }) async =>
      const ScanReport(
          added: 0, updated: 0, unchanged: 0, problems: [], missing: []);
}

/// Enough rows to overflow any test window, so a list that should scroll does.
List<Track> libraryTracks({int count = 40}) => [
      for (var i = 0; i < count; i++)
        Track(
          id: 'track-$i',
          sourceType: SourceType.local,
          localPath: '/music/$i.flac',
          title: 'Track $i',
          artist: i.isEven ? 'Dean Martin' : 'Georgia Gibbs',
          album: 'Ballroom Classics',
          durationMs: const Duration(minutes: 3),
          gainDb: 0,
          cueInMs: Duration.zero,
          isDrm: false,
          cachePolicy: CachePolicy.allow,
          addedAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
    ];

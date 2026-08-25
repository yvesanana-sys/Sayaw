import 'dart:io';

import '../../data/db/database.dart';
import '../../data/event_mode.dart';
import '../../data/library/library_scanner.dart';

/// What the library pane needs, and nothing else.
///
/// [PlaybackSession] implements it, but the pane asks for this instead so it
/// can be built and tested without an audio engine behind it — searching a
/// library has nothing to do with two decks and a crossfade.
abstract class LibraryAccess {
  /// Aggregated across local files, Plex and TIDAL, because they all live in
  /// the same table. Still works with the venue wifi down.
  Future<List<Track>> searchLibrary(String query, {int limit = 50});

  /// What to show before anyone has typed anything.
  Future<List<Track>> recentTracks({int limit = 50});

  /// Appends to the set that is open.
  Future<void> addToSet(String trackId);

  Future<ScanReport> scanFolders(
    Iterable<Directory> folders, {
    void Function(int filesSeen, String path)? onProgress,
  });
}

/// Preparing the open set to run without a connection.
///
/// Its own interface rather than a method on the session for the same reason
/// the library is: the screen that shows the report has no business reaching
/// for the transport.
abstract class EventModeAccess {
  /// Null when no set is open.
  String? get openPlaylistId;

  Future<PreflightReport> prepareForOffline({
    void Function(PreflightProgress)? onProgress,
  });
}

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

/// How the night is shaped: how many songs, and how much of each.
///
/// Its own interface, like the two above, so the dialog that edits it can be
/// pumped without an engine behind it.
abstract class SetShapeAccess {
  /// Null when no set is open.
  String? get openPlaylistId;

  /// What the open set is currently set to.
  Future<SetShape> readSetShape();

  /// Writes it, and applies as much of it as can be applied safely.
  ///
  /// Returns whether it took effect in full. See [PlaybackSession.writeSetShape]
  /// for why a running set only takes half of it.
  Future<bool> writeSetShape(SetShape shape);

  /// Whether a set is playing, which is what decides the above.
  bool get isRunning;
}

/// How many songs, and how much of each.
class SetShape {
  const SetShape({
    this.songLimit,
    this.songDuration,
    this.rotationGap = Duration.zero,
  });

  /// Stop after this many. Null plays the list as written.
  final int? songLimit;

  /// How much of each song to play. Null plays each to its end.
  final Duration? songDuration;

  /// Silence held between songs so a floor can change partners. Zero is an
  /// ordinary set.
  final Duration rotationGap;

  /// A set with a rotation gap is The Mixer: play, fade out, chime, wait,
  /// fade in, repeat until the song count runs out.
  bool get isRotation => rotationGap > Duration.zero;

  bool get isPlainList =>
      songLimit == null && songDuration == null && !isRotation;
}

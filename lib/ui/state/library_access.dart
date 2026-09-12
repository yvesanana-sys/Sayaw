import 'dart:io';

import '../../data/db/database.dart';
import '../../data/event_mode.dart';
import '../../data/library/library_scanner.dart';
import '../../data/set_ordering.dart';

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

  /// Every track the library would list for [query], without the cap the
  /// list on screen has, in the order a set built from them should play.
  Future<List<String>> everyTrackMatching(String query);

  /// Appends them all to the open set, in that order, as one write.
  Future<void> addAllToSet(List<String> trackIds);

  /// How many tracks the library holds.
  Future<int> libraryCount();

  /// Empties the library, and with it the set. Returns how many went.
  ///
  /// A clean start before a different folder is imported. The music files
  /// are never touched. Refused while music is playing — see
  /// [PlaybackSession.clearLibrary].
  Future<int> clearLibrary();

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

/// Tagging a row in the open set with one of the operator's own clips.
///
/// Narrow for the same reason the two above are: the queue list needs to
/// point a row at a cue and nothing else, and a widget that could reach the
/// transport from a picker is a widget that can stop a set by accident.
abstract class CueTagAccess {
  /// Tags [itemId] with [cueId], or clears the tag when [cueId] is null.
  ///
  /// Takes effect on the transition it was made for, not on the next time the
  /// set is opened — see [PlaybackSession.tagSoundCue].
  Future<void> tagSoundCue({required String itemId, required String? cueId});
}

/// Joining rows of the open set into one dance.
///
/// Narrow for the same reason [CueTagAccess] is.
abstract class MergeAccess {
  /// Runs [itemId] into whatever follows it as one dance, or separates them.
  ///
  /// Takes effect on the transition it changes, not on the next time the set
  /// is opened — see [PlaybackSession.setMergeIntoNext].
  Future<void> setMergeIntoNext({required String itemId, required bool merge});

  /// Runs every row of the open set into the next as one dance — a mixer of
  /// the whole set — or separates them all.
  Future<void> setMergeAll(bool merge);
}

/// The sets the operator keeps, and which one is open.
///
/// The set being played is already a playlist — every edit lands in it as
/// it is made. What this adds is a name on it, a copy of it, and a way to
/// put a different one on the decks.
abstract class SetsAccess {
  /// Every set, most recently used first.
  Stream<List<Playlist>> watchSets();

  /// Null when no set is open.
  String? get openPlaylistId;

  /// Whether music is playing, which is what decides whether another set can
  /// be put on the decks.
  bool get isRunning;

  /// A copy of the open set under [name] — its rows, their order, their
  /// announcers, their joins, and the set's own shape. Returns the new id.
  Future<String?> saveSetAs(String name);

  /// An empty set under [name], opened. Returns its id.
  Future<String> newSet(String name);

  /// Puts a set on the decks. Refused while music plays.
  Future<bool> openSet(String id);

  Future<void> renameSet(String id, String name);

  /// Removes a set. Removing the open one opens whatever was used last, or
  /// a fresh empty one.
  Future<void> deleteSet(String id);
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

  /// Puts the open set in tempo order and writes it back.
  ///
  /// Returns what had to be guessed to do it, so the operator can be told
  /// rather than left wondering why twelve rows did not move.
  Future<OrderedSet> orderSetByTempo(TempoOrder order);
}

/// How many songs, and how much of each.
class SetShape {
  const SetShape({
    this.songLimit,
    this.songDuration,
    this.rotationGap = Duration.zero,
    this.continuousFlow = false,
    this.snowballStages = 0,
  });

  /// Stop after this many. Null plays the list as written.
  final int? songLimit;

  /// How much of each song to play. Null plays each to its end.
  final Duration? songDuration;

  /// Silence held between songs so a floor can change partners. Zero is an
  /// ordinary set.
  final Duration rotationGap;

  /// No crossfade and nothing spoken between tracks — the next song takes
  /// over at the boundary. A Line of Dance set, where the floor should not be
  /// able to hear where one track ended.
  final bool continuousFlow;

  /// How many stages a Snowball climbs through. Zero is not a Snowball.
  final int snowballStages;

  bool get isSnowball => snowballStages > 1;

  /// A set with a rotation gap is The Mixer: play, fade out, chime, wait,
  /// fade in, repeat until the song count runs out.
  bool get isRotation => rotationGap > Duration.zero;

  bool get isPlainList =>
      songLimit == null &&
      songDuration == null &&
      !isRotation &&
      !continuousFlow &&
      !isSnowball;
}

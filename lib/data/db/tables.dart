/// Drift's mirror of `schema.sql`.
///
/// `schema.sql` stays the readable source of truth — it is what you hand
/// someone asking what the app stores — and `test/data/schema_parity_test.dart`
/// builds a database from each and fails if they have diverged in columns,
/// types, nullability, defaults or indexes.
library;

import 'package:drift/drift.dart';

import '../../audio/crossfade_engine.dart' show AnnounceMode;
import '../../audio/fade_curves.dart' show FadeCurve;
import 'converters.dart';
import 'enums.dart';

/// One connected Plex server or TIDAL account.
///
/// Credentials never land here: only [SourceAccounts.keychainRef], the key they
/// are stored under in the OS keychain.
@DataClassName('SourceAccount')
class SourceAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get provider => textEnum<SourceProvider>()();
  TextColumn get displayName => text()();

  /// Plex server uuid. A `ratingKey` is only unique within one server, which is
  /// why every remote track carries its account.
  TextColumn get machineIdentifier => text().nullable()();
  TextColumn get baseUri => text().nullable()();

  /// TIDAL requires this on most endpoints.
  TextColumn get countryCode => text().nullable()();

  TextColumn get keychainRef => text()();

  /// True only where TIDAL has granted this integration an offline licence.
  /// Ships false; `MediaResolver.policyFor` reads it rather than assuming.
  BoolColumn get offlineEntitled =>
      boolean().withDefault(const Constant(false))();

  IntColumn get lastVerifiedAt =>
      integer().nullable().map(const MillisConverter())();
  IntColumn get createdAt => integer().map(const MillisConverter())();

  /// Plex: your own server, or a library someone shared with you. A shared
  /// library is not cacheable — see `MediaResolver.policyFor` — so an unset
  /// value defaults to the restrictive answer rather than the convenient one.
  BoolColumn get isOwned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints =>
      ["CHECK (provider IN ('plex','tidal'))"];
}

/// Waltz, Cha-Cha, Bachata… each with the announcement it produces.
@DataClassName('DanceType')
class DanceTypes extends Table {
  TextColumn get id => text()();

  /// 'Viennese Waltz'.
  TextColumn get name => text().unique()();

  /// 'viennese-waltz'.
  TextColumn get slug => text().unique()();

  /// `{name}` and `{next}` are substituted at render time.
  TextColumn get ttsTemplate =>
      text().withDefault(const Constant('Next dance: {name}'))();

  /// A pre-recorded MC clip, which wins over TTS when present.
  TextColumn get customClipPath => text().nullable()();

  RealColumn get bpmMin => real().nullable()();
  RealColumn get bpmMax => real().nullable()();

  /// '3/4', '4/4'.
  TextColumn get timeSignature => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The canonical media object, source-polymorphic: exactly one of the local
/// and remote column blocks is populated, enforced by a table `CHECK`.
@DataClassName('Track')
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => textEnum<SourceType>()();
  TextColumn get accountId => text()
      .nullable()
      .references(SourceAccounts, #id, onDelete: KeyAction.setNull)();

  // local -------------------------------------------------------------------
  TextColumn get localPath => text().nullable()();

  /// Android SAF `content://` URI.
  TextColumn get contentUri => text().nullable()();

  /// iOS/macOS security-scoped bookmark. Raw paths from a file picker stop
  /// resolving after relaunch; this is the durable handle.
  BlobColumn get securityBookmark => blob().nullable()();

  // remote ------------------------------------------------------------------
  /// Plex `ratingKey` or TIDAL track id.
  TextColumn get sourceId => text().nullable()();

  /// Plex part id, for the direct-play URL.
  TextColumn get sourcePartId => text().nullable()();

  /// Plex part `updatedAt`, used to bust the cache when the file changes.
  IntColumn get sourceUpdatedAt => integer().nullable()();

  // metadata ----------------------------------------------------------------
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer()
      .withDefault(const Constant(0))
      .map(const MillisDurationConverter())();
  RealColumn get bpm => real().nullable()();
  TextColumn get musicalKey => text().nullable()();
  TextColumn get codec => text().nullable()();
  IntColumn get bitrateKbps => integer().nullable()();
  IntColumn get sampleRateHz => integer().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get artworkCachePath => text().nullable()();

  // playback shaping --------------------------------------------------------
  /// ReplayGain or a manual trim.
  RealColumn get gainDb => real().withDefault(const Constant(0.0))();

  /// Skips leading silence or a count-in.
  IntColumn get cueInMs => integer()
      .withDefault(const Constant(0))
      .map(const MillisDurationConverter())();

  /// Null plays to the end.
  IntColumn get cueOutMs =>
      integer().nullable().map(const MillisDurationConverter())();

  // rights / caching --------------------------------------------------------
  BoolColumn get isDrm => boolean().withDefault(const Constant(false))();
  TextColumn get cachePolicy => text()
      .withDefault(const Constant('allow'))
      .map(const CachePolicyConverter())();

  TextColumn get defaultDanceTypeId => text()
      .nullable()
      .references(DanceTypes, #id, onDelete: KeyAction.setNull)();

  IntColumn get addedAt => integer().map(const MillisConverter())();
  IntColumn get updatedAt => integer().map(const MillisConverter())();
  IntColumn get lastVerifiedAt =>
      integer().nullable().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (source_type IN ('local','plex','tidal'))",
        "CHECK (cache_policy IN ('allow','session_only','forbid'))",
        // A local track needs a path; a remote track needs an id and an account.
        'CHECK ('
            "(source_type = 'local' AND (local_path IS NOT NULL OR content_uri IS NOT NULL))"
            " OR (source_type IN ('plex','tidal') AND source_id IS NOT NULL AND account_id IS NOT NULL)"
            ')',
      ];
}

/// An event, a set, or a practice list, carrying the defaults its rows inherit.
@DataClassName('Playlist')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// 'social', 'competition', 'showcase', 'practice'. Deliberately free text:
  /// house styles vary and an unknown value should not fail an insert.
  TextColumn get eventKind => text().nullable()();
  IntColumn get eventDate =>
      integer().nullable().map(const MillisConverter())();

  // defaults, overridable per item -----------------------------------------
  IntColumn get crossfadeMs => integer()
      .withDefault(const Constant(4000))
      .map(const MillisDurationConverter())();
  TextColumn get fadeInCurve => textEnum<FadeCurve>()
      .withDefault(const Constant('equalPower'))();
  TextColumn get fadeOutCurve => textEnum<FadeCurve>()
      .withDefault(const Constant('equalPower'))();
  TextColumn get announceMode => textEnum<AnnounceMode>()
      .withDefault(const Constant('beforeMusic'))();

  /// Music level while the voice plays, as a fraction of the current level.
  RealColumn get duckLevel => real().withDefault(const Constant(0.20))();
  IntColumn get duckFadeMs => integer()
      .withDefault(const Constant(600))
      .map(const MillisDurationConverter())();
  IntColumn get duckHoldMs => integer()
      .withDefault(const Constant(250))
      .map(const MillisDurationConverter())();
  IntColumn get duckRestoreFadeMs => integer()
      .withDefault(const Constant(900))
      .map(const MillisDurationConverter())();

  TextColumn get ttsVoiceId => text().nullable()();
  RealColumn get ttsRate => real().withDefault(const Constant(0.5))();
  RealColumn get ttsPitch => real().withDefault(const Constant(1.0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get updatedAt => integer().map(const MillisConverter())();

  // How the set is shaped ---------------------------------------------------
  //
  // Declared last, after the timestamps, because that is where `ALTER TABLE
  // ADD COLUMN` puts them. An install that upgraded and one created fresh have
  // to end up with the same table, down to column order —
  // `test/data/schema_migration_test.dart` asserts exactly that.

  /// Stop after this many songs. Null plays the list as written, which is what
  /// a set built track by track wants.
  IntColumn get songLimit => integer().nullable()();

  /// How much of each song to play before handing over — two minutes of every
  /// track in a rotation, a competition round's ninety seconds. Null plays
  /// each track to its end. A row's own `targetDurationMs` overrides this.
  IntColumn get targetDurationMs =>
      integer().nullable().map(const MillisDurationConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (announce_mode IN ('off','beforeMusic','duckOver'))",
        'CHECK (duck_level BETWEEN 0.0 AND 1.0)',
      ];
}

/// The ordered rows of a playlist.
///
/// [position] is a `REAL`, not an index: dragging one track in a 400-song event
/// playlist writes one row instead of renumbering four hundred, which matters
/// because that write happens while audio is playing off the same file. See
/// `fractional_order.dart`.
@DataClassName('PlaylistItem')
class PlaylistItems extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();
  RealColumn get position => real()();

  TextColumn get itemType => textEnum<PlaylistItemType>()
      .withDefault(const Constant('track'))();

  TextColumn get trackId => text()
      .nullable()
      .references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get danceTypeId => text()
      .nullable()
      .references(DanceTypes, #id, onDelete: KeyAction.setNull)();

  // per-item announcement overrides ----------------------------------------
  TextColumn get announceMode => textEnum<AnnounceMode>().nullable()();

  /// Overrides the dance type's template.
  TextColumn get announcementText => text().nullable()();

  /// Overrides TTS entirely.
  TextColumn get announcementClipPath => text().nullable()();

  // per-item transition overrides. Null inherits from the playlist. ---------
  IntColumn get crossfadeMs =>
      integer().nullable().map(const MillisDurationConverter())();
  TextColumn get fadeInCurve => textEnum<FadeCurve>().nullable()();
  TextColumn get fadeOutCurve => textEnum<FadeCurve>().nullable()();

  // per-item playback shaping ----------------------------------------------
  IntColumn get startOffsetMs => integer()
      .withDefault(const Constant(0))
      .map(const MillisDurationConverter())();

  /// A hard stop point.
  IntColumn get endOffsetMs =>
      integer().nullable().map(const MillisDurationConverter())();

  /// e.g. 1:45 for a competition round.
  IntColumn get targetDurationMs =>
      integer().nullable().map(const MillisDurationConverter())();

  RealColumn get gainOffsetDb => real().withDefault(const Constant(0.0))();

  /// Only meaningful when [itemType] is [PlaylistItemType.silence].
  IntColumn get silenceMs =>
      integer().nullable().map(const MillisDurationConverter())();

  /// Stop after this row and wait for the operator — applause, MC handover.
  BoolColumn get pauseAfter => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get updatedAt => integer().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (item_type IN ('track','announcement','silence','marker'))",
        "CHECK (announce_mode IN ('off','beforeMusic','duckOver'))",
        "CHECK (item_type <> 'track' OR track_id IS NOT NULL)",
      ];
}

/// What has been downloaded.
///
/// [policyAllowsPersist] is written by `MediaResolver` from the DRM matrix and
/// is the single gate on ever writing media bytes to disk.
@DataClassName('CacheEntry')
class CacheEntries extends Table {
  TextColumn get trackId =>
      text().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get state =>
      textEnum<CacheState>().withDefault(const Constant('none'))();
  TextColumn get cachePath => text().nullable()();
  IntColumn get byteSize => integer().withDefault(const Constant(0))();
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();

  /// Keychain ref for the at-rest encryption key.
  TextColumn get encryptionKeyRef => text().nullable()();
  BoolColumn get policyAllowsPersist =>
      boolean().withDefault(const Constant(false))();

  /// Offline Widevine or persistent FairPlay key.
  TextColumn get drmLicensePath => text().nullable()();
  IntColumn get drmLicenseExpiresAt =>
      integer().nullable().map(const MillisConverter())();

  /// Exempt from LRU eviction.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get expiresAt =>
      integer().nullable().map(const MillisConverter())();
  IntColumn get lastAccessedAt =>
      integer().nullable().map(const MillisConverter())();
  IntColumn get createdAt => integer().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {trackId};

  @override
  List<String> get customConstraints => [
        "CHECK (state IN ('none','pending','partial','complete','expired','failed'))",
      ];
}

/// Rendered announcement audio, keyed by a hash of (text, voice, rate, pitch).
///
/// The row class is `AnnouncementCacheRow` rather than `AnnouncementClip`:
/// the audio layer already owns that name for the thing it plays, and
/// `DriftAnnouncementCache` maps between the two.
///
/// [durationMs] is the reason announcements are synthesised to a file rather
/// than spoken directly: the duck envelope needs to know how long the voice
/// will last before it starts.
@DataClassName('AnnouncementCacheRow')
class AnnouncementCache extends Table {
  TextColumn get hash => text()();
  TextColumn get body => text().named('text')();
  TextColumn get voiceId => text().nullable()();
  RealColumn get rate => real()();
  RealColumn get pitch => real()();
  TextColumn get filePath => text()();
  IntColumn get durationMs => integer().map(const MillisDurationConverter())();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get lastUsedAt =>
      integer().nullable().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {hash};
}

/// Powers "don't repeat within N hours", which is genuinely useful across a
/// long social night.
@DataClassName('PlayHistoryEntry')
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()
      .nullable()
      .references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get playlistId => text()
      .nullable()
      .references(Playlists, #id, onDelete: KeyAction.setNull)();
  TextColumn get danceTypeId => text()
      .nullable()
      .references(DanceTypes, #id, onDelete: KeyAction.setNull)();
  IntColumn get startedAt => integer().map(const MillisConverter())();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get playedMs => integer()
      .withDefault(const Constant(0))
      .map(const MillisDurationConverter())();
}

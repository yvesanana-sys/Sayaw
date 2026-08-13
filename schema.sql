-- ============================================================================
-- Dance Media Player — SQLite schema (Drift-compatible)
-- Times are INTEGER epoch milliseconds (UTC). Durations are milliseconds.
-- ============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ---------------------------------------------------------------------------
-- Connected services. Plex ratingKeys are only unique per server, so every
-- remote track must carry the account it came from.
-- ---------------------------------------------------------------------------
CREATE TABLE source_accounts (
  id                  TEXT PRIMARY KEY,
  provider            TEXT NOT NULL CHECK (provider IN ('plex','tidal')),
  display_name        TEXT NOT NULL,
  machine_identifier  TEXT,          -- Plex: server uuid
  base_uri            TEXT,          -- Plex: best-known connection
  country_code        TEXT,          -- TIDAL: required on most endpoints
  -- Credentials live in the OS keychain, keyed by this id. Never stored here.
  keychain_ref        TEXT NOT NULL,
  offline_entitled    INTEGER NOT NULL DEFAULT 0,  -- TIDAL offline license grant
  last_verified_at    INTEGER,
  created_at          INTEGER NOT NULL
);

-- ---------------------------------------------------------------------------
-- Dance types. One row per Waltz / Cha-Cha / Bachata / ...
-- ---------------------------------------------------------------------------
CREATE TABLE dance_types (
  id                  TEXT PRIMARY KEY,
  name                TEXT NOT NULL UNIQUE,        -- 'Viennese Waltz'
  slug                TEXT NOT NULL UNIQUE,        -- 'viennese-waltz'
  -- '{name}' and '{next}' are substituted at render time.
  tts_template        TEXT NOT NULL DEFAULT 'Next dance: {name}',
  custom_clip_path    TEXT,                        -- pre-recorded MC audio, wins over TTS
  bpm_min             REAL,
  bpm_max             REAL,
  time_signature      TEXT,                        -- '3/4', '4/4'
  color_hex           TEXT,
  sort_index          INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Tracks. Source-polymorphic: exactly one of the source blocks is populated.
-- ---------------------------------------------------------------------------
CREATE TABLE tracks (
  id                  TEXT PRIMARY KEY,            -- app-generated uuid
  source_type         TEXT NOT NULL CHECK (source_type IN ('local','plex','tidal')),
  account_id          TEXT REFERENCES source_accounts(id) ON DELETE SET NULL,

  -- local ---------------------------------------------------------------
  local_path          TEXT,                        -- desktop absolute path
  content_uri         TEXT,                        -- Android SAF content://
  security_bookmark   BLOB,                        -- iOS/macOS security-scoped bookmark

  -- remote --------------------------------------------------------------
  source_id           TEXT,                        -- Plex ratingKey | TIDAL track id
  source_part_id      TEXT,                        -- Plex part id (direct play URL)
  source_updated_at   INTEGER,                     -- Plex part updatedAt (cache busting)

  -- metadata ------------------------------------------------------------
  title               TEXT NOT NULL,
  artist              TEXT,
  album               TEXT,
  album_artist        TEXT,
  year                INTEGER,
  duration_ms         INTEGER NOT NULL DEFAULT 0,
  bpm                 REAL,
  musical_key         TEXT,
  codec               TEXT,
  bitrate_kbps        INTEGER,
  sample_rate_hz      INTEGER,
  artwork_url         TEXT,
  artwork_cache_path  TEXT,

  -- playback shaping ----------------------------------------------------
  gain_db             REAL NOT NULL DEFAULT 0.0,   -- ReplayGain or manual trim
  cue_in_ms           INTEGER NOT NULL DEFAULT 0,  -- skip leading silence/count-in
  cue_out_ms          INTEGER,                     -- NULL = play to end

  -- rights / caching ----------------------------------------------------
  is_drm              INTEGER NOT NULL DEFAULT 0,
  cache_policy        TEXT NOT NULL DEFAULT 'allow'
                        CHECK (cache_policy IN ('allow','session_only','forbid')),

  default_dance_type_id TEXT REFERENCES dance_types(id) ON DELETE SET NULL,

  added_at            INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,
  last_verified_at    INTEGER,

  -- A local track needs a path; a remote track needs an id and an account.
  CHECK (
    (source_type = 'local' AND (local_path IS NOT NULL OR content_uri IS NOT NULL))
    OR (source_type IN ('plex','tidal') AND source_id IS NOT NULL AND account_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_tracks_remote_identity
  ON tracks (source_type, account_id, source_id)
  WHERE source_type <> 'local';

CREATE UNIQUE INDEX idx_tracks_local_path
  ON tracks (local_path) WHERE local_path IS NOT NULL;

CREATE INDEX idx_tracks_search ON tracks (title, artist);
CREATE INDEX idx_tracks_bpm    ON tracks (bpm);

-- Full-text search over the local mirror of all sources.
CREATE VIRTUAL TABLE tracks_fts USING fts5(
  title, artist, album,
  content = 'tracks', content_rowid = 'rowid', tokenize = 'unicode61'
);

-- ---------------------------------------------------------------------------
-- Playlists (an event, a set, a practice list).
-- ---------------------------------------------------------------------------
CREATE TABLE playlists (
  id                     TEXT PRIMARY KEY,
  name                   TEXT NOT NULL,
  description            TEXT,
  event_kind             TEXT,                     -- 'social','competition','showcase','practice'
  event_date             INTEGER,

  -- defaults, overridable per item
  crossfade_ms           INTEGER NOT NULL DEFAULT 4000,
  fade_in_curve          TEXT NOT NULL DEFAULT 'equalPower',
  fade_out_curve         TEXT NOT NULL DEFAULT 'equalPower',
  announce_mode          TEXT NOT NULL DEFAULT 'beforeMusic'
                           CHECK (announce_mode IN ('off','beforeMusic','duckOver')),
  duck_level             REAL NOT NULL DEFAULT 0.20 CHECK (duck_level BETWEEN 0.0 AND 1.0),
  duck_fade_ms           INTEGER NOT NULL DEFAULT 600,
  duck_hold_ms           INTEGER NOT NULL DEFAULT 250,
  duck_restore_fade_ms   INTEGER NOT NULL DEFAULT 900,

  tts_voice_id           TEXT,
  tts_rate               REAL NOT NULL DEFAULT 0.5,
  tts_pitch              REAL NOT NULL DEFAULT 1.0,

  is_archived            INTEGER NOT NULL DEFAULT 0,
  created_at             INTEGER NOT NULL,
  updated_at             INTEGER NOT NULL
);

-- ---------------------------------------------------------------------------
-- Ordered playlist rows. Fractional `position` makes drag-and-drop a
-- single-row UPDATE instead of a full renumber.
-- ---------------------------------------------------------------------------
CREATE TABLE playlist_items (
  id                     TEXT PRIMARY KEY,
  playlist_id            TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  position               REAL NOT NULL,

  item_type              TEXT NOT NULL DEFAULT 'track'
                           CHECK (item_type IN ('track','announcement','silence','marker')),

  track_id               TEXT REFERENCES tracks(id) ON DELETE CASCADE,
  dance_type_id          TEXT REFERENCES dance_types(id) ON DELETE SET NULL,

  -- per-item announcement overrides
  announce_mode          TEXT CHECK (announce_mode IN ('off','beforeMusic','duckOver')),
  announcement_text      TEXT,                     -- overrides the dance type template
  announcement_clip_path TEXT,                     -- overrides TTS entirely

  -- per-item transition overrides (NULL = inherit from playlist)
  crossfade_ms           INTEGER,
  fade_in_curve          TEXT,
  fade_out_curve         TEXT,

  -- per-item playback shaping
  start_offset_ms        INTEGER NOT NULL DEFAULT 0,
  end_offset_ms          INTEGER,                  -- hard stop point
  target_duration_ms     INTEGER,                  -- e.g. 105000 for a comp round
  gain_offset_db         REAL NOT NULL DEFAULT 0.0,
  silence_ms             INTEGER,                  -- item_type='silence'

  pause_after            INTEGER NOT NULL DEFAULT 0,  -- wait for MC / applause
  notes                  TEXT,

  created_at             INTEGER NOT NULL,
  updated_at             INTEGER NOT NULL,

  CHECK (item_type <> 'track' OR track_id IS NOT NULL)
);

CREATE UNIQUE INDEX idx_items_order ON playlist_items (playlist_id, position);
CREATE INDEX idx_items_track ON playlist_items (track_id);

-- ---------------------------------------------------------------------------
-- Downloaded media. `policy_allows_persist` is written by MediaResolver from
-- the DRM matrix and is the single gate on ever writing bytes to disk.
-- ---------------------------------------------------------------------------
CREATE TABLE cache_entries (
  track_id               TEXT PRIMARY KEY REFERENCES tracks(id) ON DELETE CASCADE,
  state                  TEXT NOT NULL DEFAULT 'none'
                           CHECK (state IN ('none','pending','partial','complete','expired','failed')),
  cache_path             TEXT,
  byte_size              INTEGER NOT NULL DEFAULT 0,
  bytes_downloaded       INTEGER NOT NULL DEFAULT 0,
  encryption_key_ref     TEXT,                     -- keychain ref for at-rest encryption
  policy_allows_persist  INTEGER NOT NULL DEFAULT 0,
  drm_license_path       TEXT,                     -- offline Widevine / persistent FairPlay key
  drm_license_expires_at INTEGER,
  pinned                 INTEGER NOT NULL DEFAULT 0,  -- exempt from LRU eviction
  expires_at             INTEGER,
  last_accessed_at       INTEGER,
  created_at             INTEGER NOT NULL
);

CREATE INDEX idx_cache_lru ON cache_entries (pinned, last_accessed_at)
  WHERE state = 'complete';

-- ---------------------------------------------------------------------------
-- Rendered announcement audio, keyed by a hash of (text, voice, rate, pitch).
-- Lets Event Mode pre-render everything before doors open.
-- ---------------------------------------------------------------------------
CREATE TABLE announcement_cache (
  hash                   TEXT PRIMARY KEY,
  text                   TEXT NOT NULL,
  voice_id               TEXT,
  rate                   REAL NOT NULL,
  pitch                  REAL NOT NULL,
  file_path              TEXT NOT NULL,
  duration_ms            INTEGER NOT NULL,         -- the reason we render to file
  created_at             INTEGER NOT NULL,
  last_used_at           INTEGER
);

-- ---------------------------------------------------------------------------
-- Play history — powers "don't repeat within N hours" across a long night.
-- ---------------------------------------------------------------------------
CREATE TABLE play_history (
  id                     INTEGER PRIMARY KEY AUTOINCREMENT,
  track_id               TEXT REFERENCES tracks(id) ON DELETE CASCADE,
  playlist_id            TEXT REFERENCES playlists(id) ON DELETE SET NULL,
  dance_type_id          TEXT REFERENCES dance_types(id) ON DELETE SET NULL,
  started_at             INTEGER NOT NULL,
  completed              INTEGER NOT NULL DEFAULT 0,
  played_ms              INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_history_recent ON play_history (track_id, started_at DESC);

-- ---------------------------------------------------------------------------
-- Availability view. Drives the offline UI and engine skip logic in one query.
-- ---------------------------------------------------------------------------
CREATE VIEW v_item_availability AS
SELECT
  pi.id                AS item_id,
  pi.playlist_id,
  pi.position,
  pi.item_type,
  t.id                 AS track_id,
  t.source_type,
  CASE
    WHEN pi.item_type IN ('announcement','silence','marker') THEN 1
    WHEN t.source_type = 'local'                             THEN 1
    WHEN c.state = 'complete'
     AND (c.expires_at IS NULL OR c.expires_at > CAST(strftime('%s','now') AS INTEGER) * 1000)
                                                             THEN 1
    ELSE 0
  END                  AS offline_playable
FROM playlist_items pi
LEFT JOIN tracks        t ON t.id = pi.track_id
LEFT JOIN cache_entries c ON c.track_id = t.id;

-- ---------------------------------------------------------------------------
-- Keep FTS in sync.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_tracks_fts_ins AFTER INSERT ON tracks BEGIN
  INSERT INTO tracks_fts(rowid, title, artist, album)
  VALUES (new.rowid, new.title, new.artist, new.album);
END;

CREATE TRIGGER trg_tracks_fts_del AFTER DELETE ON tracks BEGIN
  INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album)
  VALUES ('delete', old.rowid, old.title, old.artist, old.album);
END;

CREATE TRIGGER trg_tracks_fts_upd AFTER UPDATE ON tracks BEGIN
  INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album)
  VALUES ('delete', old.rowid, old.title, old.artist, old.album);
  INSERT INTO tracks_fts(rowid, title, artist, album)
  VALUES (new.rowid, new.title, new.artist, new.album);
END;

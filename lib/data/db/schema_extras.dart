/// The parts of `schema.sql` that Drift's table DSL cannot express.
///
/// FTS5 virtual tables, triggers, views, partial indexes and `DESC` index
/// columns have no Dart equivalent, so they are kept here as the same SQL text
/// that appears in `schema.sql`. `createAll()` builds the tables; these run
/// straight after it.
library;

/// What to run to get a database from one schema version to the next, keyed by
/// the version being moved *to*.
///
/// Kept as SQL next to the DDL it amends, so the statement that creates a
/// column and the statement that adds it later are read side by side. New
/// columns are appended rather than slotted in, so a database that was
/// migrated and one that was created fresh end up identical.
const Map<int, List<String>> schemaUpgrades = {
  2: [
    'ALTER TABLE source_accounts '
        'ADD COLUMN is_owned INTEGER NOT NULL DEFAULT 0',
  ],

  // Set shape. Both nullable with no default, so every playlist already on
  // disk keeps playing exactly as it did — the list as written, each track to
  // its end.
  3: [
    'ALTER TABLE playlists ADD COLUMN song_limit INTEGER',
    'ALTER TABLE playlists ADD COLUMN target_duration_ms INTEGER',
  ],

  // Partner rotation. Zero, so every set already on disk keeps transitioning
  // the way it did rather than acquiring a silence between tracks.
  4: [
    'ALTER TABLE playlists '
        'ADD COLUMN rotation_gap_ms INTEGER NOT NULL DEFAULT 0',
  ],
};

/// Statements run once, in order, when the database file is first created.
const List<String> schemaExtras = [
  // Unique per (source, account, id) — but only for remote tracks, since a
  // local file has no source id at all and NULLs would not collide anyway.
  '''
CREATE UNIQUE INDEX idx_tracks_remote_identity
  ON tracks (source_type, account_id, source_id)
  WHERE source_type <> 'local'
''',
  '''
CREATE UNIQUE INDEX idx_tracks_local_path
  ON tracks (local_path) WHERE local_path IS NOT NULL
''',
  'CREATE INDEX idx_tracks_search ON tracks (title, artist)',
  'CREATE INDEX idx_tracks_bpm    ON tracks (bpm)',

  // Full-text search over the local mirror of all sources. `content=` makes
  // this an external-content index: the text lives in `tracks`, and the
  // triggers below keep the index in step with it.
  '''
CREATE VIRTUAL TABLE tracks_fts USING fts5(
  title, artist, album,
  content = 'tracks', content_rowid = 'rowid', tokenize = 'unicode61'
)
''',

  // Two rows with the same position produce a nondeterministic set order,
  // which on stage looks like the app reordering the night by itself.
  'CREATE UNIQUE INDEX idx_items_order ON playlist_items (playlist_id, position)',
  'CREATE INDEX idx_items_track ON playlist_items (track_id)',

  '''
CREATE INDEX idx_cache_lru ON cache_entries (pinned, last_accessed_at)
  WHERE state = 'complete'
''',

  'CREATE INDEX idx_history_recent ON play_history (track_id, started_at DESC)',

  // Availability in one query: drives both the offline UI and the engine's
  // skip logic, so they can never disagree about what will play.
  '''
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
LEFT JOIN cache_entries c ON c.track_id = t.id
''',

  '''
CREATE TRIGGER trg_tracks_fts_ins AFTER INSERT ON tracks BEGIN
  INSERT INTO tracks_fts(rowid, title, artist, album)
  VALUES (new.rowid, new.title, new.artist, new.album);
END
''',
  '''
CREATE TRIGGER trg_tracks_fts_del AFTER DELETE ON tracks BEGIN
  INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album)
  VALUES ('delete', old.rowid, old.title, old.artist, old.album);
END
''',
  '''
CREATE TRIGGER trg_tracks_fts_upd AFTER UPDATE ON tracks BEGIN
  INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, album)
  VALUES ('delete', old.rowid, old.title, old.artist, old.album);
  INSERT INTO tracks_fts(rowid, title, artist, album)
  VALUES (new.rowid, new.title, new.artist, new.album);
END
''',
];

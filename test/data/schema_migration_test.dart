import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/db/schema_extras.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// `source_accounts` exactly as version 1 created it.
///
/// Inlined rather than read from `schema.sql`, which has moved on: this is the
/// table an install from before the upgrade actually has on disk, and the
/// point of the test is that it can get from there to here.
const _v1SourceAccounts = '''
CREATE TABLE source_accounts (
  id                  TEXT NOT NULL PRIMARY KEY,
  provider            TEXT NOT NULL CHECK (provider IN ('plex','tidal')),
  display_name        TEXT NOT NULL,
  machine_identifier  TEXT,
  base_uri            TEXT,
  country_code        TEXT,
  keychain_ref        TEXT NOT NULL,
  offline_entitled    INTEGER NOT NULL DEFAULT 0,
  last_verified_at    INTEGER,
  created_at          INTEGER NOT NULL
);
''';

/// `playlists` exactly as version 2 had it, before the set shape was added.
const _v2Playlists = '''
CREATE TABLE playlists (
  id                     TEXT NOT NULL PRIMARY KEY,
  name                   TEXT NOT NULL,
  description            TEXT,
  event_kind             TEXT,
  event_date             INTEGER,
  crossfade_ms           INTEGER NOT NULL DEFAULT 4000,
  fade_in_curve          TEXT NOT NULL DEFAULT 'equalPower',
  fade_out_curve         TEXT NOT NULL DEFAULT 'equalPower',
  announce_mode          TEXT NOT NULL DEFAULT 'beforeMusic',
  -- 0.2, not 0.20: a real version 2 database was created by Drift, not by
  -- schema.sql, and this has to be the table that is actually on disk.
  duck_level             REAL NOT NULL DEFAULT 0.2,
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
''';

/// A schema change is the one kind of bug that cannot be fixed in a later
/// release: by the time it is noticed, someone's library is already on disk in
/// the shape the broken migration left it.
void main() {
  test('an install from version 1 ends up with the table this version creates',
      () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final upgraded = raw.sqlite3.openInMemory()..execute(_v1SourceAccounts);
    addTearDown(upgraded.close);

    for (final statement in _upgradesTouching('source_accounts', from: 1)) {
      upgraded.execute(statement);
    }

    final columnsAfterUpgrade = _columns([
      for (final row in upgraded.select('PRAGMA table_info(source_accounts)'))
        Map<String, Object?>.from(row),
    ]);

    final fresh = SayawDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    expect(
      columnsAfterUpgrade,
      _columns([
        for (final row
            in await fresh.customSelect('PRAGMA table_info(source_accounts)').get())
          row.data,
      ]),
    );
  });

  test('an account that predates the column reads as shared, not as yours',
      () async {
    // The restrictive answer. Whether a server is yours decides whether its
    // tracks may be written to disk, and a value nobody set is not a licence.
    final upgraded = raw.sqlite3.openInMemory()..execute(_v1SourceAccounts);
    addTearDown(upgraded.close);

    upgraded.execute(
      "INSERT INTO source_accounts (id, provider, display_name, keychain_ref, "
      "created_at) VALUES ('s', 'plex', 'Home Server', 'plex:s', 0)",
    );
    for (final statement in _upgradesTouching('source_accounts', from: 1)) {
      upgraded.execute(statement);
    }

    expect(
      upgraded.select('SELECT is_owned FROM source_accounts').single['is_owned'],
      0,
    );
  });

  test('an install from version 2 ends up with the table this version creates',
      () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final upgraded = raw.sqlite3.openInMemory()..execute(_v2Playlists);
    addTearDown(upgraded.close);

    for (final statement in _upgradesTouching('playlists', from: 2)) {
      upgraded.execute(statement);
    }

    final columnsAfterUpgrade = _columns([
      for (final row in upgraded.select('PRAGMA table_info(playlists)'))
        Map<String, Object?>.from(row),
    ]);

    final fresh = SayawDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    expect(
      columnsAfterUpgrade,
      _columns([
        for (final row
            in await fresh.customSelect('PRAGMA table_info(playlists)').get())
          row.data,
      ]),
    );
  });

  test('a set that predates the shape columns keeps playing as it always did',
      () async {
    // No limit and no per-song cap: the list as written, each track to its
    // end. Anything else would silently change how someone's saved night runs
    // the first time they open the new version.
    final upgraded = raw.sqlite3.openInMemory()..execute(_v2Playlists);
    addTearDown(upgraded.close);

    upgraded.execute(
      "INSERT INTO playlists (id, name, created_at, updated_at) "
      "VALUES ('p', 'Saturday Social', 0, 0)",
    );
    for (final statement in _upgradesTouching('playlists', from: 2)) {
      upgraded.execute(statement);
    }

    final row = upgraded
        .select('SELECT song_limit, target_duration_ms, rotation_gap_ms, '
            'snowball_stages FROM playlists')
        .single;
    expect(row['song_limit'], isNull);
    expect(row['target_duration_ms'], isNull);
    expect(row['rotation_gap_ms'], 0, reason: 'no silence between tracks');
    expect(row['snowball_stages'], 0,
        reason: 'not a climb it was never ordered for');
  });


  test('every version between one and the current one has a step', () {
    final db = SayawDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // A gap here is a database that opens, finds nothing to run, and carries
    // on against a schema it does not have.
    for (var version = 2; version <= db.schemaVersion; version++) {
      expect(schemaUpgrades[version], isNotNull,
          reason: 'no upgrade to version $version');
    }
  });
}

List<String> _columns(Iterable<Map<String, Object?>> rows) => [
      for (final row in rows)
        '${row['name']} ${row['type']} '
            'null=${row['notnull'] == 0} default=${row['dflt_value']}',
    ];

/// Every upgrade step after [from] that touches [table].
///
/// Filtered by table because each fixture above holds one table, and a
/// statement about another would fail against it. Walking *all* the remaining
/// versions rather than one named version is the point: this compares an
/// upgraded install against a fresh one, and it only says anything true if a
/// migration added later is applied here too rather than quietly skipped.
List<String> _upgradesTouching(String table, {required int from}) => [
      for (final version in schemaUpgrades.keys.toList()..sort())
        if (version > from)
          for (final statement in schemaUpgrades[version]!)
            if (statement.contains(table)) statement,
    ];

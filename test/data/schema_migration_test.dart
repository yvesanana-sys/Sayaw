import 'package:drift/drift.dart' hide isNotNull;
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

/// A schema change is the one kind of bug that cannot be fixed in a later
/// release: by the time it is noticed, someone's library is already on disk in
/// the shape the broken migration left it.
void main() {
  test('an install from version 1 ends up with the table version 2 creates',
      () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final upgraded = raw.sqlite3.openInMemory()..execute(_v1SourceAccounts);
    addTearDown(upgraded.close);

    for (final statement in schemaUpgrades[2]!) {
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
    for (final statement in schemaUpgrades[2]!) {
      upgraded.execute(statement);
    }

    expect(
      upgraded.select('SELECT is_owned FROM source_accounts').single['is_owned'],
      0,
    );
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

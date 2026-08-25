import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/crossfade_engine.dart' show AnnounceMode;
import 'package:sayaw/audio/fade_curves.dart' show FadeCurve;
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/media_resolver.dart' show CachePolicy;
import 'package:sqlite3/sqlite3.dart' as raw;

import 'db_harness.dart';

/// `schema.sql` is the readable statement of what the app stores, and
/// `lib/data/db/tables.dart` is what actually creates it. Two hand-maintained
/// descriptions of one schema drift apart silently — the failure only shows up
/// months later as a column that exists in the document and not in the file.
///
/// So: build a database from each and compare the results. Not the DDL text,
/// which differs harmlessly, but what SQLite ends up with.
void main() {
  late Query fromSchemaSql;
  late Query fromDrift;
  late raw.Database reference;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    reference = raw.sqlite3.openInMemory()
      ..execute(File('schema.sql').readAsStringSync());
    fromSchemaSql = (String sql) async =>
        reference.select(sql).map(Map<String, Object?>.from).toList();

    final db = SayawDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    fromDrift = (String sql) async =>
        (await db.customSelect(sql).get()).map((row) => row.data).toList();

    // Nothing is created until the connection is actually used.
    await fromDrift('SELECT 1');
  });

  tearDownAll(() => reference.close());

  group('schema.sql and the Drift tables agree on', () {
    test('which tables exist', () async {
      expect(await _tableNames(fromDrift), await _tableNames(fromSchemaSql));
    });

    test('every column, in order, with its type, nullability and key', () async {
      for (final table in await _tableNames(fromSchemaSql)) {
        final expected = await _columns(fromSchemaSql, table);
        final actual = await _columns(fromDrift, table);
        expect(actual, expected, reason: 'columns of $table');
      }
    });

    test('what each column defaults to', () async {
      // Compared by value rather than by text: `0.20` and `0.2` are the same
      // default, and only one of them is what a Dart `Constant` prints.
      for (final table in await _tableNames(fromSchemaSql)) {
        final expected = await _defaults(fromSchemaSql, table);
        final actual = await _defaults(fromDrift, table);

        expect(actual.keys, expected.keys, reason: 'defaulted columns of $table');
        for (final column in expected.keys) {
          expect(
            _evaluate(reference, actual[column]),
            _evaluate(reference, expected[column]),
            reason: '$table.$column defaults to ${expected[column]}',
          );
        }
      }
    });

    test('foreign keys, including what happens on delete', () async {
      for (final table in await _tableNames(fromSchemaSql)) {
        expect(
          await _foreignKeys(fromDrift, table),
          await _foreignKeys(fromSchemaSql, table),
          reason: 'foreign keys of $table',
        );
      }
    });

    test('indexes, down to which ones are unique and partial', () async {
      for (final table in await _tableNames(fromSchemaSql)) {
        expect(
          await _indexes(fromDrift, table),
          await _indexes(fromSchemaSql, table),
          reason: 'indexes on $table',
        );
      }
    });

    test('views and triggers', () async {
      expect(await _definitions(fromDrift), await _definitions(fromSchemaSql));
    });
  });

  group('the values Dart writes satisfy the CHECK constraints', () {
    // Every enum here is stored as `Enum.name`, and several columns carry a
    // `CHECK (... IN (...))` listing the strings SQLite will accept. A renamed
    // enum constant compiles fine and then fails at 9pm on a Saturday, so each
    // value gets written to the real column with the real constraint.

    test('every source provider', () async {
      final db = openTestDatabase();
      for (final provider in SourceProvider.values) {
        await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
              id: 'account-${provider.name}',
              provider: provider,
              displayName: provider.name,
              keychainRef: 'keychain-${provider.name}',
              createdAt: DateTime.utc(2026),
            ));
      }
      expect(await db.select(db.sourceAccounts).get(),
          hasLength(SourceProvider.values.length));
    });

    test('every source type and cache policy', () async {
      final db = openTestDatabase();
      await db.into(db.sourceAccounts).insert(SourceAccountsCompanion.insert(
            id: 'account',
            provider: SourceProvider.plex,
            displayName: 'Server',
            keychainRef: 'keychain',
            createdAt: DateTime.utc(2026),
          ));

      for (final type in SourceType.values) {
        for (final policy in CachePolicy.values) {
          await db.into(db.tracks).insert(_track(
                id: '${type.name}-${policy.name}',
                type: type,
                policy: policy,
              ));
        }
      }

      final stored = await db.select(db.tracks).get();
      expect(stored, hasLength(SourceType.values.length * CachePolicy.values.length));
      expect(stored.map((t) => t.cachePolicy).toSet(), CachePolicy.values.toSet());
    });

    test('every announce mode, fade curve and item type', () async {
      final db = openTestDatabase();
      final now = DateTime.utc(2026);

      for (final mode in AnnounceMode.values) {
        for (final curve in FadeCurve.values) {
          await db.into(db.playlists).insert(PlaylistsCompanion.insert(
                id: '${mode.name}-${curve.name}',
                name: 'Set',
                announceMode: Value(mode),
                fadeInCurve: Value(curve),
                fadeOutCurve: Value(curve),
                createdAt: now,
                updatedAt: now,
              ));
        }
      }

      final playlist = (await db.select(db.playlists).get()).first;
      for (final type in PlaylistItemType.values.where((t) => t != PlaylistItemType.track)) {
        await db.into(db.playlistItems).insert(PlaylistItemsCompanion.insert(
              id: type.name,
              playlistId: playlist.id,
              position: PlaylistItemType.values.indexOf(type) + 1.0,
              itemType: Value(type),
              createdAt: now,
              updatedAt: now,
            ));
      }

      expect(await db.select(db.playlists).get(),
          hasLength(AnnounceMode.values.length * FadeCurve.values.length));
      expect(await db.select(db.playlistItems).get(),
          hasLength(PlaylistItemType.values.length - 1));
    });

    test('every cache state', () async {
      final db = openTestDatabase();
      await db.into(db.tracks).insert(_track(id: 'track', type: SourceType.local));

      for (final state in CacheState.values) {
        await db.into(db.cacheEntries).insertOnConflictUpdate(
              CacheEntriesCompanion.insert(
                trackId: 'track',
                state: Value(state),
                createdAt: DateTime.utc(2026),
              ),
            );
      }

      final entry = await db.select(db.cacheEntries).getSingle();
      expect(entry.state, CacheState.values.last);
    });
  });

  group('the CHECK constraints actually bite', () {
    test('a track row claiming to be local without a path is rejected', () async {
      final db = openTestDatabase();
      await expectLater(
        db.into(db.tracks).insert(TracksCompanion.insert(
              id: 'nowhere',
              sourceType: SourceType.local,
              title: 'Nowhere',
              addedAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            )),
        throwsA(isA<raw.SqliteException>()),
      );
    });

    test('a remote track without an account is rejected', () async {
      final db = openTestDatabase();
      await expectLater(
        db.into(db.tracks).insert(TracksCompanion.insert(
              id: 'orphan',
              sourceType: SourceType.plex,
              title: 'Orphan',
              sourceId: const Value('12345'),
              addedAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            )),
        throwsA(isA<raw.SqliteException>()),
      );
    });

    test('a track row cannot point at an account that is not there', () async {
      final db = openTestDatabase();
      await expectLater(
        db.into(db.tracks).insert(_track(id: 'ghost', type: SourceType.tidal)
            .copyWith(accountId: const Value('no-such-account'))),
        throwsA(isA<raw.SqliteException>()),
      );
    });
  });
}

typedef Query = Future<List<Map<String, Object?>>> Function(String sql);

TracksCompanion _track({
  required String id,
  required SourceType type,
  CachePolicy policy = CachePolicy.allow,
}) =>
    TracksCompanion.insert(
      id: id,
      sourceType: type,
      accountId: Value(type == SourceType.local ? null : 'account'),
      localPath: Value(type == SourceType.local ? '/music/$id.flac' : null),
      sourceId: Value(type == SourceType.local ? null : id),
      title: id,
      cachePolicy: Value(policy),
      addedAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

Future<List<String>> _tableNames(Query query) async {
  final rows = await query(
    "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
  );
  return [for (final row in rows) row['name'] as String];
}

Future<List<String>> _columns(Query query, String table) async {
  final rows = await query('PRAGMA table_info($table)');
  return [
    for (final row in rows)
      '${row['name']} ${row['type']} '
          'null=${row['notnull'] == 0} pk=${row['pk']}',
  ];
}

Future<Map<String, String?>> _defaults(Query query, String table) async {
  final rows = await query('PRAGMA table_info($table)');
  return {
    for (final row in rows)
      if (row['dflt_value'] != null)
        row['name'] as String: row['dflt_value'] as String,
  };
}

Future<List<String>> _foreignKeys(Query query, String table) async {
  final rows = await query('PRAGMA foreign_key_list($table)');
  return [
    for (final row in rows)
      '${row['from']} -> ${row['table']}.${row['to']} '
          'on delete ${row['on_delete']}',
  ]..sort();
}

Future<List<String>> _indexes(Query query, String table) async {
  final result = <String>[];

  for (final index in await query('PRAGMA index_list($table)')) {
    final columns = await query("PRAGMA index_info('${index['name']}')");
    final origin = index['origin'] == 'c' ? index['name'] : index['origin'];
    result.add('$origin (${[for (final c in columns) c['name']].join(', ')}) '
        'unique=${index['unique'] == 1} partial=${index['partial'] == 1}');
  }

  return result..sort();
}

Future<List<String>> _definitions(Query query) async {
  final rows = await query(
    "SELECT sql FROM sqlite_master WHERE type IN ('view', 'trigger') "
    'ORDER BY name',
  );
  return [
    for (final row in rows)
      (row['sql'] as String).replaceAll(RegExp(r'\s+'), ' ').trim(),
  ];
}

/// The literal text SQLite recorded as a default, evaluated back into a value.
Object? _evaluate(raw.Database db, String? defaultText) =>
    defaultText == null ? null : db.select('SELECT $defaultText AS v').first['v'];

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'source_account_dao.g.dart';

/// Connected Plex servers and TIDAL accounts.
///
/// Rows only. Credentials are in the OS keychain under [SourceAccount.keychainRef],
/// and nothing here can reach them.
@DriftAccessor(tables: [SourceAccounts])
class SourceAccountDao extends DatabaseAccessor<SayawDatabase>
    with _$SourceAccountDaoMixin {
  SourceAccountDao(super.db);

  Future<SourceAccount?> byId(String id) =>
      (select(sourceAccounts)..where((a) => a.id.equals(id)))
          .getSingleOrNull();

  Future<List<SourceAccount>> all({SourceProvider? provider}) {
    final query = select(sourceAccounts)
      ..orderBy([(a) => OrderingTerm.asc(a.displayName)]);
    if (provider != null) query.where((a) => a.provider.equalsValue(provider));
    return query.get();
  }

  Stream<List<SourceAccount>> watchAll() => (select(sourceAccounts)
        ..orderBy([(a) => OrderingTerm.asc(a.displayName)]))
      .watch();

  /// Records a connection, or updates the one already there.
  ///
  /// Keyed on [id] — for Plex that is the server's machine identifier, so
  /// reconnecting the same server updates its row rather than growing a second
  /// one with a stale token.
  Future<void> connect({
    required String id,
    required SourceProvider provider,
    required String displayName,
    required String keychainRef,
    String? machineIdentifier,
    String? baseUri,
    String? countryCode,
    bool offlineEntitled = false,
    bool owned = false,
  }) async {
    final now = clock.now();
    await into(sourceAccounts).insertOnConflictUpdate(SourceAccountsCompanion(
      id: Value(id),
      provider: Value(provider),
      displayName: Value(displayName),
      machineIdentifier: Value(machineIdentifier),
      baseUri: Value(baseUri),
      countryCode: Value(countryCode),
      keychainRef: Value(keychainRef),
      offlineEntitled: Value(offlineEntitled),
      isOwned: Value(owned),
      lastVerifiedAt: Value(now),
      createdAt: Value(now),
    ));
  }

  /// Remembers which connection answered, so the next launch tries the one
  /// that worked before racing all of them again.
  Future<void> rememberConnection(String id, Uri uri) =>
      (update(sourceAccounts)..where((a) => a.id.equals(id))).write(
        SourceAccountsCompanion(
          baseUri: Value(uri.toString()),
          lastVerifiedAt: Value(clock.now()),
        ),
      );

  /// Drops the row. The caller deletes the secret: this cannot reach it, which
  /// is the point.
  Future<int> forget(String id) =>
      (delete(sourceAccounts)..where((a) => a.id.equals(id))).go();
}

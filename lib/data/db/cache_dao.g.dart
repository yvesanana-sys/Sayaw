// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CacheDaoMixin on DatabaseAccessor<SayawDatabase> {
  $SourceAccountsTable get sourceAccounts => attachedDatabase.sourceAccounts;
  $DanceTypesTable get danceTypes => attachedDatabase.danceTypes;
  $TracksTable get tracks => attachedDatabase.tracks;
  $CacheEntriesTable get cacheEntries => attachedDatabase.cacheEntries;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$SourceAccountsTableTableManager get sourceAccounts =>
      $$SourceAccountsTableTableManager(
        _db.attachedDatabase,
        _db.sourceAccounts,
      );
  $$DanceTypesTableTableManager get danceTypes =>
      $$DanceTypesTableTableManager(_db.attachedDatabase, _db.danceTypes);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db.attachedDatabase, _db.cacheEntries);
}

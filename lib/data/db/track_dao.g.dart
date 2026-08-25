// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_dao.dart';

// ignore_for_file: type=lint
mixin _$TrackDaoMixin on DatabaseAccessor<SayawDatabase> {
  $SourceAccountsTable get sourceAccounts => attachedDatabase.sourceAccounts;
  $DanceTypesTable get danceTypes => attachedDatabase.danceTypes;
  $TracksTable get tracks => attachedDatabase.tracks;
  TrackDaoManager get managers => TrackDaoManager(this);
}

class TrackDaoManager {
  final _$TrackDaoMixin _db;
  TrackDaoManager(this._db);
  $$SourceAccountsTableTableManager get sourceAccounts =>
      $$SourceAccountsTableTableManager(
        _db.attachedDatabase,
        _db.sourceAccounts,
      );
  $$DanceTypesTableTableManager get danceTypes =>
      $$DanceTypesTableTableManager(_db.attachedDatabase, _db.danceTypes);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
}

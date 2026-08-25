// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistDaoMixin on DatabaseAccessor<SayawDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $SourceAccountsTable get sourceAccounts => attachedDatabase.sourceAccounts;
  $DanceTypesTable get danceTypes => attachedDatabase.danceTypes;
  $TracksTable get tracks => attachedDatabase.tracks;
  $PlaylistItemsTable get playlistItems => attachedDatabase.playlistItems;
  PlaylistDaoManager get managers => PlaylistDaoManager(this);
}

class PlaylistDaoManager {
  final _$PlaylistDaoMixin _db;
  PlaylistDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$SourceAccountsTableTableManager get sourceAccounts =>
      $$SourceAccountsTableTableManager(
        _db.attachedDatabase,
        _db.sourceAccounts,
      );
  $$DanceTypesTableTableManager get danceTypes =>
      $$DanceTypesTableTableManager(_db.attachedDatabase, _db.danceTypes);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$PlaylistItemsTableTableManager get playlistItems =>
      $$PlaylistItemsTableTableManager(_db.attachedDatabase, _db.playlistItems);
}

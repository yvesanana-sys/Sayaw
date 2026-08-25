// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_dao.dart';

// ignore_for_file: type=lint
mixin _$AnnouncementDaoMixin on DatabaseAccessor<SayawDatabase> {
  $AnnouncementCacheTable get announcementCache =>
      attachedDatabase.announcementCache;
  AnnouncementDaoManager get managers => AnnouncementDaoManager(this);
}

class AnnouncementDaoManager {
  final _$AnnouncementDaoMixin _db;
  AnnouncementDaoManager(this._db);
  $$AnnouncementCacheTableTableManager get announcementCache =>
      $$AnnouncementCacheTableTableManager(
        _db.attachedDatabase,
        _db.announcementCache,
      );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_cue_dao.dart';

// ignore_for_file: type=lint
mixin _$SoundCueDaoMixin on DatabaseAccessor<SayawDatabase> {
  $SoundCuesTable get soundCues => attachedDatabase.soundCues;
  SoundCueDaoManager get managers => SoundCueDaoManager(this);
}

class SoundCueDaoManager {
  final _$SoundCueDaoMixin _db;
  SoundCueDaoManager(this._db);
  $$SoundCuesTableTableManager get soundCues =>
      $$SoundCuesTableTableManager(_db.attachedDatabase, _db.soundCues);
}

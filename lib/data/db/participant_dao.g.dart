// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_dao.dart';

// ignore_for_file: type=lint
mixin _$ParticipantDaoMixin on DatabaseAccessor<SayawDatabase> {
  $ParticipantsTable get participants => attachedDatabase.participants;
  ParticipantDaoManager get managers => ParticipantDaoManager(this);
}

class ParticipantDaoManager {
  final _$ParticipantDaoMixin _db;
  ParticipantDaoManager(this._db);
  $$ParticipantsTableTableManager get participants =>
      $$ParticipantsTableTableManager(_db.attachedDatabase, _db.participants);
}

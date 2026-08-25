// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_account_dao.dart';

// ignore_for_file: type=lint
mixin _$SourceAccountDaoMixin on DatabaseAccessor<SayawDatabase> {
  $SourceAccountsTable get sourceAccounts => attachedDatabase.sourceAccounts;
  SourceAccountDaoManager get managers => SourceAccountDaoManager(this);
}

class SourceAccountDaoManager {
  final _$SourceAccountDaoMixin _db;
  SourceAccountDaoManager(this._db);
  $$SourceAccountsTableTableManager get sourceAccounts =>
      $$SourceAccountsTableTableManager(
        _db.attachedDatabase,
        _db.sourceAccounts,
      );
}

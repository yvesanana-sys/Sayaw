import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import 'database.dart';

/// Opens the on-device database file.
///
/// Split out from `database.dart` so the database itself has no Flutter
/// dependency and tests can open it over `NativeDatabase.memory()` without a
/// binding or a plugin.
SayawDatabase openSayawDatabase({String name = 'sayaw'}) =>
    SayawDatabase(driftDatabase(
      name: name,
      native: DriftNativeOptions(
        // Application support, not documents: on iOS the documents directory is
        // visible in Files, and the library index is not something an operator
        // should be able to delete by tidying up between events.
        databaseDirectory: getApplicationSupportDirectory,
        setup: enableWriteAheadLog,
      ),
    ));

/// A set runs off the same file the operator is editing between dances. WAL
/// keeps a reorder from blocking the read the engine does to preload the next
/// track, which under the default rollback journal can stall a transition.
///
/// Top level because `drift_flutter` sends this across isolates.
void enableWriteAheadLog(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL;');
}

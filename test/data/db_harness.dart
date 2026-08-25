import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';

/// An empty database in memory, closed when the test ends.
///
/// The schema is built by the same `onCreate` migration that runs on device,
/// so these tests exercise the real DDL rather than a test-only copy of it.
SayawDatabase openTestDatabase() {
  // Several databases per test file is the point here — each one is its own
  // in-memory executor, so drift's shared-file warning does not apply.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final db = SayawDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

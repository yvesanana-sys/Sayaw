import 'package:drift/drift.dart';

import '../../audio/crossfade_engine.dart' show AnnounceMode;
import '../../audio/fade_curves.dart' show FadeCurve;
import '../media_resolver.dart' show CachePolicy;
import 'announcement_dao.dart';
import 'cache_dao.dart';
import 'converters.dart';
import 'enums.dart';
import 'playlist_dao.dart';
import 'schema_extras.dart';
import 'source_account_dao.dart';
import 'tables.dart';
import 'track_dao.dart';

export 'enums.dart';
export 'ids.dart' show newId;
export 'playlist_dao.dart' show PlaylistRow;
export 'source_account_dao.dart' show SourceAccountDao;

part 'database.g.dart';

/// The local library, the sets, and everything the app knows with the network
/// gone.
///
/// Opened with `driftDatabase` on device (see `connection.dart`) and against
/// `NativeDatabase.memory()` in tests, which is why nothing here reaches for a
/// file path or a plugin.
@DriftDatabase(
  tables: [
    SourceAccounts,
    DanceTypes,
    Tracks,
    Playlists,
    PlaylistItems,
    CacheEntries,
    AnnouncementCache,
    PlayHistory,
  ],
  daos: [
    TrackDao,
    PlaylistDao,
    AnnouncementDao,
    SourceAccountDao,
    CacheDao,
  ],
)
class SayawDatabase extends _$SayawDatabase {
  SayawDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final statement in schemaExtras) {
            await customStatement(statement);
          }
        },
        onUpgrade: (m, from, to) async {
          for (var version = from + 1; version <= to; version++) {
            for (final statement in schemaUpgrades[version] ?? const []) {
              await customStatement(statement);
            }
          }
        },
        beforeOpen: (details) async {
          // Off by default in SQLite, and everything about the ordering and
          // cascade behaviour in `schema.sql` assumes it is on. Set per
          // connection, so it belongs here rather than in the migration.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

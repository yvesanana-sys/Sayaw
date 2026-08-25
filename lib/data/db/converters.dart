import 'package:drift/drift.dart';

import '../media_resolver.dart' show CachePolicy;

/// Epoch milliseconds, UTC.
///
/// Drift's own `DateTimeColumn` stores whole **seconds**, which would quietly
/// truncate every timestamp `schema.sql` documents as milliseconds. Storing the
/// integer and converting here keeps the column exactly as specified while the
/// Dart side still gets a [DateTime].
class MillisConverter extends TypeConverter<DateTime, int> {
  const MillisConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

/// A millisecond count that means a length of time rather than an instant.
class MillisDurationConverter extends TypeConverter<Duration, int> {
  const MillisDurationConverter();

  @override
  Duration fromSql(int fromDb) => Duration(milliseconds: fromDb);

  @override
  int toSql(Duration value) => value.inMilliseconds;
}

/// [CachePolicy] is the one enum whose SQL spelling is not its Dart name:
/// `schema.sql` writes `session_only` where Dart has `sessionOnly`. Renaming
/// either side would be worse — the column is a documented `CHECK` constraint
/// and the enum is public API of [MediaResolver] — so the difference is
/// absorbed here, in the only layer that sees both.
class CachePolicyConverter extends TypeConverter<CachePolicy, String> {
  const CachePolicyConverter();

  @override
  CachePolicy fromSql(String fromDb) => switch (fromDb) {
        'allow' => CachePolicy.allow,
        'session_only' => CachePolicy.sessionOnly,
        'forbid' => CachePolicy.forbid,
        _ => throw ArgumentError.value(fromDb, 'cache_policy', 'unknown policy'),
      };

  @override
  String toSql(CachePolicy value) => switch (value) {
        CachePolicy.allow => 'allow',
        CachePolicy.sessionOnly => 'session_only',
        CachePolicy.forbid => 'forbid',
      };
}

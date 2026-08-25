/// Enum spellings here are the literal strings stored in SQLite, so the
/// `CHECK (... IN (...))` constraints in `schema.sql` and these `Enum.name`
/// values have to stay in step. The schema-parity test asserts that they do.
library;

/// Which service an account belongs to. Local files have no account.
enum SourceProvider { plex, tidal }

/// `tracks.source_type` — the discriminator of the source triple
/// `(source_type, account_id, source_id)`.
enum SourceType { local, plex, tidal }

/// A playlist row is not always a song: a set can carry a spoken announcement
/// on its own, a timed silence for a floor change, or a marker the operator
/// navigates to.
enum PlaylistItemType { track, announcement, silence, marker }

/// `cache_entries.state`.
enum CacheState { none, pending, partial, complete, expired, failed }

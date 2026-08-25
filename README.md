# Sayaw

A local-first media player for dance events — ballroom, tango, salsa, social nights.
Crossfading, automated dance-type announcements, and a library that spans local files,
a Plex server and TIDAL.

*Sayaw* is Tagalog for "dance."

Runs on **Windows, macOS, Android and iOS** from a single Flutter codebase.

## Why

Consumer music apps assume a listener sitting still. A dance event needs a different set
of things: the next dance type announced before the music starts, transitions that don't
leave a hole in the middle, tracks trimmed to a fixed length for competition rounds, and
a set that keeps running when the venue wifi dies.

## Features

- **Playlists** with drag-and-drop reordering, per-item dance type, and per-item overrides
  for crossfade duration, curve, cue-in/cue-out and announcement style
- **Dual-deck crossfade** with linear, exponential, logarithmic, equal-power, S-curve and
  dB-linear shapes — equal-power by default, so there's no level dip mid-transition
- **Dance announcements** via native TTS or pre-recorded MC clips, either played clean
  before the music or ducked over a running crossfade at a configurable level
- **Aggregated search** across local files, Plex and TIDAL in one field
- **Offline-aware**: local files and your own Plex library cache fully; unavailable tracks
  are flagged before the set starts, not when they fail
- **Event mode**: pre-flight check that downloads what it can, pre-renders every
  announcement, and reports exactly what will and won't work without a connection

## Status

Early, but it runs. Point it at a folder of music on Windows or macOS and it
imports it, searches it, and plays a set end to end with crossfades and
announcements. Not yet written: Plex and TIDAL auth and their clients, library
import on Android and iOS, downloading and caching, and Event Mode's
pre-flight check. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the design.

## Layout

```
lib/audio/fade_curves.dart           curve math
lib/audio/gain_bus.dart              composable multiplicative gain stages
lib/audio/deck.dart                  Deck interface + just_audio / media_kit backends
lib/audio/crossfade_engine.dart      the dual-deck scheduler
lib/audio/announcement_engine.dart   TTS render-to-cache and duck envelopes
lib/audio/sayaw_audio_handler.dart   background playback and lock-screen controls
lib/data/media_resolver.dart         source-polymorphic resolution and cache policy
lib/data/db/                         Drift tables and the playlist, track and
                                     announcement accessors
lib/data/library/                    folder scanning and tag reading
lib/data/playlist_repository.dart    stored rows -> engine-ready queue entries
lib/ui/screens/deck_screen.dart      the operator's screen
lib/ui/state/playback_session.dart   the seam between the engine and the screen
schema.sql                           SQLite schema, and the source of truth the
                                     Drift tables are tested against
```

## A note on TIDAL

TIDAL's developer terms restrict which playback endpoints third-party clients may call and
generally prohibit persisting decrypted content. Offline TIDAL playback requires an
entitlement granted per-partner. Sayaw ships with that capability off, and
`MediaResolver.policyFor()` is the only function permitted to authorise writing media bytes
to disk — the restriction is enforced by construction, not convention.

Plex is different: it's your own server and your own files, so full offline caching works.

Not affiliated with or endorsed by Plex or TIDAL.

## License

TBD

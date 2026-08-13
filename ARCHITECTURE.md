# Dance Media Player — Architecture & Implementation Design

A local-first, multi-platform media player for ballroom and social dance events.
Targets: **Windows, Android, iOS, macOS** from a single codebase.

---

# Phase 1 — Architecture & Tech Stack

## 1.1 Stack recommendation

| Concern | Choice | Why |
|---|---|---|
| Framework | **Flutter 3.x (Dart)** | Only mainstream framework with production-grade builds for all four targets from one tree. |
| State | **Riverpod 2.x** | Compile-safe DI, testable without a widget tree, good for long-lived audio services. |
| Local DB | **Drift (SQLite)** | Relational ordering/joins, real migrations, reactive streams, works on all four targets via `sqlite3_flutter_libs`. |
| Mobile audio | **`just_audio` + `audio_service` + `audio_session`** | ExoPlayer (Android) / AVPlayer (iOS). Multi-instance, background service, MediaSession, and — critically — the only stacks that support Widevine/FairPlay. |
| Desktop audio | **`media_kit`** (libmpv/FFmpeg) | Rock-solid multi-instance playback and format coverage on Windows/macOS without ExoPlayer's mobile baggage. |
| TTS | **`flutter_tts` synth-to-file**, with a `MethodChannel` fallback on desktop | Android `synthesizeToFile`, iOS/macOS `AVSpeechSynthesizer.write`, Windows `SpeechSynthesizer.SynthesizeTextToStreamAsync`. |
| HTTP | **`dio`** + `retrofit` | Interceptors for token refresh, per-host retry, range requests for the cache. |
| Secrets | **`flutter_secure_storage`** | Keychain / Keystore / DPAPI. OAuth tokens never touch SQLite. |
| Drag & drop | **`flutter_reorderable_list`** or `ReorderableListView` | Reorder writes fractional positions (see §2.3). |

### Why not the alternatives

- **React Native + `react-native-track-player`** — RN Windows and RN macOS are second-class, and Track Player has no meaningful desktop story. It also exposes a single queue player, so true overlapping crossfade requires forking native code on every platform.
- **.NET MAUI** — covers all four targets, but there is no mature crossfade/multi-bus audio library; you'd write four native audio engines.
- **Electron + Capacitor** — the Web Audio API is genuinely excellent for this (GainNode ducking is trivial), but iOS background audio in a WebView is unreliable and both Plex and TIDAL DRM are effectively out of reach. Also two codebases in practice.
- **`media_kit` everywhere** — tempting, but libmpv can't do Widevine, and mobile background/audio-focus/lock-screen behaviour is far better served by `audio_service`.

### The load-bearing abstraction

```
                 ┌──────────────────────────┐
                 │   CrossfadeEngine (Dart) │   ← all timing/gain math lives here
                 └────────────┬─────────────┘
                              │  abstract Deck
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
  JustAudioDeck          MediaKitDeck          JustAudioDeck
  (Android/iOS)          (Windows/macOS)       (announcement bus)
```

`Deck` is ~10 methods. Everything hard — curves, scheduling, gain composition, ducking,
announcement sequencing — is platform-agnostic Dart and unit-testable with a `FakeDeck`.

## 1.2 Runtime topology

Three concurrent voices:

- **Deck A / Deck B** — the music decks. One plays, one preloads. They swap roles each transition.
- **Announcement deck** — third player instance for TTS clips, MC recordings, and event stingers.

Final volume applied to a music deck each tick:

```
deckVolume = crossfadeGain(t) × duckGain × trackTrimGain × masterGain
```

All four are independent, streamed values. This is why ducking "just works" during a crossfade:
the duck multiplies both decks simultaneously without disturbing the fade ratio between them.

## 1.3 Background playback per platform

| Platform | Mechanism | Config |
|---|---|---|
| Android | `audio_service` foreground service + `MediaSessionCompat` | `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`; request audio focus with `AUDIOFOCUS_GAIN` |
| iOS | `UIBackgroundModes: audio` | `AVAudioSession` category `.playback`, `mixWithOthers = false`; handle `.interruption` and `.routeChange` |
| macOS | No restriction | `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` for media keys |
| Windows | No restriction | `SystemMediaTransportControls` for the flyout; disable app throttling |

**Do not use OS-level ducking** (`AVAudioSession.duckOthers`, Android `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`)
for announcements. Those apply a fixed, uncontrollable attenuation to *other* apps. We own both
the music and the voice, so we duck internally and get an exact configurable percentage and curve.

---

# Phase 2 — Data Model & API Contracts

## 2.1 Entities

Full DDL is in `schema.sql`. Summary:

- `source_accounts` — one row per connected Plex server or TIDAL account.
- `tracks` — the canonical media object. Source-polymorphic (§2.2).
- `dance_types` — Waltz, Cha-Cha, Bachata… each with a TTS template and optional custom clip.
- `playlists` — an event or set, carrying default crossfade/announcement settings.
- `playlist_items` — the ordered rows. Can be a track, a spoken announcement, a silence gap, or a marker.
- `cache_entries` — what's downloaded, how big, when it expires, whether policy allows persistence.
- `play_history` — for "don't repeat within N hours", genuinely useful across a long social night.

### Why Drift over Isar/Hive

Isar is faster on raw reads, but this schema is relational (many-to-many playlists↔tracks with
per-row ordering and per-row overrides), needs real migrations across app updates, and benefits
from SQL for the availability queries in §2.5. Isar's maintenance status has also been uncertain.
Hive is a key-value store and would push all ordering logic into Dart.

## 2.2 Source polymorphism

A track is identified by a **discriminated triple**: `(source_type, account_id, source_id)`.

```dart
sealed class TrackSource {
  const TrackSource();
}

class LocalSource extends TrackSource {
  final String path;              // desktop absolute path
  final String? contentUri;       // Android SAF content:// URI
  final Uint8List? bookmark;      // iOS/macOS security-scoped bookmark
}

class PlexSource extends TrackSource {
  final String accountId;         // FK -> source_accounts
  final String machineIdentifier; // ratingKey is only unique *per server*
  final String ratingKey;
  final String? partId;
}

class TidalSource extends TrackSource {
  final String accountId;
  final String trackId;
}
```

The database stores the flattened columns; a `TrackMapper` reconstitutes the sealed class.
The rule that keeps this clean: **nothing outside `MediaResolver` knows which source a track
came from.** The resolver takes a `Track` and returns a `PlayableMedia`:

```dart
class PlayableMedia {
  final Uri uri;                      // file://, https://, or cache path
  final Map<String, String> headers;  // X-Plex-Token, Authorization: Bearer …
  final DrmConfig? drm;               // Widevine/FairPlay license server + headers
  final DateTime? expiresAt;          // signed URLs expire; re-resolve before use
  final double gainDb;                // ReplayGain / manual trim
  final Duration? cueIn, cueOut;
}
```

The crossfade engine only ever sees `PlayableMedia`. Adding Apple Music or a Subsonic server
later is one new resolver branch and zero changes to the audio core.

## 2.3 Ordering without rewrites

`playlist_items.position` is a `REAL`, not an integer. Inserting between two rows sets
`position = (prev + next) / 2`. Dragging one track in a 400-song event playlist writes **one row**,
not 400. Renormalise to `1.0, 2.0, 3.0…` when any adjacent gap drops below `1e-6` (roughly 50
consecutive insertions at the same point — rare, and cheap to fix in a single transaction).

## 2.4 API contracts

### Plex

Auth is a PIN flow, not standard OAuth:

```
POST https://plex.tv/api/v2/pins?strong=true
     X-Plex-Client-Identifier: <stable uuid>
     X-Plex-Product: Sayaw
  -> { id, code }

User opens: https://app.plex.tv/auth#?clientID=<uuid>&code=<code>

Poll GET https://plex.tv/api/v2/pins/{id}   (every 2s, ~2 min budget)
  -> { authToken }   once approved
```

Server discovery and connection selection:

```
GET https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1
  -> devices[].connections[]  { uri, local, relay }
```

Order connections **local → remote direct → relay** and race them with a short-timeout
`/identity` probe. At a venue on the same LAN as the DJ's server, the local URI is dramatically
faster and survives a dead WAN link.

```
Search    GET {server}/hubs/search?query=…&limit=30      (music: type 8 artist / 9 album / 10 track)
Metadata  GET {server}/library/metadata/{ratingKey}
Direct    GET {server}/library/parts/{partId}/{updatedAt}/file.flac?X-Plex-Token=…
Transcode GET {server}/music/:/transcode/universal/start.mp3?path=…&protocol=http&…
```

Always send `Accept: application/json` — Plex defaults to XML.
Prefer direct-play; only transcode when the codec isn't locally decodable.

### TIDAL

OAuth 2.0 Authorization Code + PKCE (or Device Authorization on TV-like surfaces):

```
Authorize  https://login.tidal.com/authorize
             ?response_type=code&client_id=…&redirect_uri=…
             &code_challenge=…&code_challenge_method=S256
             &scope=r_usr+collection.read+playlists.read
Token      POST https://auth.tidal.com/v1/oauth2/token
Refresh    POST https://auth.tidal.com/v1/oauth2/token  grant_type=refresh_token
```

```
Search     GET https://openapi.tidal.com/v2/searchResults/{query}?countryCode=…
Playlists  GET https://openapi.tidal.com/v2/playlists?filter[r.owners.id]=…
Playback   GET /v1/tracks/{id}/playbackinfopostpaywall
             ?audioquality=LOSSLESS&playbackmode=STREAM&assetpresentation=FULL
  -> { manifestMimeType, manifest (base64), trackId, audioQuality }
```

`manifestMimeType` decides the path:
- `application/vnd.tidal.bts` → JSON with direct URLs, unencrypted, short-lived.
- `application/dash+xml` → MPEG-DASH, **Widevine (Android/Windows) or FairPlay (Apple)**.
  Requires the DRM-capable backend and a license request per session.

> **Compliance note, and you should treat this as a hard gate rather than a detail.**
> TIDAL's developer terms restrict which playback endpoints third-party clients may call and
> generally prohibit persisting decrypted content. Offline TIDAL playback requires an offline
> license entitlement that is granted per-partner, not available by default. Design the app so
> TIDAL offline is a *capability flag* the backend can switch on if and when you're granted it —
> and ship with it off. Building a local cache of decrypted TIDAL audio without that grant is a
> straightforward terms violation and a plausible DMCA §1201 problem, so the architecture below
> deliberately makes it impossible rather than merely discouraged.

## 2.5 Offline strategy & DRM matrix

| Source | Persistently cacheable? | Mechanism | Offline behaviour |
|---|---|---|---|
| Local file | N/A — already local | — | ✅ Always available |
| Plex, user's **own** server, direct play | ✅ Yes | Range-download to encrypted cache, LRU | ✅ Full |
| Plex, **shared** library | ⚠️ Policy flag, default off | Metadata + artwork only | ⚠️ Degrades to unavailable |
| Plex, transcoded | ✅ Yes (cache the transcode output) | Same as direct | ✅ Full |
| TIDAL, BTS manifest | ❌ No — session-scoped only | In-memory buffer, dropped on stop | ❌ Unavailable offline |
| TIDAL, DASH + Widevine/FairPlay | ⚠️ Only with an offline entitlement | ExoPlayer `DownloadManager` + offline Widevine license / `AVAssetDownloadTask` + persistent FairPlay key | ⚠️ Gated behind partner grant |

### Graceful degradation

A `ConnectivityService` combines `connectivity_plus` with an actual reachability probe against
each configured Plex server and `openapi.tidal.com` — a captive-portal venue wifi reports
"connected" while passing zero traffic, which is exactly the failure you'll hit in the real world.

State machine: `Online → Degraded (one service down) → LocalOnly`.

On entering `LocalOnly`, an `AvailabilityService` recomputes `playable` per playlist item:

```sql
SELECT pi.id,
       CASE
         WHEN t.source_type = 'local'                       THEN 1
         WHEN c.state = 'complete' AND c.expires_at > :now   THEN 1
         ELSE 0
       END AS playable
FROM playlist_items pi
LEFT JOIN tracks t        ON t.id = pi.track_id
LEFT JOIN cache_entries c ON c.track_id = t.id
WHERE pi.playlist_id = :id
ORDER BY pi.position;
```

Unplayable items render dimmed with a cloud-slash badge; the engine skips them and surfaces a
single non-modal banner rather than an error per track. Announcements keep working — their audio
is always local.

### Event Mode pre-flight

The feature that actually matters to a DJ standing in a venue at 6pm:

**"Prepare for offline"** walks the playlist and, for every item, downloads what policy permits,
pre-renders every TTS announcement, validates every local file path still resolves (SAF permissions
and macOS security-scoped bookmarks both expire), and then reports:

```
312 of 318 tracks ready offline
  4 TIDAL tracks    — streaming only, will be skipped without internet
  2 missing files   — /Volumes/DJ/… not mounted
All 47 announcements rendered.
```

Run this over the venue's wifi before doors open and the set is deterministic.

### Prefetch during playback

The crossfade engine needs the next track preloaded anyway. Extend that: keep **N+2** resolved and
buffered, and re-resolve any `PlayableMedia` whose `expiresAt` is within 60 seconds before handing
it to a deck. Signed Plex and TIDAL URLs expiring mid-set is a real and very embarrassing failure.

---

# Phase 3 — Implementation

Code lives in `lib/`:

| File | Contents |
|---|---|
| `lib/audio/fade_curves.dart` | Curve math, equal-power default, dB helpers |
| `lib/audio/deck.dart` | `Deck` interface + `just_audio` and `media_kit` implementations |
| `lib/audio/gain_bus.dart` | Composable gain stages and the duck controller |
| `lib/audio/crossfade_engine.dart` | The dual-deck scheduler — the core of the app |
| `lib/audio/announcement_engine.dart` | TTS render-to-cache and announcement sequencing |
| `lib/audio/sayaw_audio_handler.dart` | `audio_service` wiring for background + lock screen |
| `lib/data/media_resolver.dart` | Source-polymorphic resolution and DRM policy |

## 3.1 Gain composition

Every tick, both music decks get:

```
volume = crossfade(t) × duck × trim × master
```

Because these multiply, a duck during a crossfade attenuates both decks equally and the
fade ratio is preserved. Restoring the duck restores the crossfade exactly where it was.

## 3.2 Curve selection

`fadeOut(t) = fadeIn(1 - t)` holds for every curve, so one function covers both directions.

| Curve | `fadeIn(t)` | Character |
|---|---|---|
| `linear` | `t` | Audible dip mid-crossfade. Fine for fade-to-silence, poor for crossfade. |
| `exponential` | `t²` | Stays quiet longer, then rushes. Good for fading *into* a strong downbeat. |
| `logarithmic` | `√t` | Rises fast, plateaus. Good for fading out under an announcement. |
| `equalPower` | `sin(t·π/2)` | `sin² + cos² = 1` → constant perceived loudness. **Default for crossfade.** |
| `sCurve` | `t²(3−2t)` | Smoothstep. Gentle at both ends, no discontinuity in slope. |
| `dbLinear` | `10^(−60(1−t)/20)` | Linear in decibels. Matches how mixing desks behave. |

The equal-power default matters more than it sounds. With a linear crossfade, both tracks sit at
0.5 amplitude at the midpoint, summing to roughly −3 dB of perceived level — a hole in the middle
of every transition. On a dance floor that reads as a stumble.

## 3.3 Announcement modes

**`beforeMusic`** — outgoing track fades to silence, announcement plays clean, incoming fades in.
Highest intelligibility. Correct for competition rounds and formal ballroom.

```
──── outgoing ────╲                                  ╱──── incoming ────
                   ╲________________________________╱
                        [ "Next dance: Viennese Waltz" ]
```

**`duckOver`** — crossfade proceeds normally; music dips to the configured percentage while the
voice plays, then rises. Keeps the floor moving. Correct for social nights.

```
──── outgoing ────╲                    ╱──── incoming ────
                   ╲──────╲    ╱──────╱
                           ╲__╱  ← duck to 20%
                        [ "Bachata" ]
```

Timing is derived from the clip's *known* duration (the reason for rendering TTS to file):

```
duckStart   = announceStart − duckFadeMs
speakStart  = announceStart
speakEnd    = announceStart + clip.duration
restoreEnd  = speakEnd + holdMs + restoreFadeMs
```

## 3.4 Platform gotchas worth knowing before you hit them

- **Volume-set rate.** 50 Hz over a platform channel is fine on all four targets, but coalesce
  redundant writes (skip if |Δ| < 0.005) or you'll burn battery on Android for nothing.
- **iOS preroll.** `AVPlayer` reports `readyToPlay` before it can start instantly. Preroll the
  standby deck by playing at volume 0 for ~200 ms, then pausing and seeking back to the cue point.
- **Android audio focus.** A notification sound triggers transient focus loss. Handle it in
  `audio_session` by applying a *system duck* stage to the gain bus — again multiplicative, so it
  composes with an in-flight announcement duck instead of fighting it.
- **`media_kit` volume is 0–100**, `just_audio` is 0.0–1.0. Normalise inside the `Deck` impl, never
  at the call site.
- **Windows TTS.** `flutter_tts` supports Windows but its `synthesizeToFile` coverage is patchy;
  the `MethodChannel` fallback stub in `announcement_engine.dart` shows where to drop in
  `SpeechSynthesizer.SynthesizeTextToStreamAsync`.
- **macOS sandbox.** File paths from a picker die on relaunch. Store security-scoped bookmarks in
  `tracks.security_bookmark` and re-resolve on load — this is why that column exists.
- **Gapless.** A crossfade of 0 ms is not the same code path. Detect it and route to a single deck
  with `ConcatenatingAudioSource` (mobile) / playlist API (media_kit), which gives true sample-
  accurate gapless. Two-deck crossfade at 0 ms will produce a click.

## 3.5 Testing the engine without audio

`FakeDeck` implements `Deck` with a synthetic clock and records every `setVolume` call. Then:

```dart
test('equal-power crossfade holds constant power', () async {
  final engine = CrossfadeEngine(deckA: fakeA, deckB: fakeB, clock: fakeClock);
  await engine.load(item(duration: 30.s), next: item());
  fakeClock.advanceTo(28.s);                       // 2s crossfade window
  for (final s in fakeClock.stepThrough(2.s, 20.ms)) {
    final p = fakeA.volume * fakeA.volume + fakeB.volume * fakeB.volume;
    expect(p, closeTo(1.0, 0.01));                 // sin² + cos² = 1
  }
});
```

Every curve, every duck sequence, and every announcement mode is testable this way in
milliseconds. Reserve device testing for the things only devices reveal: focus loss, route
changes, backgrounding, and buffer underruns.

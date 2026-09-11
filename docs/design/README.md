# Handoff: Sayaw operator redesign

## Overview

A redesign of Sayaw's operator interface so a first-time volunteer — a dance instructor or organiser at the laptop, standing, one-handed, in a dark room, an hour after installing the app — can run a whole social night without training, while a working DJ can still reach every advanced control.

Eleven artboards cover the 90% path (open a set → press play → see what is playing and what is next → let the transition happen or push it early → fire a cue sound) plus the demoted 10% (sources, offline caching, set shape, Snowball, Jack & Jill, event presets, announcement mode, soundboard, crossfade curves).

**Source of truth for the current app:** `yvesanana-sys/Sayaw@main`. Every colour, breakpoint and touch dimension below is lifted from `lib/ui/theme/sayaw_theme.dart`, `lib/ui/layout/breakpoints.dart` and `lib/ui/touch/touch_targets.dart` — they are unchanged, and the existing widget tests should still pass against them.

## About the design files

`Sayaw Redesign Canvas.dc.html` is a **design reference created in HTML** — a prototype showing intended look, wording and layout. It is not production code and should not be ported line-for-line.

The task is to **recreate these designs in the existing Flutter app**, using its established patterns: `SayawColors` / `SayawTheme`, `SayawBreakpoint` / `SayawLayout`, the `kMinTouchTarget` / `kTransportTouchTarget` constants, the existing `Riverpod` providers and `PlaybackUiState`. Widget names below map onto the files that exist today.

Open the HTML file in any browser. Annotations (numbered pins in the gutter + note panels to the right of each board) explain what changed and why; both can be toggled off via the `showPins` / `showNotes` props.

## Fidelity

**High-fidelity.** Final colours, type sizes, spacing, touch dimensions and copy. Recreate pixel-accurately using Flutter widgets — the HTML is the specification, not the implementation.

Exception: icons are drawn as coloured rectangles/glyph placeholders in the HTML. Use the app's existing Material icons; the redesign's rule is that **no icon appears without a text label**, so the icon choice matters much less than the label beside it.

---

## The central design change

Today the interface is two audio decks, A and B, each rendered by `DeckPanel`, joined by a `Crossfader`. The operator has to know which deck is live, which is cued, and what a crossfader does.

The redesign replaces that model with a **handover lane**:

- **On the floor now** — the currently playing song. Always lavender `#C7A9F5`.
- **Coming in** — the cued song. Always mint `#7FD1C1`.
- **The lane** — a single 44dp draggable band, lavender at the left end, mint at the right, labelled `SALSA OUT` / `BACHATA IN` in words.

The letters "A" and "B" never appear in the UI. The hue/lightness pair is unchanged from `SayawColors.deckA` / `deckB`, so the colour-blind-differentiation test still holds; the colours now mean *role* (outgoing/incoming) rather than *hardware deck*. Underneath, deck A and deck B still alternate exactly as they do today — the mapping from deck to lane side flips at each transition.

**The most valuable element on screen** is a plain sentence in amber `#F2C46B`:

> In 40 seconds, the music blends into Bachata and the room hears "Next dance: Bachata".

It states the event, the delay, and the words the room will hear. It occupies a fixed-height box that never collapses: with nothing queued it reads "Nothing after this song"; on failure it turns red in the same slot at the same height.

---

## Screens / views

### 1a — Main screen, compact (640 × 1000, `< 700dp`)

**Purpose:** the default view on a tablet in portrait. Everything needed to run the night.

**Layout:** vertical flex. Fixed 64dp status ribbon → scrollable content (16dp padding, 12dp gaps) → fixed action bar → 72dp bottom nav.

| Region | Spec |
|---|---|
| Status ribbon | 64dp, `#17171E`, 1px `#3A3648` bottom border. Left: set name 15/600, below it "Song 9 of 34 · 2h 41m of music left" 12px `#B9B4C7` tabular. Right: two 48dp pill buttons, `#2A2A36` fill, 1px `#6E6880` border, 14/600 — **Adjust**, **Stage view**. |
| On the floor now | Card `#1F1F28`, 2px `#C7A9F5` border, 18dp radius, 20dp padding. Label 12/800 letter-spacing 1.4 `#C7A9F5`. Dance name 40/700 `#C7A9F5` tracking −1. Title 22/600 `#ECEAF2`, artist 16 `#B9B4C7`. Right: time remaining 56/600 tabular tracking −2, "left" 14 `#B9B4C7`. Bottom: 10dp progress bar, `#2A2A36` track, `#C7A9F5` fill. |
| What happens next | Card `#241D0F`, 2px `#F2C46B` border, 18dp radius, 20dp padding. 10dp amber dot + label 12/800 `#F2C46B`. **Sentence 26/600, line-height 1.35, `#ECEAF2`**, with the incoming dance name in `#7FD1C1`. Below: three 32dp chips — "Voice ready" (`#3D3116` / `#F2C46B`), "Blend takes 8s", "Happens on its own" (`#2A2A36` / `#ECEAF2`). |
| Coming in | Card `#1F1F28`, 1px `#3A3648`, 18dp padding. Label 12/800 `#7FD1C1`, title 20/600, artist+duration 15 `#B9B4C7`. Right: 34dp dance chip `#1B3D38` / `#7FD1C1` 15/700, and "ready and cued" 13 `#B9B4C7`. |
| Handover lane | Card `#17171E`, 1px `#3A3648`. Header row: `SALSA OUT` 12/700 `#C7A9F5` · "Blend by hand — drag anywhere on the lane" 12/600 `#B9B4C7` · `BACHATA IN` 12/700 `#7FD1C1`. Band: 44dp tall, 12dp radius, hard-stop gradient lavender 0–30% / `#2A2A36` 30–70% / mint 70–100%. Thumb: 28 × 52dp, 14dp radius, `#ECEAF2`, 2px `#0E0E12` border. |
| Sounds | Three equal 56dp buttons, `#1F1F28`, 1px `#3A3648`, 14dp radius, 12dp gap. Label 15/600 + key number 12 `#B9B4C7`. |
| Action bar | `#17171E`, 1px top border, 14/16dp padding, 12dp gaps. **Pause** 88 × 72dp `#2A2A36` + 2px `#C7A9F5`. **Start Bachata now** flex:1, 72dp, solid `#C7A9F5`, label 20/700 `#12081F`, sub-label 13/600 `#2A1747`. **Say it** 88 × 72dp `#3D3116` + 2px `#F2C46B`, label 12/700 `#F2C46B`. |
| Bottom nav | 72dp, `#1F1F28`. Three equal items: **Now** (active, `#3A2A55` fill, 12/700 `#ECEAF2`), **Set list**, **Music** (12/600 `#B9B4C7`). |

**What changed:**
1. The six unlabelled app-bar icon buttons collapse to two words — **Adjust** and **Stage view** (full mapping below).
2. The plain sentence is the second-loudest element after the clock. The old `AnnouncerStrip` stated a label and a timing fragment; this states event, delay and the exact words.
3. "Deck A / Deck B" is gone — one handover lane, labelled in words.
4. Two equal-weight actions: Pause is the *state*, "Start Bachata now" is the *act*. The old `TransportBar` had six identical squares (cue / play / load × 2) plus FADE; cue and load are automatic now.
5. Panes renamed: Library → **Music**, Queue → **Set list**, Decks → **Now**.

### 1b — Main screen, expanded (1440 × 900, `> 1100dp`)

Three panes plus rail. **The centre column is byte-identical to compact** — same cards, same order, same sizes. Wide windows add panes on either side; they never rearrange what a hand already knows.

- **Rail** 88dp, `#1F1F28`, three 72dp destinations in the same order as the bottom nav.
- **Music pane** 320dp: 48dp search field, "318 SONGS · ADDED THIS WEEK" 12/800, then 64dp rows (title 15/500, "artist · dance" 12 `#B9B4C7`, 48dp circular `+` in `#2C2340` / `#C7A9F5`).
- **Set list pane** 360dp: header + "5 songs per dance · 20s gap for the floor to change". Rows 64dp min. The playing row has a 3dp `#C7A9F5` left border on `#1E1830`; the cued row a 3dp `#7FD1C1` border on `#141C1B`, sub-line "coming in · says 'Next dance: Bachata'". Remaining rows carry a dance chip and a 48dp drag handle.
- App bar gains a third pill, **Prepare** — a desktop is where the night gets set up an hour early.

### 1i — Main screen, medium (980 × 760, `700–1100dp`)

Compact plus a 300dp set list; rail replaces bottom nav. **The Now column and the action bar keep their coordinates.** Two things drop relative to compact — the sounds strip and the Coming-in card — both restated inside the sentence and the set list. *(Open question for the team: whether the sounds strip should survive here at the cost of set-list width.)*

### 1c — Stage view (Performance Mode) (1440 × 810)

Borderless, chrome-free, 48dp padding. Not a bigger main screen — a different question answered, readable from three metres:

- `ON THE FLOOR` 18/700 tracking 2 `#C7A9F5`, hairline rule, "Song 9 of 34 · Friday Social" 18 `#B9B4C7`.
- Dance name **112/700** tracking −4 `#C7A9F5`; title 40/600; artist 28 `#B9B4C7`.
- Time remaining **180/600** tracking −8, tabular; "left on this song" 26 `#B9B4C7`.
- 16dp progress bar.
- Amber sentence card at **40/600**, with a "VOICE READY" indicator (28dp dot + 16/700) on the right.
- Transport: 112dp tall. Pause 200dp · "Start Bachata now" flex (34/700) · "Say it" 200dp · **"Leave stage view / or press Esc"** 200dp.

**What changed:** the old mode was exitable only by F11 or Esc — invisible on a tablet. A labelled fourth button sits beside the transport, preserving the existing left-to-right order of the three transport controls.

### 1d — First run / empty state (1100 × 850)

The moment that decides whether a volunteer succeeds. Today a fresh install shows empty decks, an empty queue, an empty library and a "Search your library" hint — four dead ends and no order.

- H2 "Let's get tonight ready." 38/600 tracking −1; sub "Three steps, about five minutes. You can run a whole night with just the first two." 18 `#B9B4C7`.
- **Step 1 — active.** Card `#1F1F28` + 2px `#C7A9F5`. 48dp lavender numeral. "Point Sayaw at your music" 22/600 · "A folder on this machine or a drive. Nothing is copied or uploaded." 15 `#B9B4C7`. 64dp solid-lavender pill **Choose a folder**.
- **Step 2 — pending.** Same geometry, `#17171E` + 1px `#3A3648`, numerals and title in `#B9B4C7`, button reads "After step 1".
- **Step 3 — optional.** "Decide what the room hears between dances" · button "Optional".
- **Footer**, hairline-separated: "Your music lives on a Plex server?" 16/600 + reassurance 14 `#B9B4C7` + 48dp **Connect a Plex server**.

**What changed:** one ordered path with exactly one enabled button; later steps visible but explicitly not-yet, so the shape of the night is learnable before anything is asked. Plex is demoted to the footer (it was an unlabelled server-rack icon in the app bar) with the existing reassurance copy from `sources_screen.dart` kept verbatim.

### 1e — Set list with a row mid-drag (760 × 940)

- Header: "Tonight's set list" 18/600 + 48dp **Adjust the shape**; stats line "34 songs · 2h 41m · Salsa 10 · Bachata 9 · Cha-Cha 8 · Swing 7" 14 tabular; **amber line naming the row in hand**: "Holding 'Propuesta Indecente' — drop it where you want it played."
- **Drop target:** 72dp, 14dp radius, 2px dashed `#C7A9F5` on `#1A1526`, centred label 14/600 `#C7A9F5` — **"Drop here — plays 11th, after Obsesión"**. The consequence is stated; the operator never counts rows.
- **Lifted row:** `#2A2A36`, 2px `#C7A9F5`, 16dp radius, `0 18px 40px rgba(0,0,0,.65)`, `rotate(-0.4deg)`. Keeps the existing elevation-8 proxy behaviour.
- **Unplayable row:** `#1A1416` ground, title struck through in `#B9B4C7`, reason + remedy in `#FF9A94` — "Won't play — file not found. Plug the drive in, or remove it." — plus a 48dp **Fix** button. Today this reads "File not found.": true, and no help.
- **Footer:** "Playing continues while you edit. Nothing you drop changes the song on the floor." + 56dp **Done**.
- Dance chips show at **every** width. Hiding them in compact (today's behaviour) hides a row's single most important attribute on the device most likely to be in use.

Drag mechanics unchanged: 48dp handles, long-press on touch, press-to-drag with a mouse, fractional ordering.

### 1f — Tagging one song (760 × 1040)

One screen, not two. Dance type and announcement are one decision — the dance decides the words.

1. **"Which dance is this?"** — 56dp chips, 22dp horizontal padding, 14dp radius. Selected: solid `#7FD1C1` with `#00201A` text. Unselected: `#1F1F28` + 1px `#3A3648`. Ends with **More…**.
2. **"What should the room hear before it?"** — three 64dp radio cards. Selected is `#241D0F` + 2px `#F2C46B` with a 24dp amber ring. Options: *A spoken "Next dance: Bachata"* ("Made on this machine — works with the wifi down.") · *One of your own recordings* · *Nothing — let the music change on its own*.
3. **"When?"** — two 80dp cards: **Over the blend** ("Music dips underneath the voice.") and **In the quiet first** ("Voice alone, then the music starts."). The ducking concept lives inside the option that causes it.
4. **"Do this for every Bachata in the set"** — toggle, default **on**, sub-line "9 songs. You can change any one of them later."
5. **Footer:** amber read-back "At this transition the room will hear: 'Next dance: Bachata', over the blend." + **Hear it in my headphones** (56dp secondary) + **Save** (56dp primary).

Preview is explicitly headphones-only. The old dialog refused a preview entirely rather than risk a whistle over a full floor; naming the output makes offering it safe.

### 1g — The other 10%: Prepare (760 × 900) + Adjust (520 × 1000)

Split by **time**, not by feature: everything you do at six o'clock is a checklist; everything you do at eleven is a sheet over the running set.

**Prepare for tonight** — "Do this on the venue wifi, before doors. Then the set stops depending on it."
- ✓ Music is where it should be — "318 songs · folder 'D:\Dance Music' · checked just now"
- ! **6 songs still need the internet** — amber card, "28 of 34 are downloaded and will play with the wifi down.", 48dp **Download them**
- ✓ All 24 announcements are made and saved
- → **The shape of the night** — "5 songs per dance · stop each song at 4:00 · 20s gap for the floor" + **Change**, and preset chips: Social night (active) · Class · Competition rounds · Practice
- **Special formats** — "Snowball staged set · Jack & Jill partner draw · both off" + **Set up**
- **Where your music comes from** — "This machine · Plex server 'Attic NAS' connected" + **Manage**
- 72dp primary **Check everything again**

The Event Mode pre-flight report *became* the screen: it used to be a modal whose findings vanished on close. Here each finding is a row with the one action that resolves it.

**Adjust** — "Changes take effect at the next transition. The music keeps playing." (the safety rule, stated at the top)
- **How long the blend takes** — 44dp slider, value 8s in `#C7A9F5` 18/700, ends labelled "Quick, 2s" / "Long, 16s"
- **Announcements tonight** — three radios: Over the blend · In the quiet before the music · Silent for the rest of the night
- **Move on by itself** — toggle, "Off means you press to start each dance."
- **Your sounds** — "3 on the bar · keys 1–3" + Edit
- **Blend shape** — "Equal-power — no dip in the middle" + Change
- 64dp **Back to the floor**

Expert controls sit at the bottom with the jargon as the *value*, not the label — a working DJ finds all six curves behind "Blend shape"; nobody else meets the word.

**Where the six app-bar icons went:**

| Today | Redesign |
|---|---|
| `casino` (Jack & Jill) | Prepare › Special formats |
| `graphic_eq` (soundboard) | Adjust › Your sounds |
| `timelapse` (set shape) | Prepare › Shape of the night |
| `cloud_download` (event mode) | Prepare › the checklist itself |
| `dns` (sources) | Prepare › Where your music comes from |
| `fullscreen` | "Stage view", still one tap |

### 1h — Failure: song won't play **and** its announcement failed (760 × 1150)

The compound worst case, 38 seconds before it becomes audible.

- **Ribbon** gains a 48dp red count pill: `#4C1512` fill, 1px `#FF9A94`, "2 problems" 14/700.
- **The sentence slot goes red, in the exact position and height the good news occupied** — `#2A1210`, 2px `#FF9A94`. Same 26/600 sentence: "In 38 seconds the floor gets silence: **Obsesión can't play, and the words 'Next dance: Bachata' couldn't be made.**" Below it two labelled causes so a compound failure doesn't read as one vague problem:
  - `SONG` — "The file isn't where it was — the drive it lives on isn't connected."
  - `VOICE` — "This announcement was never made before doors, and this machine has nothing to say it with — no speech synthesiser is installed."
- **Three ways out, with a default that fires by itself.** "Pick one — or do nothing and Sayaw takes the first option by itself in 38s."
  - Primary 72dp: **Skip to Propuesta Indecente** / "Bachata, downloaded, announcement ready"
  - **Play Bachata without the words** / "you announce it yourself"
  - **Stay on Salsa** / "repeat this dance, decide later"
- **Scope stated once, not per row:** "5 more songs in tonight's set live on that drive" + **Show them**. This replaces the forty-toast failure mode the existing `NetworkBanner` was built to avoid.
- The lane shows `SALSA OUT` / "nothing loaded to blend into" / `— —`.
- **The primary action is visibly disabled and says why** — "nothing playable is cued". The old bar dropped opacity to 38% with no reason given.

A dialog would have blocked the transport; this must not. The volunteer who freezes still gets music.

### 1j — Jack & Jill partner draw (820 × 760)

Reached via Prepare › Special formats — a format decision made before the round, not a transport control.

Header "Partner draw" + "Round 2 of 4 · nobody dances with the same partner twice" + **Who's dancing**. Two roster cards (LEADS 8 in `#C7A9F5`, FOLLOWS 8 in `#7FD1C1`) of 36dp number chips. **The pairs are the screen:** a 2-column grid of 64dp cards, `#104` `with` `#209` at 20/700 in the two lane hues, readable without leaning in. Footer: 72dp **Draw round 3** / "then read the pairs to the floor" + amber **Announce these** / "spoken, over the music" — the same amber voice affordance as every other screen.

### 1k — Your sounds (700 × 970)

"Soundboard", "cue" and "duck" are all gone.

- **Add a sound:** 56dp *Choose a file* + accepted formats (wav, mp3, flac, m4a, aiff, ogg) · 56dp name field, placeholder "Name it — this is what the button says" · toggle "**Dip the music under it** — for anything spoken. A whistle cuts through on its own." · 56dp **Add**.
- **3 on the bar:** 72dp rows — 48dp circular play button (`#2C2340` / `#C7A9F5`), name 16/600, "Plays over the music · key 1" 13 `#B9B4C7` (or "Music dips under it · key 2" in `#F2C46B`), 48dp **Rename**, 48dp remove `✕` in `#FF9A94`.
- **Amber note:** "Trying a sound here plays it in your headphones only. Pressing it on the main screen plays it to the room."

The keyboard shortcut is printed on every row: a working DJ wants keys 1–9, and a first-timer needs to know the number under the button means something.

---

## Interactions & behaviour

| Behaviour | Spec |
|---|---|
| Automatic transition | At `T − blend length`, the lane animates lavender→mint over the blend duration (default 8s). The countdown sentence updates every second. |
| Push early | "Start Bachata now" performs blend + announcement immediately. Label always names the incoming **dance**, never "next" or "cue". |
| Manual blend | The whole 44dp lane is draggable; drag overrides automation for that transition only. |
| Say it | Fires the pending announcement immediately, independent of the music. |
| Sounds | Keys 1–9 mirror the on-screen buttons. Sounds marked "dips the music" duck the bed; others play over it. |
| Nothing moves on state change | Every state-dependent box is fixed-height. Empty announcer readout, red failure state and normal sentence all occupy the same slot at the same height. |
| Controls never move | Action bar, in all three layouts, sits at the bottom of the primary column at the same offset with the same three widths (88 / flex / 88). |
| Disabled | Never opacity alone. Grey fill + `#6E6880` border + a sub-label stating the reason. |
| No hover-only affordances | Every action carries a persistent text label. Hover may tint background only. |
| Layout switching | Driven by **width alone** — `< 700dp` compact, `700–1100dp` medium, `> 1100dp` expanded — recomputed live as the window is dragged. |
| Motion | 180ms `cubic-bezier(.22,.61,.36,1)` for state changes; blend animation runs for the configured blend length. No bounces, no slide-ins. |

## State

Mostly existing `PlaybackUiState`. Additions the redesign needs:

- `secondsUntilTransition: int?` — drives the sentence countdown.
- `nextTransitionSentence: String` — composed server-side of the UI, not assembled in the widget, so it is testable: `"In {n} seconds, the music blends into {dance} and the room hears \"{announcementText}\"."`
- `announcementReadiness: {ready | notMade | noNetwork | failed}` — distinguishes the four cases the current silent-failure bug conflates.
- `pendingProblems: List<Problem>` — each with `kind: song | voice`, a plain-language cause, and a remedy action. Drives the ribbon count and the red sentence card.
- `failureResolution` — the three offered actions plus which one auto-fires at zero.
- `driveScopedFailureCount: int` — "5 more songs live on that drive".

## Design tokens

All from `lib/ui/theme/sayaw_theme.dart` — none invented.

**Colour**

| Token | Hex | Use |
|---|---|---|
| ground | `#0E0E12` | app background |
| canvas (this doc) | `#08080B` | the design canvas only, not the app |
| surface | `#17171E` | bars, headers, footers |
| surface raised | `#1F1F28` | cards |
| surface raised 2 | `#2A2A36` | secondary buttons, slider tracks |
| outline | `#6E6880` | **borders and icon fills only — never text** |
| divider | `#3A3648` / `#262330` | card borders / row separators |
| text primary | `#ECEAF2` | 17.4:1 on ground |
| text secondary | `#B9B4C7` | 7.9:1 on ground — the lowest text colour permitted |
| outgoing (deck A) | `#C7A9F5` | on the floor |
| incoming (deck B) | `#7FD1C1` | coming in |
| voice | `#F2C46B` | announcements, the sentence |
| error | `#FF9A94` | failures |
| on-lavender ink | `#12081F` / `#2A1747` | text on solid lavender |
| on-mint ink | `#00201A` | text on solid mint |
| on-amber ink | `#3D1400` | text on solid amber |
| lavender tint | `#3A2A55` / `#2C2340` / `#1E1830` / `#1A1526` | active nav, icon wells, playing row |
| mint tint | `#1B3D38` / `#141C1B` | chips, cued row |
| amber tint | `#241D0F` / `#3D3116` | sentence card, voice chips |
| error tint | `#2A1210` / `#4C1512` / `#1A1416` | failure card, count pill, dead row |

**Contrast rule:** every text/background pair clears WCAG AA 4.5:1 — asserted in tests. `#6E6880` was originally used for de-emphasised text and fails; it is now borders only. **Demotion comes from size and weight, not from dimmer grey.**

**Type** — Inter. 12/13/14/15/16/17/18/20/22/24/26 body scale; 32/34/40/44 dance names; 48/52/56/64 clocks; 112/180 in stage view. Weights 500 / 600 / 700 / 800. All numerals `font-variant-numeric: tabular-nums`. Nothing below 12px, and nothing below 24px in stage view.

**Spacing** — 4dp base: 2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24 · 28 · 48. Card padding 16–20dp; card gaps 12dp; screen padding 16dp (48dp in stage view).

**Radius** — 8 chips-small · 12 lane/small surfaces · 14 sound buttons · 16 secondary cards · 18 primary cards & transport · 22 window · 999 pills.

**Touch** — 48dp minimum hit region everywhere (`kMinTouchTarget` in `lib/ui/touch/touch_targets.dart`). Transport 72dp painted / 64dp minimum, 12dp apart. Rail and bottom-nav destinations 72dp. List rows 64dp min (72dp in the full set list). Hit region and painted size stay independent, as today.

**Elevation** — flat. The one shadow is on the lifted drag proxy: `0 18px 40px rgba(0,0,0,.65)`.

## Vocabulary — apply globally

| Today | Redesign |
|---|---|
| crossfade | blend |
| deck A / deck B | on the floor / coming in |
| crossfader | the handover lane |
| cue / cue tag | sound / what the room hears |
| duck | dip the music under it |
| transport | the two buttons at the bottom |
| preroll | in the quiet before the music |
| queue | set list |
| library | music |
| event mode / pre-flight | prepare for tonight |
| performance mode | stage view |

Sentence case throughout. Tone: warm and encouraging, terse and professional, dance-world vocabulary (floor, rotation, social). No exclamation marks, no emoji.

## Assets

None new. Icons come from the app's existing Material set; every one is paired with a visible text label. Fonts: Inter (the HTML loads it from `rsms.me/inter`); use the app's existing font configuration.

## Files

| File | What it is |
|---|---|
| `Sayaw Redesign Canvas.dc.html` | All eleven artboards with annotations. Open in a browser. |
| `github.md` | Source association + screen-to-repo-file map. |
| this `README.md` | Self-sufficient implementation spec. |

**Repo files each board was built from** — see the `## Screen map` table in `github.md`.

## Open questions for the team

1. **Medium width (1i):** the sounds strip and Coming-in card currently drop out. Keep them at the cost of set-list width?
2. **Prepare / Adjust split (1g):** worth a sanity read that each of the six consolidated icons landed in the right home.
3. ~~**Announcement pre-generation:** the redesign assumes announcements can be generated and cached before doors.~~ **Answered — yes.** `AnnouncementEngine.warm()` renders each row's clip the moment it is preloaded, and the file is cached by text-and-voice hash, so a set opened before doors has every announcement on disk before the first song. Synthesis is on-device (`lib/audio/system_voice.dart`: SAPI on Windows, `say` on macOS, `espeak-ng` on Linux), so the network is never a factor — the 1f copy "works with the wifi down" is literally true. The one real VOICE failure is a Linux machine without `espeak-ng` installed, which is what the 1h copy now says; INSTALL.md lists it as a runtime dependency. A Prepare-screen row that checks for the synthesiser before doors would catch it an hour early, and is the right place for it.

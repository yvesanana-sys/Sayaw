repo: yvesanana-sys/Sayaw
branch: main

## Last sync

date: 2026-09-09T13:05:30Z

### Updated in this project

- Read the full operator UI: deck screen, theme, breakpoints, touch targets, all 13 widgets, and the six app-bar dialogs.
- Built an 11-artboard redesign canvas replacing the A/B deck model with a single "handover lane".
- Kept the pinned palette (#0E0E12 / #C7A9F5 / #7FD1C1 / #F2C46B), 48dp & 64dp targets, and width-only breakpoints.
- Consolidated the six unlabelled app-bar icon buttons into "Prepare" (pre-event) and "Adjust" (in-set).

## Screen map

| Project screen | Repo files it was built from |
|---|---|
| 1a Main — compact | lib/ui/screens/deck_screen.dart, lib/ui/widgets/deck_panel.dart, crossfader.dart, announcer_strip.dart, transport_bar.dart, transport_button.dart, up_next_card.dart, soundboard_bar.dart, lib/ui/layout/breakpoints.dart, lib/ui/touch/touch_targets.dart, lib/ui/theme/sayaw_theme.dart |
| 1b Main — expanded | lib/ui/screens/deck_screen.dart, lib/ui/widgets/library_pane.dart, queue_list.dart, pane_header.dart |
| 1c Stage view (Performance Mode) | lib/ui/screens/deck_screen.dart (_PerformanceModeButton), lib/main.dart (_PerformanceModeShortcuts), lib/ui/window/window_controller.dart |
| 1d First run / empty | lib/ui/widgets/library_pane.dart (_EmptyLibrary), lib/ui/widgets/queue_list.dart (empty), lib/ui/screens/sources_screen.dart |
| 1e Set list mid-drag | lib/ui/widgets/queue_list.dart, lib/data/fractional_order.dart, lib/ui/state/playback_ui_state.dart (UnavailableReason) |
| 1f Tag a song | lib/ui/screens/cue_tag_dialog.dart, lib/ui/state/playback_ui_state.dart (AnnouncementTiming), lib/data/dance_type_seed.dart |
| 1g Prepare + Adjust | lib/ui/screens/event_mode_dialog.dart, set_shape_dialog.dart, sources_screen.dart, soundboard_sheet.dart, jack_and_jill_dialog.dart |
| 1h Failure state | lib/ui/widgets/network_banner.dart, lib/ui/widgets/soundboard_bar.dart (failure listener), lib/ui/state/playback_ui_state.dart |
| 1i Main — medium | lib/ui/screens/deck_screen.dart (_buildMedium, _buildRail) |
| 1j Jack & Jill draw | lib/ui/screens/jack_and_jill_dialog.dart, lib/data/jack_and_jill.dart, lib/ui/screens/participants_sheet.dart |
| 1k Your sounds | lib/ui/screens/soundboard_sheet.dart, lib/audio/soundboard.dart |

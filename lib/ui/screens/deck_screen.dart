import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/breakpoints.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';
import '../widgets/announcer_strip.dart';
import '../widgets/crossfader.dart';
import '../widgets/deck_panel.dart';
import '../widgets/library_pane.dart';
import '../widgets/network_banner.dart';
import '../widgets/pane_header.dart';
import '../widgets/queue_list.dart';
import '../widgets/snowball_indicator.dart';
import '../widgets/song_length_chips.dart';
import '../widgets/soundboard_bar.dart';
import '../widgets/transport_bar.dart';
import '../widgets/up_next_card.dart';
import 'event_mode_dialog.dart';
import 'jack_and_jill_dialog.dart';
import 'set_shape_dialog.dart';
import 'soundboard_sheet.dart';
import 'sources_screen.dart';
import '../window/window_controller.dart';

/// Which pane a single-pane or two-pane layout is showing.
enum SayawPane {
  library(Icons.library_music, 'Library'),
  decks(Icons.album, 'Decks'),
  queue(Icons.queue_music, 'Queue');

  const SayawPane(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// The main screen, in three layouts.
///
/// One [State] above the breakpoint switch owns the scroll controllers and the
/// selected pane. That placement is the whole reason a live resize is
/// survivable: the panes below are rebuilt when the breakpoint changes, but
/// scroll offsets and selection live above them and are simply handed to
/// whatever gets built. Playback state lives higher still, in the Riverpod
/// provider, so it is untouched by layout entirely.
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  final _queueScroll = ScrollController();
  final _libraryScroll = ScrollController();

  SayawPane _pane = SayawPane.decks;

  @override
  void dispose() {
    _queueScroll.dispose();
    _libraryScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final performanceMode =
        ref.watch(playbackProvider.select((s) => s.performanceMode));

    return SayawLayout(
      builder: (context, breakpoint) {
        return Scaffold(
          // In Performance Mode the window is borderless and the title bar is
          // gone; an app bar would just be a second thing to look at on a
          // stage monitor.
          appBar: performanceMode
              ? null
              : AppBar(
                  backgroundColor: SayawColors.surfaceContainer,
                  title: Text(breakpoint.isCompact ? 'Sayaw' : 'Sayaw — Set'),
                  actions: const [
                    JackAndJillButton(),
                    SoundboardButton(),
                    SetShapeButton(),
                    EventModeButton(),
                    _SourcesButton(),
                    _PerformanceModeButton(),
                  ],
                ),
          body: SafeArea(
            child: Column(
              children: [
                // Above the panes rather than inside one: in Performance Mode
                // there is no app bar to put it in, and it has to be visible
                // whichever pane a compact layout happens to be showing.
                const NetworkBanner(),
                // Beside the banner and above the panes for the same reasons:
                // Performance Mode has no app bar to put it in, and a compact
                // layout must show it whichever pane is selected.
                const SnowballIndicator(),
                Expanded(
                  child: switch (breakpoint) {
                    SayawBreakpoint.compact => _buildCompact(),
                    SayawBreakpoint.medium => _buildMedium(),
                    SayawBreakpoint.expanded => _buildExpanded(),
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              breakpoint.isCompact ? _buildBottomNav() : null,
        );
      },
    );
  }

  // -- compact: one pane, bottom navigation ----------------------------------

  Widget _buildCompact() {
    return switch (_pane) {
      SayawPane.library => LibraryPane(scrollController: _libraryScroll),
      SayawPane.decks => _decksColumn(compactTransport: true),
      SayawPane.queue => QueueList(scrollController: _queueScroll),
    };
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _pane.index,
      onDestinationSelected: (i) =>
          setState(() => _pane = SayawPane.values[i]),
      destinations: [
        for (final pane in SayawPane.values)
          NavigationDestination(
            icon: Icon(pane.icon),
            label: pane.label,
            // Empty disables the tooltip Material adds by default. It would
            // only ever show on hover, which does not exist on the tablet this
            // layout is for, and the label is already drawn under the icon.
            tooltip: '',
          ),
      ],
    );
  }

  // -- medium: navigation rail + decks + one secondary pane -------------------

  Widget _buildMedium() {
    // The decks are always on screen at this width; the rail switches what
    // sits beside them. Hiding the decks behind a tab on a device wide enough
    // to show them would be a downgrade from the compact layout.
    final secondary = switch (_pane) {
      SayawPane.library => LibraryPane(scrollController: _libraryScroll),
      SayawPane.queue || SayawPane.decks =>
        QueueList(scrollController: _queueScroll),
    };

    return Row(
      children: [
        _buildRail(),
        const VerticalDivider(width: 1),
        Expanded(flex: 5, child: _decksColumn(compactTransport: false)),
        const VerticalDivider(width: 1),
        Expanded(flex: 4, child: secondary),
      ],
    );
  }

  Widget _buildRail() {
    return NavigationRail(
      selectedIndex: _pane.index,
      onDestinationSelected: (i) =>
          setState(() => _pane = SayawPane.values[i]),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final pane in SayawPane.values)
          NavigationRailDestination(
            icon: Icon(pane.icon),
            label: Text(pane.label),
          ),
      ],
    );
  }

  // -- expanded: library | decks | queue, all at once ------------------------

  Widget _buildExpanded() {
    return Row(
      children: [
        _buildRail(),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: LibraryPane(scrollController: _libraryScroll),
        ),
        const VerticalDivider(width: 1),
        Expanded(flex: 4, child: _decksColumn(compactTransport: false)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: QueueList(scrollController: _queueScroll),
        ),
      ],
    );
  }

  // -- shared ----------------------------------------------------------------

  /// Deck A above, crossfader across the middle, deck B below, transport at the
  /// bottom. Identical in every breakpoint — muscle memory is worth more than
  /// a layout that makes clever use of a wide window.
  Widget _decksColumn({required bool compactTransport}) {
    return Column(
      children: [
        const PaneHeader(icon: Icons.album, title: 'Decks'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                DeckPanel(slot: DeckSlot.a),
                const SizedBox(height: 8),
                const Crossfader(),
                const SizedBox(height: 8),
                // Between the decks because that is where it is heard: the
                // voice rides the crossfade from A into B. Blank when the row
                // coming up has nothing to say.
                const AnnouncerStrip(),
                const SizedBox(height: 8),
                DeckPanel(slot: DeckSlot.b),
                const SizedBox(height: 8),
                // Fills the space that otherwise sat empty below the decks
                // once both were loaded, and doubles as the "what do I do
                // now" hint on a fresh set with nothing queued yet.
                const UpNextCard(),
                const SizedBox(height: 12),
                // Under the decks because it changes between dances, not the
                // day before: two minutes of each for a class, the whole song
                // for a social, and the hand is already here.
                const SongLengthChips(),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Directly above the transport, where a hand already is. A tag call
        // happens now; anything needing a pane change has missed it.
        const SoundboardBar(),
        TransportBar(compact: compactTransport),
      ],
    );
  }
}

/// Opens the sources screen.
///
/// In the app bar rather than behind a settings menu: the moment an operator
/// needs it is when a server has stopped answering an hour before doors, and
/// that is not the moment to go looking.
class _SourcesButton extends StatelessWidget {
  const _SourcesButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Music sources',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.dns_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
          ),
        ),
      ),
    );
  }
}

/// Toggles borderless fullscreen.
///
/// Kept reachable by touch as well as by the F11 shortcut — a tablet has no
/// function-key row, and a DJ who cannot leave fullscreen is stuck.
class _PerformanceModeButton extends ConsumerWidget {
  const _PerformanceModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(playbackProvider.select((s) => s.performanceMode));

    return Semantics(
      button: true,
      label: on ? 'Exit performance mode' : 'Enter performance mode',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: InkWell(
          onTap: () => ref.read(windowControllerProvider).setPerformanceMode(
                !on,
                ref.read(playbackProvider.notifier),
              ),
          child: Icon(on ? Icons.fullscreen_exit : Icons.fullscreen),
        ),
      ),
    );
  }
}

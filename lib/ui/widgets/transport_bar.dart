import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';
import 'transport_button.dart';

/// The canonical control surface: cue, play/pause and load for each deck, with
/// crossfade-now between them.
///
/// One widget for all three breakpoints rather than a per-layout variant. The
/// controls a DJ reaches for without looking must be in the same place whether
/// the window is a quarter of a tablet or a full 4K desktop; moving them on
/// resize is exactly the kind of cleverness that causes a mis-hit on stage.
class TransportBar extends ConsumerWidget {
  const TransportBar({super.key, this.compact = false});

  /// Forces the reduced layout — drops the per-deck cue buttons. Play/pause,
  /// stop and crossfade never drop; they are the controls a set cannot run
  /// without.
  ///
  /// The bar also drops to this form on its own when it does not fit, so
  /// passing false is a preference, not a guarantee.
  final bool compact;

  static const double _horizontalPadding = 12.0;

  /// Width of one deck's control group: play/pause alone, or cue beside it.
  static double _groupWidth(bool compact) => compact
      ? kTransportTouchTarget
      : kTransportTouchTarget * 2 + kTransportSpacing;

  /// Width the whole bar needs before anything would have to shrink: two deck
  /// groups, and stop and crossfade in the middle.
  static double _barWidth(bool compact) =>
      _groupWidth(compact) * 2 +
      kTransportTouchTarget * 2 +
      kTransportSpacing * 3 +
      _horizontalPadding * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final controller = ref.read(playbackProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget deckGroup(DeckSlot slot, bool compact) {
      final deck = state.deck(slot);
      final accent =
          slot == DeckSlot.a ? SayawColors.primary : SayawColors.secondary;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            TransportButton(
              icon: Icons.replay,
              label: 'Cue deck ${slot.label}',
              caption: 'CUE',
              onPressed: deck.isLoaded ? () => controller.cue(slot) : null,
              background: accent,
              color: accent,
            ),
            const SizedBox(width: kTransportSpacing),
          ],
          // Getting a track *onto* a deck is not a job for this bar any more:
          // a tap on a queue row plays it, through the crossfade, which is
          // what the load-to-deck buttons that used to sit here pretended to
          // do and never did with an engine behind them. Their width is what
          // stop needed.
          TransportButton(
            icon: deck.isPlaying ? Icons.pause : Icons.play_arrow,
            label: deck.isPlaying
                ? 'Pause deck ${slot.label}'
                : 'Play deck ${slot.label}',
            caption: slot.label,
            onPressed:
                deck.isLoaded ? () => controller.togglePlay(slot) : null,
            isActive: deck.isPlaying,
            background: accent,
            color: accent,
          ),
        ],
      );
    }

    final crossfadeNow = TransportButton(
      icon: Icons.swap_horiz,
      label: 'Crossfade now',
      caption: 'FADE',
      onPressed: (state.deckA.isLoaded || state.deckB.isLoaded)
          ? controller.crossfadeNow
          : null,
      background: scheme.tertiary,
      color: scheme.tertiary,
    );

    // Stop, as distinct from pause: silence now, and the track back at its
    // start for the next play. In the middle with the crossfade, because it
    // belongs to the set rather than to either deck — and in the error colour,
    // because it is the one control here that empties a floor.
    final stop = TransportButton(
      icon: Icons.stop,
      label: 'Stop',
      caption: 'STOP',
      onPressed: state.anyDeckPlaying ? controller.stop : null,
      background: scheme.error,
      color: scheme.error,
    );

    return Semantics(
      container: true,
      label: 'Transport controls',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decide the layout from the room this bar actually got, not from the
          // window: at medium and expanded widths the bar sits in a pane that
          // is a fraction of the screen.
          final useCompact =
              compact || constraints.maxWidth < _barWidth(false);
          final needed = _barWidth(useCompact);
          final fits = constraints.maxWidth >= needed;

          final controls = <Widget>[
            deckGroup(DeckSlot.a, useCompact),
            // Spacer, not Flexible around a button. Flexible would let the
            // framework shrink the crossfade-now target under pressure, which
            // is exactly how it ended up at 37dp — narrower than a fingertip,
            // on the one control that ends a track in front of a room.
            if (fits) const Spacer() else const SizedBox(width: kTransportSpacing),
            stop,
            const SizedBox(width: kTransportSpacing),
            crossfadeNow,
            if (fits) const Spacer() else const SizedBox(width: kTransportSpacing),
            deckGroup(DeckSlot.b, useCompact),
          ];

          final row = Row(
            mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
            children: controls,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: 8,
            ),
            // Below the minimum window size the bar scrolls rather than
            // squeezing. Every control stays a full-size target and stays
            // reachable; nothing is silently clipped.
            child: fits
                ? row
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: row,
                  ),
          );
        },
      ),
    );
  }
}

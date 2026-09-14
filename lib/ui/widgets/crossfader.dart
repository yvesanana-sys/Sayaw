import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The handover lane: what is going out on the left, what is coming in on the
/// right, and a band to move the room from one to the other by hand.
///
/// This used to be a crossfader labelled A and B. The letters were the problem.
/// A DJ knows which deck is live; a dance teacher standing at a laptop for the
/// first time does not, and the same gesture meant opposite things depending
/// on which one it happened to be — drag right to bring in the next song on
/// one transition, drag left on the next. The decks still alternate underneath
/// (see `PlaybackUiState.lanePosition`); the lane does not. Toward the right
/// is always toward the song coming in.
///
/// The whole [kCrossfaderHeight] strip is draggable, not just the thumb. A DJ
/// grabbing this with a thumb in the dark will land somewhere on the band, not
/// on a 14dp circle, and a slider that only responds to a precise hit reads as
/// broken.
class Crossfader extends ConsumerWidget {
  const Crossfader({super.key});

  /// How far one keyboard or screen-reader nudge moves the lane.
  static const double _kStep = 0.1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackProvider.select((s) => s.lanePosition));
    final outDance =
        ref.watch(playbackProvider.select((s) => s.outgoingDance));
    final inDance = ref.watch(playbackProvider.select((s) => s.incomingDance));
    // Fixed, now that the panels are positioned by role too: lavender is
    // always what the floor has and mint is always what is coming, on the lane
    // and on the cards at either end of it. Colour that changed meaning every
    // other transition taught nothing; this teaches one thing once.
    const outColour = SayawColors.primary;
    const inColour = SayawColors.secondary;

    // Two forms of each end. The band is labelled in the shortest thing that
    // is true — "SALSA OUT" — and everything spoken aloud uses a name that
    // still reads inside a sentence.
    final outLabel = outDance == null ? 'NOTHING PLAYING' : '$outDance OUT';
    final inLabel = inDance == null ? 'NOTHING CUED' : '$inDance IN';
    final outgoing = outDance ?? 'the song playing';
    final incoming = inDance ?? 'the next song';
    final controller = ref.read(playbackProvider.notifier);

    return Semantics(
      container: true,
      slider: true,
      label: 'Handover from $outgoing to $incoming',
      value: _describe(position, outgoing, incoming),
      // Keyboard and screen-reader operation of the lane, which a bare
      // GestureDetector would not provide. `increasedValue` and
      // `decreasedValue` are not optional next to the actions: a node with an
      // increase action and a value but no increased value trips a framework
      // assertion, and ships as a silently broken control in release.
      increasedValue:
          _describe((position + _kStep).clamp(0.0, 1.0), outgoing, incoming),
      decreasedValue:
          _describe((position - _kStep).clamp(0.0, 1.0), outgoing, incoming),
      // Increase is toward the incoming song at every transition, which is the
      // whole point of the lane.
      onIncrease: () => controller.setLanePosition(position + _kStep),
      onDecrease: () => controller.setLanePosition(position - _kStep),
      child: SizedBox(
        height: kCrossfaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EndLabel(
                      outLabel,
                      outColour,
                      active: position < 0.5,
                      align: TextAlign.left,
                    ),
                  ),
                  Expanded(
                    child: _EndLabel(
                      inLabel,
                      inColour,
                      active: position > 0.5,
                      align: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // Lavender behind the thumb is what is still on the floor,
                    // mint ahead of it is what is coming in — the same two
                    // hues those songs wear everywhere else, so the band needs
                    // no legend.
                    activeTrackColor: outColour,
                    inactiveTrackColor: inColour,
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: ExcludeSemantics(
                    child: Slider(
                      value: position,
                      onChanged: controller.setLanePosition,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Said in songs, never in percentages of a deck.
  static String _describe(double p, String outgoing, String incoming) {
    if (p <= 0.02) return outgoing;
    if (p >= 0.98) return incoming;
    if ((p - 0.5).abs() < 0.02) return 'Half way across';
    return p < 0.5
        ? '${((0.5 - p) * 200).round()}% still on $outgoing'
        : '${((p - 0.5) * 200).round()}% across to $incoming';
  }
}

class _EndLabel extends StatelessWidget {
  const _EndLabel(
    this.text,
    this.color, {
    required this.active,
    required this.align,
  });

  final String text;
  final Color color;
  final bool active;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: active ? color : SayawColors.onSurfaceVariant,
      ),
    );
  }
}

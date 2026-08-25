import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The manual crossfader: deck A hard left, deck B hard right.
///
/// The whole [kCrossfaderHeight] strip is draggable, not just the thumb. A DJ
/// grabbing this with a thumb in the dark will land somewhere on the band, not
/// on a 14dp circle, and a slider that only responds to a precise hit reads as
/// broken.
class Crossfader extends ConsumerWidget {
  const Crossfader({super.key});

  /// How far one keyboard or screen-reader nudge moves the fader.
  static const double _kStep = 0.1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(playbackProvider.select((s) => s.crossfader));
    final controller = ref.read(playbackProvider.notifier);

    return Semantics(
      container: true,
      slider: true,
      label: 'Crossfader',
      value: _describe(value),
      // Keyboard and screen-reader operation of the fader, which a bare
      // GestureDetector would not provide. `increasedValue` and
      // `decreasedValue` are not optional next to the actions: a node with an
      // increase action and a value but no increased value trips a framework
      // assertion, and ships as a silently broken control in release.
      increasedValue: _describe((value + _kStep).clamp(0.0, 1.0)),
      decreasedValue: _describe((value - _kStep).clamp(0.0, 1.0)),
      onIncrease: () => controller.setCrossfader(value + _kStep),
      onDecrease: () => controller.setCrossfader(value - _kStep),
      child: SizedBox(
        height: kCrossfaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _EndLabel('A', SayawColors.primary, active: value < 0.5),
                  Text(
                    _describe(value),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SayawColors.onSurfaceVariant,
                    ),
                  ),
                  _EndLabel('B', SayawColors.secondary, active: value > 0.5),
                ],
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // The gradient reads as "A on the left, B on the right"
                    // without needing a legend.
                    activeTrackColor: SayawColors.secondary,
                    inactiveTrackColor: SayawColors.primary,
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: ExcludeSemantics(
                    child: Slider(
                      value: value,
                      onChanged: controller.setCrossfader,
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

  static String _describe(double v) {
    if (v <= 0.02) return 'Deck A';
    if (v >= 0.98) return 'Deck B';
    if ((v - 0.5).abs() < 0.02) return 'Centre';
    return v < 0.5
        ? '${((0.5 - v) * 200).round()}% toward A'
        : '${((v - 0.5) * 200).round()}% toward B';
  }
}

class _EndLabel extends StatelessWidget {
  const _EndLabel(this.text, this.color, {required this.active});

  final String text;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: active ? color : SayawColors.onSurfaceVariant,
      ),
    );
  }
}

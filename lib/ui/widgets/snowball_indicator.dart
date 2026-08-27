import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/set_ordering.dart' show SnowballProgress;
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';

/// How far up a Snowball the set has climbed.
///
/// Two readouts, and they are deliberately different things. The stage is
/// where the set *says* it is; the tempo is what the room is actually hearing.
/// A set that was never put in tempo order shows a stage number climbing and a
/// tempo that is not, which is the one thing worth being able to see at a
/// glance — the alternative is a caller announcing the last stage over music
/// that never got any faster.
class SnowballIndicator extends ConsumerWidget {
  const SnowballIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snowball = ref.watch(snowballProvider);
    if (snowball == null) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      label: _spoken(snowball),
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: SayawColors.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  snowball.isLastStage
                      ? Icons.local_fire_department
                      : Icons.ac_unit,
                  size: 18,
                  color: SayawColors.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stage ${snowball.stage} of ${snowball.stages}',
                  style: const TextStyle(
                    color: SayawColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${snowball.songsIn} of ${snowball.total}',
                    style: const TextStyle(
                      color: SayawColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (snowball.bpm case final bpm?)
                  Text(
                    '${bpm.round()} BPM',
                    style: const TextStyle(
                      color: SayawColors.onSurfaceVariant,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _StageBar(snowball: snowball),
          ],
        ),
      ),
    );
  }

  static String _spoken(SnowballProgress snowball) {
    final tempo =
        snowball.bpm == null ? '' : ', ${snowball.bpm!.round()} beats per minute';
    return 'Snowball stage ${snowball.stage} of ${snowball.stages}. '
        'Song ${snowball.songsIn} of ${snowball.total}$tempo.';
  }
}

/// One block per stage, filled up to where the set has got to.
///
/// Blocks rather than a continuous bar because the number that matters is
/// discrete — a caller works in stages, and reading "somewhere past two
/// thirds" off a smooth bar is not the same as seeing four of five lit.
class _StageBar extends StatelessWidget {
  const _StageBar({required this.snowball});

  final SnowballProgress snowball;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var stage = 1; stage <= snowball.stages; stage++) ...[
            if (stage > 1) const SizedBox(width: 3),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: stage <= snowball.stage
                      ? SayawColors.tertiary
                      : SayawColors.surfaceContainerHigh,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

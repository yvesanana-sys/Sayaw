import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/soundboard.dart';
import '../state/soundboard_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The cut-in soundboard: one button per cue, fired over whatever is playing.
///
/// A strip rather than a dialog, and it never scrolls out of reach — a tag
/// call is a thing that happens *now*, and anything that takes two taps to
/// reach has already missed the moment.
class SoundboardBar extends ConsumerWidget {
  const SoundboardBar({super.key, this.maxHeight});

  /// The most of the column this may take before it scrolls within itself.
  ///
  /// A bar that grew without limit ate the transport under it: with enough
  /// cues the column overflowed the window and everything below the first
  /// rows was clipped — which read as the bar stopping at two. Null is
  /// unbounded, for a test that only wants to see it grow.
  final double? maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A cut-in that made no noise is the one thing here the operator cannot
    // work out for themselves: they pressed a button in front of a room and
    // heard nothing, and need to know it was the file rather than their
    // timing.
    ref.listen(soundboardFailureProvider, (_, next) {
      final label = next.value;
      if (label == null) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('$label did not play — is the file still there?')),
      );
    });

    final cues = ref.watch(soundCuesProvider).value ?? const <SoundCue>[];
    if (cues.isEmpty) return const SizedBox.shrink();

    final soundboard = ref.watch(soundboardProvider);

    // Every cue on screen at once, in as many rows as it takes. A strip that
    // scrolled sideways hid the sixth cue and every one after it, and a
    // cut-in that has to be scrolled to has already missed its moment.
    final wrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < cues.length; index++)
          _CueButton(
            cue: cues[index],
            // The shortcut the operator can actually press. Only the first
            // nine get one — there is no tenth digit, and a two-key chord
            // in the dark is not a cut-in.
            shortcut: index < 9 ? '${index + 1}' : null,
            onPressed: soundboard == null
                ? null
                : () => soundboard.fire(cues[index]),
          ),
      ],
    );

    return Container(
      width: double.infinity,
      color: SayawColors.surface,
      constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
      child: SingleChildScrollView(
        // Vertical, and only once the ceiling is reached: below it the bar
        // simply is as tall as its rows.
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: wrap,
      ),
    );
  }
}

class _CueButton extends StatelessWidget {
  const _CueButton({required this.cue, this.shortcut, this.onPressed});

  final SoundCue cue;
  final String? shortcut;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: shortcut == null
          ? 'Play ${cue.label}'
          : 'Play ${cue.label}, shortcut $shortcut',
      excludeSemantics: true,
      child: SizedBox(
        height: kMinTouchTarget,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: SayawColors.surfaceContainerHigh,
            foregroundColor: SayawColors.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                // A cue that dips the music is a spoken one; a cue that does
                // not is a whistle. Worth telling apart at a glance, because
                // only one of them will talk over the vocals.
                cue.ducks ? Icons.campaign : Icons.notifications_active,
                size: 18,
                color: SayawColors.tertiary,
              ),
              const SizedBox(width: 8),
              Text(cue.label),
              if (shortcut case final shortcut?) ...[
                const SizedBox(width: 8),
                Text(
                  shortcut,
                  style: const TextStyle(
                    color: SayawColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

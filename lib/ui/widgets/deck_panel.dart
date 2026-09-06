import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format/track_title.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';

/// What is loaded on one deck, how far through it is, and how loud it is.
///
/// Read-only. Every control lives in the transport bar so there is exactly one
/// place to reach for, which is what makes the compact and expanded layouts
/// feel like the same app.
class DeckPanel extends ConsumerWidget {
  const DeckPanel({super.key, required this.slot});

  final DeckSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(playbackProvider.select((s) => s.deck(slot)));
    final title = deck.isLoaded ? displayTitle(deck.title) : '';
    final accent =
        slot == DeckSlot.a ? SayawColors.primary : SayawColors.secondary;

    return Semantics(
      container: true,
      label: deck.isLoaded
          ? 'Deck ${slot.label}: $title by ${deck.artist}, '
              '${_clock(deck.position)} of ${_clock(deck.duration)}'
          : 'Deck ${slot.label}: empty',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SayawColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: deck.isPlaying ? accent : SayawColors.outlineVariant,
              width: deck.isPlaying ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot.label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_clock(deck.position)} / ${_clock(deck.duration)}',
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: SayawColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                deck.isLoaded ? title : 'Empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: deck.isLoaded
                      ? SayawColors.onSurface
                      : SayawColors.onSurfaceVariant,
                ),
              ),
              Text(
                deck.isLoaded ? deck.artist : 'Load a track to begin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: SayawColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deck.progress,
                  minHeight: 6,
                  backgroundColor: SayawColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 10),
              _GainMeter(gain: deck.gain, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  static String _clock(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Composed output level — `crossfade x duck x trim x master`, the same product
/// the engine writes to the deck. Showing it means a DJ can see *why* a deck is
/// quiet rather than guessing which stage pulled it down.
class _GainMeter extends StatelessWidget {
  const _GainMeter({required this.gain, required this.color});

  final double gain;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.graphic_eq, size: 14, color: SayawColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: gain.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: SayawColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/breakpoints.dart';
import '../state/playback_ui_state.dart';
import '../state/transition_sentence.dart';
import '../theme/sayaw_theme.dart';

/// What happens next, in one sentence, drawn between the two decks.
///
/// Sits where the announcement is heard: between the deck going out and the
/// deck coming in, on the blend it rides over. An announcement belongs to the
/// row being faded *to*, and nothing on screen used to say so — an operator
/// who tagged the song already playing and then pressed crossfade got silence,
/// which looks exactly like a tag that did not work.
///
/// It used to state a label and a timing fragment. It now states the event,
/// the delay, and the exact words the room will hear, because that is the
/// question an operator actually has and the one thing they cannot work out by
/// watching the floor.
///
/// Keeps its height whatever it says. The decks must not move under a hand
/// reaching for them because the next row happens to be untagged.
class AnnouncerStrip extends ConsumerWidget {
  const AnnouncerStrip({super.key});

  /// Tall enough for two lines of the sentence at a readable size, and the
  /// same whether or not there is anything to say.
  ///
  /// One step smaller in compact, where the whole column is a scroll and every
  /// dp this takes is a dp of the controls below it — the same step the design
  /// takes with its own type at that width. The rule this must not break is
  /// that the height never moves with *content*; moving with the window is
  /// fine, because the window is not something a reaching hand changes.
  static const double height = 92.0;
  static const double compactHeight = 84.0;

  static double heightFor(SayawBreakpoint breakpoint) =>
      breakpoint.isCompact ? compactHeight : height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentence = ref.watch(transitionSentenceProvider);
    final announcement = ref.watch(nextAnnouncementProvider);
    final breakpoint = SayawLayout.of(context);
    final compact = breakpoint.isCompact;

    // Amber is the voice throughout the app, so the card only wears it when
    // there is actually a voice in the transition. A blend with nothing said
    // is ordinary, not noteworthy, and must not compete with one that speaks.
    final speaks = announcement != null;

    return Semantics(
      container: true,
      label: 'What happens next. ${sentence.text}',
      child: ExcludeSemantics(
        child: Container(
          height: heightFor(breakpoint),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: speaks
                ? SayawColors.tertiary.withValues(alpha: 0.10)
                : SayawColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: speaks
                  ? SayawColors.tertiary.withValues(alpha: 0.55)
                  : SayawColors.outlineVariant,
              width: speaks ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Label(speaks: speaks, isRecording: announcement?.isRecording),
              const SizedBox(height: 6),
              Expanded(child: _Sentence(sentence, compact: compact)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.speaks, required this.isRecording});

  final bool speaks;
  final bool? isRecording;

  @override
  Widget build(BuildContext context) {
    final colour =
        speaks ? SayawColors.tertiary : SayawColors.onSurfaceVariant;

    return Row(
      children: [
        // Filled for the operator's own recording, outlined for a synthesised
        // voice — the same distinction the soundboard bar draws, and worth
        // knowing at a glance because only one of them is in their voice.
        Icon(
          !speaks
              ? Icons.campaign_outlined
              : isRecording == true
                  ? Icons.campaign
                  : Icons.record_voice_over,
          size: 16,
          color: colour,
        ),
        const SizedBox(width: 8),
        Text(
          'WHAT HAPPENS NEXT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: colour,
          ),
        ),
      ],
    );
  }
}

/// The sentence itself, with the incoming dance and the spoken words picked
/// out in the colours they carry everywhere else in the app.
class _Sentence extends StatelessWidget {
  const _Sentence(this.sentence, {required this.compact});

  final TransitionSentence sentence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: compact ? 15 : 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: SayawColors.onSurface,
          ),
          children: [
            for (final span in sentence.spans)
              TextSpan(
                text: span.text,
                style: TextStyle(color: _colourFor(span.tone)),
              ),
          ],
        ),
      ),
    );
  }

  static Color _colourFor(SentenceTone tone) => switch (tone) {
        SentenceTone.plain => SayawColors.onSurface,
        // The same mint as the deck coming in.
        SentenceTone.dance => SayawColors.secondary,
        // The same amber as every other voice affordance.
        SentenceTone.voice => SayawColors.tertiary,
      };
}

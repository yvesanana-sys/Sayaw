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

  /// Finds the sentence itself, past the label above it and the cause below.
  static const sentenceKey = Key('announcer-sentence');

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
    // Red takes the same box at the same height, so a failure never moves what
    // is under a reaching hand — it only changes what that box says.
    final trouble = sentence.isTrouble;

    return Semantics(
      container: true,
      label: 'What happens next. ${sentence.text}'
          '${sentence.cause == null ? '' : ' ${sentence.cause}'}',
      child: ExcludeSemantics(
        child: Container(
          height: heightFor(breakpoint),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: trouble
                ? SayawColors.error.withValues(alpha: 0.12)
                : speaks
                    ? SayawColors.tertiary.withValues(alpha: 0.10)
                    : SayawColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: trouble
                  ? SayawColors.error
                  : speaks
                      ? SayawColors.tertiary.withValues(alpha: 0.55)
                      : SayawColors.outlineVariant,
              width: speaks || trouble ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Label(
                speaks: speaks,
                trouble: trouble,
                isRecording: announcement?.isRecording,
              ),
              const SizedBox(height: 6),
              Expanded(child: _Sentence(sentence, compact: compact)),
              // The fixable thing, under the sentence that reports it. A
              // failure that says only "no voice" sends the operator looking;
              // this says where to look.
              if (sentence.cause case final cause?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    cause,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SayawColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.speaks,
    required this.trouble,
    required this.isRecording,
  });

  final bool speaks;
  final bool trouble;
  final bool? isRecording;

  @override
  Widget build(BuildContext context) {
    final colour = trouble
        ? SayawColors.error
        : speaks
            ? SayawColors.tertiary
            : SayawColors.onSurfaceVariant;

    return Row(
      children: [
        // Filled for the operator's own recording, outlined for a synthesised
        // voice — the same distinction the soundboard bar draws, and worth
        // knowing at a glance because only one of them is in their voice.
        Icon(
          trouble
              ? Icons.warning_amber_rounded
              : !speaks
                  ? Icons.campaign_outlined
                  : isRecording == true
                      ? Icons.campaign
                      : Icons.record_voice_over,
          size: 16,
          color: colour,
        ),
        const SizedBox(width: 8),
        Text(
          trouble ? 'WHAT HAPPENS NEXT — NEEDS YOU' : 'WHAT HAPPENS NEXT',
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
        key: AnnouncerStrip.sentenceKey,
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
        SentenceTone.trouble => SayawColors.error,
      };
}

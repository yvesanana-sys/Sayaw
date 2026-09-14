import 'package:flutter/foundation.dart';

import 'playback_ui_state.dart' show AnnouncementTiming, NextAnnouncementUi;

/// How a run of words in the sentence is coloured.
///
/// Roles rather than colours: this file has no opinion about the palette, and
/// the widget that draws it has no opinion about the wording. That split is
/// the reason the sentence can be asserted without pumping a widget tree.
enum SentenceTone {
  /// Ordinary words.
  plain,

  /// The dance coming in — mint, the same hue as the incoming deck.
  dance,

  /// What the room will actually hear — amber, the voice colour.
  voice,
}

@immutable
class SentenceSpan {
  const SentenceSpan(this.text, [this.tone = SentenceTone.plain]);

  final String text;
  final SentenceTone tone;

  @override
  bool operator ==(Object other) =>
      other is SentenceSpan && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);

  @override
  String toString() => '${tone.name}("$text")';
}

/// The one sentence that says what happens next and when.
///
/// The most valuable thing on the screen for an operator who has not run a
/// night before: it states the event, the delay, and the exact words the room
/// will hear. Everything else on the deck screen can be worked out by watching
/// the floor; this cannot.
@immutable
class TransitionSentence {
  const TransitionSentence(this.spans);

  final List<SentenceSpan> spans;

  /// The whole thing as plain text — what a screen reader says, and what a
  /// test asserts.
  String get text => spans.map((s) => s.text).join();

  /// Whether anything is actually coming. False is not an error: it is the end
  /// of the set, and the card says so rather than going blank.
  bool get hasNext => spans.length > 1;

  @override
  String toString() => text;
}

/// Turns the state of the next transition into that sentence.
///
/// Pure, and deliberately so. The wording is the part of this screen most
/// likely to be argued over and revised, and keeping it out of the widget
/// means every revision is one assertion rather than a pumped frame and a
/// regenerated golden.
///
/// [until] is how long is left on the song now playing. Null when nothing is
/// playing or the length is unknown, in which case the sentence simply drops
/// its opening clause rather than inventing a number.
TransitionSentence composeTransitionSentence({
  required NextAnnouncementUi? announcement,
  required bool merges,
  required String? incomingDance,
  required Duration? until,
}) {
  // Nothing cued. Said plainly, because an empty card and a card that has not
  // loaded yet look identical, and only one of them means the music is about
  // to stop.
  if (announcement == null && !merges && incomingDance == null) {
    return const TransitionSentence([SentenceSpan('Nothing after this song.')]);
  }

  final spans = <SentenceSpan>[];

  final lead = _lead(until);
  if (lead != null) spans.add(SentenceSpan(lead));

  final dance = incomingDance == null || incomingDance.isEmpty
      ? const SentenceSpan('the next song', SentenceTone.dance)
      : SentenceSpan(incomingDance, SentenceTone.dance);

  // A merge is one dance continuing across two files. It has no voice by
  // definition, so it never reaches the announcement branches below.
  if (merges) {
    spans
      ..add(SentenceSpan(lead == null ? 'The music runs on into ' : 'the music runs on into '))
      ..add(dance)
      ..add(const SentenceSpan(', still the same dance.'));
    return TransitionSentence(spans);
  }

  if (announcement == null) {
    spans
      ..add(SentenceSpan(lead == null ? 'The music blends into ' : 'the music blends into '))
      ..add(dance)
      ..add(const SentenceSpan(', with nothing said.'));
    return TransitionSentence(spans);
  }

  // Their own recording is worth naming as theirs: it is the one case where
  // the operator already knows exactly what it sounds like.
  final saying = announcement.isRecording
      ? [
          const SentenceSpan(' and the room hears your recording '),
          SentenceSpan('“${announcement.label}”', SentenceTone.voice),
        ]
      : [
          const SentenceSpan(' and the room hears '),
          SentenceSpan('“${announcement.label}”', SentenceTone.voice),
        ];

  switch (announcement.timing) {
    // The music dips underneath the voice and keeps going.
    case AnnouncementTiming.overTheCrossfade:
      spans
        ..add(SentenceSpan(
            lead == null ? 'The music blends into ' : 'the music blends into '))
        ..add(dance)
        ..addAll(saying)
        ..add(const SentenceSpan('.'));

    // Silence, then the voice alone, then the song.
    case AnnouncementTiming.beforeTheMusic:
      spans
        ..add(SentenceSpan(lead == null ? 'The music stops' : 'the music stops'))
        ..addAll(saying)
        ..add(const SentenceSpan(' in the quiet, then '))
        ..add(dance)
        ..add(const SentenceSpan(' starts.'));

    // The gap a floor changes partners in.
    case AnnouncementTiming.inTheRotationGap:
      spans
        ..add(SentenceSpan(lead == null ? 'The music stops' : 'the music stops'))
        ..addAll(saying)
        ..add(const SentenceSpan(' in the gap, then '))
        ..add(dance)
        ..add(const SentenceSpan(' starts.'));
  }

  return TransitionSentence(spans);
}

/// The opening clause — "In 40 seconds, ".
///
/// Null when there is no length to count down from, so the sentence starts at
/// its verb instead of announcing a delay nobody can verify.
String? _lead(Duration? until) {
  if (until == null) return null;

  final seconds = until.inSeconds;
  if (seconds <= 0) return 'Any moment now, ';
  if (seconds == 1) return 'In 1 second, ';
  if (seconds < 90) return 'In $seconds seconds, ';

  // Past a minute and a half the exact second stops being useful and starts
  // being a distraction — the operator wants to know they have time, not how
  // much of it to the second.
  final minutes = (seconds / 60).round();
  return 'In $minutes minutes, ';
}

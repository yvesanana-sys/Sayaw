import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/state/transition_sentence.dart';

NextAnnouncementUi _spoken(
  String label, {
  AnnouncementTiming timing = AnnouncementTiming.overTheCrossfade,
  String? dance,
}) =>
    NextAnnouncementUi(
      label: label,
      isRecording: false,
      timing: timing,
      danceType: dance,
    );

String _say({
  NextAnnouncementUi? announcement,
  bool merges = false,
  String? dance,
  Duration? until,
}) =>
    composeTransitionSentence(
      announcement: announcement,
      merges: merges,
      incomingDance: dance,
      until: until,
    ).text;

void main() {
  group('the sentence the operator reads', () {
    test('states the delay, the dance and the words', () {
      // The whole point of the card: an operator who has never run a night
      // should need no more than this line.
      expect(
        _say(
          announcement: _spoken('Next dance: Bachata'),
          dance: 'Bachata',
          until: const Duration(seconds: 40),
        ),
        'In 40 seconds, the music blends into Bachata '
        'and the room hears “Next dance: Bachata”.',
      );
    });

    test('an announcement before the music describes the quiet', () {
      expect(
        _say(
          announcement: _spoken('Next dance: Waltz',
              timing: AnnouncementTiming.beforeTheMusic),
          dance: 'Waltz',
          until: const Duration(seconds: 12),
        ),
        'In 12 seconds, the music stops and the room hears '
        '“Next dance: Waltz” in the quiet, then Waltz starts.',
      );
    });

    test('a rotation gap is named as the gap it is', () {
      expect(
        _say(
          announcement: _spoken('Change partners',
              timing: AnnouncementTiming.inTheRotationGap),
          dance: 'Salsa',
          until: const Duration(seconds: 8),
        ),
        contains('in the gap, then Salsa starts.'),
      );
    });

    test("their own recording is named as theirs", () {
      // The one case where the operator already knows what it sounds like.
      final sentence = composeTransitionSentence(
        announcement: const NextAnnouncementUi(
          label: 'Ladies’ choice',
          isRecording: true,
          timing: AnnouncementTiming.overTheCrossfade,
        ),
        merges: false,
        incomingDance: 'Bachata',
        until: const Duration(seconds: 20),
      );

      expect(sentence.text, contains('your recording'));
      expect(sentence.text, contains('Ladies’ choice'));
    });
  });

  group('when there is nothing to say', () {
    test('the end of the set says so, rather than going blank', () {
      // A blank card and a card that has not loaded look identical, and only
      // one of them means the music is about to stop.
      expect(_say(), 'Nothing after this song.');
      expect(
        composeTransitionSentence(
          announcement: null,
          merges: false,
          incomingDance: null,
          until: null,
        ).hasNext,
        isFalse,
      );
    });

    test('a blend with no announcement still says what happens', () {
      expect(
        _say(dance: 'Cha-Cha', until: const Duration(seconds: 30)),
        'In 30 seconds, the music blends into Cha-Cha, with nothing said.',
      );
    });

    test('a merge reads as one dance continuing, not as a failed tag', () {
      expect(
        _say(merges: true, dance: 'Salsa', until: const Duration(seconds: 15)),
        'In 15 seconds, the music runs on into Salsa, still the same dance.',
      );
    });

    test('an untagged row falls back to the song, never to a file name', () {
      expect(
        _say(
            announcement: _spoken('Next dance'),
            until: const Duration(seconds: 5)),
        contains('blends into the next song'),
      );
    });
  });

  group('the countdown', () {
    test('reads in seconds, singular at one', () {
      expect(_say(dance: 'Swing', until: const Duration(seconds: 1)),
          startsWith('In 1 second, '));
      expect(_say(dance: 'Swing', until: const Duration(seconds: 2)),
          startsWith('In 2 seconds, '));
    });

    test('zero and past-zero read as imminent, never as negative', () {
      for (final d in [Duration.zero, const Duration(seconds: -3)]) {
        expect(_say(dance: 'Swing', until: d), startsWith('Any moment now, '));
      }
    });

    test('past a minute and a half it stops counting seconds', () {
      // The operator wants to know they have time, not how much to the second.
      expect(_say(dance: 'Swing', until: const Duration(seconds: 200)),
          startsWith('In 3 minutes, '));
    });

    test('an unknown length drops the clause rather than inventing a number',
        () {
      final text = _say(dance: 'Swing', until: null);
      expect(text, startsWith('The music blends into Swing'));
      expect(text, isNot(contains('In ')));
    });
  });

  group('what gets coloured', () {
    test('the dance and the spoken words carry their own tones', () {
      final sentence = composeTransitionSentence(
        announcement: _spoken('Next dance: Bachata'),
        merges: false,
        incomingDance: 'Bachata',
        until: const Duration(seconds: 40),
      );

      expect(
        sentence.spans.where((s) => s.tone == SentenceTone.dance).single.text,
        'Bachata',
      );
      expect(
        sentence.spans.where((s) => s.tone == SentenceTone.voice).single.text,
        '“Next dance: Bachata”',
      );
    });

    test('the plain text is exactly the spans joined', () {
      final sentence = composeTransitionSentence(
        announcement: _spoken('Next dance: Tango'),
        merges: false,
        incomingDance: 'Tango',
        until: const Duration(seconds: 9),
      );
      expect(sentence.text, sentence.spans.map((s) => s.text).join());
    });
  });
}

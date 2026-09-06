import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/format/track_title.dart';

void main() {
  group('displayTitle', () {
    test('strips a two-part set-order prefix and underscores', () {
      expect(
        displayTitle('00_00_Intro_(A_Starting_Pre_Party_Music)'),
        'Intro (A Starting Pre Party Music)',
      );
    });

    test('strips a trailing trimmed marker', () {
      expect(
        displayTitle('00_01_(Cha_Cha)_Aqua de Beber (31 BPM)_(trimmed+)'),
        '(Cha Cha) Aqua de Beber (31 BPM)',
      );
    });

    test('copes with a bare single-number prefix followed by a space', () {
      expect(displayTitle('01_ Intro_(Waltz)'), 'Intro (Waltz)');
    });

    test('leaves a tagged title untouched', () {
      expect(displayTitle('Fields Of Gold'), 'Fields Of Gold');
    });

    test('never returns an empty string', () {
      expect(displayTitle('00_00_'), '00_00_');
    });
  });
}

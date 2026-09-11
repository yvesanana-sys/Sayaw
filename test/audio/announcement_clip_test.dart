import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';

import '../fakes/fake_deck.dart';

/// A deck that loads a file and will not say how long it is — which is what
/// libmpv does for the moment after a load, and what made every announcement
/// on the desktop backend silent.
class _LengthlessDeck extends FakeDeck {
  _LengthlessDeck() : super('voice');

  @override
  Duration? get duration => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reading a clip the operator recorded', () {
    test('a length the backend will not report is assumed, not fatal', () async {
      final factory = PlatformClipFactory(
        deck: _LengthlessDeck(),
        cacheDirectory: '/tmp/sayaw-test',
        settings: const TtsVoiceSettings(),
      );

      final clip = await factory.probe('/clips/partners.wav', text: 'Waltz');

      // Announcing on a guessed envelope is a small error. Announcing nothing
      // is a silent one, and it is the failure this path exists to prevent.
      expect(clip, isNotNull);
      expect(clip!.duration, PlatformClipFactory.assumedLength);
      expect(clip.filePath, '/clips/partners.wav');
    });

    test('a length of zero is a length not yet known, not a clip of nothing',
        () async {
      // libmpv reports zero on open, before it has parsed the file. Timed at
      // zero, an announcement is played and stopped in the same instant.
      final deck = FakeDeck('voice', trackDuration: Duration.zero);
      final factory = PlatformClipFactory(
        deck: deck,
        cacheDirectory: '/tmp/sayaw-test',
        settings: const TtsVoiceSettings(),
      );

      final clip = await factory.probe('/clips/partners.wav', text: 'Waltz');

      expect(clip!.duration, PlatformClipFactory.assumedLength);
    });

    test('a length the backend does report is used as is', () async {
      final deck = FakeDeck('voice', trackDuration: const Duration(seconds: 4));
      final factory = PlatformClipFactory(
        deck: deck,
        cacheDirectory: '/tmp/sayaw-test',
        settings: const TtsVoiceSettings(),
      );

      final clip = await factory.probe('/clips/partners.wav', text: 'Waltz');

      expect(clip!.duration, const Duration(seconds: 4));
    });

    test('a file that will not load answers rather than throwing', () async {
      // Called on the path of a transition that is already running: an
      // exception here stops the set in the middle of a crossfade.
      final deck = FakeDeck('voice')..failUris.add('file:///clips/moved.wav');
      final factory = PlatformClipFactory(
        deck: deck,
        cacheDirectory: '/tmp/sayaw-test',
        settings: const TtsVoiceSettings(),
      );

      expect(await factory.probe('/clips/moved.wav', text: 'Waltz'), isNull);
    });
  });
}

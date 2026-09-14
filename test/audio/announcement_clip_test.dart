import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/crossfade_engine.dart';
import 'package:sayaw/audio/deck.dart';

import '../fakes/fake_clip_factory.dart';
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

  _readinessTests();

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

/// A factory that cannot speak and says why — a Linux box with no espeak-ng,
/// which is the one real cause of a silent synthesised announcement.
class _MuteFactory extends FakeClipFactory {
  _MuteFactory() {
    failRender = true;
  }

  @override
  Future<String?> describeUnavailable() async =>
      'No speech synthesiser is installed.';
}

QueueEntry _row(String id, {String? dance, AnnounceMode mode = AnnounceMode.duckOver}) =>
    QueueEntry(
      itemId: id,
      media: PlayableMedia(uri: Uri.parse('fake://$id')),
      spec: TransitionSpec(announceMode: mode),
      danceTypeName: dance,
    );

void _readinessTests() {
  group('knowing before the room does', () {
    late AnnouncementEngine engine;
    late _MuteFactory mute;

    setUp(() {
      mute = _MuteFactory();
      engine = AnnouncementEngine(
        voiceDeck: FakeDeck('voice'),
        cacheDirectory: '/tmp/sayaw-test',
        settings: const TtsVoiceSettings(),
        clipFactory: mute,
      );
    });

    test('a row that will not speak is not a failure', () async {
      // No dance, no text: it was never going to say anything, and calling
      // that broken would cry wolf on most of a social set.
      await engine.warm(_row('quiet'));
      expect(engine.statusFor('quiet').readiness, AnnouncementReadiness.silent);
      expect(engine.statusFor('quiet').isFailure, isFalse);
    });

    test('a row set to say nothing is silent, not failed', () async {
      await engine.warm(_row('off', dance: 'Salsa', mode: AnnounceMode.off));
      expect(engine.statusFor('off').readiness, AnnouncementReadiness.silent);
    });

    test('a row that should speak and cannot says so, with the cause',
        () async {
      await engine.warm(_row('bachata', dance: 'Bachata'));

      final status = engine.statusFor('bachata');
      expect(status.isFailure, isTrue);
      expect(status.reason, 'No speech synthesiser is installed.');
    });

    test('a row that renders is ready', () async {
      mute.failRender = false;
      await engine.warm(_row('waltz', dance: 'Waltz'));
      expect(engine.statusFor('waltz').readiness, AnnouncementReadiness.ready);
    });

    test('a row nothing has looked at yet is unknown, not broken', () async {
      // Warming has not run. Drawing that as a failure would light the card up
      // red for every set the moment it opens.
      expect(engine.statusFor('never-seen').readiness,
          AnnouncementReadiness.unknown);
      expect(engine.statusFor('never-seen').isFailure, isFalse);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/system_voice.dart';

import '../fakes/fake_deck.dart';

/// A synthesiser that writes a file without going near a real TTS engine.
class _FakeVoice implements SystemVoice {
  _FakeVoice({this.succeeds = true, this.missing});

  bool succeeds;
  String? missing;

  final List<String> spoken = [];
  TtsVoiceSettings? lastSettings;

  @override
  Future<bool> synthesize({
    required String text,
    required String outPath,
    required TtsVoiceSettings settings,
  }) async {
    spoken.add(text);
    lastSettings = settings;
    if (!succeeds) return false;
    await File(outPath).writeAsString('not really a wav');
    return true;
  }

  @override
  Future<String?> describeMissing() async => missing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('sayaw-voice-test');
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  group('rendering an announcement on the desktop', () {
    test('speaks the text and answers a clip', () async {
      // The bug this covers: the desktop branch used to call a MethodChannel
      // that nothing implemented, so every synthesised announcement threw
      // MissingPluginException, was swallowed, and the transition ran silent.
      final voice = _FakeVoice();
      final factory = PlatformClipFactory(
        deck: FakeDeck('voice', trackDuration: const Duration(seconds: 2)),
        cacheDirectory: cache.path,
        settings: const TtsVoiceSettings(),
        voice: voice,
      );

      final clip = await factory.render('Next dance: Bachata', 'abc123');

      expect(voice.spoken, ['Next dance: Bachata']);
      expect(clip, isNotNull);
      expect(clip!.duration, const Duration(seconds: 2));
      expect(File(clip.filePath).existsSync(), isTrue);
    });

    test('a synthesiser that will not speak costs the voice, not the set',
        () async {
      final factory = PlatformClipFactory(
        deck: FakeDeck('voice'),
        cacheDirectory: cache.path,
        settings: const TtsVoiceSettings(),
        voice: _FakeVoice(succeeds: false, missing: 'no espeak here'),
      );

      // Null rather than a throw: this is reached from inside a transition
      // that has already begun.
      expect(await factory.render('Next dance: Waltz', 'def456'), isNull);
    });

    test('the voice settings reach the synthesiser', () async {
      final voice = _FakeVoice();
      final factory = PlatformClipFactory(
        deck: FakeDeck('voice'),
        cacheDirectory: cache.path,
        settings: const TtsVoiceSettings(rate: 0.7, pitch: 1.2, voiceId: 'Anna'),
        voice: voice,
      );

      await factory.render('Next dance: Salsa', 'ghi789');

      expect(voice.lastSettings!.rate, 0.7);
      expect(voice.lastSettings!.pitch, 1.2);
      expect(voice.lastSettings!.voiceId, 'Anna');
    });

    test('the cache directory is created if it is not there', () async {
      final nested = '${cache.path}/announcements/v1';
      final factory = PlatformClipFactory(
        deck: FakeDeck('voice'),
        cacheDirectory: nested,
        settings: const TtsVoiceSettings(),
        voice: _FakeVoice(),
      );

      expect(await factory.render('Next dance: Tango', 'jkl012'), isNotNull);
      expect(Directory(nested).existsSync(), isTrue);
    });
  });

  group('rate mapping', () {
    test('the default rate is ordinary speaking speed', () {
      // 0.5 is the midpoint of the app's scale, and normal speech is ~175 wpm.
      expect(wordsPerMinute(0.5), 175);
    });

    test('slower and faster move in the right direction', () {
      expect(wordsPerMinute(0.0), lessThan(wordsPerMinute(0.5)));
      expect(wordsPerMinute(1.0), greaterThan(wordsPerMinute(0.5)));
    });

    test('a nonsense rate still lands somewhere sayable', () {
      expect(wordsPerMinute(-5), inInclusiveRange(80, 450));
      expect(wordsPerMinute(99), inInclusiveRange(80, 450));
    });
  });

  group('the synthesiser for this platform', () {
    test('is the one that matches the host', () {
      final voice = SystemVoice.platform();
      if (Platform.isWindows) {
        expect(voice, isA<WindowsSapiVoice>());
      } else if (Platform.isMacOS) {
        expect(voice, isA<MacSayVoice>());
      } else {
        expect(voice, isA<LinuxEspeakVoice>());
      }
    });

    test('says what is missing rather than going quietly silent', () async {
      // On a box with no synthesiser this is the only thing standing between
      // the operator and a night of announcements that never play.
      final missing = await LinuxEspeakVoice().describeMissing();
      if (missing != null) expect(missing, contains('espeak-ng'));
    });
  });
}

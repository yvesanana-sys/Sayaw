import 'package:sayaw/audio/announcement_engine.dart';

/// A [ClipFactory] that mints clips of a known duration out of nothing.
///
/// No TTS engine, no audio backend, no filesystem. Announcement timing is
/// derived entirely from `clip.duration`, so supplying that directly is enough
/// to assert every duck envelope the engine produces.
class FakeClipFactory implements ClipFactory {
  FakeClipFactory({this.clipDuration = const Duration(seconds: 2)});

  /// Duration reported for every clip this factory produces.
  Duration clipDuration;

  /// Text passed to [render], in order — lets a test assert that a playlist of
  /// forty Cha-Chas synthesises "Cha-Cha" exactly once.
  final List<String> rendered = [];

  /// Paths handed to [probe], in order.
  final List<String> probed = [];

  /// Set to make every render fail, as a mute TTS engine would.
  bool failRender = false;

  @override
  bool exists(String path) => true;

  @override
  Future<AnnouncementClip?> render(String text, String hash) async {
    rendered.add(text);
    if (failRender) return null;
    return AnnouncementClip(
      hash: hash,
      filePath: '/fake/$hash.wav',
      duration: clipDuration,
      text: text,
    );
  }

  @override
  Future<AnnouncementClip?> probe(String path,
      {required String text, String? hash}) async {
    probed.add(path);
    return AnnouncementClip(
      hash: hash ?? 'fake-$path',
      filePath: path,
      duration: clipDuration,
      text: text,
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'announcement_engine.dart' show TtsVoiceSettings;

/// Synthesises speech to a WAV file using the synthesiser already built into
/// the operating system.
///
/// This exists because the desktop platforms have no usable Flutter TTS plugin
/// that will render *to a file*. `flutter_tts` speaks aloud on Windows but its
/// `synthesizeToFile` is not dependable there, and on Linux it has no
/// implementation at all. Sayaw needs a file rather than live speech — the
/// whole duck envelope is timed from the clip's known duration — so the
/// remaining option is the synthesiser every one of these machines already
/// ships with:
///
///   * Windows — `System.Speech` (SAPI), driven through PowerShell.
///   * macOS   — `say`, which writes audio files natively.
///   * Linux   — `espeak-ng`, or `espeak` where that is what is installed.
///
/// Shelling out looks crude next to a platform channel. It is also the only
/// version of this that ships without a C++ and a Swift implementation to
/// maintain, and every binary it reaches for is present by default on its
/// platform — except on Linux, where [describeMissing] says what to install
/// rather than leaving the operator with silence and no explanation.
abstract class SystemVoice {
  /// The synthesiser for the platform this build is running on.
  factory SystemVoice.platform() {
    if (Platform.isWindows) return WindowsSapiVoice();
    if (Platform.isMacOS) return MacSayVoice();
    return LinuxEspeakVoice();
  }

  /// Renders [text] to a WAV file at [outPath].
  ///
  /// Returns true only if the file is actually there afterwards. A synthesiser
  /// that exits zero without writing anything is a failure like any other, and
  /// the caller cannot tell the difference from the exit code alone.
  Future<bool> synthesize({
    required String text,
    required String outPath,
    required TtsVoiceSettings settings,
  });

  /// Why this platform cannot speak, phrased so the operator can fix it, or
  /// null when nothing is missing.
  ///
  /// A missing synthesiser costs every announcement of the night, and the
  /// symptom — a transition that simply runs without a voice — looks identical
  /// to a row nobody tagged. Something has to say which it is.
  Future<String?> describeMissing();
}

/// Shared plumbing: run a process, decide whether it produced a file.
abstract class _ProcessVoice implements SystemVoice {
  /// Runs [executable] with [arguments], never through a shell.
  ///
  /// No shell means no quoting rules, which means announcement text cannot
  /// escape into a command line however it is punctuated. Text still travels
  /// via a file rather than an argument — see [writeTextFile] — but this is the
  /// layer that makes the paths safe too.
  Future<bool> run(String executable, List<String> arguments,
      {required String outPath}) async {
    try {
      final result = await Process.run(executable, arguments);
      if (result.exitCode != 0) {
        debugPrint(
          'sayaw: $executable exited ${result.exitCode}: ${result.stderr}',
        );
        return false;
      }
    } on ProcessException catch (e) {
      debugPrint('sayaw: cannot run $executable — ${e.message}');
      return false;
    }
    return File(outPath).existsSync();
  }

  /// Writes [text] beside its output file for the synthesiser to read.
  ///
  /// Every one of these tools can take its input from a file, and that is the
  /// reason to use it: an apostrophe in "Ladies' choice" is a quoting bug
  /// waiting for a Saturday night, and text that never touches a command line
  /// cannot cause one.
  Future<String> writeTextFile(String outPath, String text) async {
    final path = '$outPath.txt';
    await File(path).writeAsString(text, encoding: utf8);
    return path;
  }

  Future<void> cleanUp(String textPath) async {
    try {
      await File(textPath).delete();
    } on FileSystemException {
      // A leftover text file next to the cached wav is harmless.
    }
  }

  /// Whether [executable] can be found on PATH.
  Future<bool> canRun(String executable) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [executable],
      );
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}

/// Words per minute, from the 0..1 rate the rest of the app uses.
///
/// 0.5 is "normal" in that scale — it is `flutter_tts`'s own midpoint and the
/// default in [TtsVoiceSettings] — and normal speech is about 175 wpm, so the
/// mapping is pinned through that point rather than scaled from zero.
int wordsPerMinute(double rate) => (80 + rate * 190).round().clamp(80, 450);

/// Windows: SAPI through PowerShell, which is present on every supported
/// Windows version without anything to install.
class WindowsSapiVoice extends _ProcessVoice {
  @override
  Future<bool> synthesize({
    required String text,
    required String outPath,
    required TtsVoiceSettings settings,
  }) async {
    final textPath = await writeTextFile(outPath, text);

    // SAPI's rate is -10..10 around a normal of 0, so the app's 0.5 maps to 0.
    final rate = ((settings.rate - 0.5) * 20).round().clamp(-10, 10);
    final volume = (settings.volume * 100).round().clamp(0, 100);

    final voice = settings.voiceId == null
        ? ''
        : "try { \$s.SelectVoice('${_quote(settings.voiceId!)}') } catch { }";

    final script = '''
Add-Type -AssemblyName System.Speech
\$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$s.Rate = $rate
\$s.Volume = $volume
$voice
\$s.SetOutputToWaveFile('${_quote(outPath)}')
\$s.Speak([IO.File]::ReadAllText('${_quote(textPath)}', [Text.Encoding]::UTF8))
\$s.Dispose()
''';

    final ok = await run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', script],
      outPath: outPath,
    );
    await cleanUp(textPath);
    return ok;
  }

  /// PowerShell single-quoted strings escape a quote by doubling it. Only
  /// paths and a voice name go through here; the announcement text does not.
  static String _quote(String value) => value.replaceAll("'", "''");

  @override
  Future<String?> describeMissing() async =>
      await canRun('powershell') ? null : 'PowerShell was not found on PATH.';
}

/// macOS: `say`, which writes audio files natively and is always installed.
class MacSayVoice extends _ProcessVoice {
  @override
  Future<bool> synthesize({
    required String text,
    required String outPath,
    required TtsVoiceSettings settings,
  }) async {
    final textPath = await writeTextFile(outPath, text);

    final ok = await run(
      'say',
      [
        '-o', outPath,
        // `say` writes AIFF unless told otherwise, and the deck is happier
        // with a plain 16-bit WAV than with whatever it infers from the name.
        '--data-format=LEI16@22050',
        '--file-format=WAVE',
        '-r', '${wordsPerMinute(settings.rate)}',
        if (settings.voiceId != null) ...['-v', settings.voiceId!],
        '-f', textPath,
      ],
      outPath: outPath,
    );
    await cleanUp(textPath);
    return ok;
  }

  @override
  Future<String?> describeMissing() async =>
      await canRun('say') ? null : 'The macOS `say` command was not found.';
}

/// Linux: `espeak-ng`, falling back to the older `espeak`.
///
/// The one platform where the synthesiser is genuinely not guaranteed to be
/// there, which is why [describeMissing] names the package to install.
class LinuxEspeakVoice extends _ProcessVoice {
  static const _candidates = ['espeak-ng', 'espeak'];

  Future<String?> _executable() async {
    for (final candidate in _candidates) {
      if (await canRun(candidate)) return candidate;
    }
    return null;
  }

  @override
  Future<bool> synthesize({
    required String text,
    required String outPath,
    required TtsVoiceSettings settings,
  }) async {
    final executable = await _executable();
    if (executable == null) {
      debugPrint('sayaw: ${await describeMissing()}');
      return false;
    }

    final textPath = await writeTextFile(outPath, text);

    // espeak's pitch is 0..99 around a normal of 50; the app's pitch is a
    // multiplier around a normal of 1.0.
    final pitch = (settings.pitch * 50).round().clamp(0, 99);

    final ok = await run(
      executable,
      [
        '-w', outPath,
        '-s', '${wordsPerMinute(settings.rate)}',
        '-p', '$pitch',
        if (settings.voiceId != null) ...['-v', settings.voiceId!],
        '-f', textPath,
      ],
      outPath: outPath,
    );
    await cleanUp(textPath);
    return ok;
  }

  @override
  Future<String?> describeMissing() async {
    if (await _executable() != null) return null;
    return 'No speech synthesiser is installed. '
        'Announcements need espeak-ng: `sudo apt install espeak-ng`.';
  }
}

/// Where rendered announcements live, given the app's cache directory.
String announcementFileFor(String cacheDirectory, String hash) =>
    p.join(cacheDirectory, '$hash.wav');

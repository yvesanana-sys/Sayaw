import 'dart:io';

import 'package:flutter/services.dart';

/// Turning a stored security-scoped bookmark back into a usable path.
///
/// macOS and iOS hand a sandboxed app a bookmark rather than a path when the
/// operator picks a folder. The path inside it stops working across launches;
/// the bookmark is the durable handle, and resolving it is also what
/// re-acquires permission to read the file at all.
///
/// An interface, because the alternative — the bare static this replaced —
/// could not be swapped for a platform, could not be tested, and answered null
/// on macOS as readily as on Linux with no way to tell the two apart.
abstract class SecurityBookmarks {
  /// The path this bookmark now points at, or null if it cannot be resolved.
  ///
  /// Null covers three different things and the caller cannot act on any of
  /// them differently: no implementation on this platform, a grant the
  /// operator revoked, and a volume that is not mounted. What the caller does
  /// with null is the same in all three — fall back to the stored path and let
  /// that fail in the ordinary way.
  Future<String?> resolve(Uint8List bookmark);

  /// Whether this platform has bookmarks at all.
  ///
  /// Read by anything that would otherwise report "file missing" for a file
  /// that is present but unreachable — the two need telling apart, and only
  /// the platform knows which it is.
  bool get isSupported;
}

/// Windows, Linux and Android: paths are paths, and a bookmark is not a thing.
class NoSecurityBookmarks implements SecurityBookmarks {
  const NoSecurityBookmarks();

  @override
  Future<String?> resolve(Uint8List bookmark) async => null;

  @override
  bool get isSupported => false;
}

/// The Apple platforms, over a method channel.
///
/// The native half is **not written yet**. Until it is, every call comes back
/// as a missing plugin and is answered null — which is what this did before
/// there was an interface, except that it now says so rather than looking like
/// a bookmark that failed to resolve.
class PlatformSecurityBookmarks implements SecurityBookmarks {
  PlatformSecurityBookmarks(
      [this.channel = const MethodChannel('sayaw/security_bookmarks')]);

  final MethodChannel channel;

  /// Set once the channel has been found to have nothing behind it.
  ///
  /// The native half is **not written yet**, and until it is, this platform
  /// has bookmarks in principle and not in practice. The difference decides
  /// what an operator is told about a file that will not play: "give this
  /// folder again" is the right instruction only if something actually
  /// declined, and is a wild goose chase otherwise.
  bool _handlerMissing = false;

  @override
  bool get isSupported =>
      !_handlerMissing && (Platform.isMacOS || Platform.isIOS);

  @override
  Future<String?> resolve(Uint8List bookmark) async {
    if (!isSupported) return null;

    try {
      return await channel.invokeMethod<String>('resolve', bookmark);
    } on MissingPluginException {
      // Nothing is listening. Remembered, so this stops claiming a capability
      // it does not have — and every bookmarked file falls back to its stored
      // path, which is exactly what happened before any of this existed.
      _handlerMissing = true;
      return null;
    } on PlatformException {
      // Something answered and said no: a revoked grant, or a volume that is
      // not mounted. The platform does have bookmarks, so the operator is told
      // to give the folder again.
      return null;
    }
  }
}

/// What to use on the platform this is running on.
SecurityBookmarks defaultSecurityBookmarks() =>
    Platform.isMacOS || Platform.isIOS
        ? PlatformSecurityBookmarks()
        : const NoSecurityBookmarks();

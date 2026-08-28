import Flutter
import UIKit

/// Security-scoped bookmarks for the `sayaw/security_bookmarks` channel.
///
/// iOS hands an app a URL from the document picker that it may read for as
/// long as it holds the scope open, and a bookmark is what carries that across
/// a relaunch. The container's own files need none of this; anything the
/// operator picked from Files does.
///
/// The macOS-only `.withSecurityScope` option does not exist here — on iOS the
/// scope comes from the picker, and a plain bookmark carries it.
final class SecurityBookmarks: NSObject {
  private static let channelName = "sayaw/security_bookmarks"

  /// Held for the life of the process, for the same reason as on macOS: a deck
  /// opens the file long after `resolve` returned, and stopping early is how a
  /// track plays once and then fails.
  private var accessing: [URL] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = SecurityBookmarks()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "resolve":
      guard let data = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "bad-argument",
                            message: "resolve expects bookmark bytes",
                            details: nil))
        return
      }
      result(resolve(data.data))

    case "create":
      guard let paths = call.arguments as? [String] else {
        result(FlutterError(code: "bad-argument",
                            message: "create expects a list of paths",
                            details: nil))
        return
      }
      result(paths.map { path -> FlutterStandardTypedData? in
        create(URL(fileURLWithPath: path)).map { FlutterStandardTypedData(bytes: $0) }
      })

    case "release":
      accessing.forEach { $0.stopAccessingSecurityScopedResource() }
      accessing.removeAll()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func create(_ url: URL) -> Data? {
    try? url.bookmarkData(
      options: [],
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }

  private func resolve(_ data: Data) -> String? {
    var stale = false
    guard
      let url = try? URL(
        resolvingBookmarkData: data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
    else { return nil }

    // A file inside the app's own container needs no scope, and asking for one
    // fails. Treat that as fine rather than as a failure to resolve.
    if url.startAccessingSecurityScopedResource() {
      accessing.append(url)
    }

    return url.path
  }
}

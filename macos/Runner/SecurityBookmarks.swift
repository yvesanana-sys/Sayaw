import Cocoa
import FlutterMacOS

/// Security-scoped bookmarks for the `sayaw/security_bookmarks` channel.
///
/// A sandboxed macOS app is granted access to a file the operator picked, and
/// that grant does not survive a relaunch. A bookmark does: it is the durable
/// handle, and resolving it is what re-acquires permission to read the bytes.
/// Without this, a library imported on Monday is unreadable on Tuesday.
///
/// Requires `com.apple.security.files.user-selected.read-only` and
/// `com.apple.security.files.bookmarks.app-scope` in the entitlements.
final class SecurityBookmarks: NSObject {
  private static let channelName = "sayaw/security_bookmarks"

  /// URLs this process has started accessing and must not stop accessing
  /// while anything might still be reading them.
  ///
  /// Deliberately held for the life of the process. A deck can open a file
  /// long after `resolve` returned, and the balanced `stopAccessing` call
  /// belongs at teardown rather than at the end of this method — releasing it
  /// early is how a track plays once and then fails.
  private var accessing: [URL] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger
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
      // One call for a whole scan batch: a library is tens of thousands of
      // files, and a channel round trip each would dominate the import.
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
    // The file has to be reachable right now for this to mean anything, which
    // during a scan it is — the walk just found it.
    try? url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }

  private func resolve(_ data: Data) -> String? {
    var stale = false
    guard
      let url = try? URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
    else { return nil }

    // A stale bookmark still resolves and still grants access; it only means
    // the file moved and the bookmark should be rewritten. Refusing here would
    // turn a renamed folder into a library that will not play.
    guard url.startAccessingSecurityScopedResource() else { return nil }
    accessing.append(url)

    return url.path
  }
}

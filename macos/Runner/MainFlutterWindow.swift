import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Not a pub plugin, so it registers itself. See SecurityBookmarks.swift:
    // a sandboxed grant does not survive a relaunch and the bookmark is what
    // carries it.
    SecurityBookmarks.register(
      with: flutterViewController.registrar(forPlugin: "SecurityBookmarks"))

    super.awakeFromNib()
  }
}

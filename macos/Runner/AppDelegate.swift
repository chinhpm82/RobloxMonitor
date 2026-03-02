import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  /// Prevent app from quitting when the last window is closed.
  /// This keeps MoniGuard running in the background (visible in Activity Monitor).
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  /// Intercept all Quit events (Cmd+Q, Dock menu, etc).
  /// Instead of quitting, hide all windows so the app stays in the menu bar / tray.
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    NSApp.windows.forEach { $0.orderOut(nil) }
    return .terminateCancel
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

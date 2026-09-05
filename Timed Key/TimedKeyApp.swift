import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Without this, closing the window leaves the app running in the
    // background (standard macOS behavior). This makes the close button
    // fully quit the GUI app instead.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct TimedKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // When launchd triggers this same app with --fire <keycode> <appname>,
        // fire the key press immediately and quit — no window is ever shown,
        // so the close-behavior above never applies to this invocation.
        let args = CommandLine.arguments
        if let fireIndex = args.firstIndex(of: "--fire"), args.count > fireIndex + 2 {
            let keyCode = UInt16(args[fireIndex + 1]) ?? 36
            let appName = args[fireIndex + 2]
            KeyEventSender.fire(keyCode: CGKeyCode(keyCode), targetAppName: appName)
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 380, height: 480)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

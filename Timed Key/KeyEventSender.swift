import Foundation
import AppKit
import ApplicationServices

enum KeyEventSender {
    /// Checks (and optionally prompts for) Accessibility permission.
    static func hasAccessibilityPermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Activates the target app (launching it if needed, and waiting for it
    /// to actually finish launching) then sends the key press.
    static func fire(keyCode: CGKeyCode, targetAppName: String) {
        let app = activateApp(named: targetAppName)

        // Poll until the app reports itself ready, instead of a blind fixed
        // delay — a cold launch can take much longer than 1 second, which is
        // why the key press was getting silently dropped overnight.
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            if let app, app.isFinishedLaunching {
                break
            }
            Thread.sleep(forTimeInterval: 0.2)
        }

        // Extra settle time even after "finished launching" — the process
        // being ready isn't the same as its window/UI being ready to type into.
        Thread.sleep(forTimeInterval: 1.0)

        postKeyPress(keyCode: keyCode)
    }

    @discardableResult
    private static func activateApp(named name: String) -> NSRunningApplication? {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
            running.activate()
            return running
        }

        // Not currently running — launch it by name.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", name]
        try? process.run()
        process.waitUntilExit()

        // Give the OS a brief moment to register the new process, then look it up.
        for _ in 0..<20 {
            if let launched = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
                launched.activate()
                return launched
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return nil
    }

    private static func postKeyPress(keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

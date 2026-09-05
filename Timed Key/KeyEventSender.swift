import Foundation
import AppKit
import ApplicationServices

enum KeyEventSender {
    /// Checks (and optionally prompts for) Accessibility permission.
    static func hasAccessibilityPermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Activates the target app (launching it if needed) and sends the key press.
    static func fire(keyCode: CGKeyCode, targetAppName: String) {
        activateApp(named: targetAppName)
        Thread.sleep(forTimeInterval: 1.0)
        postKeyPress(keyCode: keyCode)
    }

    private static func activateApp(named name: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
            app.activate()
            return
        }
        // Not currently running — launch it by name.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", name]
        try? process.run()
        process.waitUntilExit()
    }

    private static func postKeyPress(keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

import SwiftUI
import AppKit
import Darwin

private let otherAppOption = "Other…"

struct ContentView: View {
    @State private var time = Date()
    @State private var selectedKey: KeyOption = commonKeys[0]
    @State private var availableApps: [String] = ["ChatGPT"]
    @State private var selectedAppOption: String = "ChatGPT"
    @State private var customAppName: String = ""
    @State private var statusMessage: String = "not scheduled yet"
    @State private var statusIsError: Bool = false

    private var targetApp: String {
        selectedAppOption == otherAppOption ? customAppName : selectedAppOption
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack(spacing: 6) {
                    Image("MacUtilitiesIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Mac Utilities")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 20)

                VStack(spacing: 6) {
                    Text("timed key")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("press a key, on schedule")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 0) {
                    row(label: "time") {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    divider
                    row(label: "key") {
                        Picker("", selection: $selectedKey) {
                            ForEach(commonKeys) { key in
                                Text(key.name).tag(key)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    divider
                    row(label: "app") {
                        Picker("", selection: $selectedAppOption) {
                            ForEach(availableApps, id: \.self) { name in
                                Text(name).tag(name)
                            }
                            Divider()
                            Text(otherAppOption).tag(otherAppOption)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    if selectedAppOption == otherAppOption {
                        divider
                        row(label: "name") {
                            TextField("app name", text: $customAppName)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                // Force light appearance just for the panel's native controls,
                // since they sit on a light background — without this they'd
                // inherit the app's dark scheme and render illegibly.
                .environment(\.colorScheme, .light)
                .background(Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)

                Button(action: schedule) {
                    Text("Schedule")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Theme.buttonBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)

                Text(statusMessage)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(statusIsError ? .red : Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refreshAvailableApps()
            // Ask for Accessibility permission the moment the app opens,
            // not only when the user hits Schedule.
            _ = KeyEventSender.hasAccessibilityPermission(prompt: true)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.panelTextSecondary)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func refreshAvailableApps() {
        let names = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { $0.localizedName }
        var unique = Array(Set(names)).sorted()
        // Make sure the default is present even if it's not currently running.
        if !unique.contains("ChatGPT") {
            unique.insert("ChatGPT", at: 0)
        }
        availableApps = unique
    }

    func schedule() {
        // Ask for (or prompt for) Accessibility permission right now, tied to
        // this app, so it's granted well before the scheduled time fires.
        let trusted = KeyEventSender.hasAccessibilityPermission(prompt: true)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsDir = home.appendingPathComponent("Library/LaunchAgents")
        let plistURL = launchAgentsDir.appendingPathComponent("com.timedkey.trigger.plist")

        // Point the scheduled job at THIS SAME app binary, invoked with
        // --fire <keycode> <appname>, instead of spawning osascript.
        let executablePath = Bundle.main.executablePath ?? ""
        let resolvedApp = targetApp

        let plistContents = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.timedkey.trigger</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
                <string>--fire</string>
                <string>\(selectedKey.code)</string>
                <string>\(resolvedApp)</string>
            </array>
            <key>StartCalendarInterval</key>
            <dict>
                <key>Hour</key>
                <integer>\(hour)</integer>
                <key>Minute</key>
                <integer>\(minute)</integer>
            </dict>
        </dict>
        </plist>
        """

        do {
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try plistContents.write(to: plistURL, atomically: true, encoding: .utf8)

            _ = runShell("/bin/launchctl", ["bootout", "gui/\(getuid())", plistURL.path])
            let loadResult = runShell("/bin/launchctl", ["bootstrap", "gui/\(getuid())", plistURL.path])

            if loadResult.isEmpty {
                let timeString = String(format: "%02d:%02d", hour, minute)
                if trusted {
                    statusMessage = "scheduled: \(selectedKey.name) → \(resolvedApp) at \(timeString)"
                    statusIsError = false
                } else {
                    statusMessage = "scheduled, but grant Accessibility access in System Settings for it to work"
                    statusIsError = true
                }
            } else {
                statusMessage = "launchctl said: \(loadResult)"
                statusIsError = true
            }
        } catch {
            statusMessage = "error: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    @discardableResult
    func runShell(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return "failed to run: \(error.localizedDescription)"
        }
    }
}

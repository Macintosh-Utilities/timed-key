<div align="center">

# ⌨️ Timed Key

**A tiny macOS utility that presses a chosen key in a chosen app at a specific time.**

Built with SwiftUI, for Apple Silicon Macs.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-orange?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

</div>

---

## 🚀 What it does

Timed Key lets you pick:

| Pick                | Options                                                                     |
| ------------------- | --------------------------------------------------------------------------- |
| 🕐 **A time**       | hour and minute                                                             |
| ⌨️ **A key**        | Return, Tab, Space, arrows, letters, numbers, or a handful of function keys |
| 🎯 **A target app** | from your currently running apps, or type a custom name                     |

Click **Schedule**, and the key fires automatically at the set time, even if the app isn't open.

---

## 📋 Requirements

| Requirement      | Version               |
| ---------------- | --------------------- |
| macOS            | 14 (Sonoma) or later  |
| Chip             | Apple Silicon (arm64) |
| Xcode (to build) | 15+                   |

---

## 🔐 Permissions

> [!IMPORTANT]
> **Timed Key needs Accessibility access** to send key presses to other apps.
>
> The first time you **open the app,** macOS will prompt you to grant this in
> **System Settings → Privacy & Security → Accessibility**.
> Without this permission, the scheduled key press won't fire.

---

## 🛠 Building it yourself

1. Clone this repo.

2. Open `Timed Key.xcodeproj` in Xcode.

3. Under **Signing & Capabilities**, make sure **App Sandbox** is _not_ enabled.
   _(This app needs to write to `~/Library/LaunchAgents` and run `launchctl`, which sandboxed apps can't do.)_

4. Build by pressing `⌘B`.

---

## ⚙️ How scheduling works

1. A .plist file is created at `~/Library/LaunchAgents/com.timedkey.trigger.plist`.

2. It's loaded via `launchctl bootstrap`.

3. At the scheduled time, `launchd` runs this app with a `--fire` flag.

4. The app detects this flag, fires the key press,
   and exits immediately without showing a window.

---

<div align="center">

Made with ⌨️ + ☕️

</div>

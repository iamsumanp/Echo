# Echo 📋

**Echo** is a lightweight, high-performance, native macOS clipboard manager designed to boost your productivity. Inspired by the premium aesthetics of Raycast and Spotlight, it extends your system clipboard with a powerful, searchable history that stays out of your way until you need it.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## ✨ Features

- **Unlimited History**: Automatically captures text and images copied to your clipboard.
- **Raycast-Inspired UI**: A beautiful, borderless floating window with vibrant "frosted glass" effects.
- **Smart Search**: Instantly filter your history by content or application name.
- **Keyboard First**: Navigate with arrow keys, paste with `Enter`, and launch with a global hotkey.
- **Rich Previews**: dedicated preview pane for reading long text or viewing full-size images.
- **Pinning**: Keep important snippets at the top of your list forever.
- **Privacy Focused**: All data is stored locally on your machine. Nothing is ever sent to the cloud.
- **Native Performance**: Built with Swift and SwiftUI for minimal resource usage.

## 🚀 Installation

### Download
1.  Go to the [Releases](../../releases) page.
2.  Download the latest `Echo.dmg`.
3.  Open the disk image and drag **Echo** to your **Applications** folder.

### First Run
1.  Launch **Echo** from your Applications folder.
2.  **Grant Permissions**: Echo requires **Accessibility** permissions to paste directly into other applications.
    - Go to `System Settings` -> `Privacy & Security` -> `Accessibility`.
    - Enable **Echo** in the list.

## ⌨️ Usage

### Global Shortcut
The default shortcut to open Echo is:
**`Shift` + `Command` + `C`**

*(You can customize this in Preferences)*

### Navigation
- **`↑` / `↓`**: Navigate the list.
- **Type to Search**: Filter history instantly (no need to click the search bar).
- **`Enter`**: Paste the selected item into the active application.
- **Double Click**: Paste the clicked item.
- **Right Click**: Open context menu to Pin, Delete, or Copy.

### Preferences
- Press **`Cmd` + `,`** while the window is open to access Settings.
- Configure history retention (1 day to Forever).
- Record a custom global hotkey.

## 🛠️ Building from Source

If you want to build the app yourself or contribute:

1.  **Prerequisites**:
    - macOS 14.0 (Sonoma) or later.
    - Xcode 15+ (or Command Line Tools).

2.  **Clone the Repository**:
    ```bash
    git clone https://github.com/yourusername/Echo.git
    cd Echo
    ```

3.  **Build and Create DMG**:
    We've included a script to build the release executable, generate the app icon, and bundle it into a DMG.
    ```bash
    ./create_dmg.sh
    ```
    The output `Echo.dmg` will be created in the project root.

4.  **Run Locally (Debug)**:
    ```bash
    swift run
    ```

## 📂 Project Structure

- `Sources/Echo/`: Main application source code.
    - `EchoApp.swift`: App entry point and delegation.
    - `Models/`: Core logic (`HistoryManager`, `ClipboardMonitor`, `HotKeyManager`).
    - `Views/`: SwiftUI views (`ContentView`, `SettingsView`).
- `create_dmg.sh`: Build script for distribution.

## 🔒 Privacy

Echo operates **100% offline**. Your clipboard history is stored locally at:
`~/Library/Application Support/Echo`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
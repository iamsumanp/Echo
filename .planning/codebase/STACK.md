# Technology Stack

**Analysis Date:** 2026-02-19

## Languages

**Primary:**
- Swift 5.9+ - Native macOS application, all source code in `Sources/Echo/`

## Runtime

**Environment:**
- macOS 14.0 (Sonoma) or later
- Apple Silicon (arm64) and Intel (x86_64) native execution

**Build System:**
- Swift Package Manager (SwiftPM) - Package manifest at `Package.swift`
- Build command: `swift build -c release`

## Frameworks

**Core Framework:**
- SwiftUI 5.9+ - Primary UI framework, used throughout all views
  - Located in: `Sources/Echo/Views/`
  - Components: ContentView, SettingsView

**System Frameworks:**
- AppKit - Native macOS system integration
  - Window management: `WindowManager.swift`
  - Clipboard access: `ClipboardMonitor.swift`
  - Menu and status bar handling: `WindowManager.swift`
  - Accessibility/Event handling: `PasteManager.swift`, `HotKeyManager.swift`

- Carbon - Low-level system event handling
  - Global hotkey registration: `HotKeyManager.swift`
  - Key event simulation: `PasteManager.swift`
  - Used for: Event handling, keyboard event simulation

- Combine - Reactive programming framework
  - State management: `HistoryManager.swift` (ObservableObject with @Published)
  - Monitoring: `ClipboardMonitor.swift`

## Key Dependencies

**No external package dependencies** - The application uses only native Apple frameworks with zero third-party dependencies defined in `Package.swift`.

## Configuration

**Environment:**
- No environment variables required
- Configuration stored via UserDefaults (macOS standard preferences)

**Build Configuration:**
- Build target: executable named "Echo"
- Output: Standalone macOS application bundle
- Release build path: `.build/release/Echo`

**User Preferences Storage:**
- Location: `~/Library/Application Support/Echo/`
- History file: `clipboard_history.json`
- Images directory: `clipboard_images/` (subdirectory)
- Preferences: `UserDefaults.standard` (defaults storage)
  - Key: `retentionDays` - Clipboard history retention period (1-infinite days)
  - Key: `hotKeyKeyCode` - Global hotkey key code
  - Key: `hotKeyModifiers` - Global hotkey modifier flags

## Platform Requirements

**Development:**
- macOS 14.0 or later
- Xcode 15+ (or Command Line Tools)
- Swift toolchain 5.9+

**Runtime:**
- macOS 14.0 (Sonoma) or later
- System Accessibility permissions required for:
  - Pasting via simulated keyboard input
  - Detecting which application is frontmost

**Distribution:**
- macOS application bundle (.app)
- DMG installer for distribution
- Code signing not required for local builds (unsigned/ad-hoc for distribution)

## Special Notes

**Accessibility Requirements:**
The application requires Accessibility permissions to function:
- Simulates Command+V keypress for pasting (`PasteManager.swift`)
- Detects frontmost application to record clipboard source
- Checked via `AXIsProcessTrustedWithOptions` in `PasteManager.swift`

**Data Privacy:**
All clipboard data stored locally via JSON serialization:
- Text: Stored in `clipboard_history.json`
- Images: Stored as PNG files in `clipboard_images/` directory
- No external services or cloud synchronization

---

*Stack analysis: 2026-02-19*

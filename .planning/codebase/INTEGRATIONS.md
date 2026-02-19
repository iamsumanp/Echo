# External Integrations

**Analysis Date:** 2026-02-19

## APIs & External Services

**No External API Integrations** - This application does not integrate with any third-party APIs or external services.

## Data Storage

**Local File System Only:**
- Primary storage: `~/Library/Application Support/Echo/`
- History metadata: `clipboard_history.json` (JSON encoded)
- Image storage: `clipboard_images/` directory with PNG files
- Client: Native Swift FileManager API (`Foundation` framework)

**Configuration Storage:**
- UserDefaults (macOS NSUserDefaults)
- Storage location: Application sandbox preferences domain
- Keys stored:
  - `retentionDays`: Integer (default: 30)
  - `hotKeyKeyCode`: Integer (default: kVK_ANSI_C)
  - `hotKeyModifiers`: Integer (default: cmdKey | shiftKey)

**No Database:** Application uses only local file storage, no database backend.

**No Remote Sync:** All data remains on user's machine. No cloud storage or synchronization.

## Authentication & Identity

**Auth Provider:** Not applicable - No authentication required

**Access Control:**
- System Accessibility permissions required for:
  - Simulating keyboard input (Command+V paste)
  - Detecting frontmost application name
- Verified via: `AXIsProcessTrustedWithOptions()` in `PasteManager.swift`
- User must grant in System Settings → Privacy & Security → Accessibility

## Monitoring & Observability

**Error Tracking:** Not detected

**Logs:**
- print() statements for debugging only (development-oriented)
- No persistent logging
- Error messages printed to console:
  - Directory creation errors: `HistoryManager.swift`
  - History load/save errors: `HistoryManager.swift`
  - Image save errors: `HistoryManager.swift`
  - Hotkey registration failures: `HotKeyManager.swift`

## CI/CD & Deployment

**Hosting:** Local distribution via DMG installer

**Distribution Method:**
- GitHub Releases: `Echo.dmg` downloadable
- Manual installation: Drag to Applications folder
- Build script: `create_dmg.sh` creates distributable DMG

**No CI/CD Pipeline Detected**

## Clipboard Integration

**System Clipboard Access:**
- Framework: AppKit `NSPasteboard` API
- Monitoring interval: 0.5 seconds via Timer
- Implementation: `ClipboardMonitor.swift`
  - Detects text content via `pasteboard.string(forType: .string)`
  - Detects image content via `NSImage(pasteboard:)`
  - Converts images to PNG format

**Source Application Detection:**
- Method: `NSWorkspace.shared.frontmostApplication`
- Data captured: `localizedName`, `bundleIdentifier`
- Stored in: ClipboardItem's `applicationName`, `bundleIdentifier` fields

## System Integration

**Global Hotkey Registration:**
- Framework: Carbon event handling
- Default shortcut: Shift + Command + C
- Customizable via Settings
- Implementation: `HotKeyManager.swift`
  - Uses `RegisterEventHotKey()` for global hotkey
  - Event handler: `hotKeyHandler()` callback
  - Cleanup: `UnregisterEventHotKey()` on app termination

**Keyboard Input Simulation:**
- Framework: Core Graphics (`CGEvent`)
- Action: Simulates Command+V for pasting
- Implementation: `PasteManager.swift`
  - Key code 9 = 'v'
  - Posts event to `.cghidEventTap`
  - Used after hiding window to return focus to previous app

**Status Bar Integration:**
- Framework: AppKit NSStatusBar
- Implementation: `WindowManager.swift`
- Features:
  - Clipboard icon in system menu bar
  - Left-click: Toggle window visibility
  - Right-click: Context menu (Show, Preferences, Quit)

## Webhooks & Callbacks

**Incoming:** None

**Outgoing:** None - Application is entirely local

---

*Integration audit: 2026-02-19*

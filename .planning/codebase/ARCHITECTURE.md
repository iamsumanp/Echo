# Architecture

**Analysis Date:** 2026-02-19

## Pattern Overview

**Overall:** SwiftUI-based Model-View-Manager (MVM) pattern with singleton managers for system integrations.

**Key Characteristics:**
- Centralized dependency injection via `AppDependencies` class instantiated in `AppDelegate`
- Singleton managers (`HotKeyManager`, `PasteManager`) for system-level interactions
- SwiftUI environment objects for reactive state propagation
- Direct system framework integrations (AppKit, Carbon, Cocoa)
- File-based persistence with JSON serialization

## Layers

**Presentation Layer (Views):**
- Purpose: SwiftUI components for rendering UI and handling user interactions
- Location: `Sources/Echo/Views/`
- Contains: `ContentView.swift`, `SettingsView.swift` with sub-components
- Depends on: `HistoryManager` (via `@EnvironmentObject`), `PasteManager` for actions
- Used by: `WindowManager` as root view content

**Model Layer (Data):**
- Purpose: Data structures and business logic for clipboard management
- Location: `Sources/Echo/Models/`
- Contains: `ClipboardItem` (data model), `HistoryManager` (state management), managers
- Depends on: Foundation, Combine for reactive updates
- Used by: Presentation layer via environment objects

**Manager Layer (System Integration):**
- Purpose: Encapsulate system-level functionality behind clean APIs
- Location: `Sources/Echo/Models/`
- Components:
  - `ClipboardMonitor`: Polls system clipboard and detects changes
  - `HistoryManager`: Persists and manages clipboard history
  - `HotKeyManager`: Registers global hotkey and triggers window
  - `PasteManager`: Simulates Cmd+V to paste into active application
  - `WindowManager`: Manages window lifecycle and status bar item

**Application Root:**
- Location: `Sources/Echo/EchoApp.swift`
- Entry point: `@main struct EchoApp: App`
- Delegate: `AppDelegate` (NSApplicationDelegate) for lifecycle management

## Data Flow

**Clipboard Capture → History → Display → Paste:**

1. **Monitor Phase**: `ClipboardMonitor` polls `NSPasteboard.general` every 0.5 seconds via `Timer`
2. **Detection Phase**: When `pasteboard.changeCount` differs, extract text or image and identify source app via `NSWorkspace.shared.frontmostApplication`
3. **Persistence Phase**: Call `HistoryManager.addText()` or `HistoryManager.addImage()` which:
   - Check for duplicates (refresh date, preserve pin state)
   - Insert at index 0 (most recent first)
   - Call `saveHistory()` to write JSON to disk
   - For images, save PNG to `~/Library/Application Support/Echo/clipboard_images/`
4. **Reactive Update**: `@Published var items: [ClipboardItem]` triggers view refresh
5. **User Selection**: `ContentView` filters items, displays in list, updates `selectedItemId`
6. **Paste Action**: User presses Enter or double-clicks → call `pasteItem()` which:
   - Copies selected item back to `NSPasteboard.general`
   - Calls `PasteManager.shared.paste()` to hide window and simulate Cmd+V
   - System pastes into active application

**Global Hotkey Flow:**

1. User presses Shift+Cmd+C (default, customizable)
2. Carbon event handler (`hotKeyHandler`) calls `HotKeyManager.shared.handleHotKey()`
3. Calls registered callback: `windowManager?.toggleWindow()`
4. `WindowManager.toggleWindow()` → `show()` or `close()`
5. `show()`: Center on active monitor, activate app, bring window to front
6. `close()`: Hide app (returns focus to previous app)

**State Management:**

- `HistoryManager` is the single source of truth for clipboard history
- Published via `@EnvironmentObject` to all views in `ContentView`
- `UserDefaults` stores retention days and hotkey configuration
- Image files persisted to disk, JSON metadata persisted separately
- Filtering and sorting done in-memory in view layer

## Key Abstractions

**ClipboardItem:**
- Purpose: Data model representing a single clipboard entry
- Location: `Sources/Echo/Models/ClipboardItem.swift`
- Structure: UUID identifier, type (text/image), content, metadata (app, date, pin state)
- Pattern: `Codable` for serialization, `Identifiable` for list rendering, `Hashable` for Set operations

**HistoryManager:**
- Purpose: Central state container and persistence layer
- Location: `Sources/Echo/Models/HistoryManager.swift`
- Pattern: `ObservableObject` with `@Published var items`
- Responsibilities:
  - Load/save history from `~/Library/Application Support/Echo/clipboard_history.json`
  - Manage images on disk (save/delete)
  - Enforce retention policies (configurable days)
  - Handle duplicate detection and refresh logic
  - Provide computed accessors: `retentionDays`, `dataDirectory`, `imagesDirectoryURL`

**WindowManager:**
- Purpose: Encapsulate macOS window and status bar management
- Location: `Sources/Echo/Models/WindowManager.swift`
- Pattern: Generic over view content, NSWindowDelegate for focus handling
- Responsibilities:
  - Create and configure borderless floating window
  - Manage status bar item with menu and click handling
  - Position window on active monitor
  - Auto-close on focus loss
  - Handle preferences/settings shortcuts

**Managers (Singletons):**
- `HotKeyManager`: Global hotkey registration via Carbon APIs
- `PasteManager`: Accessibility-level keyboard simulation via CGEvent

## Entry Points

**Application Start:**
- Location: `Sources/Echo/EchoApp.swift`
- Trigger: User launches app from Applications folder
- Flow:
  1. SwiftUI runtime instantiates `EchoApp` (marked with `@main`)
  2. SwiftUI creates `AppDelegate` via `@NSApplicationDelegateAdaptor`
  3. `applicationDidFinishLaunching()` called
  4. Create `AppDependencies` (initializes `HistoryManager`, `ClipboardMonitor`)
  5. Start clipboard monitoring
  6. Create `WindowManager` with `ContentView`
  7. Register global hotkey with `HotKeyManager`

**Global Hotkey Trigger:**
- Location: `Sources/Echo/Models/HotKeyManager.swift` → `hotKeyHandler()` callback
- Trigger: User presses registered hotkey (default Shift+Cmd+C)
- Action: Toggle window visibility via `WindowManager.toggleWindow()`

**Settings Panel:**
- Location: `Sources/Echo/Views/SettingsView.swift`
- Trigger: Cmd+. while window is open, or "Preferences..." from menu
- Content: Hotkey recorder, retention period picker, accessibility status, clear history action

## Error Handling

**Strategy:** Graceful degradation with console logging.

**Patterns:**

- **File I/O**: Try-catch blocks log errors but don't crash
  ```swift
  // In HistoryManager.loadHistory(), HistoryManager.saveHistory()
  do {
      let data = try Data(contentsOf: historyFileURL)
      let decoder = JSONDecoder()
      items = try decoder.decode([ClipboardItem].self, from: data)
  } catch {
      print("Error loading history: \(error)")  // Logs silently, items remain empty
  }
  ```

- **Image Processing**: Return optional, skip on failure
  ```swift
  // In ClipboardMonitor.checkClipboard()
  guard let filename = saveImageToDisk(data) else { return }  // Silently skip if save fails
  ```

- **Pasteboard Access**: Guard patterns prevent nil-based crashes
  ```swift
  if let string = pasteboard.string(forType: .string) { ... }
  else if NSImage.canInit(with: pasteboard) { ... }
  ```

- **UI State**: Missing data results in "Unknown" labels or empty states
  ```swift
  // In ModernListItem and PreviewPane
  Text(item.applicationName ?? "Unknown")
  ```

## Cross-Cutting Concerns

**Logging:** Simple `print()` statements for errors and diagnostics
- Used in: `HistoryManager` (file I/O), `HotKeyManager` (hotkey registration)
- Not used: Info or debug logging for normal operations

**Validation:**
- Input validation in `ClipboardMonitor`: Ignore whitespace-only text
- Duplicate detection in `HistoryManager.addText()`: Refresh existing entries instead of duplicating

**Authentication:**
- Accessibility permissions checked via `AXIsProcessTrustedWithOptions()`
- Checked in `SettingsView` to warn users if paste will fail
- No automatic prompt; users must enable in System Settings

**Data Integrity:**
- JSON persistence with pretty-printing for human readability
- Timestamp strategy: ISO8601 date encoding
- Image files named by UUID to prevent collisions
- Retention pruning runs on init and when retention days change

---

*Architecture analysis: 2026-02-19*

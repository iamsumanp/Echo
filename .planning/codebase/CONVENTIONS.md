# Coding Conventions

**Analysis Date:** 2026-02-19

## Naming Patterns

**Files:**
- PascalCase for all Swift files: `EchoApp.swift`, `ClipboardItem.swift`, `HistoryManager.swift`
- One primary type per file (usually a class, struct, or protocol)
- View files use `View` suffix: `ContentView.swift`, `SettingsView.swift`, `PreviewPane` (struct within View file)

**Functions:**
- camelCase for all function names
- Private functions use `private func` explicitly: `private func checkClipboard()`, `private func saveImageToDisk()`
- Public methods omit the private keyword
- Objective-C callback functions use snake_case prefixed with context: `hotKeyHandler()` for Carbon event handler

**Variables:**
- camelCase for property names: `items`, `isRecording`, `selectedItemId`, `retentionDays`
- Private properties use `private var` or `private let`: `private var timer`, `private let pasteboard`
- Mutable state in Views uses `@State`: `@State private var searchText`, `@State private var selectedItemId`
- Lazy computed properties use `var` with getter: `var filteredItems: [ClipboardItem]`, `var retentionDays: Int`
- Boolean properties use descriptive names: `isPinned`, `isSelected`, `isRecording`, `isCodeLike`, `isSearchFocused`

**Types:**
- PascalCase for classes, structs, enums: `ClipboardItem`, `HistoryManager`, `WindowManager`
- Enum cases use camelCase: `case text`, `case image`
- Enum types: `enum ClipboardItemType: String, Codable`
- Type aliases capitalized: `AnyView` (from SwiftUI)

**Constants:**
- Uppercase with underscores for C constants: `kVK_ANSI_C`, `kEventClassKeyboard`
- Private constants use camelCase: `historyFileName = "clipboard_history.json"`, `imagesDirectoryName = "clipboard_images"`

## Code Style

**Formatting:**
- No explicit formatter configured (SwiftUI/Swift defaults apply)
- 4-space indentation (Swift convention)
- Line continuations align at operators or method chains
- Closures on separate lines when complex:
  ```swift
  timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.checkClipboard()
  }
  ```

**Import Organization:**
- System frameworks first, then third-party (none in this project)
- Each import on its own line:
  ```swift
  import AppKit
  import SwiftUI
  import Combine
  import Foundation
  import Carbon
  ```
- Order: Foundation/system frameworks, then UI frameworks

**Modifier Order (Classes/Structs):**
- `@main` for app entry point
- `@NSApplicationDelegateAdaptor` for app delegates
- `@EnvironmentObject` for SwiftUI environment
- `@State` for local view state
- `@Published` for Observable objects
- `@AppStorage` for persisted user defaults

**Weak Self Closures:**
- Always use `[weak self]` in closures to prevent retain cycles
- Used extensively in timers and event handlers:
  ```swift
  timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.checkClipboard()
  }
  ```

## Import Organization

**Order:**
1. System frameworks (AppKit, SwiftUI, Foundation, Combine, Carbon)
2. Local modules (none - single target)

**Path Aliases:**
- No aliases used (simple single-target structure)

**Example from `HistoryManager.swift`:**
```swift
import Combine
import Foundation
```

**Example from `ContentView.swift`:**
```swift
import AppKit
import SwiftUI
```

## Error Handling

**Patterns:**
- Guard statements for early returns: `guard let dataDirectory = dataDirectory else { return }`
- Do-catch blocks for file I/O operations:
  ```swift
  do {
      let data = try Data(contentsOf: historyFileURL)
      let decoder = JSONDecoder()
      items = try decoder.decode([ClipboardItem].self, from: data)
  } catch {
      print("Error loading history: \(error)")
  }
  ```
- Try-optional chaining: `try? FileManager.default.removeItem(at: fileURL)` when failure is acceptable
- Print debugging for errors (non-recoverable): `print("Error creating directories: \(error)")`
- No custom error types defined - uses native Foundation error handling

**Nil Coalescing:**
- Used for default values: `appName = frontmostApp?.localizedName`
- Optional binding in guards: `guard let imagePath = item.imagePath else { return }`

## Logging

**Framework:** `print()` console output only

**Patterns:**
- Errors logged with context: `print("Error loading history: \(error)")`
- Status messages: `print("Failed to register hotkey: \(status)")`
- No structured logging or log levels

## Comments

**When to Comment:**
- MARK sections organize large files into logical groups:
  ```swift
  // MARK: - Left Pane (Search & List)
  // MARK: - Logic & Actions
  // MARK: - NSWindowDelegate
  ```
- Used to separate concerns within View bodies (4 in ContentView)
- Comments above complex logic blocks: "Ignore empty strings or strings that are just whitespace"

**JSDoc/DocComments:**
- Single documentation comment used: `/// Centers the window on whichever screen the mouse cursor is currently on` (WindowManager.swift:128)
- Mostly absent - only one example in codebase
- Not required for obvious functions

## Function Design

**Size:** Functions range 5-30 lines, most under 20 lines

**Parameters:**
- Trailing closures used extensively: `Timer.scheduledTimer { [weak self] _ in ... }`
- Default parameters in initializers: `id: UUID = UUID()`, `dateCreated: Date = Date()`
- Parameters include type information: `func addText(_ text: String, from appName: String?, bundleIdentifier: String?)`
- Omit parameter name with underscore for single-use params: `func startMonitoring()` timer closure uses `{ [weak self] _ in ... }`

**Return Values:**
- View builders use `@ViewBuilder` annotation:
  ```swift
  @ViewBuilder
  private func rowView(for item: ClipboardItem) -> some View { }
  ```
- Optional returns for fallible operations: `func saveImageToDisk(_ data: Data) -> String?`
- Boolean for permission checks: `func checkAccessibilityPermissions() -> Bool`

## Module Design

**Exports:**
- All public types in `Sources/Echo/`: `ClipboardItem`, `HistoryManager`, `WindowManager`, `ContentView`
- Single executable target with no internal module structure
- Implicit exports - no explicit `public` keyword used

**Barrel Files:**
- Not used - single target, no intermediate re-exports
- Each file is self-contained

**Shared Utility Functions:**
- `ShortcutHelper` struct contains static utility functions for key code conversion
- `RelativeDateTimeFormatter` used for relative time display
- Extension on `Notification.Name`: `extension Notification.Name { static let openPreferences = Notification.Name("OpenPreferences") }`

**Singletons:**
- `HotKeyManager.shared` - singleton for global hotkey registration
- `PasteManager.shared` - singleton for paste simulation
- Used for system-wide concerns (hotkeys, paste automation)

---

*Convention analysis: 2026-02-19*

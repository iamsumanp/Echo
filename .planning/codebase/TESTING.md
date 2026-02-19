# Testing Patterns

**Analysis Date:** 2026-02-19

## Test Framework

**Runner:**
- Not detected - no test framework configured
- `Package.swift` defines only executable target: `name: "Echo", targets: ["Echo"]`
- No test targets in manifest

**Assertion Library:**
- Not applicable - no testing framework present

**Run Commands:**
- `swift run` - Runs debug executable locally
- `./create_dmg.sh` - Builds release and packages DMG (implicit integration test)
- No explicit test commands configured

## Test File Organization

**Status:** No unit or integration tests present in codebase

**Why:**
- Single executable application focused on UI and system integration
- Testing challenges:
  - Heavy reliance on macOS system APIs (NSPasteboard, Carbon events, Accessibility)
  - SwiftUI view testing requires Xcode UI testing framework (XCTest)
  - Global hotkey and clipboard monitoring are system-level concerns

## Manual Testing Approach

**Build and Launch:**
- `swift run` launches app with debug logging
- Visual testing of UI through direct interaction

**System Integration Testing:**
- Global hotkey registration (`Cmd+Shift+C` default)
- Clipboard monitoring on 0.5 second intervals
- Paste simulation using CGEvent key injection
- File persistence: `~/Library/Application Support/Echo/`

**UI/Interaction Testing:**
- Arrow key navigation through history list
- Search filtering by text content or app name
- Double-click to paste
- Context menu operations (Pin, Delete, Copy)
- Settings modal (Cmd+. shortcut)
- Dark/light theme appearance

## Testability Considerations

**Dependency Injection:**
- `AppDependencies` container created in `AppDelegate`:
  ```swift
  class AppDependencies: ObservableObject {
      let historyManager: HistoryManager
      let clipboardMonitor: ClipboardMonitor
  }
  ```
- Injected into views via SwiftUI environment: `.environmentObject(dependencies.historyManager)`
- Enables isolated testing of `HistoryManager` by providing mock implementations

**Observable State:**
- `HistoryManager: ObservableObject` with `@Published var items` allows state inspection
- `ClipboardMonitor: ObservableObject` for testable clipboard state
- View models use `@StateObject` for lifecycle management

**File I/O Abstraction:**
- `HistoryManager` handles all file operations internally
- Paths computed via `FileManager.urls()` - could be mocked
- Errors printed but not thrown - makes testing simpler but harder to verify failures

## Singleton Pattern Testing

**Registered Singletons:**
- `HotKeyManager.shared` - Global hotkey manager
- `PasteManager.shared` - Clipboard paste automation

**Challenges:**
- Global state makes unit testing difficult
- Would require state reset between tests
- No initialization parameters for dependency injection

## Code Patterns Suitable for Testing

**Isolated Computation:**
- `timeAgo(_ date: Date) -> String` in `ModernListItem` - pure function, easily testable
- `ShortcutHelper.keyString(for:)` - static function mapping key codes to strings
- `isCodeLike` computed property in `PreviewPane` - pattern matching logic

**Example Testable Code (from `PreviewPane.swift`):**
```swift
private var isCodeLike: Bool {
    guard let text = item.textContent else { return false }
    let codeIndicators = [
        "{", "}", "()", "=>", "->", "func ", "def ", "class ", "import ",
        // ... more indicators
    ]
    let matchCount = codeIndicators.filter { text.contains($0) }.count
    return matchCount >= 2
}
```

## Data Persistence Testing

**Storage Location:**
- `~/Library/Application Support/Echo/clipboard_history.json` - History file
- `~/Library/Application Support/Echo/clipboard_images/` - Image cache

**Format:**
- JSON with ISO8601 date encoding/decoding
- `JSONEncoder` with `.prettyPrinted` formatting for debugging
- Versioning not implemented - format changes would break existing history

**Test Approach (Manual):**
- Inspect JSON file to verify encoding
- Delete files to test recovery/recreation
- Verify retention pruning with fixed test data

## Error Cases Not Covered

**File System Errors:**
```swift
} catch {
    print("Error loading history: \(error)")  // Silently fails, continues with empty history
}
```
- No test for corrupted JSON
- No test for permission errors
- No test for disk full scenarios

**System Integration Errors:**
- Hotkey registration failures logged but not handled: `print("Failed to register hotkey: \(status)")`
- Clipboard access errors silently ignored
- Image save failures return `nil` without notification

## Future Testing Strategy

**Unit Testing Candidates:**
- Extract `HistoryManager` filtering/sorting logic into testable functions
- Separate `ShortcutRecorderViewModel` state from view for testing
- Create test doubles for file operations

**Integration Testing Candidates:**
- Test complete clipboard capture flow with test data
- Verify JSON persistence round-trip
- Test retention pruning with various age scenarios

**UI Testing:**
- XCTest with SwiftUI testing API (iOS 15+, macOS 13+)
- Mock `HistoryManager` with predefined test data
- Verify list rendering, search filtering, selection

**Example Test Structure (if added):**
```swift
import XCTest

class HistoryManagerTests: XCTestCase {
    var sut: HistoryManager!
    var mockFileManager: MockFileManager!

    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        // Inject mock
    }

    func testAddTextCreatesNewItem() {
        let item = sut.addText("test", from: "TestApp", bundleIdentifier: "test.app")
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items[0].textContent, "test")
    }
}
```

---

*Testing analysis: 2026-02-19*

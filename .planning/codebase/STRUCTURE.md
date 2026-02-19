# Codebase Structure

**Analysis Date:** 2026-02-19

## Directory Layout

```
ClipboardManager/
├── Sources/Echo/                    # Main application source code
│   ├── EchoApp.swift               # App entry point and AppDelegate
│   ├── Models/                     # Core business logic and state management
│   │   ├── ClipboardItem.swift
│   │   ├── ClipboardMonitor.swift
│   │   ├── HistoryManager.swift
│   │   ├── HotKeyManager.swift
│   │   ├── PasteManager.swift
│   │   └── WindowManager.swift
│   └── Views/                      # SwiftUI presentation components
│       ├── ContentView.swift
│       └── SettingsView.swift
├── Package.swift                   # Swift Package Manager manifest
├── create_dmg.sh                   # Build and packaging script
├── README.md                       # Project documentation
├── .planning/                      # GSD planning documentation
│   └── codebase/
└── Screenshots/                    # UI screenshots for documentation
```

## Directory Purposes

**Sources/Echo/:**
- Purpose: Main application source code directory
- Contains: Swift files for models, views, and app logic
- Key files: `EchoApp.swift` (entry), Models/ (business logic), Views/ (UI)

**Sources/Echo/Models/:**
- Purpose: Contains managers and data models for business logic
- Contains: Clipboard monitoring, history persistence, system integrations
- Key files:
  - `ClipboardItem.swift`: Data model (12 fields including UUID, type, content, metadata)
  - `HistoryManager.swift`: Clipboard history state and persistence (210 lines)
  - `ClipboardMonitor.swift`: Clipboard polling and change detection (57 lines)
  - `HotKeyManager.swift`: Global hotkey registration via Carbon APIs (116 lines)
  - `PasteManager.swift`: Keyboard simulation for pasting (39 lines)
  - `WindowManager.swift`: Window and status bar management (172 lines)

**Sources/Echo/Views/:**
- Purpose: SwiftUI presentation layer
- Contains: User interface components and user interaction handlers
- Key files:
  - `ContentView.swift`: Main clipboard history list, search, preview pane (693 lines)
  - `SettingsView.swift`: Settings panel with hotkey recorder and preferences (238 lines)

## Key File Locations

**Entry Points:**
- `Sources/Echo/EchoApp.swift`: App initialization, dependency injection, hotkey registration
- `Sources/Echo/Views/ContentView.swift`: Main UI entry point for window content

**Configuration:**
- `Package.swift`: Build configuration, Swift 5.9 requirement, macOS 14 minimum
- No config files (no .eslintrc, tsconfig, etc. - native Swift project)
- `UserDefaults` used for runtime config: retention days, hotkey codes/modifiers

**Core Logic:**
- `Sources/Echo/Models/HistoryManager.swift`: State container and persistence
- `Sources/Echo/Models/ClipboardMonitor.swift`: System clipboard monitoring
- `Sources/Echo/Models/HotKeyManager.swift`: Global hotkey handling
- `Sources/Echo/Models/PasteManager.swift`: Paste simulation

**Data Storage:**
- `~/Library/Application Support/Echo/clipboard_history.json`: History metadata
- `~/Library/Application Support/Echo/clipboard_images/`: Image files (PNGs named by UUID)

**Testing:**
- No test directory present; no test framework configured

## Naming Conventions

**Files:**
- Pattern: PascalCase for all Swift files (`EchoApp.swift`, `ClipboardItem.swift`)
- Example: `HistoryManager.swift`, `ContentView.swift`, `SettingsView.swift`

**Classes/Structs:**
- Pattern: PascalCase with descriptive name
- Examples:
  - `EchoApp` (app entry)
  - `AppDelegate` (lifecycle)
  - `ClipboardItem` (data model)
  - `HistoryManager` (business logic)
  - `WindowManager` (system integration)

**Functions/Methods:**
- Pattern: camelCase
- Examples in `HistoryManager`:
  - `addText()`, `addImage()`, `deleteItem()`, `togglePin()`
  - `saveHistory()`, `loadHistory()`, `pruneOldItems()`
  - `createDirectories()`, `saveImageToDisk()`, `deleteImageFile()`

**Variables:**
- Pattern: camelCase for properties and local variables
- Examples:
  - `let historyFileName = "clipboard_history.json"`
  - `var items: [ClipboardItem]`
  - `private var timer: Timer?`
  - `@State private var searchText = ""`

**Properties:**
- Pattern: Use `@Published` for observable state in `ObservableObject` classes
- Use `@AppStorage` for user defaults-backed properties in views
- Use `@Environment`, `@EnvironmentObject`, `@State`, `@FocusState` for SwiftUI state

## Where to Add New Code

**New Feature (e.g., cloud sync, new clipboard type):**
- Primary code: `Sources/Echo/Models/` (add new manager or extend existing)
- UI changes: `Sources/Echo/Views/ContentView.swift` or new view file in `Sources/Echo/Views/`
- Example: To add database sync, create `Sources/Echo/Models/SyncManager.swift`

**New Component/Module (e.g., export feature, advanced search):**
- Implementation: `Sources/Echo/Models/` (business logic), `Sources/Echo/Views/` (UI)
- Pattern: Create manager class in Models/, SwiftUI view in Views/
- Wire into `AppDelegate` via `AppDependencies` if system-level

**Utilities:**
- Shared helpers: Add as extensions or utility structs in `Sources/Echo/Models/`
- Example: `ShortcutHelper` (struct with static methods) in `SettingsView.swift`
- Keep small utilities co-located with related code

**Views:**
- New full screens/panels: Create in `Sources/Echo/Views/` as separate `.swift` file
- Sub-components: Define in same file using `@ViewBuilder` if small, separate file if complex
- Pattern in codebase: `ContentView.swift` contains primary view + helpers (`ModernListItem`, `PreviewPane`, `EmptyPreviewState`, `EmptySearchState`, `VisualEffectView`)

## Special Directories

**Sources/Echo/:**
- Purpose: Single executable target containing all app code
- Generated: No (hand-written source)
- Committed: Yes

**~/Library/Application Support/Echo/:**
- Purpose: Runtime data directory for history and images
- Generated: Yes (auto-created by `HistoryManager.createDirectories()`)
- Committed: No (user data)

**.planning/codebase/:**
- Purpose: GSD codebase analysis documents
- Generated: Yes (generated by GSD tools)
- Committed: Yes

## Import Organization

**Pattern in codebase:**

1. Foundation framework imports (Foundation, Combine)
2. System framework imports (AppKit, SwiftUI, Carbon, Cocoa)
3. Local imports (none - single executable target)

**Examples:**

In `EchoApp.swift`:
```swift
import AppKit
import SwiftUI
```

In `HistoryManager.swift`:
```swift
import Combine
import Foundation
```

In `ContentView.swift`:
```swift
import AppKit
import SwiftUI
```

In `HotKeyManager.swift`:
```swift
import Carbon
import Cocoa
```

**Path Aliases:**
- Not used (single executable, no complex module structure)

## SwiftUI Architecture Patterns

**State Management:**
- `@State`: Local view state (e.g., `@State private var searchText = ""`)
- `@EnvironmentObject`: Shared observables (`@EnvironmentObject var historyManager: HistoryManager`)
- `@AppStorage`: UserDefaults-backed (e.g., `@AppStorage("retentionDays")`)
- `@FocusState`: Focus management (e.g., `@FocusState private var isSearchFocused`)

**View Composition:**
- Primary view contains logic and sub-components via `@ViewBuilder`
- Example: `ContentView` contains `searchHeader`, `listView`, `footerBar`, `PreviewPane`
- Sub-views are `ViewBuilder` methods returning `some View`

**Reactive Updates:**
- `@Published` properties in `ObservableObject` trigger view refreshes
- `onChange()` modifier listens to property changes and updates related state
- `onReceive()` for NotificationCenter events (e.g., settings open)

## Code Organization Guidelines

**File Size:**
- Views are typically 200-700 lines (e.g., ContentView 693 lines)
- Managers are 50-210 lines each (focused responsibility)
- Keep files under 300 lines when possible; extract sub-views to `@ViewBuilder` methods

**Struct vs Class:**
- Use `struct` for data models and views (SwiftUI requirement)
- Use `class` for managers that need reference semantics: `HistoryManager`, `ClipboardMonitor`, `WindowManager`, `HotKeyManager`, `PasteManager`

**Access Modifiers:**
- Properties: `private` by default, `var` if observable via `@Published`
- Methods: `private` for internal logic, `func` without modifier for public APIs
- Mark internal implementation with `// MARK: - Section Name` for organization

---

*Structure analysis: 2026-02-19*

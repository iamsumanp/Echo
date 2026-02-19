# Codebase Concerns

**Analysis Date:** 2026-02-19

## Tech Debt

**Silent Error Handling in File Operations:**
- Issue: Print statements used for errors without user notification or logging infrastructure
- Files: `Sources/Echo/Models/HistoryManager.swift` (lines 54-56, 71-73, 85-87, 193-194)
- Impact: Users have no visibility into failures (load/save history fails silently, images fail to save). Errors only appear in console, not debuggable in production
- Fix approach: Implement proper error tracking with user-facing alerts for critical failures (history save), silent logging for non-critical issues. Consider Logger framework instead of print()

**Weak Clipboard Monitoring Timing:**
- Issue: Clipboard monitoring uses fixed 0.5-second interval polling instead of event-driven approach
- Files: `Sources/Echo/Models/ClipboardMonitor.swift` (line 17)
- Impact: 500ms delay means fast clipboard operations can be missed, especially when copying multiple items rapidly; uses CPU continuously instead of responding to system notifications
- Fix approach: Consider using NSPasteboard.availableTypeNotification or other event-driven APIs if available on macOS 14+. Document why polling was chosen if unavoidable

**Duplicate Detection Logic and ID Reuse:**
- Issue: Ambiguous design decision: when duplicate text is detected, existing item is removed and replaced with new item. Line 99 comment asks "Reuse ID? Or new ID?" but creates new item with existing ID then re-uses it
- Files: `Sources/Echo/Models/HistoryManager.swift` (lines 94-108)
- Impact: Unpredictable ID behavior - if callers rely on ID stability, this breaks that contract. New item gets existing ID (preserves pinned state) but unclear intent
- Fix approach: Clarify design: either truly reuse the ID (create new ClipboardItem with explicit ID parameter) OR use new ID. Update comment to reflect actual behavior. Add unit test for this scenario

**Magic Constant in HotKey Registration:**
- Issue: Hardcoded OSType signature value with no documentation
- Files: `Sources/Echo/Models/HotKeyManager.swift` (line 82)
- Impact: The value `1_196_381_003` maps to 'ghk1' but is opaque without context. Cannot determine why this specific value or if it's unique
- Fix approach: Replace magic number with constant: `let HOT_KEY_SIGNATURE = OSType("ghk1")`; document significance

**Unsafe ContentView Selection Logic:**
- Issue: Selection is lost/reset when filtered items change, causing disorientation
- Files: `Sources/Echo/Views/ContentView.swift` (lines 104-109)
- Impact: When user searches or history updates, selected item resets to first filtered result. If user navigates to item #5 then searches, selection jumps back to first match
- Fix approach: Preserve selection if item still exists in filtered results; only reset if selected item is filtered out

**Hardcoded Window Dimensions:**
- Issue: Window size (800x500) and list panel width (280) are magic values
- Files: `Sources/Echo/Views/ContentView.swift` (lines 44, 99) and `Sources/Echo/Models/WindowManager.swift` (lines 22)
- Impact: No responsive design; window cannot be resized by user. If content density changes or font sizes vary, UI breaks
- Fix approach: Move dimensions to constants (or eventually Settings). Consider making window resizable, or at minimum respecting Safe Area

**Image Conversion Always to PNG:**
- Issue: All images converted to PNG regardless of source format
- Files: `Sources/Echo/Models/HistoryManager.swift` (line 186) - assumes PNG; `Sources/Echo/Models/ClipboardMonitor.swift` (line 48) uses TIFF intermediate
- Impact: Potential quality loss (animated GIFs become static PNG), larger file sizes than source (JPEG to PNG), memory overhead from TIFF->PNG conversion
- Fix approach: Detect source format and preserve it when possible. Document format support requirements

## Known Issues

**Potential Memory Leak with RelativeDateTimeFormatter:**
- Symptoms: RelativeDateTimeFormatter created every time row is rendered, no pooling
- Files: `Sources/Echo/Views/ContentView.swift` (lines 494-498 in ModernListItem.timeAgo)
- Trigger: Any list scroll causes multiple formatter instances
- Workaround: Acceptable in practice due to small list sizes, but not optimal

**Race Condition on App Startup:**
- Symptoms: Window creation deferred to async block, but other code might access window before it exists
- Files: `Sources/Echo/Models/WindowManager.swift` (lines 14-16)
- Trigger: Hot key pressed immediately after app launch before `DispatchQueue.main.async` block executes
- Current safeguard: `if window == nil { setupWindow() }` in show() (line 113) prevents crash, but timing-dependent

**Image Loading Can Block UI:**
- Symptoms: NSImage(contentsOf:) is synchronous IO operation on main thread
- Files: `Sources/Echo/Views/ContentView.swift` (lines 426-427, 612); `Sources/Echo/Views/SettingsView.swift` (referenced via ModernListItem)
- Trigger: When opening history with many large images
- Current behavior: UI blocks until all image thumbnails load from disk

## Security Considerations

**Accessibility API Trust Without Verification:**
- Risk: PasteManager assumes Accessibility permissions granted without robust error handling
- Files: `Sources/Echo/Models/PasteManager.swift` (lines 19-32)
- Current mitigation: SettingsView checks permissions and prompts user (SettingsView.swift lines 34-53)
- Recommendations: Add fallback to NSPasteboard.setString() if keyboard simulation fails; verify permissions before each paste operation; log paste failures

**Plaintext History Storage:**
- Risk: All clipboard history stored as JSON in Application Support directory, accessible by other processes/users on shared systems
- Files: `Sources/Echo/Models/HistoryManager.swift` (lines 26-28, 64-73)
- Current mitigation: macOS user permission isolation (file in ~/Library/Application Support/Echo)
- Recommendations: For sensitive use cases, document risk clearly. Consider optional encryption layer for future versions. Add warning in Settings about sensitive data

**No Validation of Image Sources:**
- Risk: Images from pasteboard are trusted implicitly, no format validation
- Files: `Sources/Echo/Models/ClipboardMonitor.swift` (lines 45-54)
- Current mitigation: NSBitmapImageRep conversion will reject corrupt data
- Recommendations: Add error handling; reject excessively large images (>100MB) to prevent DoS

## Performance Bottlenecks

**Inefficient Duplicate Detection in addText():**
- Problem: Linear O(n) search through items list every time text copied
- Files: `Sources/Echo/Models/HistoryManager.swift` (line 94)
- Cause: No indexing; uses firstIndex(where:) with string equality check
- Improvement path: For large histories (10k+ items), maintain HashMap of text hashes to IDs. For typical use (< 1000 items), current approach acceptable but should profile

**JSON Encoding of Entire History on Every Change:**
- Problem: saveHistory() serializes all items to JSON, writes entire file repeatedly
- Files: `Sources/Echo/Models/HistoryManager.swift` (lines 76-88)
- Cause: Called after every add/delete/toggle operation
- Improvement path: Batch writes (debounce 500ms), or eventually switch to lightweight database (SQLite) for 10k+ item histories. Document expected save time for 1000 items

**Linear Search in ContentView.filteredItems:**
- Problem: Recomputes filtered list on every render, no memoization
- Files: `Sources/Echo/Views/ContentView.swift` (lines 13-34)
- Cause: Swift UI rerenders frequently; no caching of filtered results
- Improvement path: Add computed property that caches based on `searchText` and `items`, invalidates only when these change

**Continuous 0.5-second Polling:**
- Problem: ClipboardMonitor timer runs always, even when window hidden
- Files: `Sources/Echo/Models/ClipboardMonitor.swift` (lines 15-20)
- Cause: No suspend/resume based on visibility
- Improvement path: Stop monitoring when app goes to background, resume on foreground. Requires listening to NSApplication notifications

## Fragile Areas

**ContentView is 693 lines and contains multiple sub-views:**
- Files: `Sources/Echo/Views/ContentView.swift`
- Why fragile: Single file contains ModernListItem, PreviewPane, EmptyPreviewState, EmptySearchState, VisualEffectView. Changes to any view ripple through. No clear separation of concerns
- Safe modification: Extract sub-views into separate files (ModernListItem.swift, PreviewPane.swift) before adding new features. Add unit tests for selection logic
- Test coverage: No unit tests visible; KeyboardHandler logic (arrow keys, typing) is untested

**HistoryManager has Multiple Responsibilities:**
- Files: `Sources/Echo/Models/HistoryManager.swift`
- Why fragile: Handles loading, saving, pruning, deduplication, image file management. 207 lines of state management. Hard to test in isolation
- Safe modification: Consider splitting into HistoryStore (persistence), HistoryDeduplicator (duplicate logic), ImageStore (file operations)
- Test coverage: No unit tests. Pruning logic (lines 164-181) is critical but untested

**HotKeyManager uses Global C Callback:**
- Files: `Sources/Echo/Models/HotKeyManager.swift` (lines 5-10)
- Why fragile: Global function `hotKeyHandler` requires shared singleton. If multiple instances needed, crashes. Uses Carbon API (deprecated in modern macOS)
- Safe modification: Document requirement for singleton pattern. Consider migration path to newer APIs
- Test coverage: Carbon API callbacks are difficult to unit test

**Window Manager Manual Focus Handling:**
- Files: `Sources/Echo/Models/WindowManager.swift` (lines 150-155)
- Why fragile: Relies on windowDidResignKey to close window. Exception for sheets but other modal scenarios (file dialogs) not handled
- Safe modification: Add comments documenting all modal states that shouldn't close window. Test with SettingsView sheet

## Scaling Limits

**Clipboard History Storage Unbounded:**
- Current capacity: ~5000 items before JSON serialization noticeable (guessing; needs profiling)
- Limit: JSON string concatenation for 10k+ items, no pagination or lazy loading
- Scaling path: Implement pagination in UI (show 100 items, load more on scroll). Backend: switch to SQLite for >5k items

**Memory Usage of Large Images:**
- Current capacity: Can hold hundreds of images in items array + loaded image views
- Limit: Large screenshots (>10MB) cause memory spike; no image compression or thumbnail caching
- Scaling path: Store only thumbnail in memory; load full image on demand. Compress large images on ingest

**Search Filter Recomputes All Items:**
- Current capacity: Smooth at ~1000 items
- Limit: At ~10k items, search becomes noticeably slow due to linear filter + sort
- Scaling path: Build search index (trie or inverted index) for text. Add indexed sort field

## Dependencies at Risk

**Deprecated Carbon Framework Usage:**
- Risk: Carbon APIs (used in HotKeyManager and PasteManager) are deprecated and may be removed in future macOS versions
- Impact: Hot key registration and keyboard simulation will break
- Migration plan: Research replacements - possibly Swift Concurrency friendly APIs in AppKit or third-party library (KeyboardKit?). Add to roadmap for macOS 15+

**SwiftUI View Extraction Limitations:**
- Risk: Large view files (ContentView 693 lines) difficult to refactor due to SwiftUI's Environment/State complexity
- Impact: Hard to test, hard to maintain, performance unpredictable
- Migration plan: Extract sub-views gradually. Consider MVVM layer with dedicated ViewModels for complex views

## Missing Critical Features

**No Data Backup/Export:**
- Problem: History lives only in ~/Library/Application Support/Echo. No way to backup or export
- Blocks: Users cannot migrate to new Mac, backup to cloud, or share snippets

**No Synchronization Between Devices:**
- Problem: History is local-only by design
- Blocks: Cannot access clipboard history on iPad or sync across Macs

**No Application-Level Logging:**
- Problem: All errors use print() statements, no unified logging or log viewer
- Blocks: Users cannot diagnose issues, developer cannot collect crash data

**No Duplicate Content Detection Settings:**
- Problem: Duplicate detection is automatic but not configurable. Some users may want to log every copy
- Blocks: Advanced use cases (tracking copy frequency) impossible

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: HistoryManager.addText() duplicate detection (lines 93-120), pruneOldItems() (lines 164-181), HotKeyManager registration (lines 75-97)
- Files: `Sources/Echo/Models/`
- Risk: Regressions in history management could corrupt user data silently
- Priority: High - duplicate logic and pruning are critical paths

**No Integration Tests:**
- What's not tested: End-to-end flow (clipboard change → capture → save → display → paste)
- Risk: UI changes or model changes can break integration without detection
- Priority: High - but requires UI automation framework (XCTest)

**No Tests for Keyboard Navigation:**
- What's not tested: Arrow key navigation (ContentView.moveSelection), seamless typing search
- Files: `Sources/Echo/Views/ContentView.swift` (lines 112-142)
- Risk: Keyboard behavior regressions go undetected, affects core UX
- Priority: High

**No Image Handling Tests:**
- What's not tested: Image conversion, corruption handling, large image scenarios
- Files: `Sources/Echo/Models/ClipboardMonitor.swift` (lines 45-54), HistoryManager.saveImageToDisk()
- Risk: Image clipboard items could cause crashes or data loss
- Priority: Medium

---

*Concerns audit: 2026-02-19*

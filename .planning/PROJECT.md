# Echo — Clipboard Manager

## What This Is

A macOS clipboard manager that monitors the system clipboard, stores a searchable history of text and images, and lets users quickly paste previous items via a global hotkey. Built with SwiftUI and native Apple frameworks, runs as a menu bar app with zero external dependencies.

## Core Value

Instant, frictionless access to clipboard history — press the hotkey, find what you copied, paste it.

## Requirements

### Validated

- ✓ Monitor system clipboard and capture text/images — existing
- ✓ Persist clipboard history to disk (JSON + image files) — existing
- ✓ Global hotkey to toggle clipboard window — existing
- ✓ Search/filter clipboard items by text — existing
- ✓ Pin items to keep them from expiring — existing
- ✓ Paste selected item into active application via simulated Cmd+V — existing
- ✓ Detect and display source application name — existing
- ✓ Image clipboard support with preview — existing
- ✓ Configurable history retention period — existing
- ✓ Configurable hotkey — existing
- ✓ Status bar menu integration — existing
- ✓ Auto-close on focus loss — existing
- ✓ Duplicate detection (refresh instead of re-add) — existing

### Active

- [x] Fix scroll performance lag when navigating items quickly (stutter + input delay)
- [x] Pinned items go to end of pinned group (not top)
- [ ] Full link preview cards for copied URLs (title, description, thumbnail)
- [ ] Right detail panel color slightly lighter than left panel (visual separation)
- [ ] Gray selection highlight instead of blue (match dark theme)
- [ ] Show source app icon in list rows and detail panel (fallback to default icon)
- [x] Search matches against full clipboard content, not just title/preview

### Out of Scope

- Cloud sync — local-only by design
- iOS/iPadOS companion app — macOS only
- Rich text formatting preservation — plain text and images only
- Plugin/extension system — keep it simple

## Context

- Brownfield project with working clipboard manager already in production use
- SwiftUI + AppKit hybrid, no external dependencies
- Data stored at `~/Library/Application Support/Echo/`
- Existing codebase mapped in `.planning/codebase/`
- App name is "Echo", built with Swift Package Manager

## Constraints

- **Platform**: macOS 14.0+ (Sonoma) — uses SwiftUI 5.9+ features
- **Dependencies**: Zero external packages — Apple frameworks only
- **Permissions**: Requires Accessibility permissions for paste simulation
- **Architecture**: Maintain existing MVM pattern with singleton managers

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| URL metadata fetching for link previews | Need to fetch page title/description/thumbnail from URLs | — Pending |
| App icon retrieval method | Use NSWorkspace/NSRunningApplication to get app icons at copy time | — Pending |
| Gray selection color exact value | Should complement the dark theme without losing visibility | — Pending |

---
*Last updated: 2026-02-19 after initialization*

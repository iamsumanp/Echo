# Requirements: Echo Clipboard Manager

**Defined:** 2026-02-19
**Core Value:** Instant, frictionless access to clipboard history

## v1 Requirements

### Performance

- [ ] **PERF-01**: Scrolling through clipboard items with arrow keys is smooth with no stutter or input delay, even when navigating quickly

### UI Polish

- [ ] **UI-01**: Right detail panel background is slightly lighter than left panel for visual separation
- [ ] **UI-02**: Selected item highlight is gray instead of blue to match dark theme
- [ ] **UI-03**: Source application icon displayed in list rows (small icon per item)
- [ ] **UI-04**: Source application icon displayed in detail panel
- [ ] **UI-05**: Default fallback icon shown when source app icon is unavailable (images keep current preview behavior)

### Clipboard Behavior

- [ ] **CLIP-01**: Pinned items are placed at the end of the pinned group (after existing pins)
- [ ] **CLIP-02**: Copied URLs show full link preview card (page title, description, thumbnail) in detail panel

### Search

- [ ] **SRCH-01**: Search matches against full clipboard content, not just displayed title/preview text

## v2 Requirements

(None deferred)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud sync | Local-only by design |
| iOS companion | macOS only |
| Rich text preservation | Plain text and images only |
| Plugin system | Keep it simple |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERF-01 | Phase 1 | Pending |
| UI-01 | Phase 2 | Pending |
| UI-02 | Phase 2 | Pending |
| UI-03 | Phase 3 | Pending |
| UI-04 | Phase 3 | Pending |
| UI-05 | Phase 3 | Pending |
| CLIP-01 | Phase 1 | Pending |
| CLIP-02 | Phase 4 | Pending |
| SRCH-01 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-19*
*Last updated: 2026-02-19 after initial definition*

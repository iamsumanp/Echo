# Roadmap: Echo Clipboard Manager

**Created:** 2026-02-19
**Phases:** 4
**Requirements covered:** 9/9 ✓

## Phase Overview

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 1 | Core Fixes | Fix scroll performance, pin ordering, and full-content search | PERF-01, CLIP-01, SRCH-01 | 3 |
| 2 | Theme Polish | Match right panel color and fix selection highlight | UI-01, UI-02 | 2 |
| 3 | App Icons | Show source application icons in list and detail views | UI-03, UI-04, UI-05 | 3 |
| 4 | Link Previews | Full card previews for copied URLs | CLIP-02 | 2 |

---

## Phase 1: Core Fixes

**Goal:** Fix scroll performance, pin ordering, and full-content search so the app feels responsive and behaves correctly.

**Requirements:** PERF-01, CLIP-01, SRCH-01

**Plans:** 2 plans

Plans:
- [ ] 01-01-PLAN.md — Fix arrow key stutter (PERF-01) and harden full-content search (SRCH-01)
- [ ] 01-02-PLAN.md — Fix pin ordering: set pinnedDate in togglePin, sort pinned group by pinnedDate ascending (CLIP-01)

**Success Criteria:**
1. User can hold arrow key and scroll through 100+ items without stutter or input delay
2. Pinning an item places it after all existing pinned items (not at the top)
3. Searching for text that appears in clipboard content (but not title) returns matching items

---

## Phase 2: Theme Polish

**Goal:** Unify the visual theme so both panels and selection highlight match the dark aesthetic.

**Requirements:** UI-01, UI-02

**Plans:** 1 plan

Plans:
- [ ] 02-01-PLAN.md — Refine panel background contrast and selection highlight color

**Success Criteria:**
1. Right detail panel has a visibly lighter background than the left list panel
2. Selected item highlight is gray instead of blue

---

## Phase 3: App Icons

**Goal:** Display the source application icon for each clipboard item in both the list and detail views.

**Requirements:** UI-03, UI-04, UI-05

**Success Criteria:**
1. Each clipboard item in the list shows a small icon of the app it was copied from
2. Detail panel shows the source app icon
3. Items without a known source app show a default clipboard icon (image items keep current preview)

---

## Phase 4: Link Previews

**Goal:** Show rich link preview cards for copied URLs with title, description, and thumbnail.

**Requirements:** CLIP-02

**Success Criteria:**
1. Copied URL displays page title, description, and thumbnail in the detail panel
2. Link previews load asynchronously without blocking the UI

---
*Roadmap created: 2026-02-19*
*Last updated: 2026-02-19*

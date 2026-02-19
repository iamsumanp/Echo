# Research: Phase 2 - Theme Polish

**Goal:** Unify the visual theme so both panels and selection highlight match the dark aesthetic.

## Requirements Analysis

### UI-01: Right detail panel background is slightly lighter than left panel
- **Current State:**
    - Left Pane: `.background(Material.ultraThin)` (on top of global `.sidebar` material).
    - Right Pane: `.background(ZStack { Color.white.opacity(0.04) })` (on top of global `.sidebar` material).
- **Observation:** Both use the same base material. The right pane adds a 4% white overlay. This might be too subtle.
- **Implementation:** Increase the white opacity in the right pane to `0.08` or `0.10` to create a clearer visual separation (lighter than the left pane).

### UI-02: Selected item highlight is gray instead of blue
- **Current State:**
    - `rowView` uses `.listRowBackground` with `Color.white.opacity(0.12)` for selected items.
    - Text color becomes `.white` when selected.
- **Observation:** `Color.white.opacity(0.12)` is neutral, but might appear weak or "tinted" depending on the wallpaper (since it's translucent). "Instead of blue" implies avoiding the system accent color.
- **Implementation:**
    - Change the selection background to `Color.white.opacity(0.20)` or `Color.gray.opacity(0.25)` to be more opaque and "solid gray".
    - Ensure no system selection style is leaking through (the current `.listRowBackground` should prevent this, but we'll make the fill more robust).

## File Changes

### Sources/Echo/Views/ContentView.swift

1.  **Right Pane Background:**
    -   Loc: ~Line 86
    -   Change: `Color.white.opacity(0.04)` -> `Color.white.opacity(0.08)` (or `0.1`)

2.  **Selection Highlight:**
    -   Loc: ~Line 175 (in `rowView`)
    -   Change: `Color.white.opacity(0.12)` -> `Color.white.opacity(0.2)` or `Color.gray.opacity(0.25)`.
    -   Recommendation: `Color.white.opacity(0.2)` is safer for dark mode "gray" look without introducing a specific gray hue that might clash.

## Verification Strategy
- **Manual Check:**
    -   Build app.
    -   Compare left vs right panel background brightness.
    -   Select an item and verify the highlight color is a visible gray/white overlay, distinct from the blue accent color used in other parts of the system.

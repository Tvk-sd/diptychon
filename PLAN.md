# PLAN — Issue 13: Panel resize + collapse/expand the right panel

Spec: `.scratch/diptychon-mvp/issues/13-panel-resize-and-toggle.md`.
Branch: `feat/13-panel-resize-toggle`.

## What I understood
1. **Resize** — a draggable divider between the two file panels (today a fixed
   50/50 `HStack`).
2. **Collapse/expand the right panel** — a toolbar button (split-view icon) +
   shortcut hides the right panel (left fills the window) and restores it, keeping
   the right `PanelModel` alive (dir + selection preserved). Active-panel/keyboard
   stay coherent when it's hidden.

## Approach
- **Resize:** wrap the two panels in `HSplitView` (native NSSplitView-backed
  draggable divider). Keep the issue-14 preview pane as a sibling in the outer
  `HStack` so its toggle doesn't reset the file-panel split. Give each panel a
  `minWidth` so the divider can't collapse one to nothing. Split ratio persists
  for the session (HSplitView holds it); across-launches deferred (no cheap SwiftUI
  autosave) — within-session satisfies the AC.
- **Collapse:** `WorkspaceModel.rightPanelVisible` (UserDefaults-persisted,
  default true). The right panel is conditionally included in the `HSplitView`;
  when hidden, only the left remains and fills.
- **Toggle:** toolbar button (`rectangle.split.2x1`) + ⌥⌘S (SwiftUI
  `.keyboardShortcut`, same pattern as the preview toggle).
- **Coherence when hidden:**
  - Setting `rightPanelVisible = false` forces `active = .left` (didSet).
  - Mouse monitor: when hidden, always set `active = .left` (the left panel now
    spans the window).
  - `.switchPanel` (Tab): if right is hidden, **re-open it** and focus it; else
    flip as today.
  - `.copyToInactive` (⌥⌘→): no-op when the right panel is hidden (no visible
    inactive target).

## "Done" = checkable
- Drag the divider → panels resize; ratio holds during the session.
- Toolbar button / ⌥⌘S hides the right panel (left fills) and restores it; the
  restored panel shows the same directory + selection.
- With the right panel hidden: clicks keep active = left; Tab re-opens the right
  panel; ⌥⌘→ does nothing.
- Build green; existing tests still pass; verified on-screen.

## Risks
- HSplitView resets the divider to equal split after a collapse→restore cycle
  (children change) — acceptable (model state preserved; ratio is session polish).
- Two toolbar buttons now (right-panel + preview) — keep icons distinct.

## Progress
- [x] Slice 1 — HSplitView resize + per-panel minWidth (240).
- [x] Slice 2 — rightPanelVisible (registered default true) + toolbar toggle + ⌥⌘S.
- [x] Slice 3 — coherence (active forced left, Tab re-opens, ⌥⌘→ no-op, mouse half).

## Gotchas hit + fixed
- **HSplitView won't drop a conditional child** — toggling `if rightPanelVisible`
  *inside* HSplitView didn't remove the pane. Fix: swap the whole container
  (HSplitView when both visible, the left panel alone when collapsed).
- **`object(forKey:) as? Bool` doesn't read launch args / default-true** — a
  `-rightPanelVisible NO` arg is a string in NSArgumentDomain. Fix: register a
  default (`UserDefaults.register`) + read with `bool(forKey:)` (which honors the
  argument domain — that's how the test forces state).
- 27 tests green (22 unit + 5 UI), incl. `testToggleRightPanel`.

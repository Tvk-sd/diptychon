# 13 — Panel resize + collapse/expand the right panel

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Two pieces of panel-layout chrome:

1. **Resize** — a draggable divider between the left and right panels so the user
   can rebalance the split (today they're a fixed 50/50 `HStack`).
2. **Collapse/expand the right panel** — a toolbar/header button (the standard
   split-view toggle icon, like Finder's/Xcode's sidebar toggle) that hides the
   right panel so the left fills the window, and restores it. Single-panel mode is
   useful when the user just wants one wide list.

## Notes / implementation hints

- `WorkspaceView` currently lays the two `PanelView`s in a fixed split. SwiftUI's
  `HSplitView` gives a native draggable divider (NSSplitView-backed) — likely the
  smallest change for piece 1.
- Add `rightPanelVisible: Bool` (default true) to `WorkspaceModel`; the toggle
  flips it. When hidden, render only the left panel.
- Keep keyboard/active-panel logic coherent when the right panel is hidden: force
  `active = .left`, and make ⌥⌘→ (copy-to-inactive) and Tab degrade gracefully
  (no-op, or Tab re-opens the right panel) rather than acting on a hidden panel.
- Collapsing then restoring must preserve the right panel's directory + selection
  (keep the `PanelModel` alive; just hide its view).
- Persist the split ratio + visibility across launches if cheap (`@AppStorage` /
  `UserDefaults`); at minimum persist within the session.
- Give the toggle a keyboard shortcut consistent with the keymap (e.g. ⌥⌘S or
  similar) via `Keymap`/`AppAction`.

## Acceptance criteria

- [ ] A draggable divider resizes the two panels; the chosen split is retained
      (at least for the session).
- [ ] A toolbar/header button (split-view toggle icon) hides and restores the
      right panel; left panel fills the window when the right is hidden.
- [ ] A keyboard shortcut also toggles the right panel.
- [ ] With the right panel hidden, active-panel + keyboard ops stay coherent
      (active forced left; copy-to-inactive / Tab degrade gracefully).
- [ ] Restoring the right panel preserves its directory + selection.

## Blocked by

- `03-dual-panels-focus`

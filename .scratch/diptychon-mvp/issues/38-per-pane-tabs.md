# 38 — Per-pane tabs

Status: needs-triage (2026-07-02) — drafted from Marta gap analysis
(`context/competitor-benchmark.md` §5). Table-stakes for a dual-pane manager; sizeable
because it touches per-pane state ownership.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Let each pane hold **multiple tabs**, each tab remembering its own folder (and
ideally its own view state). The user opens a new tab on the active pane, switches
tabs, and closes tabs — keeping several working locations a keystroke apart without
losing the other pane.

Marta's model (our reference): "Open as many windows and tabs as you want." Tabs are
per-pane in a dual-pane layout — the classic Commander pattern.

## Notes / design

- **State ownership is the real work.** Today a pane owns one folder + selection +
  sort + filter + display mode. A tab must become the unit that owns that state, and
  the pane owns an ordered list of tabs + an active index. Audit `PanelModel`
  (`Sources/Diptychon/Panel/PanelModel.swift`) before design — this likely means
  extracting a `PanelTab`/`TabState` and having `PanelModel` hold `[Tab]` +
  `activeTab`. **Grep the codebase for direct `panel.folder`/selection access first**
  so the refactor's blast radius is known.
- **What a tab remembers (v1):** folder, selection, sort, filter, and display mode
  (issue 37). Scroll position is a nice-to-have.
- **Interactions to preserve:** copy-to-other-panel (issue 04) targets the *active
  tab* of the inactive pane; drag & drop (06), FSEvents refresh (09), tags filter
  (08), staging (20/30–33) all operate on the active tab. The active-pane/inactive-
  pane focus model (issue 03) is unchanged — tabs live *within* a pane.
- **UI:** a tab strip per pane. Decide placement in plan (top of each pane vs shared
  with the top bar, issue 21). Keep it quiet/native — restraint per positioning.
- **Interactions:** new tab (⌘T), close tab (⌘W — must not close the window when
  tabs remain), next/prev tab (⌃⇥ / ⌃⇧⇥ or ⌘⇧[ / ⌘⇧]). Coordinate bindings with
  issue 28. Consider "open folder in new tab" from context menu / a modifier on open.
- **Empty/last-tab behavior:** closing the last tab in a pane — define it (keep one
  tab minimum, don't leave an empty pane).
- **State persistence (issue 41).** 41 shipped the durable snapshot mechanism and owns
  the save/restore path; its schema is **additive**. When tabs land, extend
  `WorkspaceState`/`PaneState` (`Sources/Diptychon/Panel/WorkspaceState.swift`) so a
  pane persists its **ordered tabs + active index** (each tab's folder + sort — the
  same per-tab state 41 already persists for the single pane today). Restore must apply
  41's unmounted-vs-gone resolution **per tab** (a tab on an ejected drive falls back /
  restores on remount, never a broken tab). This *is* JTBD-1's "tabs are preserved"
  clause — build it into this issue, don't re-defer it.

## Acceptance criteria

- [ ] Each pane can open, switch, and close multiple tabs; each tab remembers its own
      folder + selection + sort + filter + display mode.
- [ ] The active-pane / inactive-pane focus model still works; ops (copy-to-other,
      drag & drop, tag filter, staging) target the correct pane's *active* tab.
- [ ] Keyboard: new tab, close tab, next/prev tab bindings exist; ⌘W closes a tab (not
      the window) when more than one tab is open.
- [ ] Closing the last tab in a pane has defined, non-broken behavior.
- [ ] No regression to single-tab behavior for users who never open a second tab.
- [ ] **Open tabs + active index per pane survive quit + relaunch** (via issue 41's
      snapshot; each tab's folder + sort restored, per-tab unmounted-vs-gone fallback).
      Flips issue 41's deferred "open tabs are restored" AC to done.
- [ ] `context/competitor-benchmark.md` §5 gap row for Tabs flips to ✅.

## Out of scope

- Multiple windows (separate issue if desired — this is tabs *within* a window).
- Tab reordering by drag, tab pinning. (Restoring tabs across restarts is now **in
  scope** — issue 41's mechanism exists; persist via its snapshot, see Notes/AC.)
- Dragging files onto a tab to move-into-that-folder (nice-to-have, later).

## Blocked by

- `03-dual-panels-focus` (the pane focus model tabs live inside) — done.
- Touches `PanelModel` broadly; coordinate with `21-unified-top-bar` (strip
  placement) and `28-keyboard-command-expansion` (bindings).

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive).
- `Sources/Diptychon/Panel/PanelModel.swift` (state that becomes per-tab).
- `37-multi-column-brief-display-mode` (display mode is per-tab state).
- `41-state-persistence` (owns the snapshot; extend it to persist tabs — see Notes).

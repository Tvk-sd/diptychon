# 21 — Unified top bar: breadcrumb, back/forward, search

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A single window-level **top bar above both panels** that reflects the **Active
Panel**: back / forward / up navigation, a clickable **breadcrumb** of the active
panel's path, and a **search field** that filters the active panel's current
folder. It's the foundational chrome the later features plug into (time-travel,
view switcher). It replaces the per-panel path dropdown (issue 15) and the
per-panel Filter field, and moves the hidden toggle + tag filter into the bar
(acting on the active panel).

```
┌─ Top bar (acts on the Active Panel) ──────────────────────────────┐
│  ‹  ›  ⌃   Home › Projects › Diptychon     🔍 Search…   👁  🏷   [ ⟦slots⟧ ] │
├──────────────────────────┬────────────────────────────────────────┤
│  Projects   (folder label)│  Archive   (folder label)              │  ← minimal per-panel label
│  Name        Size   Date  │  Name        Size   Date               │
│  …                        │  …                                     │
```

## Decisions (resolved with the user)

- **Search = promote the current filter** to a prominent search field that narrows
  the active panel's *current folder* instantly. **Recursive subfolder search is a
  separate later issue.**
- **Layout = single global bar** acting on the Active Panel (not per-panel chrome).
- **Scope = bar + breadcrumb + back/forward + search now**, with clean insertion
  points for a view-switcher and time-travel — **no dead placeholder buttons**.
- **Keep both panel locations visible:** each panel keeps a *minimal* current-folder
  label (just the name), since a global bar otherwise hides the inactive panel's
  location (important in a dual-panel app).

## Acceptance criteria

- [ ] A top bar spans above both panels and **acts on the Active Panel**:
      back, forward, up; breadcrumb; search; hidden toggle; tag filter.
- [ ] **Breadcrumb** shows the active panel's path as clickable segments; clicking a
      segment navigates the active panel there. (Replaces issue 15's dropdown; keep
      Go to Folder ⇧⌘G reachable.)
- [ ] **Back / forward** navigate the active panel's own history (per-panel stack);
      disabled when there's no history. **Up** goes to the parent.
- [ ] **Search field** filters the active panel's current folder live (replaces the
      old per-panel Filter). Recursive search is out of scope here.
- [ ] **Switching the Active Panel updates the bar** to that panel's path, history
      state, search text, and toggles.
- [ ] Each panel still shows its **current folder name** so the inactive panel's
      location is visible.
- [ ] **Reserved, clean slots** for a view-switcher and a time-travel control exist
      in the bar's layout, but neither feature is built here (no dead buttons).
- [ ] No regression to navigation, selection, hidden toggle, tag filter, or the
      file-list polish (issue 17).

## Notes

- **Supersedes** issue 15's per-panel path dropdown — fold the breadcrumb behaviour
  into the bar; keep `PathInput` / Go to Folder (⇧⌘G).
- `PanelModel` gains a **back/forward history stack** (push on navigate; back/forward
  move a cursor without re-pushing). `go(to:)` / `navigate(into:)` / `navigateUp()`
  feed it.
- The bar reads/writes the **Active Panel** via `WorkspaceModel.activeModel`; active
  switches must re-render the bar.
- Search field is a text field → same keyboard caveat as Filter/rename (⌘-shortcuts
  pass through while it's focused).
- **Future hooks:** time-travel (issue 18) adds a control to the bar over the active
  panel; the view-switcher lands when a 2nd view mode exists (its own issue). The
  command palette (issue 19, ⌘K) stays separate — global *commands*, not in-folder
  find.

## Suggested slices

1. **Bar scaffold + breadcrumb + up.** Top bar container; move the path display out
   of the panel header into the bar (reflects the active panel, breadcrumb
   navigates); add the minimal per-panel folder label.
2. **Back/forward history.** `PanelModel` history stack + the ‹ › buttons (enabled
   state, per-panel).
3. **Search + remaining controls.** Promote the filter into the bar's search field;
   move hidden toggle + tag filter into the bar; remove the old per-panel header row.

## Blocked by

- Builds on `15-path-bar-go-to-folder`, `16-left-sidebar`, `17-file-list-polish`
  (all merged). No blockers.

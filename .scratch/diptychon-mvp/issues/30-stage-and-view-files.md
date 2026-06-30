# 30 — Stage files and view them in a panel

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

The tracer-bullet foundation for the virtual staging panel: a session-only, ordered
collection of files the user has gathered from **different folders**, plus the ability
to swap a panel to show that collection and back.

End-to-end behavior:

- The user selects files in any folder and **adds the active selection to a staging
  set** via a keyboard chord (proposed `⌘⇧S` — verify no collision in the keymap first).
- A keyboard chord (proposed `⌘⇧B`) **toggles the active panel** between its directory
  and the staging view. Toggling back is instant — the panel keeps its directory.
- The staging view lists all staged items together even though they live in different
  folders. The panel header reads "Staging".
- An empty staging view shows a placeholder ("Drag here or ⌘⇧S to add").

This slice introduces the staging collection, a new `PanelSource` for it (modeled on
the existing directory source per ADR 0003), and a per-item "missing" flag that later
slices use to grey/exclude stale entries. Operating on the set, the full add surface
(context menu, drag, header button), and remove/clear are intentionally **out of scope
here** — see issues 31–33.

## Acceptance criteria

- [ ] The user can add the active selection (from any folder) to a staging set.
- [ ] A chord toggles the active panel to show the staged set and back; the panel's
      original directory is restored on toggle-off.
- [ ] Staged items from multiple different folders appear together in one panel.
- [ ] An empty staging view shows a clear add/drag placeholder.
- [ ] Staged items carry a "missing" flag (set when the file no longer exists on load),
      even though greying/exclusion behavior lands in issue 33.
- [ ] Unit coverage: the staging source loads items across folders; a since-deleted URL
      comes back flagged missing.

## Blocked by

- `03-dual-panels-focus` (existing; provides the active-panel and dual-panel frame).
- Relies on the `PanelSource` seam from `01-panel-lists-local-folder` (ADR 0003).

## Related

- ADR 0003 (`PanelSource`).

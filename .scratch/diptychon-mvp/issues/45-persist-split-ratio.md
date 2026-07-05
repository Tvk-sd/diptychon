# 45 — Persist the pane split ratio

Status: needs-triage (2026-07-03) — split off from issue 41 (state persistence), the
one AC item deferred there. Number 45 (44 was the previous max across all branches).

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make the left/right pane **split ratio survive a restart**, completing issue 41's
"window layout is restored" AC. The persistence mechanism already exists — this issue
only removes the blocker that stopped 41 from wiring it.

## Why it was deferred (the blocker)

Issue 41 ships a versioned snapshot (`WorkspaceState`) that already reserves an optional
`splitRatio: Double?` field — currently always nil. The blocker is the **view**, not the
store: the panel container is a SwiftUI `HSplitView` (`Sources/Diptychon/Panel/
WorkspaceView.swift`, `panels`), which exposes **no bindable/readable divider fraction**.
There's nothing to read on save or set on restore. Wiring it means replacing `HSplitView`
with a container whose split fraction *is* app state.

Deferred under issue 41's governing principle — **core-restore reliability outranks
breadth** — a rock-solid folder/sort/staging restore was not worth risking the working,
tested panel container (issue 13) for the least-valuable restored item.

## Scope

- Replace `HSplitView` with a custom two-pane split: a `GeometryReader` + a draggable
  divider bound to a stored fraction (0…1), honoring the existing per-pane `minWidth`
  (180) and the right-panel-hidden branch (issue 13 — `HSplitView` can't drop a
  conditional child; the replacement must preserve that toggle).
- Hold the fraction as observable state on `WorkspaceModel`; feed it into
  `WorkspaceState.splitRatio` on save and apply it on restore. The snapshot field and
  the debounced-save trigger are already in place — extend `saveState()` / the
  observation tracking to include it.
- Clamp a restored fraction to valid bounds (both panes ≥ min width at the current
  window size) so a narrow window can't restore a broken/zero-width pane
  (issue 41 principle: a restore that confuses is worse than no restore).

## Acceptance criteria

- [ ] Dragging the divider, quitting, and relaunching restores the same split.
- [ ] The right-panel-hidden layout (issue 13) still works — left pane full width, no
      stray divider; toggling back restores the divider.
- [ ] A restored fraction that would violate a pane's min width at the current window
      size is clamped, never applied broken.
- [ ] No regression to divider drag feel / min widths vs the current `HSplitView`.
- [ ] Flips issue 41's "window layout (split ratio…) restored" AC to done.

## Out of scope

- Persisting the *right auxiliary pane* (preview/staging) width — separate if wanted.
- Multiple split configurations / saved layouts (issue 41 out-of-scope: no timeline).

## Related

- `41-state-persistence` (owns the snapshot + save/restore; `splitRatio` field reserved).
- `13-panel-resize-and-toggle` (the divider + right-panel toggle this must preserve).
- `Sources/Diptychon/Panel/WorkspaceView.swift` (`panels` — the `HSplitView` to replace).

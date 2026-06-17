# 06 — Drag & drop

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make drag & drop always available, routed through the same Operations as the
keyboard paths so it inherits progress, collision resolution, and undo. Support
dragging within a Panel, between the two Panels, and to/from external apps
(Finder etc.).

## Acceptance criteria

- [ ] Dragging files between the two Panels moves/copies them via the existing
      Operations (with progress, collision handling, undo).
- [ ] Dragging within a Panel into a subfolder works.
- [ ] Dragging files out to Finder (and other apps) works, and dragging files in
      from external apps works.
- [ ] Drop destination resolves to where the user drops (see `/CONTEXT.md` →
      Destination).

## Blocked by

- `05-remaining-file-operations`

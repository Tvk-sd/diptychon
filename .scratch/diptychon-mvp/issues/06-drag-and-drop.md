# 06 — Drag & drop

Status: done — merged (PR #7)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make drag & drop always available, routed through the same Operations as the
keyboard paths so it inherits progress, collision resolution, and undo. Support
dragging within a Panel, between the two Panels, and to/from external apps
(Finder etc.).

## Acceptance criteria

- [x] Dragging files between the two Panels moves/copies them via the existing
      Operations (with progress, collision handling, undo). (Routes through
      `WorkspaceModel.handleDrop` → the same `write(kind:)` path; default copy.)
- [x] Dragging within a Panel into a subfolder works. (Folder rows are drop
      targets with a hover highlight.)
- [x] Dragging files out to Finder (and other apps) works, and dragging files in
      from external apps works. (NSTableView drag source + `.fileURL` drop.)
- [x] Drop destination resolves to where the user drops (folder row → into it;
      background → Panel's current directory).

Note: drag defaults to **copy** (safe + undoable); move-on-drag (⌘-drag) is a
later refinement. Required the **ADR 0002 AppKit escape hatch** — see below.

## Blocked by

- `05-remaining-file-operations`

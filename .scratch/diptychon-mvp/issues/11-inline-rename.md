# 11 — Inline single-file rename

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Rename a single file or folder in place, the way Finder does: select a row and
press Return (or slow-click the name) to edit the name inline in the list, commit
on Return, cancel on Escape. Distinct from batch rename (issue 07, which is a
sheet over a multi-selection). Reuses the `RenameOperation` from 04/07 so the
edit is a single undoable step (⌘Z).

Requested by the user during issue 07 review ("rename by clicking on it just
like in Finder").

## Acceptance criteria

- [ ] Pressing Return on a single selected row makes its name editable in place.
- [ ] Slow-click (click an already-selected row's name) also begins editing.
- [ ] Commit on Return writes via a `RenameOperation` (undoable with ⌘Z);
      Escape cancels with no change.
- [ ] A name collision is rejected (no overwrite) with clear feedback.
- [ ] Editing the name leaves the extension intact by default.

## Notes

- The file list is AppKit `NSTableView` (ADR 0002 hatch) — use the native
  editable cell (`NSTextField` becomes first responder), which is the clean path.

## Blocked by

- `07-batch-rename`

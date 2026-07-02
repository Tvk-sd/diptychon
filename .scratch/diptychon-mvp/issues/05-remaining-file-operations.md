# 05 — Remaining file operations + clipboard

Status: done — merged (PR #6)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Add the rest of the core operations, each reusing the Command/undo spine from 04:
Move, Delete-to-Trash, Duplicate, and Create folder/file. Add the Mac clipboard
gesture: ⌘C marks the selection, ⌘V pastes into the **Active Panel** (distinct
from the Commander gesture, which targets the Inactive Panel — see `/CONTEXT.md`
→ Destination).

## Acceptance criteria

- [x] Move, Delete-to-Trash, Duplicate, Create folder/file all work as reversible
      Commands (undo/redo via the 04 spine). (`MoveOperation`, `TrashOperation`,
      `CreateOperation`; Duplicate reuses `CopyOperation`.)
- [x] Delete goes to the macOS Trash, not a hard delete. (`FileManager.trashItem`;
      revert restores from Trash.)
- [x] ⌘C / ⌘V copies into the Active Panel's directory. (Real `NSPasteboard`;
      ⌥⌘V pastes-as-move, Finder convention.)
- [x] All writing operations route through the same collision resolution as 04.
      (Generalized `write(kind:)` → shared collision dialog.)

Notes: New File uses ⌃⌘N (macOS has no native new-file key). Create makes an
`untitled …` name since single-file rename isn't built yet (rename = issue 07).

## Blocked by

- `04-command-undo-spine-copy-to-inactive`

# 05 — Remaining file operations + clipboard

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Add the rest of the core operations, each reusing the Command/undo spine from 04:
Move, Delete-to-Trash, Duplicate, and Create folder/file. Add the Mac clipboard
gesture: ⌘C marks the selection, ⌘V pastes into the **Active Panel** (distinct
from the Commander gesture, which targets the Inactive Panel — see `/CONTEXT.md`
→ Destination).

## Acceptance criteria

- [ ] Move, Delete-to-Trash, Duplicate, Create folder/file all work as reversible
      Commands (undo/redo via the 04 spine).
- [ ] Delete goes to the macOS Trash, not a hard delete.
- [ ] ⌘C / ⌘V copies into the Active Panel's directory.
- [ ] All writing operations route through the same collision resolution as 04.

## Blocked by

- `04-command-undo-spine-copy-to-inactive`

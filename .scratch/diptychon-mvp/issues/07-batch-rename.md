# 07 — Batch rename

Status: ready-for-human

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A batch-rename sheet operating on the Active Panel's selection, modeled as a
reversible Operation (reuses the 04 spine). Transformations for the MVP:
find & replace (plain text), sequential numbering, prefix/suffix, case change.
A live before/after preview table shows the result before anything is written,
and collisions (two files mapping to the same name) are detected and blocked.
Regex is out of MVP scope (→ v1.1).

## Acceptance criteria

- [x] Renames the Active Panel selection using find&replace, numbering,
      prefix/suffix, and case change. (Sheet modeled on Finder: Replace Text /
      Add Text / Name + Number / Case.)
- [x] A before/after preview updates live as the user adjusts the rule; nothing
      is written until confirmed.
- [x] Name collisions are detected and the rename is blocked with a clear
      indication of which entries collide. (Colliding rows red; Rename disabled.)
- [x] The whole batch is undoable as one Operation (⌘Z). (`RenameOperation`,
      two-phase to handle intra-batch swaps.)

Opened via ⌘R (app has no other use for it; macOS has no standard rename key).
Inline single-file rename split out to issue 11 (user request).

## Blocked by

- `04-command-undo-spine-copy-to-inactive`

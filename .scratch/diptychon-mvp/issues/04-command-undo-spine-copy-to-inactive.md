# 04 — Command/undo spine + "copy to Inactive Panel" gesture

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Establish the reversible-Operation architecture (ADR 0004) by shipping the first
real operation through it: the Commander gesture ⌥⌘→ / ⌥⌘← copies the Active
Panel's selection straight into the Inactive Panel's directory. The operation
runs with a progress indicator and cancel, resolves collisions before writing
(overwrite / rename / skip), and is undoable via a multi-level undo/redo stack
(⌘Z / ⇧⌘Z). Hotkeys are driven by a data table (action → key) from the start so a
remapping UI can be added later.

This slice is the spine: later operations (05) and batch rename (07) reuse it.

## Acceptance criteria

- [ ] Every operation is modeled as a Command that knows its inverse (ADR 0004).
- [ ] ⌥⌘→ / ⌥⌘← copies the Active Panel selection into the Inactive Panel.
- [ ] Long copies show progress and can be cancelled.
- [ ] Collisions are detected and resolved before writing (overwrite / rename /
      skip); the overwrite choice states it is not undoable.
- [ ] ⌘Z undoes and ⇧⌘Z redoes across multiple steps.
- [ ] Hotkeys resolve through an action→key table, not hard-coded key checks.

## Blocked by

- `03-dual-panels-focus`

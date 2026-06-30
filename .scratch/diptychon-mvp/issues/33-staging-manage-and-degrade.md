# 33 — Staging: manage the set + degrade gracefully

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

Let the user curate the staged set without touching files on disk, and make stale
entries degrade gracefully.

End-to-end behavior:

- **Remove individual items** from the staging set (hover/context menu) and a
  **clear-all**. Removing from staging never moves, deletes, or otherwise touches the
  file on disk — it only edits the in-memory set.
- A staged file that has since **moved or been deleted** is shown **greyed** and is
  **excluded from operations** (it can't be a source for copy/move/trash/tag). This uses
  the per-item missing flag introduced in issue 30.

## Acceptance criteria

- [x] Items can be removed from the staging set individually and via clear-all.
      (⌫ unstages; right-click "Remove from Staging" for mouse; ✕ header button clears all.)
- [x] Remove and clear-all never touch the underlying files on disk.
- [x] Staged items that no longer exist are greyed and excluded from operation sources.
      (`FileItem.isMissing` → dimmed row + filtered out of `operationSourceURLs`. Re-validated
      on app reactivation, since the scattered staged files carry no FSEvents watch.)

## Blocked by

- `30-stage-and-view-files`
- Best sequenced after `32-operate-on-staged-set` (so missing-item exclusion can be
  verified against real operations).

## Related

- ADR 0003 (`PanelSource`), ADR 0004 (reversible Operations).

# 25 — Double-click opens the entire selection, not the clicked row

Status: needs-triage — found during copy-overwrite QA (2026-06-26); root-cause path and desired behaviour both need a call

## Parent

`.scratch/diptychon-mvp/PRD.md`

## Problem

With several rows selected in a Panel, double-clicking one row opens **all**
selected files rather than the row that was double-clicked. Reproduced after a
batch rename: select multiple files, ⌘R to rename them ("name 2", "name 3", …),
then double-click one of the still-selected rows — every selected file opens.

Likely path (needs confirming): the double-click action routes into
`WorkspaceModel.openSelection()` (`Sources/Diptychon/Panel/WorkspaceModel.swift:189`),
which loops over `activeModel.selectedItems` and opens each non-directory item.
So a double-click acts on the whole current selection instead of collapsing the
selection to the clicked row first (an unmodified click on a row should normally
reduce the selection to that single row before opening).

This is **pre-existing** — unrelated to the copy-overwrite fix or the
OperationCoordinator refresh refactor it was found alongside. No data risk.

## Open question (triage)

Is open-all actually wrong? macOS Finder *does* open every selected item when you
double-click within a multi-selection. The surprising part here is that an
unmodified double-click doesn't first **collapse the selection to the clicked
row**. Decide the intended behaviour before building:

- **A** — double-click collapses to the clicked row, then opens just it (matches
  the "a plain click selects one row" expectation).
- **B** — keep open-all (Finder-like) for an existing multi-selection, but ensure
  a plain single click on a row still reduces selection to one.

## What to build (pending the decision above)

- Confirm the double-click → `openSelection()` wiring in `NSTableViewFileList`
  (the `table.target` / double-action path, see ~`Sources/Diptychon/Panel/NSTableViewFileList.swift:46`).
- Implement the chosen behaviour so a double-click opens/navigates the **clicked**
  row (Option A) or so plain-click selection semantics are correct (Option B).
- Directory rows should still navigate-into on double-click (single-item case in
  `openSelection()` already does this).

## Acceptance criteria

- [ ] Intended behaviour (A or B) decided and recorded here.
- [ ] Double-clicking a row in a multi-selection no longer opens unintended files.
- [ ] Single-click selection semantics on a row remain correct (reduces to one row).
- [ ] Double-clicking a folder still navigates into it.

## Notes

Found via manual QA on `improve-codebase-architecture`. Verifying the fix needs a
manual app run (and likely a UI test); double-click disambiguation already has
timing logic around `NSEvent.doubleClickInterval` in `NSTableViewFileList`.

# PLAN — Issue 04: Operation/undo spine + copy-to-Inactive

Issue: `.scratch/diptychon-mvp/issues/04-command-undo-spine-copy-to-inactive.md`
ADR 0004. Branch: `feat/04-operation-undo-spine`

## Naming
CONTEXT.md domain term = **Operation** (avoid "command"). Protocol named
`Operation` even though issue/ADR title say "Command".

## Build
- `Operation` protocol: `title`, `isUndoable`, `apply(progress:)`, `revert()`.
- `CopyOperation` (class): copies sources into dest dir; records `createdURLs`
  for revert; `didOverwrite` -> `isUndoable=false`; collision resolution
  (overwrite/rename/skip); off-main via `Task.detached`; progress by count;
  cancellable (`Task.checkCancellation`, cleanup partial).
- `OperationCoordinator` (@MainActor @Observable): undo/redo stacks, `run`,
  `undo`, `redo`, `running` (title+fraction), `cancel`.
- `Keymap`: `AppAction` (copyToInactive/undo/redo), `KeyChord` (Character +
  modifiers), default table. Data-driven (remap UI later).
- `PanelModel`: add `refresh()` + `selectionURLs`.
- `WorkspaceView`: coordinator; general `onKeyPress` -> keymap dispatch
  (copy/undo/redo) bubbling under panel nav; collision `confirmationDialog`
  (overwrite warns "not undoable"); progress overlay w/ Cancel; reload inactive
  panel on finish.

## Acceptance
- [ ] every op = Operation w/ inverse
- [ ] ⌥⌘→/← copies active selection into inactive dir
- [ ] long copy: progress + cancel
- [ ] collisions resolved pre-write; overwrite says not undoable
- [ ] ⌘Z / ⇧⌘Z multi-level
- [ ] hotkeys via action→key table

## Verify
Build + screenshot. User test: select files, ⌥⌘→ copy, collision dialog,
progress, ⌘Z undo / ⇧⌘Z redo.

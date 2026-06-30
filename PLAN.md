# PLAN

_No active task._

Last task: **issue 32 (operate on the staged set)** — done, user-verified, on branch
`feat/32-operate-on-staged-set` (not pushed).
- The Staging pane can hold **operation focus** (`stagingFocused`): copy/move/trash/tag
  then source from the Staging selection → active file panel as destination, undoable
  via the existing spine (no new operation type). Focus auto-on when the pane opens,
  cleared by clicking a file panel. No focus border (user found it confusing).
- Two source→dest paths: clipboard (⌘C → click folder → ⌘V) and Commander gesture (⌥⌘→/←).
- **Delete semantics:** ⌫ in staging **unstages** (non-destructive, `StagingStore.remove`,
  pulled forward from #33); ⌘⌫ **trashes the real file** (undoable). User confirmed keep.
- 98 unit tests green.

Grab next: **#33** — clear-all + a mouse affordance for unstaging, and the missing-item
**greying + exclusion** (the `isMissing` flag already ships from #30; needs the render +
operation-source filtering).

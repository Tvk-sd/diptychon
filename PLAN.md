# PLAN

_No active task._

Last task: **issue 18 (operation history) — Tier 1 undo toast** — done, user-verified,
on branch `feat/18-operation-history` (not pushed). PM challenged the feature's value;
reframed around the JTBD ("did I just break my folders?"), right-sized into tiers,
shipped the cheap one.
- Transient HUD on every ⌘Z/⇧⌘Z — "Undone — Moved 12 items". `OperationCoordinator`
  emits `onUndoRedoToast` (no stack refactor); `WorkspaceModel` shows a self-dismissing
  toast; `WorkspaceView` floats a capsule over the bottom bar. Overwrites stay honest.
- **Tier 2 (scrubbable timeline + undo-to-here) deferred** — build on a demand signal;
  explicitly a flat list, NOT a git graph (undo is linear). Recorded in issue 18.
- 105 unit tests green.

Backlog remaining: **#22** performance baseline measurements (evidence, no UI), and
**#18 Tier 2** if appetite shows. See tracker Status table.

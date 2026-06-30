# PLAN

_No active task._

Last task: **issue 25 (double-click opens entire selection — bug)** — triaged (Option A)
then fixed + user-verified, on branch `fix/25-double-click-clicked-row` (not pushed).
- Double-click now opens/navigates the **clicked row only**, via the table's native
  `doubleAction` reading `clickedRow` (new optional `onActivate` on the list seam →
  `WorkspaceModel.activate(_:in:)`). Replaced the `WorkspaceView` mouse-monitor
  `clickCount == 2 → openSelection()` branch — selection- and timing-independent.
- `Return`/`↩` unchanged (opens whole selection). 102 unit tests green (+ `ActivateTests`).

Open issues remaining: **#29** Kind/Type column (small, AFK-ready), **#18** operation
history / time-travel undo (large, differentiation bet), **#22** performance baseline
measurements (evidence, no UI). See `PROJECT-TRACKER.md` Status table.

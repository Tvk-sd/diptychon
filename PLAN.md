# PLAN

## 🔴 CRITICAL — fix first: memory/CPU runaway in issue 21 slice 1

**Symptom:** the unified-top-bar work (branch `feat/21-unified-top-bar`, WIP commit)
makes Diptychon balloon to **~15 GB RAM and crash the machine** ("Dein System hat
keinen Programmspeicher mehr"). Under XCUITest the UI suite jumped from ~75s to
**410s**, a single test took 138s, and `testPinFolder` fails as a *symptom* (app
hung/slow), not a logic bug.

**Status:** slice 1 is committed to the branch ONLY (NOT merged). `main` is clean
and safe (issue 11 is the latest merged work). **Do not run / merge the branch
build until this is fixed.**

**Prime suspect — `WindowMinWidth` (in `WorkspaceView.swift`):** it's the only code
that calls `window.setFrame`, and slice 1 moved its `.background(WindowMinWidth…)`
onto the new outer `VStack { TopBarView; Divider; content }`. Likely an unbounded
feedback loop: `updateNSView` → `DispatchQueue.main.async { apply }` → `apply`
`setFrame`s when `current < minWidth` → triggers relayout → `updateNSView` again →
… spawning closures every cycle. It also has an **infinite retry timer** when
`view.window == nil` (`asyncAfter(0.1){ apply }`) with no cap.

**Investigation plan (next session):**
1. Confirm the loop cheaply: add a counter/`print` in `WindowMinWidth.apply` and
   `TopBarView.body`; or just temporarily delete `.background(WindowMinWidth(…))`
   from `WorkspaceView` and see if the runaway stops. **Do NOT run the full UI
   suite** until confirmed — it crashed the machine. Test a single launch while
   watching Activity Monitor.
2. Likely fix: make `WindowMinWidth` idempotent + loop-proof — give it a Coordinator
   that remembers the last-applied `minWidth`; only `setFrame` when `minWidth`
   actually *increased* (not every update), with a tolerance; cap/stop the
   nil-window retry. Or drop grow-on-update and only set `contentMinSize` once.
3. Re-verify slice 1 visually + a single UI test before resuming slices 2–3.

**Secondary suspects (less likely):** the slow-click `asyncAfter` timers in
`FileTableView.mouseDown` (one-shot, cancelled — probably fine); a render storm in
`TopBarView` only if #1's relayout loop drives it.

## Issue 21 — remaining slices (after the leak is fixed)
- Slice 1 (branch): top bar + breadcrumb + Up + per-panel minimal label. **Built but
  blocked by the leak above.**
- Slice 2: back/forward history (`PanelModel` stack + ‹ › buttons).
- Slice 3: promote Filter → search in the bar; move hidden + tag controls into the
  bar; drop the old per-panel header row.

## Backlog
- **Ready for agent:** 12 (custom tag color registration).
- **Needs triage:** 18 (time-travel undo), 19 (command palette ⌘K),
  20 (virtual staging), 22 (performance baseline).

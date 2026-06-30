# PLAN

_No active task._

Last task: **issue 31 (staging add surface) + surfacing pivot to the auxiliary pane** —
done, user-verified ("looks very well"), on branch `feat/31-staging-add-surface` (not pushed).
- Live testing reversed **Option A** (in-place panel source-swap) → **A′**: Staging now
  renders in the right auxiliary pane (where Preview sits), mutually exclusive with
  Preview, toggled from the bottom bar (tray icon + 32pt divider). Both file panels stay
  directories — preserves the diptych. Add via ⌘⇧S / context-menu / drag, all auto-reveal
  the pane. Data layer (`StagingStore`/`StagingSource`) unchanged; staging pane reuses
  `PanelFileList` via a dedicated `stagingPanel: PanelModel`.
- Also fixed a layout bug: empty-state `ContentUnavailableView`s now force-fill height
  (they were letting the panel column collapse and drop the path bar).
- 95 unit tests green. Issue 20/31/32 notes updated for A′; exclusivity dropped from #32.

Grab next (issue 20 backlog): **#32** operate-on-set (Staging-pane selection → active
file panel as destination; undoable spine) and **#33** manage+degrade (remove/clear,
grey missing via the `isMissing` flag).

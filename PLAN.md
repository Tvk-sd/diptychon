# PLAN

_No active task._

Last task: **issue 33 (staging — manage & degrade), the final slice** — done, user-verified,
on branch `feat/33-staging-manage-degrade` (not pushed). This completes the virtual
staging feature (#30→#33).
- **Missing items:** `FileItem.isMissing` rows are dimmed (NSTableView alpha) and filtered
  out of `operationSourceURLs` (copy/move/trash/tag skip ghosts). Re-validated on app
  reactivation (`windowDidBecomeActive`) since the scattered staged files carry no FSEvents
  watch — external Finder deletes grey out when you return to the app.
- **Manage:** ⌫ unstages; right-click "Remove from Staging" (replaces "Add to Staging" inside
  the pane); ✕ header button clears all. All non-destructive.
- 100 unit tests green.

**Staging feature complete.** Branches: `feat/30…` → `feat/31…` → `feat/32…` → `feat/33…`,
all local, none pushed. Open: push + PRs for the stack (parent issue #20), then #33 → merge.

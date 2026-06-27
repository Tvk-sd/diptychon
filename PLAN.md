# PLAN

_No active task._

Last task: **issue 12 (custom tag color registration) — closed `wontfix`** (decision
2026-06-27). Resolved via AC3's documented-fallback clause rather than forging
Finder's undocumented, Finder-owned custom-tag→color store (fragile, version-
sensitive, risks desyncing the user's real tags for a cosmetic different-app gain).
The file xattr layer already round-trips name+color; the 7 built-in colors are
unaffected. Artifacts: `docs/adr/0005-no-custom-tag-color-registration.md`, issue 12
decision block, `PROJECT-TRACKER.md` issue-12 entry. No code or system writes.
Branch `feat/12-custom-tag-color-registration` (off `main`) — docs-only.

Next when picked (see `PROJECT-TRACKER.md`): the actual tag features users see —
**#26** tag-filter-menu dot grey, **#27** tags column in file list — both
`ready-for-agent`. Or the backlog: #18 / #20 / #22.

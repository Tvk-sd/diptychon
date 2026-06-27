# PLAN

_No active task._

Repo is clean as of 2026-06-27: **`main` only** (local + remote), **zero open PRs**,
working tree clean, `main` builds + unit tests green. The stacked chain was landed via
merge commits — PR #27 (`improve-codebase-architecture`) then PR #28
(`feat/28-keyboard-commands`) — and all stale branches were pruned (local + remote):
`design-experiments`, `feat/dim-hidden-files`, `feat/file-type-icons`,
`fix/23-uitest-panel-identifiers`, `improve-codebase-architecture`,
`backup/21-pre-history-cleanup`, and the obsolete `chore/local-app-build-script`
(its `reinstall.sh` combined three now-merged branches).

Ready to start the next issue from a clean `main`. Open candidates (see
`PROJECT-TRACKER.md`): #19 command palette (⌘K — every new keyboard command would
populate it), #25/#26/#27-tracker QA items, #12/#18/#20/#22 backlog.

Reminder: the `.xcodeproj` is XcodeGen-generated and gitignored — run
`xcodegen generate` after pulling before building.

# HANDOFF — Diptychon

_Updated: 2026-06-22. Xcode migration done (PR #9, awaiting merge)._

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit). MVP in progress — **7 of 10 issues done and merged to `main`;
Xcode migration in PR #9.**

## ✅ DONE: Xcode migration (PR #9 — merge bottom-up, then start issue 08)
Migrated off the no-Xcode SwiftPM + hand-wrapped `.app` setup to a real Xcode
project (Xcode 26.5) on branch `chore/xcode-migration`. Both
`xcodebuild -scheme Diptychon build` and `... test` pass.
- **XcodeGen**: `project.yml` is the source of truth; `.xcodeproj` is gitignored,
  regenerate with `xcodegen generate` (`brew install xcodegen` one-time).
- Bundle workarounds reverted: `App/main.swift` + AppDelegate gone → clean
  `@main struct DiptychonApp: App`. Kept the `NSEvent` monitor + `NSTableViewFileList`.
- `Resources/Diptychon.entitlements` (sandbox OFF, ADR 0001). Ad-hoc signing.
- `DiptychonUITests` target + smoke test (launch, assert two panels) — green.
- Removed `Package.swift`, `scripts/run.sh`, hand-wrapped `.app`.

## ⏭️ NEXT TASK: merge PR #9, then issue 08 (Finder tags)
1. Merge PR #9 into `main` (no stacked children → safe to delete branch).
2. Start issue 08 (real Apple Finder tags, round-trip) — `.scratch/diptychon-mvp/issues/`.
   Now write XCUITests to self-verify instead of the manual log loop.

Why the migration mattered: issue 10 (FDA onboarding) wants a properly signed
bundle; packaging (ADR 0001: Releases + Homebrew Cask) needs Xcode; and XCUITest
ends the manual test round-trips that dominated issues 01–07.

## Git state
- Branch: `main`. Clean. Issues **01–07 merged** (PRs #1,#4,#3,#5,#6,#7,#8).
- Only `main` exists locally + remote. Repo: https://github.com/Tvk-sd/diptychon
- Build today (pre-Xcode): `./scripts/run.sh [release]` (SwiftPM + hand-wrapped
  `.app`; debug or release).

## Progress
| # | Title | State |
|---|-------|-------|
| 01 | Panel lists a local folder | ✅ merged |
| 02 | Navigation, sort, hidden, type-ahead | ✅ merged |
| 03 | Dual panels + focus | ✅ merged |
| 04 | Operation/undo spine + copy-to-Inactive | ✅ merged |
| 05 | Remaining file ops + clipboard | ✅ merged |
| 06 | Drag & drop (+ AppKit NSTableView list) | ✅ merged |
| 07 | Batch rename | ✅ merged |
| 08 | Finder tags (real Apple tags, round-trip) | ⬜ next feature after migration |
| 09 | QuickLook / Open-with / FSEvents | ⬜ |
| 10 | Full Disk Access onboarding | ⬜ (wants signed bundle → do after Xcode) |
| 11 | Inline single-file rename (split from 07) | ⬜ backlog |

## Architecture (current)
- `App/DiptychonApp.swift` — `@main struct DiptychonApp: App` with
  `WindowGroup { WorkspaceView() }`. (Post-migration; AppDelegate hack removed.)
- `Panel/WorkspaceModel.swift` — `@Observable`; owns both `PanelModel`s,
  `OperationCoordinator`, active side, clipboard, drag handling, rename. `NSEvent`
  monitor (in WorkspaceView) is the keyboard authority.
- `Panel/WorkspaceView.swift` — two PanelViews; key+mouse monitors; collision
  dialog; progress overlay; rename sheet.
- `Panel/PanelView.swift` — header (Up/path/Hidden/Filter) + list; active border.
- `Panel/PanelModel.swift` — `directory`, cached `visibleItems` (filter+sort),
  selection, nav, refresh.
- `Panel/NSTableViewFileList.swift` — AppKit list (selection/drag/drop/sort).
  `Panel/FileListView.swift` — protocol + `PanelFileList` typealias (→ NSTableView)
  + SwiftUI `TableFileListView` reference impl.
- `Operations/` — `Operation` protocol; `CopyOperation`+`detectCollisions`
  (Operation.swift); `MoveOperation`/`TrashOperation`/`CreateOperation`/
  `RenameOperation` (FileOperations.swift); `RenameRule` (pure); `Keymap`
  (data-driven, matched on NSEvent); `OperationCoordinator`.
- `Panel/BatchRenameSheet.swift` — Finder-style rename UI.

## Hard-won gotchas (don't rediscover)
- **CLT compiler+SDK must match** — a mismatch broke all builds (fixed by
  reinstalling CLT). Xcode bundles a matched toolchain → this goes away.
- **QWERTZ/non-US keyboards**: match letter hotkeys by *character*, not hardware
  keyCode (keyCode 6 = `y` on German). Arrows/Tab by keyCode (layout-independent).
- **SwiftUI `Table` can't combine row-drag with reliable click-selection** — took
  the ADR 0002 AppKit `NSTableView` hatch. Prefer AppKit for list work.
- **NSViewRepresentable two-way selection binding fights itself**: `updateNSView`
  echoing a stale binding wiped multi-select. Track `lastPublished`; only push
  binding→table on external changes.
- Window opened on a secondary display / wrong Space under the hand-wrapped
  bundle — should disappear with the `@main App` migration.

## How to work here (agent constraints)
- The agent **cannot drive mouse/keyboard** today. Verify by: (a) unit-test pure
  logic via a `swiftc` temp-dir harness (see how Operations were tested);
  (b) launch + screenshot (find window via a tiny `CGWindowListCopyWindowInfo`
  helper, then `screencapture -x -R<x,y,w,h>`); (c) scripted user test while the
  binary logs to `/tmp/dipt.log` (run the binary directly, not via `open`; note
  stdout is buffered — use `setbuf(stdout, nil)` or stderr for live logs).
- **After Xcode**: write XCUITests instead — the agent CAN run those.
- Issues live as markdown under `.scratch/diptychon-mvp/issues/`. Update the
  `Status:` line + check acceptance boxes; close PLAN into PROJECT-TRACKER.
- Merge PRs **bottom-up, no `--delete-branch` on a PR that has a stacked child**
  (it auto-closes the child — happened to #2).

## To resume
1. Merge PR #9 (Xcode migration) into `main`.
2. `xcodegen generate` (regenerate the gitignored `.xcodeproj`), then
   `xcodebuild -scheme Diptychon -destination 'platform=macOS' build` to confirm.
3. Start issue 08 (Finder tags) — now with XCUITests for self-verification.

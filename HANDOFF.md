# HANDOFF — Diptychon

_Updated: 2026-06-22. Xcode migration + issue 07 QA fixes all merged to `main`._

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit). MVP in progress — **7 of 10 issues done; Xcode migration +
two issue-07 QA fixes merged to `main`.**

## ✅ DONE: Xcode migration (PR #9, merged)
Migrated off the no-Xcode SwiftPM + hand-wrapped `.app` setup to a real Xcode
project (Xcode 26.5). Both `xcodebuild -scheme Diptychon build` and `... test` pass.
- **XcodeGen**: `project.yml` is the source of truth; `.xcodeproj` is gitignored,
  regenerate with `xcodegen generate` (`brew install xcodegen` one-time).
- Bundle workarounds reverted → clean `@main struct DiptychonApp: App`. Kept the
  `NSEvent` monitor + `NSTableViewFileList`.
- `Resources/Diptychon.entitlements` (sandbox OFF, ADR 0001). Ad-hoc signing.
- Test targets: `DiptychonTests` (unit) + `DiptychonUITests` (UI). Removed
  `Package.swift`, `scripts/run.sh`, hand-wrapped `.app`.

## ✅ DONE: issue 07 QA fixes (PRs #10, #11, merged)
Found by manually testing batch rename with both panels on the same folder:
- **#10** — rename/duplicate/create only refreshed the active panel; the inactive
  panel showing the same dir stayed stale until ⌘Z. Now all ops call `refreshBoth()`.
  Guarded by `testRenameRefreshesBothPanelsOnSameDir` (UI test).
- **#11** — on case-insensitive APFS a case-only rename (`a.txt`→`A.txt`) was
  wrongly flagged as a collision. `renameCollisionIndices` is now volume-aware.
  Guarded by `DiptychonTests/RenameCollisionTests` (5 unit tests).

## ⏭️ NEXT TASK: issue 08 (Finder tags)
Start issue 08 (real Apple Finder tags, round-trip) — `.scratch/diptychon-mvp/issues/`.
Use XCUITests + unit tests to self-verify instead of the manual log loop.

Why the migration mattered: issue 10 (FDA onboarding) wants a properly signed
bundle; packaging (ADR 0001: Releases + Homebrew Cask) needs Xcode; and the test
targets end the manual round-trips that dominated issues 01–07.

## Git state
- Branch: `main`. Clean. Issues **01–07 merged**; migration + QA fixes merged
  (PRs #9, #10, #11). Only `main` exists locally + remote.
- Repo: https://github.com/Tvk-sd/diptychon
- Build/run: `xcodegen generate` then `open Diptychon.xcodeproj`, or
  `xcodebuild -scheme Diptychon -destination 'platform=macOS' build|test`.

## Progress
| # | Title | State |
|---|-------|-------|
| 01 | Panel lists a local folder | ✅ merged |
| 02 | Navigation, sort, hidden, type-ahead | ✅ merged |
| 03 | Dual panels + focus | ✅ merged |
| 04 | Operation/undo spine + copy-to-Inactive | ✅ merged |
| 05 | Remaining file ops + clipboard | ✅ merged |
| 06 | Drag & drop (+ AppKit NSTableView list) | ✅ merged |
| 07 | Batch rename | ✅ merged (+ QA fixes #10, #11) |
| 08 | Finder tags (real Apple tags, round-trip) | ⬜ NEXT |
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
1. `xcodegen generate` (regenerate the gitignored `.xcodeproj`), then
   `xcodebuild -scheme Diptychon -destination 'platform=macOS' test` to confirm green.
2. Start issue 08 (Finder tags) — write unit tests for the pure tag round-trip
   logic and XCUITests for the UI, instead of the manual log loop.

## Dev-loop gotcha (post-migration)
The app keeps a fixed bundle id, so launching never starts a second copy — macOS
re-activates whatever instance is already running. After any rebuild, quit the
running app first (⌘Q / `pkill -f Diptychon`) or changes look like they didn't
take. (A stale pre-migration instance bit us once during issue-07 QA.)

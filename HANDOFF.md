# HANDOFF — Diptychon

_Updated: 2026-06-19. Session paused to install Xcode (system update required)._

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit). MVP in progress — **7 of 10 issues done and merged to `main`.**

## ⏭️ NEXT TASK: migrate to Xcode (decided, not started)
We agreed to move off the no-Xcode SwiftPM setup to a real Xcode project before
issues 08–10. **Xcode is being installed now.** When `xcodebuild -version` works:

```
! sudo xcode-select -s /Applications/Xcode.app
! sudo xcodebuild -license accept
```

Then do this migration on a branch `chore/xcode-migration` (small, reversible PR):
1. Generate `Diptychon.xcodeproj` wrapping the existing `Sources/Diptychon/` files
   (no logic rewrite). Consider XcodeGen (`brew install xcodegen` + `project.yml`)
   or `swift package generate-xcodeproj` is deprecated — prefer a hand-written
   project or XcodeGen.
2. **Revert the bundle workarounds**: `App/main.swift` + `App/DiptychonApp.swift`
   (AppDelegate building an NSWindow + NSHostingController) → a clean
   `@main struct DiptychonApp: App { WindowGroup { WorkspaceView() } }`.
   These hacks existed ONLY because we hand-wrapped a SwiftPM binary into a
   `.app`. **KEEP**: the `NSEvent` key/mouse monitor in WorkspaceView (legit) and
   the `NSTableViewFileList` (ADR 0002, legit).
3. Add entitlements + Info.plist (app sandbox OFF per ADR 0001; prepare for
   issue 10 Full Disk Access). App category, bundle id `com.diptychon.app`.
4. Add an **XCUITest** target + first smoke test (launch, assert two panels
   exist). This is the payoff — it lets the agent self-verify clicks/drag/
   selection instead of the "you test, I read logs" loop we used for 01–07.
5. Update PROJECT-TRACKER build/run section (`xcodebuild` / open in Xcode).
   Verify with `xcodebuild -scheme Diptychon build` before opening the PR.

Why: issue 10 (FDA onboarding) wants a properly signed bundle; packaging
(ADR 0001: Releases + Homebrew Cask) needs Xcode; and XCUITest ends the manual
test round-trips that dominated this build.

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
- `App/` — `main.swift` + `DiptychonApp.swift` (AppDelegate → NSWindow +
  NSHostingController). **To be replaced by `@main App` in the migration.**
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
1. Finish Xcode install → `xcodebuild -version` works.
2. Tell the agent: **"continue from HANDOFF.md — do the Xcode migration."**
3. After migration merges, proceed to issue 08 (Finder tags).

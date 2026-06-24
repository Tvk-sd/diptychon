# HANDOFF — Diptychon

_Updated: 2026-06-24. 10-issue MVP complete (08–10 merged: PRs #12/#13/#14).
Post-MVP: issue 14 inline preview pane merged (PR #15). Backlog: 11 (inline
rename), 12 (tag sidebar color), 13 (panel resize/collapse), 15 (path bar)._

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit). MVP in progress — **7 of 10 issues merged; Xcode migration +
two issue-07 QA fixes merged to `main`; issue 08 underway.**

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

## ✅ DONE: issue 08 (Finder tags) — merged (PR #12)
Real Apple Finder tags via the `_kMDItemUserTags` xattr, round-trip with Finder.
Spec: `.scratch/diptychon-mvp/issues/08-finder-tags.md`. Built in vertical slices,
TDD where pure. **All 5 slices committed locally, not pushed:**
- **Slice 1** — `FinderTag` model + `FinderTagCodec` (xattr binary-plist
  `"name\nColorIndex"` ↔ tags). `Operations/FinderTag.swift`. 7 unit tests
  (incl. a real Finder-written sample as fixture).
- **Slice 2 (AC1)** — read tags into `FileItem` (`LocalDirectorySource`, only
  paying the per-file `getxattr` when batched `tagNames` says a file is tagged);
  display up to 3 color dots + “+N” in the name cell (`NameCellView` /
  `FinderTagDotsView` in `NSTableViewFileList.swift`). Tooltip/AX carry names.
- **Slice 3 (AC2)** — ⌘T opens `TagPickerSheet` over the Active selection;
  tapping a tag toggles it across the whole selection as one undoable
  `SetTagsOperation` (`Operations/TagOperations.swift`), reflected live + in
  Finder. Whole row is the hit target (verified with a real mouse click).

- **Slice 4 (AC4)** — filter the Active Panel to a chosen tag. `PanelModel.tagFilter`
  applied via a pure, unit-tested `PanelModel.applyFilters` (text + tag); header
  tag menu lists the tags present in the folder (toggle to set, "All Tags" to
  clear), cleared on navigation. `PanelView.tagFilterMenu`.
- **Slice 5 (AC3)** — create a new tag + pick from tags in use. `TagPickerSheet`
  gained a new-tag composer (name + built-in color, applied via `toggleTag` = one
  undoable op) and a "custom tags in use" section (`WorkspaceModel.customTagsInUse`)
  to re-apply existing tags.

**Scoped follow-up (not a blocker):** Finder's *sidebar* only colors a brand-new
custom-named tag once it's registered in Finder's separate, undocumented system
tag store. We write the tag **name + color correctly to the file xattr** (so the
file's dot is right and it round-trips), but a never-before-seen custom tag may not
appear in Finder's sidebar until Finder itself sees it. Split per the PLAN scope
call — open a follow-up issue if full sidebar parity is wanted.

Tests: **26 green** (23 unit + 3 UI). The picker UI test asserts the file's real
tag xattr, proving the Finder round-trip (not just in-app state). New this round:
5 `PanelFilterTests` for the tag/text filter.

## Gotcha learned this session (issue 08)
SwiftUI under XCUITest: a `.plain` Button's hit area for *synthetic* clicks is the
rendered content, not the framed row — but a real pointer respects `.contentShape`.
So "the UI test can't click it" ≠ "users can't." Assert against on-disk state
(the xattr) rather than the accessibility tree for robust, meaningful UI tests.

## Git state
- Branch: **`feat/08-finder-tags`** (off `main`). All 5 slices committed locally,
  **not yet pushed**; no PR open. `main` has issues 01–07 + PRs #9/#10/#11.
- Repo: https://github.com/Tvk-sd/diptychon
- Build/run: `xcodegen generate` then `open Diptychon.xcodeproj`, or
  `xcodebuild -scheme Diptychon -destination 'platform=macOS' build|test`.
  (Regenerate the gitignored `.xcodeproj` after pulling or adding files.)

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
| 08 | Finder tags (real Apple tags, round-trip) | ✅ done on branch — all 4 ACs; pending UX check + PR |
| 09 | QuickLook / Open-with / FSEvents | ✅ merged (PR #13) |
| 10 | Full Disk Access onboarding | ✅ merged (PR #14) — **MVP complete** |
| 11 | Inline single-file rename (split from 07) | ⬜ backlog |
| 12 | Custom tag color registration / Finder sidebar (split from 08) | ⬜ backlog |
| 13 | Panel resize + collapse/expand right panel | ✅ merged (PR #16) |
| 14 | Inline preview / inspector pane (raised during 09) | ✅ merged (PR #15) |
| 15 | Path bar / Go to Folder (raised during 10) | ✅ merged (PR #17) |

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

## How to work here (agent verification toolkit)
Preferred order, cheapest first:
- **Unit tests** (`DiptychonTests`, `@testable import Diptychon`) for pure logic —
  fast, deterministic. Where behavior depends on disk (xattr, collisions), write
  to a temp dir and assert real state.
- **XCUITests** (`DiptychonUITests`) for UI flows. Assert against **on-disk state**
  (e.g. the tag xattr) rather than the accessibility tree where possible — robust
  and proves real effects. Note the SwiftUI/XCUITest `.plain`-button hit-area
  gotcha above: click rendered content, not empty row space.
- **Screenshot** a running build: find the window via `CGWindowListCopyWindowInfo`,
  then `screencapture -x -R<x,y,w,h>`.
- **Real input injection** (used this session): a small Swift `CGEvent` script can
  post real mouse clicks + ⌘-key chords to the running app — useful to verify
  behavior XCUITest's synthetic clicks misreport (e.g. full-row click). Get the
  window rect first, compute coordinates, click, then assert on-disk state.
- Always **quit the running app before relaunching a rebuild** (see dev-loop
  gotcha below) — macOS re-activates the stale instance otherwise.

- Issues live as markdown under `.scratch/diptychon-mvp/issues/`. Update the
  `Status:` line + check acceptance boxes; close PLAN into PROJECT-TRACKER.
- Merge PRs **bottom-up, no `--delete-branch` on a PR that has a stacked child**
  (it auto-closes the child — happened to #2).

## To resume (issue 08)
1. `git checkout feat/08-finder-tags`; `xcodegen generate`;
   `xcodebuild -scheme Diptychon -destination 'platform=macOS' test` → 26 green.
2. **UX check** the running build (all 4 ACs): per-panel header tag menu filters;
   ⌘T picker toggles built-in colors, creates new tags, re-applies custom tags.
3. **Push branch + open PR.** Then close PLAN.md into PROJECT-TRACKER.
4. **Follow-up issue (optional):** custom-color Finder *sidebar* registration via
   Finder's undocumented system tag store (the only deferred piece of AC3).

## Dev-loop gotcha (post-migration)
The app keeps a fixed bundle id, so launching never starts a second copy — macOS
re-activates whatever instance is already running. After any rebuild, quit the
running app first (⌘Q / `pkill -f Diptychon`) or changes look like they didn't
take. (A stale pre-migration instance bit us once during issue-07 QA.)

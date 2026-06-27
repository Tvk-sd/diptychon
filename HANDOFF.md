# HANDOFF — Diptychon

_Updated: 2026-06-26. 10-issue MVP complete; post-MVP issues 11–21 built.
**Current: architecture deepening on branch `improve-codebase-architecture`
(off `main`), pushed — all 5 deepenings (#1–#5) + a data-loss fix shipped. Issue
21 PR #21 also still open.** Full per-issue history in `PROJECT-TRACKER.md`._

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit).

## CURRENT STATE (2026-06-26) — architecture deepening (`improve-codebase-architecture`)
Branch **`improve-codebase-architecture`** (off `main`), pushed, tree clean, **61
tests green** (quit the running app before `test` — bundle-id collision; force-kill +
confirm a new pid, see `transferable-learnings.md` §12). A `/improve-codebase-architecture`
review found 5 deepening candidates; the HTML report was temp-only, so
`PROJECT-TRACKER.md` (architecture-review section) is the durable record. Shipped on
this branch:
- **#1 — one settle hook for Panel refresh** (`OperationCoordinator.onOperationSettled`):
  collapsed 9 per-call `refreshBoth` closures into one hook wired in
  `WorkspaceModel.init`; undo/redo inherit it; removed the dead `refresh:` parameter
  strand. `OperationCoordinatorTests` (refresh wiring had no test surface before).
- **#3 — inject the Panel Source factory**: `PanelModel` takes
  `makeSource: (URL, Bool) -> PanelSource` (default builds the real
  `LocalDirectorySource`), turning ADR-0003's one-adapter hypothetical seam into a real
  one. `FakeSource` + `PanelSourceInjectionTests` drive a whole Panel with no
  filesystem. No behavior change.
- **#4 — extract `SelectionEchoGuard`**: the AppKit↔SwiftUI selection echo rule was
  two ad-hoc Coordinator fields + two guards ~120 lines apart (the selection-thrash
  logic, untestable). Pulled into a pure `SelectionEchoGuard` (echo suppression +
  reentrancy); Coordinator keeps only the imperative table I/O. `SelectionEchoGuardTests`.
  Behavior unchanged, user-verified live (multi-select hold, nav-clears).
- **Data-loss fix** (found in QA): pasting a file into its own folder + Overwrite
  destroyed it (`dest == src`); `CopyOperation` now treats self-overwrite as a no-op.
  `CopyOverwriteTests` incl. the real `NSPasteboard` round-trip. User-verified live.
- **#2 — unify modal flags into `presentedSheet`**: four independent modal flags
  collapsed into one `Sheet?` enum (`.collision`/`.rename`/`.tags`/`.goToFolder`) —
  one value ⇒ exactly one modal, the invariant now structural. All four modals
  user-verified live. (Narrow cut; the broader router/state split stays a mirage.)
- **#5 — extract pure `compileVisible`**: lifted `PanelModel`'s base→filter→sort
  pipeline into a pure static function. `VisibleItemsTests`. No behavior change.

**All 5 deepening candidates done.** 70 tests green. New learnings:
`context/transferable-learnings.md` **§12** (verify through the real call path, not a
synthetic test or stale process) and **§13** (steer refactors by fitness functions, not
a north-star). QA filed: **#25** (double-click opens whole selection), **#26** (tag
filter menu dot grey), **#27** (tags column) — all needs-triage / ready-for-agent.

**To resume:** open a PR for the branch (it's a full reviewable sweep). Issue 21 PR
#21 also still open to merge.

## PRIOR STATE (2026-06-25) — issue 21, unified top bar
Branch **`feat/21-unified-top-bar`** (off `main`), **PR #21 open**, pushed, tree
clean, all tests green (quit the running app before `test` — bundle-id collision).
Slices 1–3 + a redesign + fixes, all user-verified in the running app:
- **Slice 1** top bar (Up + clickable breadcrumb) — incl. the breadcrumb runaway
  fix (bounded `pathComponents`, not a `deletingLastPathComponent()` loop).
- **Slice 2** per-panel back/forward history (⌘[ / ⌘] + ‹ ›), `NavigationHistoryTests`.
- **Redesign** bar scoped to the panel column; full-width title-bar divider;
  sidebar tint; square active ring; Filter moved into the bar; Go-to-Folder button
  replaced by the sidebar field (⇧⌘G still opens the sheet).
- **Slice 3** recursive file **Search** (sidebar field) → results in the active
  panel; `RecursiveSearch` bounded ≤1000 matches / ≤100k scanned, off-main +
  cancellable; `SearchTests`.
- **Fixes** — both the §11 content-blind-geometry-router trap: clicks on the bar
  Filter, and on the sidebar/preview, no longer steal/flip the active panel
  (monitor measures from `contentLayoutRect`, reassigns only inside the panels' x-range).

**To resume / finish issue 21:** review + merge PR #21. Deferred niceties (own
follow-ups): show each search result's location (relative path; needs a Table
column); ⇧⌘G could focus the sidebar field instead of the redundant sheet.

**New learning this session:** `context/transferable-learnings.md` **§11** — routing
by geometry is content-blind, and a coordinate-space mismatch fails silently.

_Older milestones below are historical; `PROJECT-TRACKER.md` is the canonical log._

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
- Branch: **`feat/21-unified-top-bar`** (off `main`), **pushed**, **PR #21 open**.
  (Older branches 08/11/16/17 may still have pending PRs — see PROJECT-TRACKER.)
- Repo: https://github.com/Tvk-sd/diptychon
- Build/run: `xcodegen generate` then `open Diptychon.xcodeproj`, or
  `xcodebuild -scheme Diptychon -destination 'platform=macOS' build|test`.
  (Regenerate the gitignored `.xcodeproj` after pulling or adding files.)
- Local app build: `./reinstall.sh` builds the **combined** app
  (`design-experiments` + `feat/file-type-icons` + `fix/23-uitest-panel-identifiers`)
  into `/Applications` via a throwaway worktree. Re-run after changing any of those
  branches. See issue 24 (`.scratch/diptychon-mvp/issues/`) for why they aren't merged
  yet — `design-experiments` won't compile without `fix/23`.

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
| 11 | Inline single-file rename (split from 07) | ✅ done on branch `feat/11-inline-rename` — ⌘R / slow-click, user-verified; PR pending |
| 12 | Custom tag color registration / Finder sidebar (split from 08) | ⬜ backlog |
| 13 | Panel resize + collapse/expand right panel | ✅ merged (PR #16) |
| 14 | Inline preview / inspector pane (raised during 09) | ✅ merged (PR #15) |
| 15 | Path bar / Go to Folder (raised during 10) | ✅ merged (PR #17) |
| 16 | Left sidebar (places + pinned folders) | ✅ merged (PR #18) |
| 17 | File-list polish (data-driven display) | ✅ merged (PR #19) |
| 18 | Operation history / time-travel undo | ⬜ needs-triage (differentiation bet) |
| 19 | Command palette (⌘K) | ⬜ needs-triage (differentiation bet) |
| 20 | Virtual staging panel | ⬜ needs-triage (differentiation bet) |
| 21 | Unified top bar (breadcrumb, back/forward, search) | ✅ done on branch, PR #21 open — slices 1–3 + redesign, user-verified |

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

## To resume
See **CURRENT STATE** at the top — active work is issue 21 (PR #21 open, review +
merge). `git checkout feat/21-unified-top-bar`; `xcodegen generate`;
`xcodebuild -scheme Diptychon -destination 'platform=macOS' test` (quit any running
app first). Per-issue history + outcomes: `PROJECT-TRACKER.md`.

## Dev-loop gotcha (post-migration)
The app keeps a fixed bundle id, so launching never starts a second copy — macOS
re-activates whatever instance is already running. After any rebuild, quit the
running app first (⌘Q / `pkill -f Diptychon`) or changes look like they didn't
take. (A stale pre-migration instance bit us once during issue-07 QA.)

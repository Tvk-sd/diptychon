# Diptychon — Project Tracker

Dual-panel macOS file manager. MVP PRD: `.scratch/diptychon-mvp/PRD.md`.

## Build & run
Real Xcode project (Xcode 26.5). The `.xcodeproj` is generated from `project.yml`
by [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is **gitignored** —
regenerate it after pulling or editing `project.yml`.
```
brew install xcodegen          # one-time
xcodegen generate              # (re)create Diptychon.xcodeproj from project.yml
open Diptychon.xcodeproj       # or build/test from the CLI:
xcodebuild -scheme Diptychon -destination 'platform=macOS' build
xcodebuild -scheme Diptychon -destination 'platform=macOS' test    # runs XCUITests
DIPTYCHON_DIR=/path            # env override for the initial folder (read by WorkspaceView)
```
Signing: ad-hoc / "Sign to Run Locally" (no Apple Developer team needed); app
sandbox OFF via `Resources/Diptychon.entitlements` (ADR 0001). Notarization /
hardened runtime deferred to issue 10.

XCUITest target `DiptychonUITests` lets the agent self-verify the UI (launch +
assert state) instead of the manual "you click, I read logs" loop used for 01–07.

_History: 01–07 were built with Command Line Tools + SwiftPM and a hand-wrapped
`.app` (no Xcode). Migrated to Xcode on 2026-06-22 (branch `chore/xcode-migration`).
The CLT compiler/SDK-mismatch hazard from that era is gone — Xcode bundles a
matched toolchain._

### Issue 04 outcome (2026-06-18)
Reversible-`Operation` spine (ADR 0004): `Operation` protocol + `CopyOperation`
(records created URLs for revert; overwrite = not undoable), `OperationCoordinator`
(undo/redo stacks, progress, cancel), data-driven `Keymap`. Commander gesture
⌥⌘→/← copies Active selection into Inactive Panel; collision dialog
(overwrite/keep-both/skip) pre-write; ⌘Z/⇧⌘Z multi-level. Keyboard owned by an
`NSEvent` local monitor (a focused `Table` swallows arrow keys otherwise); active
Panel set by which window-half was clicked; double-click-to-open also via the
monitor. User-verified end to end.

Bugs found + fixed this slice (good lessons):
- **QWERTZ keyboard**: matching ⌘Z by hardware keyCode 6 = `y` on German layout.
  Fix: match letters by character, arrows/Tab by keyCode.
- **Single-click selection eaten** by a `.onTapGesture(count: 2)` on the Name
  cell. Fix: no tap gesture; double-click via mouse monitor; `Table` keeps native
  single-click select.
- **Active-panel switching** can't derive from selection changes (re-clicking an
  already-selected row fires nothing). Fix: `leftMouseDown` monitor sets active by
  window half.
- `visibleItems` recomputed every render -> cache it (recompute on filter/sort/
  contents change only).

### Issue 05 outcome (2026-06-18)
Remaining core operations on the 04 spine: `MoveOperation`, `TrashOperation`
(`trashItem`, revert restores from Trash), `CreateOperation` (folder/file,
`untitled …`); Duplicate reuses `CopyOperation` into the same dir. Real
`NSPasteboard` clipboard: ⌘C / ⌘V (copy into Active) / ⌥⌘V (move into Active,
Finder convention); ⌘⌫ Trash, ⌘D Duplicate, ⇧⌘N New Folder, ⌃⌘N New File.
Collision flow generalized to any copy/move (`write(kind:)`). All new ops
unit-tested vs temp dirs; user-verified end to end.

### Issue 06 outcome (2026-06-18)
Drag & drop, routed through the same `write(kind:)` Operations (free progress,
collision dialog, undo). Drag between Panels, into subfolders (with hover
highlight), and to/from Finder. **Took the ADR 0002 AppKit escape hatch**:
SwiftUI `Table` can't combine row-drag with reliable single-click selection, so
`PanelFileList` now aliases `NSTableViewFileList` (NSViewRepresentable over
NSTableView). Only the list layer changed; `FileListView` protocol unchanged.
This also pre-empts the 50k-row perf trigger. Drag defaults to copy (move-on-drag
deferred). `WorkspaceModel.write` generalized to target any directory.

**Lesson:** SwiftUI `Table` fought us on input across issues 03/04/06 (focus,
tap, drag all swallow clicks). AppKit `NSTableView` is the right home for the
file list. Prefer it for future list work.

### Issue 07 outcome (2026-06-18)
Batch rename on the Active selection, one undoable `RenameOperation` (two-phase
temp→final so intra-batch swaps don't collide). Sheet modeled on Finder, four
exclusive modes: Replace Text / Add Text / Name + Number / Case. Live
before/after preview; collisions flagged red + Rename disabled. Opened with ⌘R.
Pure `RenameRule` + collision detection unit-tested.

Bug fixed: **NSTableView multi-select was wiped by two-way selection binding** —
`updateNSView` ran on every re-render and `syncSelection` echoed a stale binding
back onto the table, clearing in-progress ⌘/⇧-click selection. Fix: track
`lastPublished`; only push binding→table on *external* changes (e.g. nav), never
echo what the table just published. (General lesson for NSViewRepresentable
two-way bindings.)

Split out: inline single-file rename → issue 11 (Finder-style click/Return).

### Gotchas (no-Xcode / SwiftPM bundle) — RESOLVED by Xcode migration (2026-06-22)
- ~~**SwiftUI needs `NSHostingController`, not the `App`/`WindowGroup` lifecycle.**
  Under a hand-wrapped `.app`, SwiftUI windows render but get NO input events.~~
  Gone on real Xcode: `App/DiptychonApp.swift` is now a plain `@main struct ... : App`
  with `WindowGroup { WorkspaceView() }`; input routes correctly. (`main.swift` +
  `AppDelegate` deleted.)
- ~~Window may open on an external display / wrong Space~~ — the manual primary-screen
  placement hack is gone with the hand-wrapped bundle; `WindowGroup` + `.defaultSize`.
- Localized folder names (`Musik` vs `Music`) only show once app is localized;
  `localizedNameKey` falls back to raw on-disk name otherwise.

## Status
| Issue | Title | State |
|-------|-------|-------|
| 01 | Panel lists a local folder (tracer bullet) | ✅ done, PR #1 |
| 02 | Panel navigation, sort, hidden toggle, type-ahead | ✅ done, PR #2 |
| 03 | Dual panels + focus switching | ✅ done, PR #3 |
| 04 | Operation/undo spine + copy-to-Inactive | ✅ done, PR #5 |
| 05 | Remaining file operations + clipboard | ✅ done, PR #6 |
| 06 | Drag & drop (+ AppKit list hatch) | ✅ done, PR #7 |
| 07 | Batch rename | ✅ done, PR #8 (+ QA fixes #10 refresh-both-panels, #11 case-only rename) |
| — | **Xcode migration** | ✅ done 2026-06-22, PR #9 |
| 08 | Finder tags (real Apple tags, round-trip) | 🚧 in progress — `feat/08-finder-tags`, slices 1–3 (AC1,AC2) done; 4–5 left |
| 09–10 | QuickLook/Open-with/FSEvents, FDA onboarding | not started |
| 11 | Inline single-file rename | ⬜ backlog (split from 07) |

## Decision (2026-06-19): migrate to Xcode before issues 08–10
The no-Xcode SwiftPM + hand-wrapped `.app` setup carried us through 01–07 but
cost many manual test round-trips and forced bundle/window workarounds. Moving to
a real Xcode project to gain: XCUITest (agent-driven UI verification),
entitlements/signing (needed for issue 10 Full Disk Access), packaging (ADR 0001:
Releases + Homebrew Cask), previews/debugger/Instruments. Migration is low-risk —
code is plain Swift; the `@main App` lifecycle replaces the AppDelegate/NSWindow
workaround, while the `NSEvent` monitor and `NSTableView` list stay. Full plan in
HANDOFF.md “NEXT TASK”.

### Issue 08 progress (2026-06-23) — Finder tags, slices 1–3 (branch `feat/08-finder-tags`)
Real Apple Finder tags via the `com.apple.metadata:_kMDItemUserTags` xattr (a
binary-plist array of `"name\nColorIndex"` strings; index 6 = Red, confirmed
against a Finder-written sample). Built in vertical slices, TDD where pure:
- **Slice 1** — `FinderTag` + `FinderTagCodec` (pure encode/decode), 7 unit tests.
- **Slice 2 (AC1)** — read tags into `FileItem` (only `getxattr` when the batched
  `tagNames` flags a file as tagged); show ≤3 color dots + “+N” in the name cell
  (`NameCellView`/`FinderTagDotsView`), names in tooltip/accessibility.
- **Slice 3 (AC2)** — ⌘T `TagPickerSheet` over the selection; toggling a tag is one
  undoable `SetTagsOperation` (ADR 0004), reflected live + in Finder.
- Remaining: **slice 4 (AC4)** filter Active Panel by tag; **slice 5 (AC3)** new
  tag + system list — custom-color *sidebar* parity may split to a follow-up
  (needs Finder's undocumented system tag store).
- Tests: 18 green (15 unit + 3 UI); picker UI test asserts the file's real xattr.

**Gotcha (SwiftUI + XCUITest):** a `.plain` Button's hit area for *synthetic*
clicks is the rendered content, not the framed row; a real pointer respects
`.contentShape`. Verified full-row clicking with a `CGEvent` injection script and
asserted the on-disk xattr. Lesson: test UI against on-disk state, not the AX tree.

### Issue 01 outcome (2026-06-17)
Tracer bullet works: app launches to one Panel listing a real directory
(name/size/date) via SwiftUI `Table`. Two ADR seams shipped:
- **ADR 0003** `PanelSource` protocol + `LocalDirectorySource` (loads off-main
  via `Task.detached`, prefetches resource keys).
- **ADR 0002** `FileListView` protocol + `TableFileListView`, swappable via the
  `PanelFileList` typealias.
Verified by screenshot on home dir and on a 50k-file folder (loaded off-thread,
virtualized render, no block/crash). Subjective scroll-smoothness left for human.

Open polish (non-blocking): empty files render "Zero KB"; folders show no size
by design.

### Issue 02 outcome (2026-06-17)
Single Panel now navigable: enter dir (Return / double-click), up (⌘↑ / button),
column-header sort (toggle reverses), Hidden checkbox, type-ahead Filter field.
`PanelModel` v2 owns `directory: URL` and rebuilds `LocalDirectorySource` per
load (cancels in-flight task on rapid nav). `FileListView` protocol widened to
carry selection + sortOrder bindings + `onActivate` (still impl-agnostic, ADR
0002). `FileItem` gained non-optional `sizeForSort`/`dateForSort` (Optional isn't
Comparable). Verified interactively by user.

### Issue 03 outcome (2026-06-17)
`WorkspaceView` renders two Panels side by side, each owning its own `PanelModel`
(-> independent dir, nav, selection). Active Panel tracked via `@FocusState`,
shown with an accent border; Tab flips active, clicking a panel activates it. Nav
keys gated by `isActive`. `PanelView` no longer owns its model (parent owns).
`URL.startDirectory` moved to WorkspaceView. Window widened to 1100x620.
Verified interactively by user (Tab + click focus, independent nav, per-panel
selection).

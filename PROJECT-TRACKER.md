# Diptychon — Project Tracker

Dual-panel macOS file manager. MVP PRD: `.scratch/diptychon-mvp/PRD.md`.

## Build & run
No Xcode installed — built with Command Line Tools via SwiftPM.
```
./scripts/run.sh          # swift build → wrap minimal .app → launch
DIPTYCHON_DIR=/path open --env DIPTYCHON_DIR=/path Diptychon.app   # open a specific folder
```
Toolchain note: the CLT must have a *matched* compiler+SDK. A mismatch (compiler
`…1.10` vs SDK `…1.5`) broke all builds on 2026-06-17; fixed by reinstalling CLT
(`softwareupdate -i "Command Line Tools for Xcode-16.2"`).

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

### Gotchas (no-Xcode / SwiftPM bundle)
- **SwiftUI needs `NSHostingController`, not the `App`/`WindowGroup` lifecycle.**
  Under a hand-wrapped `.app`, SwiftUI windows render but get NO input events.
  Fix: explicit AppKit entry (`main.swift` + `AppDelegate`) building an `NSWindow`
  with `window.contentViewController = NSHostingController(rootView:)`. Reverts to
  plain SwiftUI `App` once on real Xcode. See `App/DiptychonApp.swift`.
- Window may open on an external display / wrong Space -> force onto primary
  (`NSScreen` origin `.zero`) + `makeKeyAndOrderFront` + `NSApp.activate`.
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
| 07 | Batch rename | ✅ done, PR #8 |
| 08–10 | tags, QuickLook/FSEvents, FDA onboarding | not started |
| 11 | Inline single-file rename | ⬜ backlog (split from 07) |

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

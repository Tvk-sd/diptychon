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
| 03–10 | focus/dual-panel, commands, file ops, DnD, rename, tags, QuickLook/FSEvents, FDA onboarding | not started |

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

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
| 01 | Panel lists a local folder (tracer bullet) | ✅ done, awaiting human review (`ready-for-human`) |
| 02–10 | navigation, focus, commands, file ops, DnD, rename, tags, QuickLook/FSEvents, FDA onboarding | not started |

### Issue 01 outcome (2026-06-17)
Tracer bullet works: app launches to one Panel listing a real directory
(name/size/date) via SwiftUI `Table`. Two ADR seams shipped:
- **ADR 0003** `PanelSource` protocol + `LocalDirectorySource` (loads off-main
  via `Task.detached`, prefetches resource keys).
- **ADR 0002** `FileListView` protocol + `TableFileListView`, swappable via the
  `PanelFileList` typealias.
Verified by screenshot on home dir and on a 50k-file folder (loaded off-thread,
virtualized render, no block/crash). Subjective scroll-smoothness left for human.

Open polish (non-blocking): empty files render "Zero KB"; hidden files skipped
(toggle is a later issue); folders show no size by design.
